class FlavourSalesSummaryModel {
  final String name;
  final String category;
  final int qty;
  final double amount;

  const FlavourSalesSummaryModel({
    required this.name,
    this.category = '',
    required this.qty,
    required this.amount,
  });
}