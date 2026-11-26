class SaleItemModel {
  final int id;
  final String name;
  final String category;
  final String weight;
  final double price;
  final int stockQty;
  final int qty;

  const SaleItemModel({
    required this.id,
    required this.name,
    required this.category,
    this.weight = '',
    required this.price,
    this.stockQty = 0,
    this.qty = 1,
  });

  double get lineTotal => price * qty;

  SaleItemModel copyWith({
    String? weight,
    double? price,
    int? stockQty,
    int? qty,
  }) {
    return SaleItemModel(
      id: id,
      name: name,
      category: category,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      stockQty: stockQty ?? this.stockQty,
      qty: qty ?? this.qty,
    );
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) => SaleItemModel(
    id: (map['id'] as num?)?.toInt() ?? 0,
    name: (map['name'] ?? '').toString(),
    category: (map['category'] ?? 'Other').toString(),
    weight: (map['weight'] ?? '').toString(),
    price: (map['price'] as num?)?.toDouble() ?? 0,
    stockQty: (map['stock_qty'] as num?)?.toInt() ?? 0,
    qty: (map['qty'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'weight': weight,
    'price': price,
    'stock_qty': stockQty,
    'qty': qty,
  };
}