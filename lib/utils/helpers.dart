import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class Helpers {
  static String formatPrice(double price) {
    final format = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'en_US',
    );
    return format.format(price);
  }

  static String formatNumber(int number) {
    return NumberFormat.decimalPattern('en_US').format(number);
  }

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

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+963\d{8,9}$').hasMatch(phone);
  }

  static double calculateDiscount(double originalPrice, double finalPrice) {
    if (originalPrice == 0) return 0;
    return ((originalPrice - finalPrice) / originalPrice) * 100;
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static void shareText(String text) {
    Share.share(text);
  }

  static double parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      String cleanPrice = price.replaceAll(',', '').replaceAll(' ', '').trim();
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }
}
