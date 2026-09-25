class EarningsModel {
  final double todayIncome;
  final double monthlyIncome;
  final double totalEarnings;
  final int todayOrdersCount;
  final int pendingOrdersCount;
  final int pendingRequestsCount;
  final int deliveredOrdersCount;

  EarningsModel({
    required this.todayIncome,
    required this.monthlyIncome,
    this.totalEarnings = 0.0,
    required this.todayOrdersCount,
    required this.pendingOrdersCount,
    required this.pendingRequestsCount,
    required this.deliveredOrdersCount,
  });

  double get totalIncome => totalEarnings;
  double get totalRevenue => totalEarnings;
  double get totalEarning => totalEarnings;
  double get earnings => totalEarnings;

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      todayIncome: (json['todayIncome'] ?? json['today_income'] ?? 0).toDouble(),
      monthlyIncome: (json['monthlyIncome'] ?? json['monthly_income'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? json['totalRevenue'] ?? json['monthlyIncome'] ?? 0).toDouble(),
      todayOrdersCount: json['todayOrdersCount'] ?? json['today_orders_count'] ?? 0,
      pendingOrdersCount: json['pendingOrdersCount'] ?? json['pending_orders_count'] ?? 0,
      pendingRequestsCount: json['pendingRequestsCount'] ?? json['pending_requests_count'] ?? 0,
      deliveredOrdersCount: json['deliveredOrdersCount'] ?? json['delivered_orders_count'] ?? 0,
    );
  }

  factory EarningsModel.empty() {
    return EarningsModel(
      todayIncome: 0.0,
      monthlyIncome: 0.0,
      totalEarnings: 0.0,
      todayOrdersCount: 0,
      pendingOrdersCount: 0,
      pendingRequestsCount: 0,
      deliveredOrdersCount: 0,
    );
  }
}

