class LedgerTransactionModel {
  final int? id;
  final int partyId;
  final String date;
  final String type; // SUPPLY | ADVANCE | PAYMENT
  final double amount;
  final String note;

  const LedgerTransactionModel({
    this.id,
    required this.partyId,
    required this.date,
    required this.type,
    required this.amount,
    this.note = '',
  });

  factory LedgerTransactionModel.fromMap(Map<String, dynamic> map) =>
      LedgerTransactionModel(
        id: map['id'] as int?,
        partyId: (map['party_id'] as num?)?.toInt() ?? 0,
        date: (map['date'] ?? '').toString(),
        type: (map['type'] ?? 'SUPPLY').toString(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        note: (map['note'] ?? '').toString(),
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'party_id': partyId,
    'date': date,
    'type': type,
    'amount': amount,
    'note': note,
  };
}