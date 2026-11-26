import 'package:flutter/material.dart';
import 'package:jantabackery/core/constants/app_colors.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:jantabackery/core/models/all_models.dart';
import 'package:jantabackery/features/bakery_b2b/screens/party_ledger_screen.dart';
import 'package:jantabackery/shared_widgets/app_button.dart';
import 'package:jantabackery/shared_widgets/app_dialog.dart';
import 'package:jantabackery/shared_widgets/app_text_field.dart';

class BakeryListScreen extends StatefulWidget {
  const BakeryListScreen({super.key});

  @override
  State<BakeryListScreen> createState() => _BakeryListScreenState();
}

class _BakeryListScreenState extends State<BakeryListScreen> {
  List<BakeryPartyModel> _parties = [];

  @override
  void initState() {
    super.initState();
    _loadBakeries();
  }

  Future<void> _loadBakeries() async {
    final db = await DBHelper.database;
    final rows = await db.query('bakery_parties', orderBy: 'bakery_name ASC');
    if (!mounted) return;
    setState(() {
      _parties = rows.map((r) => BakeryPartyModel.fromMap(r)).toList();
    });
  }

  Future<void> _deleteBakery(BakeryPartyModel party) async {
    if (party.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await AppDialog.confirmDelete(
      context,
      title: 'Delete Customer / Bakery?',
      message:
      '"${party.bakeryName}" and all of their khata and supply entries will be permanently deleted.',
    );

    if (!confirm) return;
    final db = await DBHelper.database;
    await db.transaction((txn) async {
      await txn.delete('bakery_ledger', where: 'party_id = ?', whereArgs: [party.id]);
      await txn.delete('b2b_cake_dispatch', where: 'party_id = ?', whereArgs: [party.id]);
      await txn.delete('bakery_parties', where: 'id = ?', whereArgs: [party.id]);
    });

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${party.bakeryName}" khata'),
        backgroundColor: AppColors.danger,
      ),
    );
    _loadBakeries();
  }

  void _showAddBakeryDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    AppDialog.showFormDialog(
      context,
      title: 'Add Bakery / Customer',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: nameCtrl,
            label: 'Bakery / Customer Name *',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: phoneCtrl,
            label: 'Mobile / WhatsApp Number',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save',
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final navigator = Navigator.of(context);
            final db = await DBHelper.database;
            final newParty = BakeryPartyModel(
              bakeryName: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              currentBalance: 0,
            );
            await db.insert('bakery_parties', newParty.toMap());
            if (!mounted) return;
            navigator.pop();
            _loadBakeries();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPending = 0;
    for (final p in _parties) {
      totalPending += p.currentBalance;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('B2B Khata')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddBakeryDialog,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Party'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RECEIVABLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_parties.length} Parties',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  totalPending.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: totalPending > 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _parties.isEmpty
                ? const Center(child: Text('No khata customers added yet.'))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
              itemCount: _parties.length,
              itemBuilder: (context, index) {
                final party = _parties[index];
                final balance = party.currentBalance;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.brown.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    leading: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      party.bakeryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        party.phone.isNotEmpty ? party.phone : 'No phone number',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balance.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: balance > 0 ? AppColors.danger : AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (balance > 0 ? AppColors.danger : AppColors.success)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                balance > 0 ? 'Pending' : 'Settled',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: balance > 0 ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                          ),
                          tooltip: 'Delete Customer',
                          onPressed: () => _deleteBakery(party),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartyLedgerScreen(party: party.toMap()),
                        ),
                      );
                      _loadBakeries();
                    },
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