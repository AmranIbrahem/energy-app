// lib/services/rating_api_service.dart
import 'dart:convert';

import 'package:GeniusHouse/services/auth_service.dart';
import 'package:http/http.dart' as http;

class RatingApiService {
  final String baseUrl;
  final AuthService authService;

  RatingApiService({
    required this.baseUrl,
    required this.authService,
  });

  Future<String?> _getToken() async {
    await authService.refreshAuthState();
    return authService.token;
  }

  Future<Map<String, dynamic>> getRateableItems(int invoiceId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/nex/v1/user/ratings/invoice/$invoiceId/items'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      // print('Error getting rateable items: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> submitRating({
    required int invoiceId,
    required int itemId,
    required String itemType,
    required int rating,
    String? review,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final body = {
        'invoice_id': invoiceId,
        'item_id': itemId,
        'item_type': itemType,
        'rating': rating,
      };
      if (review != null && review.isNotEmpty) {
        body['review'] = review;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/nex/v1/user/ratings/store'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      // print('Error submitting rating: $e');
      return {'success': false, 'message': 'حدث خطأ في إرسال التقييم: $e'};
    }
  }
}
