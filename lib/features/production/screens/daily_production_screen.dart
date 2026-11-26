import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class DailyProductionScreen extends StatefulWidget {
  const DailyProductionScreen({super.key});

  @override
  State<DailyProductionScreen> createState() => _DailyProductionScreenState();
}

class _DailyProductionScreenState extends State<DailyProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  List _productionList = [];
  List _b2bDispatchList = [];
  List _bakeries = [];
  List<String> _flavourOptions = ['Other (Custom)'];

  final List<String> _weightOptions = [
    '1/2 Kg',
    '1 Kg',
    '1.5 Kg',
    '2 Kg',
    'Custom',
  ];

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final db = await DBHelper.database;

    final prod = await db.query(
      'daily_production',
      where: 'date = ?',
      whereArgs: [_dateKey],
      orderBy: 'id DESC',
    );

    final dispatch = await db.query(
      'b2b_cake_dispatch',
      where: 'date = ?',
      whereArgs: [_dateKey],
      orderBy: 'id DESC',
    );

    final parties = await db.query('bakery_parties', orderBy: 'bakery_name ASC');

    final prodFlavours = await db.query('daily_production', columns: ['flavour']);
    final dispatchFlavours = await db.query('b2b_cake_dispatch', columns: ['flavour']);
    final Set<String> uniqueFlavours = {};
    for (final r in prodFlavours) {
      final f = (r['flavour'] ?? '').toString().trim();
      if (f.isNotEmpty) uniqueFlavours.add(f);
    }
    for (final r in dispatchFlavours) {
      final f = (r['flavour'] ?? '').toString().trim();
      if (f.isNotEmpty) uniqueFlavours.add(f);
    }

    final sortedFlavours = uniqueFlavours.toList()..sort();
    sortedFlavours.add('Other (Custom)');

    if (!mounted) return;
    setState(() {
      _productionList = prod;
      _b2bDispatchList = dispatch;
      _bakeries = parties;
      _flavourOptions = sortedFlavours;
    });
  }

  Future<void> _syncNewFlavourToSystem(
      Transaction txn, {
        required String flavour,
        required String weight,
        required double price,
      }) async {
    final itemName = '$flavour ($weight)';
    final existingItems = await txn.query(
      'items',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [itemName],
    );
    if (existingItems.isEmpty) {
      await txn.insert('items', {
        'name': itemName,
        'category': weight == '1 Kg' ? '1 Kg' : 'Half Kg',
        'price': price,
        'stock_qty': 0,
        'low_stock_limit': 0,
      });
    }

    final existingProd = await txn.query(
      'daily_production',
      where: 'date = ? AND LOWER(flavour) = LOWER(?) AND weight = ?',
      whereArgs: [_dateKey, flavour, weight],
    );
    if (existingProd.isEmpty) {
      await txn.insert('daily_production', {
        'date': _dateKey,
        'flavour': flavour,
        'weight': weight,
        'yesterday_leftover': 0,
        'made_today': 0,
        'making_cost': 0,
        'selling_price': price,
        'remaining_today': 0,
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadAllData();
    }
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _loadAllData();
  }

  Future<void> _importYesterdayLeftover() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = await DBHelper.database;
    final yesterdayKey = DateFormat('yyyy-MM-dd')
        .format(_selectedDate.subtract(const Duration(days: 1)));

    final yesterdayData = await db.query(
      'daily_production',
      where: 'date = ? AND remaining_today > 0',
      whereArgs: [yesterdayKey],
    );

    if (yesterdayData.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No leftover cakes found from yesterday.')),
      );
      return;
    }

    int importedCount = 0;
    for (final row in yesterdayData) {
      final existing = await db.query(
        'daily_production',
        where: 'date = ? AND flavour = ? AND weight = ?',
        whereArgs: [_dateKey, row['flavour'], row['weight']],
      );

      if (existing.isEmpty) {
        final leftQty = (row['remaining_today'] as num).toInt();
        await db.insert('daily_production', {
          'date': _dateKey,
          'flavour': row['flavour'],
          'weight': row['weight'],
          'yesterday_leftover': leftQty,
          'made_today': 0,
          'making_cost': row['making_cost'],
          'selling_price': row['selling_price'],
          'remaining_today': leftQty,
        });
        importedCount++;
      }
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Imported leftover cakes for $importedCount flavours.'),
        backgroundColor: Colors.green,
      ),
    );
    _loadAllData();
  }

  void _showAddProductionDialog() {
    String selectedFlavour = _flavourOptions.first;
    final customFlavourCtrl = TextEditingController();
    String selectedWeight = _weightOptions.first;
    final customWeightCtrl = TextEditingController();
    final yesterdayCtrl = TextEditingController();
    final madeTodayCtrl = TextEditingController();
    final makingCostCtrl = TextEditingController();
    final sellingPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cake Production Entry',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedFlavour,
                  decoration: const InputDecoration(labelText: 'Flavour *'),
                  items: _flavourOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedFlavour = v);
                  },
                ),
                if (selectedFlavour == 'Other (Custom)') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customFlavourCtrl,
                    decoration: const InputDecoration(labelText: 'New Flavour Name *'),
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedWeight,
                  decoration: const InputDecoration(labelText: 'Weight *'),
                  items: _weightOptions
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedWeight = v);
                  },
                ),
                if (selectedWeight == 'Custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customWeightCtrl,
                    decoration: const InputDecoration(labelText: 'Custom Weight (e.g. 1.5 Kg) *'),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yesterdayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Yesterday Left'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: madeTodayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Made Today *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: makingCostCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Making Cost'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final flavour = selectedFlavour == 'Other (Custom)'
                    ? customFlavourCtrl.text.trim()
                    : selectedFlavour;
                final weight = selectedWeight == 'Custom'
                    ? customWeightCtrl.text.trim()
                    : selectedWeight;
                if (flavour.isEmpty || weight.isEmpty) return;

                final navigator = Navigator.of(ctx);
                final yest = int.tryParse(yesterdayCtrl.text) ?? 0;
                final made = int.tryParse(madeTodayCtrl.text) ?? 0;
                final price = double.tryParse(sellingPriceCtrl.text) ?? 0;
                final db = await DBHelper.database;

                await db.transaction((txn) async {
                  await txn.insert('daily_production', {
                    'date': _dateKey,
                    'flavour': flavour,
                    'weight': weight,
                    'yesterday_leftover': yest,
                    'made_today': made,
                    'making_cost': double.tryParse(makingCostCtrl.text) ?? 0,
                    'selling_price': price,
                    'remaining_today': yest + made,
                  });

                  final itemName = '$flavour ($weight)';
                  final existingItem = await txn.query(
                    'items',
                    where: 'LOWER(name) = LOWER(?)',
                    whereArgs: [itemName],
                  );
                  if (existingItem.isEmpty) {
                    await txn.insert('items', {
                      'name': itemName,
                      'category': weight == '1 Kg' ? '1 Kg' : 'Half Kg',
                      'price': price,
                      'stock_qty': yest + made,
                      'low_stock_limit': 0,
                    });
                  }
                });

                if (!ctx.mounted) return;
                navigator.pop();
                _loadAllData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRemaining(int id, int newQty) async {
    if (newQty < 0) return;
    final db = await DBHelper.database;
    await db.update(
      'daily_production',
      {'remaining_today': newQty},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadAllData();
  }

  Future<void> _deleteProduction(int id, String flavour) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Entry?'),
        content: Text('Delete production entry for "$flavour"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = await DBHelper.database;
    await db.delete('daily_production', where: 'id = ?', whereArgs: [id]);
    _loadAllData();
  }

  void _showAddB2bDispatchDialog() {
    if (_bakeries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a party in B2B Khata first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int selectedPartyId = _bakeries.first['id'] as int;
    String selectedFlavour = _flavourOptions.first;
    final customFlavourCtrl = TextEditingController();
    String selectedWeight = _weightOptions.first;
    final customWeightCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final rateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'B2B Bakery Cake Supply',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedPartyId,
                  decoration: const InputDecoration(labelText: 'Select Bakery / Party *'),
                  items: _bakeries
                      .map(
                        (b) => DropdownMenuItem<int>(
                      value: b['id'] as int,
                      child: Text(b['bakery_name'].toString()),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedPartyId = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedFlavour,
                  decoration: const InputDecoration(labelText: 'Flavour *'),
                  items: _flavourOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedFlavour = v);
                  },
                ),
                if (selectedFlavour == 'Other (Custom)') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customFlavourCtrl,
                    decoration: const InputDecoration(labelText: 'New Flavour Name *'),
                  ),
                ],
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedWeight,
                  decoration: const InputDecoration(labelText: 'Weight *'),
                  items: _weightOptions
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedWeight = v);
                  },
                ),
                if (selectedWeight == 'Custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customWeightCtrl,
                    decoration: const InputDecoration(labelText: 'Custom Weight (e.g. 1.5 Kg) *'),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Rate *'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final flavour = selectedFlavour == 'Other (Custom)'
                    ? customFlavourCtrl.text.trim()
                    : selectedFlavour;
                final weight = selectedWeight == 'Custom'
                    ? customWeightCtrl.text.trim()
                    : selectedWeight;
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                final rate = double.tryParse(rateCtrl.text) ?? 0;
                if (flavour.isEmpty || weight.isEmpty || qty <= 0 || rate <= 0) return;

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final bakery = _bakeries.firstWhere((b) => b['id'] == selectedPartyId);
                final bakeryName = bakery['bakery_name'].toString();
                final totalAmt = qty * rate;
                final currentBal = (bakery['current_balance'] as num).toDouble();

                final db = await DBHelper.database;
                await db.transaction((txn) async {
                  await _syncNewFlavourToSystem(
                    txn,
                    flavour: flavour,
                    weight: weight,
                    price: rate,
                  );

                  await txn.insert('b2b_cake_dispatch', {
                    'date': _dateKey,
                    'party_id': selectedPartyId,
                    'bakery_name': bakeryName,
                    'flavour': flavour,
                    'weight': weight,
                    'qty': qty,
                    'price_per_cake': rate,
                    'total_amount': totalAmt,
                  });

                  await txn.insert('bakery_ledger', {
                    'party_id': selectedPartyId,
                    'date': DateTime.now().toIso8601String(),
                    'type': 'SUPPLY',
                    'amount': totalAmt,
                    'note': '$qty x $flavour ($weight) @ ${rate.toStringAsFixed(0)}',
                  });

                  await txn.update(
                    'bakery_parties',
                    {'current_balance': currentBal + totalAmt},
                    where: 'id = ?',
                    whereArgs: [selectedPartyId],
                  );
                });

                if (!ctx.mounted) return;
                navigator.pop();
                await _loadAllData();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Saved $flavour ($weight) supply for $bakeryName.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save Supply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteB2bDispatch(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Supply?'),
        content: Text(
          'Deleting this entry will reduce ${item['bakery_name']} balance by ${(item['total_amount'] as num).toStringAsFixed(0)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = await DBHelper.database;
    final partyId = item['party_id'] as int;
    final amt = (item['total_amount'] as num).toDouble();

    await db.transaction((txn) async {
      await txn.delete('b2b_cake_dispatch', where: 'id = ?', whereArgs: [item['id']]);
      final party = await txn.query('bakery_parties', where: 'id = ?', whereArgs: [partyId]);
      if (party.isNotEmpty) {
        final oldBal = (party.first['current_balance'] as num).toDouble();
        await txn.update(
          'bakery_parties',
          {'current_balance': oldBal - amt},
          where: 'id = ?',
          whereArgs: [partyId],
        );
      }
    });
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    int totalYesterday = 0;
    int totalMade = 0;
    int totalRemaining = 0;
    for (final p in _productionList) {
      totalYesterday += (p['yesterday_leftover'] as num).toInt();
      totalMade += (p['made_today'] as num).toInt();
      totalRemaining += (p['remaining_today'] as num).toInt();
    }

    int totalB2bCakes = 0;
    double totalB2bAmount = 0;
    for (final b in _b2bDispatchList) {
      totalB2bCakes += (b['qty'] as num).toInt();
      totalB2bAmount += (b['total_amount'] as num).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Production & B2B'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE91E63),
          indicatorColor: const Color(0xFFE91E63),
          tabs: const [
            Tab(icon: Icon(Icons.cake_rounded), text: 'Production'),
            Tab(icon: Icon(Icons.local_shipping_rounded), text: 'B2B Supply'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Color(0xFFE91E63)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd MMM yyyy (EEE)').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _miniStat('Leftover', '$totalYesterday', Colors.orange),
                          const SizedBox(width: 8),
                          _miniStat('Made', '$totalMade', Colors.pink),
                          const SizedBox(width: 8),
                          _miniStat('Remaining', '$totalRemaining', Colors.green),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importYesterdayLeftover,
                              icon: const Icon(Icons.history_rounded, size: 18),
                              label: const Text('Import Leftover'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _showAddProductionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Cake'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _productionList.isEmpty
                          ? const Center(child: Text('No production entries for this date.'))
                          : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _productionList.length,
                        itemBuilder: (context, index) {
                          final p = _productionList[index] as Map;
                          final yest = (p['yesterday_leftover'] as num).toInt();
                          final made = (p['made_today'] as num).toInt();
                          final rem = (p['remaining_today'] as num).toInt();
                          final cost = (p['making_cost'] as num).toDouble();
                          final price = (p['selling_price'] as num).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${p['flavour']} (${p['weight']})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                      onPressed: () => _deleteProduction(p['id'] as int, p['flavour'].toString()),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Leftover: $yest  |  Made: $made  |  Total: ${yest + made}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cost: ${cost.toStringAsFixed(0)}  •  Price: ${price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Remaining:', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Row(
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                          onPressed: () => _updateRemaining(p['id'] as int, rem - 1),
                                        ),
                                        Text('$rem', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                          onPressed: () => _updateRemaining(p['id'] as int, rem + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _miniStat('B2B Cakes', '$totalB2bCakes', Colors.blue),
                          const SizedBox(width: 8),
                          _miniStat(
                            'Total Bill',
                            totalB2bAmount.toStringAsFixed(0),
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _showAddB2bDispatchDialog,
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: const Text('Add Bakery Cake Supply'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _b2bDispatchList.isEmpty
                          ? const Center(child: Text('No B2B supply entries for this date.'))
                          : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _b2bDispatchList.length,
                        itemBuilder: (context, index) {
                          final b = _b2bDispatchList[index] as Map;
                          final wText = (b['weight'] ?? '').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.pink.withValues(alpha: 0.12),
                                child: Text(
                                  '${b['qty']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                                ),
                              ),
                              title: Text(
                                '${b['bakery_name']} — ${b['flavour']}${wText.isNotEmpty ? ' ($wText)' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                'Rate: ${(b['price_per_cake'] as num).toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (b['total_amount'] as num).toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.green,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _deleteB2bDispatch(b),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}