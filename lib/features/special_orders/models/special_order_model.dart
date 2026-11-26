class SpecialOrderItemModel {
  final int? id;
  final String customerName;
  final String phone;
  final String flavour;
  final String weight;
  final String message;
  final double totalPrice;
  final double advancePaid;
  final String deliveryDate;
  final String imagePath;
  final String status;

  const SpecialOrderItemModel({
    this.id,
    required this.customerName,
    required this.phone,
    required this.flavour,
    required this.weight,
    this.message = '',
    required this.totalPrice,
    this.advancePaid = 0,
    required this.deliveryDate,
    this.imagePath = '',
    this.status = 'Pending',
  });

  double get remainingBalance =>
      (totalPrice - advancePaid) < 0 ? 0.0 : (totalPrice - advancePaid);

  factory SpecialOrderItemModel.fromMap(Map<String, dynamic> map) =>
      SpecialOrderItemModel(
        id: map['id'] as int?,
        customerName: (map['customer_name'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        flavour: (map['flavour'] ?? '').toString(),
        weight: (map['weight'] ?? '').toString(),
        message: (map['message'] ?? '').toString(),
        totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0,
        advancePaid: (map['advance_paid'] as num?)?.toDouble() ?? 0,
        deliveryDate: (map['delivery_date'] ?? '').toString(),
        imagePath: (map['image_path'] ?? '').toString(),
        status: (map['status'] ?? 'Pending').toString(),
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_name': customerName,
    'phone': phone,
    'flavour': flavour,
    'weight': weight,
    'message': message,
    'total_price': totalPrice,
    'advance_paid': advancePaid,
    'delivery_date': deliveryDate,
    'image_path': imagePath,
    'status': status,
  };
}