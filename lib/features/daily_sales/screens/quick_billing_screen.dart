import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';

class QuickBillingScreen extends StatefulWidget {
  const QuickBillingScreen({super.key});

  @override
  State<QuickBillingScreen> createState() => _QuickBillingScreenState();
}

class _QuickBillingScreenState extends State<QuickBillingScreen> {
  String selectedCategory = 'All';
  String paymentMode = 'Cash';
  bool isLoading = true;

  double _todayCashSales = 0;
  double _todayUpiSales = 0;

  List menuItems = [];
  final Map cart = {};
  int _customIdCounter = -1;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    _loadTodayPaymentTotals();
  }

  Future<void> _loadTodayPaymentTotals() async {
    final db = await DBHelper.database;
    final todayPrefix = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sales = await db.query(
      'sales',
      where: 'date LIKE ?',
      whereArgs: ['$todayPrefix%'],
    );

    double cashSum = 0;
    double upiSum = 0;

    for (final row in sales) {
      final amt = (row['total_amount'] as num).toDouble();
      final mode = (row['payment_mode'] ?? 'Cash').toString().toUpperCase();
      if (mode == 'UPI') {
        upiSum += amt;
      } else {
        cashSum += amt;
      }
    }

    if (!mounted) return;
    setState(() {
      _todayCashSales = cashSum;
      _todayUpiSales = upiSum;
    });
  }

  Future<void> _loadMenuItems() async {
    final db = await DBHelper.database;
    final data = await db.query('items', orderBy: 'category ASC, name ASC');

    if (!mounted) return;
    setState(() {
      menuItems = data;
      isLoading = false;
    });
  }

  List get filteredItems {
    if (selectedCategory == 'All') return menuItems;
    return menuItems.where((item) => item['category'] == selectedCategory).toList();
  }

  double get totalAmount {
    double total = 0;
    for (final entry in cart.values) {
      total += (entry['price'] as num).toDouble() * (entry['qty'] as int);
    }
    return total;
  }

  int get totalItems {
    int count = 0;
    for (final entry in cart.values) {
      count += entry['qty'] as int;
    }
    return count;
  }

  void addToCart(Map item, {double? customPrice, String? customWeight}) {
    final int id = item['id'] as int;
    final int availableStock = (item['stock_qty'] as num).toInt();
    final int currentQty = (cart[id]?['qty'] as int?) ?? 0;

    if (item['category'] == 'Decoration' && id > 0 && currentQty >= availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['name']} has only $availableStock stock left.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      if (cart.containsKey(id)) {
        cart[id]['qty'] = currentQty + 1;
        if (customPrice != null) cart[id]['price'] = customPrice;
        if (customWeight != null && customWeight.isNotEmpty) {
          cart[id]['weight'] = customWeight;
        }
      } else {
        cart[id] = {
          ...item,
          'weight': customWeight ?? (item['weight'] ?? ''),
          'price': customPrice ?? (item['price'] as num).toDouble(),
          'qty': 1,
        };
      }
    });
  }

  void _showManualPriceAndWeightDialog(Map item) {
    final priceCtrl = TextEditingController(
      text: ((cart[item['id']]?['price'] ?? item['price']) as num).toStringAsFixed(0),
    );
    final weightCtrl = TextEditingController(
      text: (cart[item['id']]?['weight'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Rate / Weight: ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Price *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(
                labelText: 'Custom Weight (e.g. 1/2 Kg, 1 Kg, 1.5 Kg)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text);
              if (newPrice != null && newPrice > 0) {
                addToCart(
                  item,
                  customPrice: newPrice,
                  customWeight: weightCtrl.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add to Bill'),
          ),
        ],
      ),
    );
  }

  void _showCustomProductDialog() {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Half Kg';
    bool saveToMenu = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Product to Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Flavour / Item Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Weight (e.g. 1/2 Kg, 1 Kg, 2 Kg)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Half Kg', '1 Kg', 'Decoration', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save to stock menu', style: TextStyle(fontSize: 13)),
                  value: saveToMenu,
                  onChanged: (v) => setDialogState(() => saveToMenu = v ?? true),
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
                final rawName = nameCtrl.text.trim();
                final weightText = weightCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (rawName.isEmpty || price <= 0) return;

                final fullName = weightText.isNotEmpty ? '$rawName ($weightText)' : rawName;
                final navigator = Navigator.of(ctx);

                if (saveToMenu) {
                  final db = await DBHelper.database;
                  final newId = await db.insert('items', {
                    'name': fullName,
                    'category': category,
                    'price': price,
                    'stock_qty': 0,
                    'low_stock_limit': 0,
                  });
                  await _loadMenuItems();
                  addToCart({
                    'id': newId,
                    'name': fullName,
                    'category': category,
                    'price': price,
                    'stock_qty': 0,
                  });
                } else {
                  addToCart({
                    'id': _customIdCounter--,
                    'name': fullName,
                    'category': category,
                    'price': price,
                    'stock_qty': 0,
                  });
                }
                if (!ctx.mounted) return;
                navigator.pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void removeFromCart(int id) {
    setState(() {
      if (!cart.containsKey(id)) return;
      if ((cart[id]['qty'] as int) > 1) {
        cart[id]['qty'] = (cart[id]['qty'] as int) - 1;
      } else {
        cart.remove(id);
      }
    });
  }

  Future<void> saveBill() async {
    if (cart.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final soldItems = cart.values.toList();
    final billTotal = totalAmount;
    final billMode = paymentMode;

    final db = await DBHelper.database;
    await db.transaction((txn) async {
      await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'total_amount': billTotal,
        'payment_mode': billMode,
        'items_json': jsonEncode(soldItems),
      });

      for (final entry in soldItems) {
        final int itemId = entry['id'] as int;
        if (itemId > 0) {
          final int soldQty = entry['qty'] as int;
          final int oldStock = (entry['stock_qty'] as num).toInt();
          final int newStock = (oldStock - soldQty) < 0 ? 0 : (oldStock - soldQty);
          await txn.update(
            'items',
            {'stock_qty': newStock},
            where: 'id = ?',
            whereArgs: [itemId],
          );
        }
      }
    });

    if (!mounted) return;
    setState(() => cart.clear());
    await _loadMenuItems();
    await _loadTodayPaymentTotals();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Bill Saved! Total: ${billTotal.toStringAsFixed(0)} ($billMode)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _paymentTotalBadge(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B1B17).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              amount.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Half Kg', '1 Kg', 'Decoration', 'Other'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Janta Bakery Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Color(0xFFD81B60)),
            tooltip: 'Add Item',
            onPressed: _showCustomProductDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadMenuItems();
              _loadTodayPaymentTotals();
            },
          ),
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => setState(() => cart.clear()),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                _paymentTotalBadge('TODAY CASH', _todayCashSales, Colors.green),
                const SizedBox(width: 10),
                _paymentTotalBadge('TODAY UPI', _todayUpiSales, Colors.blue),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedCategory = cat),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Long press item for custom rate/weight • Tap + to add product',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _showCustomProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Product to Bill'),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.12,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index] as Map;
                final qtyInCart = (cart[item['id']]?['qty'] as int?) ?? 0;
                final displayPrice = (cart[item['id']]?['price'] ?? item['price']) as num;
                final stockQty = (item['stock_qty'] as num).toInt();
                final isOutOfStock = item['category'] == 'Decoration' && stockQty <= 0;

                return Container(
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: qtyInCart > 0
                          ? const Color(0xFFD81B60)
                          : Colors.brown.withValues(alpha: 0.08),
                      width: qtyInCart > 0 ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B1B17).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: isOutOfStock ? null : () => addToCart(item),
                    onLongPress: isOutOfStock
                        ? null
                        : () => _showManualPriceAndWeightDialog(item),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF2B1B17),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stock: $stockQty',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayPrice.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD81B60),
                                ),
                              ),
                              if (qtyInCart > 0)
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => removeFromCart(item['id'] as int),
                                      child: const Icon(
                                        Icons.remove_circle_rounded,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Text(
                                        '$qtyInCart',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => addToCart(item),
                                      child: const Icon(
                                        Icons.add_circle_rounded,
                                        color: Colors.green,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B1B17).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Payment:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: paymentMode == 'Cash',
                          onSelected: (_) => setState(() => paymentMode = 'Cash'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('UPI'),
                          selected: paymentMode == 'UPI',
                          onSelected: (_) => setState(() => paymentMode = 'UPI'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalItems Items',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text(
                              totalAmount.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2B1B17),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD81B60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          onPressed: saveBill,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Save Bill', style: TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}