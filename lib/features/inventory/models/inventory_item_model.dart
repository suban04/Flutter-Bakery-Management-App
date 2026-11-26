class InventoryItemModel {
  final int? id;
  final String name;
  final String category;
  final double price;
  final int stockQty;
  final int lowStockLimit;

  const InventoryItemModel({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQty,
    this.lowStockLimit = 0,
  });

  bool get isLowStock => lowStockLimit > 0 && stockQty <= lowStockLimit;

  factory InventoryItemModel.fromMap(Map<String, dynamic> map) =>
      InventoryItemModel(
        id: map['id'] as int?,
        name: (map['name'] ?? '').toString(),
        category: (map['category'] ?? 'Other').toString(),
        price: (map['price'] as num?)?.toDouble() ?? 0,
        stockQty: (map['stock_qty'] as num?)?.toInt() ?? 0,
        lowStockLimit: (map['low_stock_limit'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'price': price,
    'stock_qty': stockQty,
    'low_stock_limit': lowStockLimit,
  };
}