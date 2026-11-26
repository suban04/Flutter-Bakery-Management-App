class ExpenseModel {
  final int? id;
  final String date;
  final String title;
  final String category;
  final double amount;

  const ExpenseModel({
    this.id,
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] as int?,
    date: (map['date'] ?? '').toString(),
    title: (map['title'] ?? '').toString(),
    category: (map['category'] ?? 'Other').toString(),
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'title': title,
    'category': category,
    'amount': amount,
  };
}