import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PartyLedgerScreen extends StatefulWidget {
  final Map party;
  const PartyLedgerScreen({super.key, required this.party});

  @override
  State<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends State<PartyLedgerScreen> {
  List _transactions = [];
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _currentBalance = (widget.party['current_balance'] as num).toDouble();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final db = await DBHelper.database;
    final txns = await db.query(
      'bakery_ledger',
      where: 'party_id = ?',
      whereArgs: [widget.party['id']],
      orderBy: 'id DESC',
    );
    final partyData = await db.query(
      'bakery_parties',
      where: 'id = ?',
      whereArgs: [widget.party['id']],
    );

    if (!mounted) return;
    setState(() {
      _transactions = txns;
      if (partyData.isNotEmpty) {
        _currentBalance = (partyData.first['current_balance'] as num).toDouble();
      }
    });
  }

  Future<void> _deleteTransaction(Map txn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Khata Entry Delete Karein?'),
        content: const Text('Ye entry delete karne par total balance apne aap update ho jayega.'),
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
    final amt = (txn['amount'] as num).toDouble();
    final isSupply = txn['type'] == 'SUPPLY';
    final updatedBalance = isSupply ? (_currentBalance - amt) : (_currentBalance + amt);

    await db.transaction((t) async {
      await t.delete('bakery_ledger', where: 'id = ?', whereArgs: [txn['id']]);
      await t.update(
        'bakery_parties',
        {'current_balance': updatedBalance},
        where: 'id = ?',
        whereArgs: [widget.party['id']],
      );
    });
    _loadLedger();
  }

  Future<void> _addTransaction(String type) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(type == 'SUPPLY' ? 'Add Cake Supply' : 'Receive Bill / Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹) *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: type == 'SUPPLY' ? 'Note (Flavour / Weight / Qty)' : 'Note (Cash / UPI / Bill No.)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;

              final navigator = Navigator.of(ctx);
              final db = await DBHelper.database;
              final newBalance = type == 'SUPPLY' ? _currentBalance + amount : _currentBalance - amount;

              await db.transaction((t) async {
                await t.insert('bakery_ledger', {
                  'party_id': widget.party['id'],
                  'date': DateTime.now().toIso8601String(),
                  'type': type,
                  'amount': amount,
                  'note': noteCtrl.text.trim(),
                });

                await t.update(
                  'bakery_parties',
                  {'current_balance': newBalance},
                  where: 'id = ?',
                  whereArgs: [widget.party['id']],
                );
              });

              if (!ctx.mounted) return;
              navigator.pop();
              _loadLedger();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppReminder() async {
    final phone = (widget.party['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return;

    final message = Uri.encodeComponent(
      'Namaste ${widget.party['bakery_name']}, aapka cake supply ka total pending balance ₹${_currentBalance.toStringAsFixed(0)} hai. Kripya jald payment kar dein.',
    );
    final url = Uri.parse('https://wa.me/91$phone?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.party['bakery_name'].toString()),
        actions: [
          if (_currentBalance > 0)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.green),
              tooltip: 'Send WhatsApp Reminder',
              onPressed: _sendWhatsAppReminder,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentBalance > 0
                    ? [Colors.red.shade400, Colors.pink.shade400]
                    : [Colors.green.shade400, Colors.teal.shade400],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pending Balance',
                  style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${_currentBalance.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('Abhi koi khata entry nahi hai.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final txn = _transactions[index] as Map;
                final isSupply = txn['type'] == 'SUPPLY';
                final date = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(txn['date'].toString()));
                final note = (txn['note'] ?? '').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSupply
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      child: Icon(
                        isSupply ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isSupply ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(
                      note.isNotEmpty ? note : (isSupply ? 'Cake Supply' : 'Bill / Payment Received'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(date, style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isSupply ? '+' : '-'} ₹${(txn['amount'] as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSupply ? Colors.red : Colors.green,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Entry',
                          onPressed: () => _deleteTransaction(txn),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _addTransaction('SUPPLY'),
                      icon: const Icon(Icons.cake_rounded),
                      label: const Text('Add Supply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _addTransaction('PAYMENT'),
                      icon: const Icon(Icons.currency_rupee_rounded),
                      label: const Text('Got Payment'),
                    ),
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