// lib/services/order_api_service.dart
import 'dart:convert';

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:http/http.dart' as http;

class OrderApiService {
  final String baseUrl;
  final AuthService authService;

  OrderApiService({
    required this.baseUrl,
    required this.authService,
  });

  Future<String?> _getToken() async {
    try {
      await authService.refreshAuthState();
      final token = authService.token;

      if (token == null || token.isEmpty) {
        // print('❌ No valid token found');
        return null;
      }

      return token;
    } catch (e) {
      // print('❌ Error getting token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String firstName,
    required String lastName,
    required String phone,
    required String shippingAddress,
    required String paymentMethod,
    required List<CartItemModel> items,
    String? couponCode,
    String? userNotes,
    bool isPrepaid = false,
    bool isSyp = false,
    String? governorate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final itemsData = items
          .map((item) => {
                'type': item.itemType,
                'id': item.id,
                'quantity': item.quantity,
              })
          .toList();

      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        'items': itemsData,
        'is_prepaid': isPrepaid,
        'is_syp': isSyp,
      };

      if (governorate != null && governorate.isNotEmpty) {
        body['governorate'] = governorate;
      }

      if (couponCode != null && couponCode.isNotEmpty) {
        body['coupon_code'] = couponCode;
      }
      if (userNotes != null && userNotes.isNotEmpty) {
        body['user_notes'] = userNotes;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/nex/v1/user/orders/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data;
        }
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في إنشاء الطلب',
        'errors': data['errors'] ?? null,
      };
    } catch (e) {
      // print('Error creating order: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserOrders(
      {int page = 1, String? status}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      String url =
          '$baseUrl/api/nex/v1/user/orders/my-orders?page=$page&per_page=15';
      if (status != null && status.isNotEmpty && status != 'all') {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في جلب الطلبات',
      };
    } catch (e) {
      // print('❌ Error fetching orders: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int invoiceId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/nex/v1/user/orders/$invoiceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في جلب تفاصيل الطلب',
      };
    } catch (e) {
      // print('❌ Error fetching order details: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int invoiceId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/nex/v1/user/orders/$invoiceId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في إلغاء الطلب',
      };
    } catch (e) {
      // print('❌ Error cancelling order: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> validateCoupon(
      String couponCode, double subtotal) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/nex/v1/user/orders/validate-coupon'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'coupon_code': couponCode,
          'subtotal': subtotal.toString(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'كود الخصم غير صالح',
      };
    } catch (e) {
      // print('❌ Error validating coupon: $e');
      return {'success': false, 'message': 'حدث خطأ في التحقق من الكود'};
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/nex/v1/user/orders/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في جلب الإحصائيات',
      };
    } catch (e) {
      // print('❌ Error fetching order stats: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }
}
