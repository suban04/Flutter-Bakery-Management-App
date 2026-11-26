class DashboardSummaryModel {
  final double todaySales;
  final double todayExpenses;
  final int pendingOrders;
  final double totalBalance;
  final int lowStockCount;

  const DashboardSummaryModel({
    this.todaySales = 0,
    this.todayExpenses = 0,
    this.pendingOrders = 0,
    this.totalBalance = 0,
    this.lowStockCount = 0,
  });
}