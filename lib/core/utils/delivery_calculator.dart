import '../constants/app_constants.dart';

class DeliveryCalculator {
  /// Check if ordering is currently available based on the time and day.
  /// Sunday allowed times: 10 AM - 12 PM (10:00 - 12:00) and 4 PM - 1:30 AM (16:00 - 25:30 equivalent)
  /// Weekday allowed times: 6 PM - 11 PM or after 11 PM (basically evening/night is allowed, but let's check general availability).
  /// The spec says:
  /// "Sunday Allowed Times: 10 AM - 12 PM, 4 PM - 1:30 AM. Outside service hours: Ordering unavailable"
  /// For weekdays, does it say anything about restricted hours?
  /// "Monday-Saturday: 6 PM - 11 PM (Standard), After 11 PM (Urgent)"
  /// We will assume Mon-Sat deliveries are active from 6 PM onwards until late (e.g. 3 AM). Let's implement this validation method.
  static Map<String, dynamic> checkServiceAvailability(DateTime time) {
    int day = time.weekday; // 1 = Monday, 7 = Sunday
    int hour = time.hour;
    int minute = time.minute;
    double timeInHours = hour + (minute / 60.0);

    if (day == DateTime.sunday) {
      // Sunday allowed: 10 AM - 12 PM (10.0 to 12.0) and 4 PM - 1:30 AM (16.0 to 25.5 or 0.0 to 1.5)
      bool morningShift = (timeInHours >= 10.0 && timeInHours <= 12.0);
      bool eveningShift = (timeInHours >= 16.0 || timeInHours < 1.5);
      
      if (morningShift || eveningShift) {
        return {'available': true, 'reason': ''};
      } else {
        return {
          'available': false,
          'reason': 'Sunday ordering is only open 10 AM - 12 PM & 4 PM - 1:30 AM.'
        };
      }
    } else {
      // Weekdays: 6 PM (18.0) onwards. Let's assume delivery ends at 2:00 AM.
      // Outside this range, ordering is unavailable.
      bool isServiceHours = (timeInHours >= 18.0 || timeInHours < 2.0);
      if (isServiceHours) {
        return {'available': true, 'reason': ''};
      } else {
        return {
          'available': false,
          'reason': 'Hostel delivery service operates Mon-Sat 6 PM - 2 AM.'
        };
      }
    }
  }

  /// Calculates delivery charges based on time and subtotal.
  static double calculateDeliveryFee(DateTime time, double subtotal) {
    if (subtotal < AppConstants.minOrderValue) {
      return 0.0;
    }

    int day = time.weekday;
    int hour = time.hour;
    int minute = time.minute;
    double timeInHours = hour + (minute / 60.0);

    // Identify if the time represents "Urgent" rate (after 11 PM or before 6 PM if Sunday morning/late night)
    bool isUrgent = false;

    if (day == DateTime.sunday) {
      // Sunday morning or late night after 11 PM is urgent
      if (timeInHours >= 23.0 || timeInHours < 1.5 || (timeInHours >= 10.0 && timeInHours <= 12.0)) {
        isUrgent = true;
      }
    } else {
      // Mon-Sat: After 11 PM is urgent
      if (timeInHours >= 23.0 || timeInHours < 2.0) {
        isUrgent = true;
      }
    }

    if (isUrgent) {
      if (subtotal >= 100 && subtotal <= 249) return AppConstants.urgentFee100_249;
      if (subtotal >= 250 && subtotal <= 349) return AppConstants.urgentFee250_349;
      if (subtotal >= 350 && subtotal <= 499) return AppConstants.urgentFee350_499;
      return AppConstants.urgentFee500Plus; // 500+
    } else {
      // Standard weekday rates (6 PM - 11 PM)
      if (subtotal >= 100 && subtotal <= 249) return AppConstants.weekdayFee100_249;
      if (subtotal >= 250 && subtotal <= 349) return AppConstants.weekdayFee250_349;
      if (subtotal >= 350 && subtotal <= 499) return AppConstants.weekdayFee350_499;
      return AppConstants.weekdayFee500Plus; // 500+
    }
  }
}
