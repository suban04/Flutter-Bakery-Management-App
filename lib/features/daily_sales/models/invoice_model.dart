import 'dart:convert';
import 'package:jantabackery/features/daily_sales/models/sale_item_model.dart';

class InvoiceModel {
  final int? id;
  final String date;
  final double totalAmount;
  final String paymentMode; // Cash | UPI
  final List<SaleItemModel> items;

  const InvoiceModel({
    this.id,
    required this.date,
    required this.totalAmount,
    required this.paymentMode,
    this.items = const [],
  });

  String get itemsJson => jsonEncode(items.map((e) => e.toMap()).toList());

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    final rawJson = (map['items_json'] ?? '[]').toString();
    final List decoded = jsonDecode(rawJson) as List;
    return InvoiceModel(
      id: map['id'] as int?,
      date: (map['date'] ?? '').toString(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMode: (map['payment_mode'] ?? 'Cash').toString(),
      items: decoded
          .map((e) => SaleItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'total_amount': totalAmount,
    'payment_mode': paymentMode,
    'items_json': itemsJson,
  };
}