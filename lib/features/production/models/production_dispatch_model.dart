class ProductionEntryModel {
  final int? id;
  final String date;
  final String flavour;
  final String weight;
  final int yesterdayLeftover;
  final int madeToday;
  final double makingCost;
  final double sellingPrice;
  final int remainingToday;

  const ProductionEntryModel({
    this.id,
    required this.date,
    required this.flavour,
    required this.weight,
    this.yesterdayLeftover = 0,
    this.madeToday = 0,
    this.makingCost = 0,
    this.sellingPrice = 0,
    this.remainingToday = 0,
  });

  factory ProductionEntryModel.fromMap(Map<String, dynamic> map) =>
      ProductionEntryModel(
        id: map['id'] as int?,
        date: (map['date'] ?? '').toString(),
        flavour: (map['flavour'] ?? '').toString(),
        weight: (map['weight'] ?? '').toString(),
        yesterdayLeftover: (map['yesterday_leftover'] as num?)?.toInt() ?? 0,
        madeToday: (map['made_today'] as num?)?.toInt() ?? 0,
        makingCost: (map['making_cost'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
        remainingToday: (map['remaining_today'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'flavour': flavour,
    'weight': weight,
    'yesterday_leftover': yesterdayLeftover,
    'made_today': madeToday,
    'making_cost': makingCost,
    'selling_price': sellingPrice,
    'remaining_today': remainingToday,
  };
}

class B2bDispatchModel {
  final int? id;
  final String date;
  final int partyId;
  final String bakeryName;
  final String flavour;
  final String weight;
  final int qty;
  final double pricePerCake;
  final double totalAmount;

  const B2bDispatchModel({
    this.id,
    required this.date,
    required this.partyId,
    required this.bakeryName,
    required this.flavour,
    required this.weight,
    required this.qty,
    required this.pricePerCake,
    required this.totalAmount,
  });

  factory B2bDispatchModel.fromMap(Map<String, dynamic> map) => B2bDispatchModel(
    id: map['id'] as int?,
    date: (map['date'] ?? '').toString(),
    partyId: (map['party_id'] as num?)?.toInt() ?? 0,
    bakeryName: (map['bakery_name'] ?? '').toString(),
    flavour: (map['flavour'] ?? '').toString(),
    weight: (map['weight'] ?? '').toString(),
    qty: (map['qty'] as num?)?.toInt() ?? 0,
    pricePerCake: (map['price_per_cake'] as num?)?.toDouble() ?? 0,
    totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'party_id': partyId,
    'bakery_name': bakeryName,
    'flavour': flavour,
    'weight': weight,
    'qty': qty,
    'price_per_cake': pricePerCake,
    'total_amount': totalAmount,
  };
}