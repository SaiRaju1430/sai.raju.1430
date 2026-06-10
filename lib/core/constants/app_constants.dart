class AppConstants {
  static const String appName = 'CampusKart';

  // Categories
  static const List<String> categories = [
    'Vegetables',
    'Fruits',
    'Groceries',
    'Pickles',
    'Snacks',
    'Stationery',
    'Dairy',
    'Personal Care',
  ];

  // Cart rules
  static const double minOrderValue = 100.0;

  // Delivery Charges - Weekday (Mon-Sat) 6 PM - 11 PM
  static const double weekdayFee100_249 = 20.0;
  static const double weekdayFee250_349 = 25.0;
  static const double weekdayFee350_499 = 30.0;
  static const double weekdayFee500Plus = 35.0;

  // Delivery Charges - Weekday after 11 PM (Urgent)
  static const double urgentFee100_249 = 30.0;
  static const double urgentFee250_349 = 35.0;
  static const double urgentFee350_499 = 40.0;
  static const double urgentFee500Plus = 45.0;
}
