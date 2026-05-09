import 'package:intl/intl.dart';

class Helpers {
  // Format price with currency
  static String formatPrice(double price) {
    final format = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'en_US',
    );
    return format.format(price);
  }

  // Format number with thousand separator
  static String formatNumber(int number) {
    return NumberFormat.decimalPattern('en_US').format(number);
  }

  // Format date to relative time (e.g., "2 days ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone (Syrian format)
  static bool isValidPhone(String phone) {
    return RegExp(r'^\+963\d{8,9}$').hasMatch(phone);
  }

  // Calculate discount percentage
  static double calculateDiscount(double originalPrice, double finalPrice) {
    if (originalPrice == 0) return 0;
    return ((originalPrice - finalPrice) / originalPrice) * 100;
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}