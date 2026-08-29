// ============================================================
// الملف: lib/services/system_builder_service.dart
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/utils/constants.dart';

class SystemBuilderService {
  final AuthService authService;

  SystemBuilderService({required this.authService});

  Future<String?> _getToken() async {
    await authService.refreshAuthState();
    return authService.token;
  }

  Future<Map<String, dynamic>> getProducts(String type,
      {String? search, int page = 1}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/system-builder/products')
          .replace(queryParameters: {
        'type': type,
        'page': page.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data']};
        }
        return {'success': false, 'message': data['message'] ?? 'حدث خطأ'};
      }
      return {'success': false, 'message': 'حدث خطأ (${response.statusCode})'};
    } catch (e) {
      print('❌ Error in getProducts: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  // ✅ جلب نسبة الدفع المسبق من الإعدادات العامة
  Future<Map<String, dynamic>> getPrepaidPercentage() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/setting/aldfaa_almsbk');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'value': double.tryParse(data['data']?['value']?.toString() ?? '0') ?? 0,
          'formatted_value': data['data']?['formatted_value'] ?? '0.00 %',
          'type': data['data']?['type'] ?? 'percentage',
        };
      }
      return {'success': false, 'value': 0};
    } catch (e) {
      print('❌ Error fetching prepaid percentage: $e');
      return {'success': false, 'value': 0};
    }
  }

  // ✅ تم تعديل createOrder لإضافة الحقول الجديدة والدفع المسبق
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    required List<Map<String, dynamic>> cables,
    required List<Map<String, dynamic>> panelBoards,
    String? notes,
    // ✅ الحقول الجديدة
    String? fullName,
    String? phone,
    String? shippingAddress,
    String? paymentMethod,
    String? userNotes,
    // ✅ الدفع المسبق
    bool isPrepaid = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null)
        return {'success': false, 'message': 'يرجى تسجيل الدخول'};

      final body = {
        'panels': panels
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'inverters': inverters
            .map((i) => {'id': i['id'], 'quantity': i['quantity']})
            .toList(),
        'batteries': batteries
            .map((b) => {'id': b['id'], 'quantity': b['quantity']})
            .toList(),
        'cables': cables
            .map((c) => {'id': c['id'], 'quantity': c['quantity']})
            .toList(),
        'panel_boards': panelBoards
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'notes': notes ?? '',
        // ✅ إرسال الحقول الجديدة
        'full_name': fullName ?? '',
        'phone': phone ?? '',
        'shipping_address': shippingAddress ?? '',
        'payment_method': paymentMethod ?? 'cash',
        'user_notes': userNotes ?? '',
        // ✅ إرسال الدفع المسبق
        'is_prepaid': isPrepaid,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/v1/user/system-builder/order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'تم الإرسال',
          'data': data['data'],
          'compatibility': data['compatibility'] ?? null,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ',
        'compatibility': data['compatibility'] ?? null,
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  // ✅ دالة تحديث طلب موجود
  Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    required List<Map<String, dynamic>> cables,
    required List<Map<String, dynamic>> panelBoards,
    String? notes,
    String? fullName,
    String? phone,
    String? shippingAddress,
    String? paymentMethod,
    String? userNotes,
    bool isPrepaid = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null)
        return {'success': false, 'message': 'يرجى تسجيل الدخول'};

      final body = {
        'panels': panels
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'inverters': inverters
            .map((i) => {'id': i['id'], 'quantity': i['quantity']})
            .toList(),
        'batteries': batteries
            .map((b) => {'id': b['id'], 'quantity': b['quantity']})
            .toList(),
        'cables': cables
            .map((c) => {'id': c['id'], 'quantity': c['quantity']})
            .toList(),
        'panel_boards': panelBoards
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'notes': notes ?? '',
        'full_name': fullName ?? '',
        'phone': phone ?? '',
        'shipping_address': shippingAddress ?? '',
        'payment_method': paymentMethod ?? 'cash',
        'user_notes': userNotes ?? '',
        'is_prepaid': isPrepaid,
      };

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/v1/user/system-builder/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'تم التحديث',
          'data': data['data'],
          'compatibility': data['compatibility'] ?? null,
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ',
        'compatibility': data['compatibility'] ?? null,
      };
    } catch (e) {
      print('❌ Error in updateOrder: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  // ✅ دالة إلغاء طلب
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final token = await _getToken();
      if (token == null)
        return {'success': false, 'message': 'يرجى تسجيل الدخول'};

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/v1/user/system-builder/orders/$orderId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'تم الإلغاء',
          'data': data['data'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ',
      };
    } catch (e) {
      print('❌ Error in cancelOrder: $e');
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final token = await _getToken();
      if (token == null)
        return {'success': false, 'message': 'يرجى تسجيل الدخول'};

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/v1/user/system-builder/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200)
        return {'success': true, 'data': data['data'] ?? []};
      return {'success': false, 'message': data['message'] ?? 'حدث خطأ'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> analyzeSystem({
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    required List<Map<String, dynamic>> cables,
    required List<Map<String, dynamic>> panelBoards,
    String? question,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'panels': panels
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'inverters': inverters
            .map((i) => {'id': i['id'], 'quantity': i['quantity']})
            .toList(),
        'batteries': batteries
            .map((b) => {'id': b['id'], 'quantity': b['quantity']})
            .toList(),
        'cables': cables
            .map((c) => {'id': c['id'], 'quantity': c['quantity']})
            .toList(),
        'panel_boards': panelBoards
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        if (question != null && question.isNotEmpty) 'question': question,
      };

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/system-builder/analyze');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response =
      await http.post(uri, headers: headers, body: jsonEncode(body));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'تم التحليل'
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'خطأ ${response.statusCode}'
      };
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> autoDesign({
    required double budgetMin,
    required double budgetMax,
    required List<Map<String, dynamic>> appliances,
    required double sunHours,
    String? notes,
  }) async {
    try {
      final body = {
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'appliances': appliances,
        'sun_hours': sunHours,
        if (notes != null) 'notes': notes,
      };

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/system-builder/auto-design');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل التصميم'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> requestHumanDesign({
    required String name,
    required String phone,
    String? email,
    required double budgetMin,
    required double budgetMax,
    required int sunHours,
    required List<Map<String, dynamic>> appliances,
    String? notes,
    Map<String, dynamic>? aiRecommendations,
  }) async {
    try {
      final body = {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'sun_hours': sunHours,
        'appliances': appliances,
        if (notes != null) 'notes': notes,
        if (aiRecommendations != null) 'ai_recommendations': aiRecommendations,
      };

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/system-builder/request-human-design');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم الإرسال',
          'data': data['data']
        };
      }
      return {'success': false, 'message': data['message'] ?? 'فشل الإرسال'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // ✅ جلب سعر التركيب من الإعدادات العامة
  Future<Map<String, dynamic>> getInstallationPrice() async {
    try {
      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/setting/installation_almnthom');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'formatted_value': data['data']?['formatted_value'] ?? '0.00',
          'value': data['data']?['value'] ?? 0,
        };
      }
      return {'success': false, 'formatted_value': '0.00'};
    } catch (e) {
      print('❌ Error fetching installation price: $e');
      return {'success': false, 'formatted_value': '0.00'};
    }
  }
}