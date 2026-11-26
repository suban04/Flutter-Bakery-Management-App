import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:jantabackery/features/special_orders/screens/create_order_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List _orders = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final db = await DBHelper.database;
    final rows = await db.query('special_orders', orderBy: 'delivery_date ASC');
    if (!mounted) return;
    setState(() => _orders = rows);
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    final db = await DBHelper.database;
    await db.update(
      'special_orders',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadOrders();
  }

  Future<void> _deleteOrder(int id, String customerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Special Order?'),
        content: Text('Delete order for "$customerName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = await DBHelper.database;
    await db.delete('special_orders', where: 'id = ?', whereArgs: [id]);
    _loadOrders();
  }

  List get _filteredOrders {
    if (_filter == 'All') return _orders;
    return _orders.where((o) => o['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Pending', 'Delivered'];

    return Scaffold(
      appBar: AppBar(title: const Text('Special Cake Orders')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
          );
          if (created == true) _loadOrders();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Order'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = filters[index];
                final isSelected = _filter == f;
                return ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredOrders.isEmpty
                ? const Center(child: Text('No special orders found.'))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index] as Map;
                final total = (order['total_price'] as num).toDouble();
                final advance = (order['advance_paid'] as num).toDouble();
                final balance = (total - advance) < 0 ? 0.0 : (total - advance);
                final status = (order['status'] ?? 'Pending').toString();
                final isDelivered = status == 'Delivered';
                final imgPath = (order['image_path'] ?? '').toString();
                final deliveryDate = DateTime.tryParse(order['delivery_date'].toString());
                final formattedDate = deliveryDate != null
                    ? DateFormat('dd MMM, hh:mm a').format(deliveryDate)
                    : order['delivery_date'].toString();
                final message = (order['message'] ?? '').toString().trim();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imgPath.isNotEmpty && File(imgPath).existsSync()) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imgPath),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['customer_name'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                    color: Color(0xFF2B1B17),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${order['flavour']} (${order['weight']})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: Color(0xFFD81B60),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Delivery: $formattedDate',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDelivered ? Colors.green : Colors.orange)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDelivered
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Message: "$message"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                      const Divider(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Total: ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            'Adv: ${advance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            'Due: ${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isDelivered)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              onPressed: () => _updateStatus(order['id'] as int, 'Delivered'),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: const Text('Mark Delivered', style: TextStyle(fontSize: 12)),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => _deleteOrder(
                              order['id'] as int,
                              order['customer_name'].toString(),
                            ),
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
    );
  }
}