class BakeryPartyModel {
  final int? id;
  final String bakeryName;
  final String phone;
  final double currentBalance;

  const BakeryPartyModel({
    this.id,
    required this.bakeryName,
    this.phone = '',
    this.currentBalance = 0,
  });

  factory BakeryPartyModel.fromMap(Map<String, dynamic> map) => BakeryPartyModel(
    id: map['id'] as int?,
    bakeryName: (map['bakery_name'] ?? '').toString(),
    phone: (map['phone'] ?? '').toString(),
    currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'bakery_name': bakeryName,
    'phone': phone,
    'current_balance': currentBalance,
  };
}