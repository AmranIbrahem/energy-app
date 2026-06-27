// lib/services/system_builder_service.dart
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

  // جلب المنتجات حسب النوع
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

      print('📦 Products API Response Status: ${response.statusCode}');

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

  // إنشاء طلب تصميم
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null)
        return {'success': false, 'message': 'يرجى تسجيل الدخول'};

      final body = {
        'panels': panels
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'inverters': inverters.map((i) =>
        {
          'id': i['id'],
          'quantity': i['quantity']
        }).toList(),
        'batteries': batteries.map((b) =>
        {
          'id': b['id'],
          'quantity': b['quantity']
        }).toList(),
        'notes': notes ?? '',
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
          'success': true,
          'message': data['message'] ?? 'تم الإرسال',
          'data': data['data']
        };
      }
      return {'success': false, 'message': data['message'] ?? 'حدث خطأ'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال'};
    }
  }

  // جلب طلباتي
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

  // 🆕 تحليل المنظومة بالذكاء الاصطناعي
  Future<Map<String, dynamic>> analyzeSystem({
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    String? question, // 🆕
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'panels': panels
            .map((p) => {'id': p['id'], 'quantity': p['quantity']})
            .toList(),
        'inverters': inverters.map((i) =>
        {
          'id': i['id'],
          'quantity': i['quantity']
        }).toList(),
        'batteries': batteries.map((b) =>
        {
          'id': b['id'],
          'quantity': b['quantity']
        }).toList(),
        if (question != null && question.isNotEmpty) 'question': question, // 🆕

      };

      final uri = Uri.parse(
          '${AppConstants.baseUrl}/v1/user/public/system-builder/analyze');

      print('══════════════════════════════════════');
      print('🔗 FULL URL: $uri');
      print('📦 BODY: ${jsonEncode(body)}');
      print('══════════════════════════════════════');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
          uri, headers: headers, body: jsonEncode(body));

      print('📡 Status: ${response.statusCode}');
      print('📡 Body: ${response.body}');

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



  // 🆕 تصميم منظومة تلقائياً
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

      final uri = Uri.parse('${AppConstants.baseUrl}/v1/user/public/system-builder/auto-design');

      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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

      final uri = Uri.parse('${AppConstants.baseUrl}/v1/user/public/system-builder/request-human-design');

      final response = await http.post(uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'تم الإرسال', 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل الإرسال'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

}