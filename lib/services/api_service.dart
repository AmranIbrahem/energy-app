import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/storage_service.dart';

class ApiService {
  final StorageService storageService;
  String? _token;

  ApiService({required this.storageService}) {
    _token = storageService.getToken();
  }

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(
      String endpoint, {
        bool requiresAuth = false,
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      Uri uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }

      final response = await http.get(
        uri,
        headers: _getHeaders(requiresAuth: requiresAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, {
        required Map<String, dynamic> data,
        bool requiresAuth = false,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> put(
      String endpoint, {
        required Map<String, dynamic> data,
        bool requiresAuth = false,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(
      String endpoint, {
        bool requiresAuth = false,
        Map<String, dynamic>? data,
      }) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );

      request.headers.addAll(_getHeaders(requiresAuth: requiresAuth));

      if (data != null) {
        request.body = jsonEncode(data);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      return _handleResponse(http.Response(responseBody, response.statusCode));
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      try {
        final error = jsonDecode(response.body);
        return {
          'error': true,
          'message': error['message'] ?? 'حدث خطأ في الخادم',
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'error': true,
          'message': 'حدث خطأ غير متوقع',
          'statusCode': response.statusCode,
        };
      }
    }
  }


  // Add this method to ApiService class
  Future<Map<String, dynamic>> uploadImage(
      String endpoint,
      File imageFile, {
        bool requiresAuth = false,
      }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );

      request.headers.addAll(_getHeaders(requiresAuth: requiresAuth));
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      return _handleResponse(http.Response(responseBody, response.statusCode));
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاتصال: $e'};
    }
  }



  // ==================== دوال الإشعارات ====================

  /// جلب عدد الإشعارات غير المقروءة
  Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    try {
      final response = await get(
        '/v1/user/notifications/count/unread',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في جلب عدد الإشعارات'};
    }
  }

  /// جلب جميع الإشعارات (مع Pagination)
  Future<Map<String, dynamic>> getAllNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await get(
        '/v1/user/notifications?page=$page&per_page=$perPage',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في جلب الإشعارات'};
    }
  }

  /// جلب الإشعارات غير المقروءة فقط
  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await get(
        '/v1/user/notifications/unread',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في جلب الإشعارات غير المقروءة'};
    }
  }

  /// جلب تفاصيل إشعار محدد
  Future<Map<String, dynamic>> getNotification(int notificationId) async {
    try {
      final response = await get(
        '/v1/user/notifications/$notificationId',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في جلب تفاصيل الإشعار'};
    }
  }

  /// تحديد إشعار كمقروء
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await put(
        '/v1/user/notifications/$notificationId/read',
        requiresAuth: true,
        data: {},
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في تحديث حالة الإشعار'};
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await put(
        '/v1/user/notifications/read-all',
        requiresAuth: true,
        data: {},
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في تحديث جميع الإشعارات'};
    }
  }

  /// حذف إشعار محدد
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final response = await delete(
        '/v1/user/notifications/$notificationId',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في حذف الإشعار'};
    }
  }

  /// حذف جميع الإشعارات
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      final response = await delete(
        '/v1/user/notifications',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في حذف جميع الإشعارات'};
    }
  }


  /// إرسال FCM Token إلى الخادم
  Future<Map<String, dynamic>> sendFcmToken(String token) async {
    try {
      final response = await post(
        '/v1/user/fcm-token',
        requiresAuth: true,
        data: {'fcm_token': token},
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'حدث خطأ في إرسال التوكن'};
    }
  }

  // أضف هذه الدوال داخل class ApiService بدلاً من الدالتين السابقتين

  /// إرسال طلب صيانة جديد (يدعم الصورة)
  Future<Map<String, dynamic>> sendMaintenanceRequest({
    required String message,
    required String type, // 'team' or 'ai'
    String? name,
    String? phone,
    String? email,
    File? image,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/user/public/maintenance'),
      );

      // إضافة الهيدر (قد يحتوي على التوكن إذا كان المستخدم مسجلاً)
      final headers = await _getHeadersWithAuth(); // سننشئ هذه الدالة المساعدة
      request.headers.addAll(headers);

      // إضافة الحقول النصية
      request.fields['message'] = message;
      request.fields['type'] = type;
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (email != null && email.isNotEmpty) request.fields['email'] = email;

      // إضافة الصورة إن وجدت
      if (image != null) {
        var multipartFile = await http.MultipartFile.fromPath('image', image.path);
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال طلب الصيانة: $e'};
    }
  }

  /// جلب طلبات الصيانة الخاصة بالمستخدم (أو العامة حسب صلاحية التوكن)
  Future<Map<String, dynamic>> fetchMaintenanceRequests() async {
    try {
      final response = await get(
        '/v1/user/public/maintenance/my-requests',
        requiresAuth: false, // السماح للزوار أيضاً (التوكن سيضاف تلقائياً إذا كان موجوداً)
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب طلبات الصيانة: $e'};
    }
  }

// دالة مساعدة لاستخراج الهيدر مع التوكن بشكل غير متزامن (لأن التوكن قد يكون متغيراً)
  Future<Map<String, String>> _getHeadersWithAuth({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth) {
      final token = await storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }








  /// بدء جلسة محادثة جديدة للزوار
  Future<Map<String, dynamic>> startGuestSession() async {
    try {
      final response = await post(
        '/v1/user/public/chat/start',
        requiresAuth: false,
        data: {},
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء الجلسة: $e'};
    }
  }

  /// إرسال رسالة كزائر
  Future<Map<String, dynamic>> sendGuestMessage({
    required String sessionId,
    required String message,
    required String governorate,
  }) async {
    try {
      final response = await post(
        '/v1/user/public/chat/send',
        requiresAuth: false,
        data: {
          'session_id': sessionId,
          'message': message,
          'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الرسالة: $e'};
    }
  }

  /// الحصول على تاريخ محادثة الزوار
  Future<Map<String, dynamic>> getGuestChatHistory({
    required String sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await get(
        '/v1/user/public/chat/history?session_id=$sessionId&limit=$limit&offset=$offset',
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب تاريخ المحادثة: $e'};
    }
  }

  /// مسح محادثة الزوار
  Future<Map<String, dynamic>> clearGuestChat(String sessionId) async {
    try {
      final response = await post(
        '/v1/user/public/chat/clear',
        requiresAuth: false,
        data: {'session_id': sessionId},
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح المحادثة: $e'};
    }
  }

  /// تحديث محافظة الزائر
  Future<Map<String, dynamic>> updateGuestGovernorate({
    required String sessionId,
    required String governorate,
  }) async {
    try {
      final response = await post(
        '/v1/user/public/chat/update-governorate',
        requiresAuth: false,
        data: {
          'session_id': sessionId,
          'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في تحديث المحافظة: $e'};
    }
  }

  /// الحصول على نتيجة حساب (للكل - مسجل أو زائر)
  Future<Map<String, dynamic>> getCalculationResult({
    required String calculationId,
    String? sessionId,
    bool isGuest = false,
  }) async {
    try {
      final endpoint = isGuest
          ? '/v1/user/public/chat/calculation-result?calculation_id=$calculationId'
          : '/v1/user/public/chat/calculation-result?calculation_id=$calculationId';

      final response = await get(
        endpoint,
        requiresAuth: !isGuest,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب نتيجة الحساب: $e'};
    }
  }

}