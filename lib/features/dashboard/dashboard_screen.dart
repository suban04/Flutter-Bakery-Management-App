import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:jantabackery/core/utils/formatters.dart';
import 'package:jantabackery/features/expenses/screens/expense_screen.dart';
import 'package:jantabackery/features/inventory/screens/stock_list_screen.dart';
import 'package:jantabackery/features/production/screens/daily_production_screen.dart';
import 'package:jantabackery/features/reports/screens/flavour_sales_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _todaySales = 0;
  double _todayExpenses = 0;
  int _pendingOrders = 0;
  double _totalBalance = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final db = await DBHelper.database;
    final todayPrefix = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final sales = await db.query(
      'sales',
      where: 'date LIKE ?',
      whereArgs: ['$todayPrefix%'],
    );
    double saleSum = 0;
    for (final s in sales) {
      saleSum += (s['total_amount'] as num).toDouble();
    }

    final expenses = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$todayPrefix%'],
    );
    double expSum = 0;
    for (final e in expenses) {
      expSum += (e['amount'] as num).toDouble();
    }

    final orders = await db.query(
      'special_orders',
      where: 'status = ?',
      whereArgs: ['Pending'],
    );

    final parties = await db.query('bakery_parties');
    double balanceSum = 0;
    for (final p in parties) {
      balanceSum += (p['current_balance'] as num).toDouble();
    }

    final items = await db.query('items');
    int lowCount = 0;
    for (final item in items) {
      final qty = (item['stock_qty'] as num).toInt();
      final limit = (item['low_stock_limit'] as num).toInt();
      if (limit > 0 && qty <= limit) lowCount++;
    }

    if (!mounted) return;
    setState(() {
      _todaySales = saleSum;
      _todayExpenses = expSum;
      _pendingOrders = orders.length;
      _totalBalance = balanceSum;
      _lowStockCount = lowCount;
    });
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B1B17).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2B1B17),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B1B17).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6F4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
          _loadSummary();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD81B60).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 34,
                  width: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.cake_rounded,
                    color: Color(0xFFD81B60),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Janta Bakery'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                _statCard(
                  'Today Sales',
                  AppFormatters.currency(_todaySales),
                  Icons.currency_rupee_rounded,
                  Colors.green,
                ),
                _statCard(
                  'Pending Orders',
                  '$_pendingOrders Cakes',
                  Icons.cake_rounded,
                  const Color(0xFFD81B60),
                ),
                _statCard(
                  'Bakery Balance',
                  AppFormatters.currency(_totalBalance),
                  Icons.store_rounded,
                  Colors.red,
                ),
                _statCard(
                  'Today Expenses',
                  AppFormatters.currency(_todayExpenses),
                  Icons.receipt_long_rounded,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_lowStockCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                  title: Text(
                    '$_lowStockCount items low stock!',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Check cake or decoration stock',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StockListScreen()),
                    );
                    _loadSummary();
                  },
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 12),
              child: Text(
                'Quick Manage',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            _quickTile(
              title: 'Flavour-Wise Daily Sales',
              subtitle: 'Daily cake sales by flavour & payment split',
              icon: Icons.bar_chart_rounded,
              color: Colors.teal,
              destination: const FlavourSalesScreen(),
            ),
            _quickTile(
              title: 'Daily Cake Production & B2B Supply',
              subtitle: 'Made today, leftover, and bakery supply',
              icon: Icons.bakery_dining_rounded,
              color: Colors.purple,
              destination: const DailyProductionScreen(),
            ),
            _quickTile(
              title: 'Decoration & Cake Stock',
              subtitle: 'Edit product name, price, and stock',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFFD81B60),
              destination: const StockListScreen(),
            ),
            _quickTile(
              title: 'Daily Expenses',
              subtitle: 'Track raw material, rent, and bills',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.orange,
              destination: const ExpenseScreen(),
            ),
          ],
        ),
      ),
    );
  }
}