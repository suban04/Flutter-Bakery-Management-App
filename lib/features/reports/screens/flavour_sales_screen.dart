import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';

class FlavourSalesScreen extends StatefulWidget {
  const FlavourSalesScreen({super.key});

  @override
  State<FlavourSalesScreen> createState() => _FlavourSalesScreenState();
}

class _FlavourSalesScreenState extends State<FlavourSalesScreen> {
  DateTime _selectedDate = DateTime.now();
  List _flavourSummary = [];
  List _rawSales = [];
  int _totalQtySold = 0;
  double _cashTotal = 0;
  double _upiTotal = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadFlavourSales();
  }

  Future<void> _loadFlavourSales() async {
    final db = await DBHelper.database;
    final datePrefix = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final sales = await db.query(
      'sales',
      where: 'date LIKE ?',
      whereArgs: ['$datePrefix%'],
      orderBy: 'id DESC',
    );

    final Map grouped = {};
    int qtySum = 0;
    double cashSum = 0;
    double upiSum = 0;

    for (final s in sales) {
      final mode = (s['payment_mode'] ?? 'Cash').toString().toUpperCase();
      final billAmt = (s['total_amount'] as num).toDouble();
      if (mode == 'UPI') {
        upiSum += billAmt;
      } else {
        cashSum += billAmt;
      }

      final rawJson = (s['items_json'] ?? '[]').toString();
      final List items = jsonDecode(rawJson) as List;
      for (final item in items) {
        final name = item['name'].toString();
        final qty = (item['qty'] as num).toInt();
        final price = (item['price'] as num).toDouble();
        final amt = qty * price;

        qtySum += qty;

        if (grouped.containsKey(name)) {
          grouped[name]['qty'] = (grouped[name]['qty'] as int) + qty;
          grouped[name]['amount'] = (grouped[name]['amount'] as double) + amt;
        } else {
          grouped[name] = {
            'name': name,
            'category': item['category'] ?? '',
            'qty': qty,
            'amount': amt,
          };
        }
      }
    }

    final list = grouped.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));

    if (!mounted) return;
    setState(() {
      _rawSales = sales;
      _flavourSummary = list;
      _totalQtySold = qtySum;
      _cashTotal = cashSum;
      _upiTotal = upiSum;
      _totalRevenue = cashSum + upiSum;
    });
  }

  Future<void> _deleteSaleBill(int saleId, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sale Bill Delete Karein?'),
        content: Text('₹${amount.toStringAsFixed(0)} ka ye sale record delete ho jayega.'),
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
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
    _loadFlavourSales();
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _loadFlavourSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales & Payment Breakdown')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                Text(
                  DateFormat('dd MMM yyyy (EEE)').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
              ],
            ),
          ),

          // Cash, UPI & Total Breakdown Cards
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CASH PAYMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 4),
                            Text('₹${_cashTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('UPI PAYMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 4),
                            Text('₹${_upiTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Sale ($_totalQtySold Items)', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '₹${_totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _rawSales.isEmpty
                ? const Center(child: Text('Is date par koi sale record nahi hai.'))
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                if (_flavourSummary.isNotEmpty) ...[
                  const Text(
                    'Flavour-Wise Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ..._flavourSummary.map((f) {
                    final item = f as Map;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.12),
                          child: Text(
                            '${item['qty']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                          ),
                        ),
                        title: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['category'].toString()),
                        trailing: Text(
                          '₹${(item['amount'] as num).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Bills List (Cash / UPI & Delete)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ..._rawSales.map((s) {
                  final sale = s as Map;
                  final amt = (sale['total_amount'] as num).toDouble();
                  final mode = (sale['payment_mode'] ?? 'Cash').toString();
                  final isUpi = mode.toUpperCase() == 'UPI';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: Chip(
                        label: Text(
                          mode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUpi ? Colors.blue.shade800 : Colors.green.shade800,
                          ),
                        ),
                        backgroundColor: isUpi ? Colors.blue.shade50 : Colors.green.shade50,
                        side: BorderSide.none,
                      ),
                      title: Text('Bill #${sale['id']}'),
                      subtitle: Text(DateFormat('hh:mm a').format(DateTime.parse(sale['date'].toString()))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${amt.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteSaleBill(sale['id'] as int, amt),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}