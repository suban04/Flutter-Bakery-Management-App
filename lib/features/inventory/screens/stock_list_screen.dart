import 'package:flutter/material.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:jantabackery/core/utils/formatters.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  List _items = [];

  final List<String> _flavourPresets = [
    'Chocolate',
    'Black Forest',
    'Pineapple',
    'Rasmalai',
    'Chocolate Truffle',
    'Butterscotch',
    'Custom',
  ];

  final List<String> _weightPresets = [
    '1/2 Kg',
    '1 Kg',
    '1.5 Kg',
    '2 Kg',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = await DBHelper.database;
    final data = await db.query('items', orderBy: 'category ASC, name ASC');
    if (!mounted) return;
    setState(() => _items = data);
  }

  Future<void> _deleteItem(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item?'),
        content: Text('Remove "$name" from stock list?'),
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
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "$name"'), backgroundColor: Colors.redAccent),
    );
    _loadItems();
  }

  void _showAddOrEditItemDialog({Map? existingItem}) {
    final isEdit = existingItem != null;
    final validCategories = ['Half Kg', '1 Kg', 'Decoration', 'Other'];
    String category = isEdit && validCategories.contains(existingItem['category'])
        ? existingItem['category'].toString()
        : 'Half Kg';

    String selectedFlavour = 'Chocolate';
    String selectedWeight = '1/2 Kg';
    final nameCtrl = TextEditingController(
      text: isEdit ? existingItem['name'].toString() : '',
    );
    final customWeightCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: isEdit ? (existingItem['price'] as num).toStringAsFixed(0) : '',
    );
    final qtyCtrl = TextEditingController(
      text: isEdit ? existingItem['stock_qty'].toString() : '',
    );
    final limitCtrl = TextEditingController(
      text: isEdit ? existingItem['low_stock_limit'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Stock Item' : 'Add Stock Item',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: validCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                if (!isEdit && category != 'Decoration') ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedFlavour,
                    decoration: const InputDecoration(labelText: 'Flavour'),
                    items: _flavourPresets
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedFlavour = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedWeight,
                    decoration: const InputDecoration(labelText: 'Weight'),
                    items: _weightPresets
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedWeight = v);
                    },
                  ),
                  if (selectedWeight == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customWeightCtrl,
                      decoration: const InputDecoration(labelText: 'Custom Weight (e.g. 1.5 Kg)'),
                    ),
                  ],
                  if (selectedFlavour == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Custom Item Name *'),
                    ),
                  ],
                ] else ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customWeightCtrl,
                    decoration: const InputDecoration(labelText: 'Weight (Optional, e.g. 1.5 Kg)'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock Qty'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Low Stock Alert Limit'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String finalName = nameCtrl.text.trim();
                final weightVal = (!isEdit && category != 'Decoration')
                    ? (selectedWeight == 'Custom' ? customWeightCtrl.text.trim() : selectedWeight)
                    : customWeightCtrl.text.trim();

                if (!isEdit && category != 'Decoration' && selectedFlavour != 'Custom') {
                  finalName = weightVal.isNotEmpty ? '$selectedFlavour ($weightVal)' : selectedFlavour;
                } else if (weightVal.isNotEmpty && !finalName.contains(weightVal)) {
                  finalName = '$finalName ($weightVal)';
                }

                if (finalName.isEmpty) return;
                final navigator = Navigator.of(ctx);
                final db = await DBHelper.database;
                final rowData = {
                  'name': finalName,
                  'category': category,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'stock_qty': int.tryParse(qtyCtrl.text) ?? 0,
                  'low_stock_limit': int.tryParse(limitCtrl.text) ?? 0,
                };

                if (isEdit) {
                  await db.update('items', rowData, where: 'id = ?', whereArgs: [existingItem['id']]);
                } else {
                  await db.insert('items', rowData);
                }

                if (!ctx.mounted) return;
                navigator.pop();
                _loadItems();
              },
              child: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateQty(int id, int newQty) async {
    if (newQty < 0) return;
    final db = await DBHelper.database;
    await db.update('items', {'stock_qty': newQty}, where: 'id = ?', whereArgs: [id]);
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decoration & Cake Stock')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
        onPressed: () => _showAddOrEditItemDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No stock items yet. Tap Add Item to start.'))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index] as Map;
          final qty = (item['stock_qty'] as num).toInt();
          final limit = (item['low_stock_limit'] as num).toInt();
          final isLow = limit > 0 && qty <= limit;
          final accentColor = isLow ? Colors.red.shade600 : const Color(0xFFD81B60);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLow ? Colors.red.shade200 : Colors.brown.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B1B17).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['category'] == 'Decoration'
                            ? Icons.celebration_rounded
                            : Icons.cake_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF2B1B17),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item['category']} • ${AppFormatters.currency(item['price'] as num)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      onPressed: () => _showAddOrEditItemDialog(existingItem: item),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _deleteItem(item['id'] as int, item['name'].toString()),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isLow ? Colors.red : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isLow ? 'Low Stock Alert' : 'Current Stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLow ? Colors.red.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: () => _updateQty(item['id'] as int, qty - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$qty',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: () => _updateQty(item['id'] as int, qty + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}