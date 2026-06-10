class EarningsModel {
  final double todayIncome;
  final double monthlyIncome;
  final int todayOrdersCount;
  final int pendingOrdersCount;
  final int pendingRequestsCount;
  final int deliveredOrdersCount;

  EarningsModel({
    required this.todayIncome,
    required this.monthlyIncome,
    required this.todayOrdersCount,
    required this.pendingOrdersCount,
    required this.pendingRequestsCount,
    required this.deliveredOrdersCount,
  });

  factory EarningsModel.empty() {
    return EarningsModel(
      todayIncome: 0.0,
      monthlyIncome: 0.0,
      todayOrdersCount: 0,
      pendingOrdersCount: 0,
      pendingRequestsCount: 0,
      deliveredOrdersCount: 0,
    );
  }
}
