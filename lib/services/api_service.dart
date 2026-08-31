import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:http_parser/http_parser.dart';  // ✅ لـ MediaType

class ApiService {
  final StorageService storageService;
  String? _token;

  ApiService({required this.storageService}) {
    _token = storageService.getToken();
  }

  void setToken(String token) {
    _token = token;
  }

  // ✅ دالة إرسال رسالة مع صور (Multipart)
  Future<Map<String, dynamic>> sendMessageWithImages({
    required String message,
    required List<File> images,
    bool requiresAuth = true,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/user/chat/send-with-image'),
      );

      final headers = <String, String>{};
      if (requiresAuth && _token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
      request.headers.addAll(headers);

      // إضافة النص
      request.fields['message'] = message;

      // إضافة الصور
      for (var i = 0; i < images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[$i]',
            images[i].path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {
        'error': true,
        'message': 'خطأ في إرسال الرسالة مع الصورة: $e'
      };
    }
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
        uri = uri.replace(
            queryParameters: queryParams
                .map((key, value) => MapEntry(key, value.toString())));
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

  // ✅ دالة POST معدلة لدعم رفع الملفات
  Future<Map<String, dynamic>> post(
      String endpoint, {
        required Map<String, dynamic> data,
        bool requiresAuth = false,
        List<File>? files,
      }) async {
    try {
      // ✅ إذا كان هناك ملفات، استخدم MultipartRequest
      if (files != null && files.isNotEmpty) {
        return await _postMultipart(
          endpoint,
          data: data,
          files: files,
          requiresAuth: requiresAuth,
        );
      }

      // ✅ إذا لم يكن هناك ملفات، استخدم الطلب العادي
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

  // ✅ POST مع ملفات (Multipart)
  Future<Map<String, dynamic>> _postMultipart(
      String endpoint, {
        required Map<String, dynamic> data,
        required List<File> files,
        bool requiresAuth = false,
      }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );

      // ✅ إضافة الحقول النصية
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // ✅ إضافة الملفات
      for (var i = 0; i < files.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[$i]',
            files[i].path,
          ),
        );
      }

      // ✅ إضافة headers
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (requiresAuth && _token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
      request.headers.addAll(headers);

      // ✅ إرسال الطلب
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في رفع الملفات: $e'};
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
    // ✅ إذا كان 401، جرب تجديد التوكن
    if (response.statusCode == 401) {
      final rememberToken = storageService.getRememberToken();
      if (rememberToken != null && rememberToken.isNotEmpty) {
        print('⚠️ Got 401, trying to refresh token...');

        try {
          final refreshResponse = await http.post(
            Uri.parse('${AppConstants.baseUrl}/v1/user/public/refresh-token'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'remember_token': rememberToken}),
          );

          if (refreshResponse.statusCode == 200) {
            final data = jsonDecode(refreshResponse.body);
            final newToken = data['data']['token'];
            final newRememberToken = data['data']['remember_token'];

            // حفظ التوكنات الجديدة
            await storageService.saveToken(newToken);
            await storageService.saveTokenCreatedAt(DateTime.now());
            if (newRememberToken != null) {
              await storageService.saveRememberToken(newRememberToken);
            }

            _token = newToken;
            print('✅ Token refreshed after 401');

            // إرجاع إشارة بأنه تم التجديد (سيتم إعادة الطلب من المتصل)
            return {
              'error': true,
              'message': 'TOKEN_REFRESHED',
              'statusCode': 401
            };
          } else {
            print('❌ Refresh token request failed with status: ${refreshResponse.statusCode}');
          }
        } catch (e) {
          print('❌ Failed to refresh after 401: $e');
        }
      } else {
        print('❌ No remember_token found for refresh');
      }

      // فشل كل شيء - تنظيف الجلسة
      await storageService.removeToken();
      await storageService.removeRememberToken();

      try {
        final error = jsonDecode(response.body);
        return {
          'error': true,
          'message': error['message'] ?? 'انتهت الجلسة، الرجاء تسجيل الدخول مجدداً',
          'statusCode': response.statusCode,
          'session_expired': true,
        };
      } catch (e) {
        return {
          'error': true,
          'message': 'انتهت الجلسة، الرجاء تسجيل الدخول مجدداً',
          'statusCode': response.statusCode,
          'session_expired': true,
        };
      }
    }

    // ✅ نجاح (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return data;
      } catch (e) {
        return {
          'error': true,
          'message': 'خطأ في معالجة الرد من الخادم',
          'statusCode': response.statusCode,
        };
      }
    }

    // ✅ خطأ آخر (4xx, 5xx)
    try {
      final error = jsonDecode(response.body);
      return {
        'error': true,
        'message': error['message'] ?? 'حدث خطأ في الخادم',
        'statusCode': response.statusCode,
        'errors': error['errors'] ?? null,
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'حدث خطأ غير متوقع',
        'statusCode': response.statusCode,
      };
    }
  }

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

  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await get(
        '/v1/user/notifications/unread',
        requiresAuth: true,
      );
      return response;
    } catch (e) {
      return {
        'error': true,
        'message': 'حدث خطأ في جلب الإشعارات غير المقروءة'
      };
    }
  }

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

  Future<Map<String, dynamic>> sendMaintenanceRequest({
    required String message,
    required String type,
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

      final headers = await _getHeadersWithAuth();
      request.headers.addAll(headers);

      request.fields['message'] = message;
      request.fields['type'] = type;
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (email != null && email.isNotEmpty) request.fields['email'] = email;

      if (image != null) {
        var multipartFile =
        await http.MultipartFile.fromPath('image', image.path);
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

  Future<Map<String, dynamic>> fetchMaintenanceRequests() async {
    try {
      final response = await get(
        '/v1/user/public/maintenance/my-requests',
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب طلبات الصيانة: $e'};
    }
  }

  Future<Map<String, String>> _getHeadersWithAuth(
      {bool requiresAuth = true}) async {
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

  /// ✅ إرسال رسالة مع صورة كزائر (Guest)
  Future<Map<String, dynamic>> sendGuestMessageWithImage({
    required String sessionId,
    required String message,
    required List<File> images,
    required String governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/user/public/chat/send-with-image'),
      );

      request.fields['session_id'] = sessionId;
      request.fields['message'] = message;
      request.fields['governorate'] = governorate;

      if (images.isNotEmpty) {
        final image = images.first;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {
        'error': true,
        'message': 'خطأ في إرسال الرسالة مع الصورة: $e'
      };
    }
  }

  /// ✅ إرسال رسالة صوتية فقط
  Future<Map<String, dynamic>> sendVoiceMessage({
    required File audioFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      print('📁 Audio file path: ${audioFile.path}');
      print('📁 Audio file exists: ${await audioFile.exists()}');
      print('📁 Audio file size: ${await audioFile.length()}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/chat/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/chat/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      print('📥 Response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('❌ Error: $e');
      return {'error': true, 'message': 'خطأ في إرسال الرسالة الصوتية: $e'};
    }
  }

  /// ✅ إرسال صورة + صوت معاً
  Future<Map<String, dynamic>> sendImageWithVoice({
    required File imageFile,
    required File audioFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/chat/send-image-with-voice'
              : '${AppConstants.baseUrl}/v1/user/public/chat/send-image-with-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصورة مع الصوت: $e'};
    }
  }


  // ═══════════════════════════════════════════
  // ✅ Solar Chat APIs (المستشار الشمسي)
  // ═══════════════════════════════════════════

  /// ✅ إرسال رسالة نصية إلى المستشار الشمسي
  Future<Map<String, dynamic>> sendSolarMessage({
    required String message,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/solar-chat/send'
            : '/v1/user/public/solar-chat/send',
        requiresAuth: requiresAuth,
        data: {
          'message': message,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الرسالة: $e'};
    }
  }

  /// ✅ إرسال رسالة مع صورة إلى المستشار الشمسي
  Future<Map<String, dynamic>> sendSolarMessageWithImage({
    required String message,
    required List<File> images,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/solar-chat/send-with-image'
              : '${AppConstants.baseUrl}/v1/user/public/solar-chat/send-with-image',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      request.fields['message'] = message;

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      if (images.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', images.first.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصورة: $e'};
    }
  }

  /// ✅ إرسال رسالة صوتية إلى المستشار الشمسي
  Future<Map<String, dynamic>> sendSolarVoiceMessage({
    required File audioFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/solar-chat/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/solar-chat/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصوت: $e'};
    }
  }

  /// ✅ جلب تاريخ محادثة المستشار الشمسي
  Future<Map<String, dynamic>> getSolarChatHistory({
    bool requiresAuth = true,
    String? sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final endpoint = requiresAuth
          ? '/v1/user/solar-chat/history?limit=$limit&offset=$offset'
          : '/v1/user/public/solar-chat/history?session_id=$sessionId&limit=$limit&offset=$offset';

      return await get(endpoint, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب التاريخ: $e'};
    }
  }

  /// ✅ مسح محادثة المستشار الشمسي
  Future<Map<String, dynamic>> clearSolarChat({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await delete('/v1/user/solar-chat/clear', requiresAuth: true);
      } else {
        return await post(
          '/v1/user/public/solar-chat/clear',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح المحادثة: $e'};
    }
  }

  /// ✅ بدء جلسة المستشار الشمسي للضيف
  Future<Map<String, dynamic>> startGuestSolarSession() async {
    try {
      return await post(
        '/v1/user/public/solar-chat/start',
        requiresAuth: false,
        data: {},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء الجلسة: $e'};
    }
  }



  // ═══════════════════════════════════════════
  // ✅ Support Solar Chat APIs (الدعم الفني)
  // ═══════════════════════════════════════════

  /// ✅ إرسال رسالة نصية للدعم الفني
  Future<Map<String, dynamic>> sendSupportMessage({
    required String message,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/support-solar/send'
            : '/v1/user/public/support-solar/send',
        requiresAuth: requiresAuth,
        data: {
          'message': message,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الرسالة: $e'};
    }
  }

  /// ✅ إرسال رسالة مع صورة للدعم الفني
  Future<Map<String, dynamic>> sendSupportMessageWithImage({
    required String message,
    required List<File> images,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/support-solar/send-with-image'
              : '${AppConstants.baseUrl}/v1/user/public/support-solar/send-with-image',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      request.fields['message'] = message;

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      if (images.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', images.first.path),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصورة: $e'};
    }
  }

  /// ✅ إرسال رسالة صوتية للدعم الفني
  Future<Map<String, dynamic>> sendSupportVoiceMessage({
    required File audioFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/support-solar/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/support-solar/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصوت: $e'};
    }
  }

  /// ✅ جلب تاريخ محادثة الدعم الفني
  Future<Map<String, dynamic>> getSupportChatHistory({
    bool requiresAuth = true,
    String? sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final endpoint = requiresAuth
          ? '/v1/user/support-solar/history?limit=$limit&offset=$offset'
          : '/v1/user/public/support-solar/history?session_id=$sessionId&limit=$limit&offset=$offset';

      return await get(endpoint, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المحادثة: $e'};
    }
  }

  /// ✅ إغلاق محادثة الدعم الفني
  Future<Map<String, dynamic>> closeSupportConversation({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await post(
          '/v1/user/support-solar/close',
          requiresAuth: true,
          data: {},
        );
      } else {
        return await post(
          '/v1/user/public/support-solar/close',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إغلاق المحادثة: $e'};
    }
  }

  /// ✅ بدء جلسة دعم فني للضيف
  Future<Map<String, dynamic>> startGuestSupportSession() async {
    try {
      return await post(
        '/v1/user/public/support-solar/start',
        requiresAuth: false,
        data: {},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء الجلسة: $e'};
    }
  }

  /// ✅ مسح محادثة الدعم الفني (حذف كل الرسائل)
  Future<Map<String, dynamic>> clearSupportConversation({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await delete(
          '/v1/user/support-solar/clear',
          requiresAuth: true,
        );
      } else {
        return await post(
          '/v1/user/public/support-solar/clear',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح المحادثة: $e'};
    }
  }

  // ═══════════════════════════════════════════
  // ✅ Appliance Compatibility APIs (فحص التوافق)
  // ═══════════════════════════════════════════

  /// ✅ فحص توافق الأجهزة
  Future<Map<String, dynamic>> checkApplianceCompatibility({
    required String systemVoltage,
    required String inverterPower,
    required String batteryType,
    required String appliances,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/appliance-compatibility/check'
            : '/v1/user/public/appliance-compatibility/check',
        requiresAuth: requiresAuth,
        data: {
          'system_voltage': systemVoltage,
          'inverter_power': inverterPower,
          'battery_type': batteryType,
          'appliances': appliances,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في فحص التوافق: $e'};
    }
  }

  /// ✅ جلب سجل فحوصات التوافق
  Future<Map<String, dynamic>> getCompatibilityHistory({
    int limit = 20,
  }) async {
    try {
      return await get(
        '/v1/user/appliance-compatibility/history?limit=$limit',
        requiresAuth: true,
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب السجل: $e'};
    }
  }



  // ═══════════════════════════════════════════
  // ✅ Appliance Savings APIs (حاسبة التوفير)
  // ═══════════════════════════════════════════

  /// ✅ حساب توفير الطاقة
  /// ✅ حساب توفير الطاقة لعدة أجهزة
  Future<Map<String, dynamic>> calculateApplianceSavings({
    required List<Map<String, dynamic>> appliances,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/appliance-savings/calculate'
            : '/v1/user/public/appliance-savings/calculate',
        requiresAuth: requiresAuth,
        data: {
          'appliances': appliances,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في حساب التوفير: $e'};
    }
  }


  /// ✅ إنشاء جدول التشغيل
  Future<Map<String, dynamic>> generateApplianceSchedule({
    required String systemVoltage,
    required String inverterPower,
    required String batteryType,
    required String appliances,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
    int? panelCount,
    int? panelWatts,
    int? batteryCount,
    int? batteryAh,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/appliance-schedule/generate'
            : '/v1/user/public/appliance-schedule/generate',
        requiresAuth: requiresAuth,
        data: {
          'system_voltage': systemVoltage,
          'inverter_power': inverterPower,
          'battery_type': batteryType,
          'appliances': appliances,
          if (panelCount != null) 'panel_count': panelCount,
          if (panelWatts != null) 'panel_watts': panelWatts,
          if (batteryCount != null) 'battery_count': batteryCount,
          if (batteryAh != null) 'battery_ah': batteryAh,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إنشاء الجدول: $e'};
    }
  }


  // ═══════════════════════════════════════════
// ✅ Inverter Appliances APIs (الأجهزة)
// ═══════════════════════════════════════════

  /// ✅ جلب قائمة الأجهزة المدعومة
  Future<Map<String, dynamic>> getInverterAppliances() async {
    try {
      final response = await get(
        '/v1/user/public/inverter-appliances',
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب الأجهزة: $e'};
    }
  }


  // ═══════════════════════════════════════════
  // ✅ Appliance Maintenance APIs (الصيانة الذكية)
  // ═══════════════════════════════════════════

  /// ✅ بدء جلسة صيانة للضيف
  Future<Map<String, dynamic>> startGuestMaintenanceSession() async {
    try {
      return await post(
        '/v1/user/public/appliance-maintenance/start',
        requiresAuth: false,
        data: {},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء جلسة الصيانة: $e'};
    }
  }

  /// ✅ إرسال رسالة نصية للصيانة
  Future<Map<String, dynamic>> sendMaintenanceMessage({
    required String message,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/appliance-maintenance/send'
            : '/v1/user/public/appliance-maintenance/send',
        requiresAuth: requiresAuth,
        data: {
          'message': message,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال رسالة الصيانة: $e'};
    }
  }

  /// ✅ إرسال صورة للتشخيص
  Future<Map<String, dynamic>> sendMaintenanceImage({
    required File imageFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/appliance-maintenance/send-image'
              : '${AppConstants.baseUrl}/v1/user/public/appliance-maintenance/send-image',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال صورة الصيانة: $e'};
    }
  }

  /// ✅ إرسال رسالة صوتية للصيانة
  Future<Map<String, dynamic>> sendMaintenanceVoice({
    required File audioFile,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/appliance-maintenance/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/appliance-maintenance/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال صوت الصيانة: $e'};
    }
  }

  /// ✅ جلب تاريخ محادثة الصيانة
  Future<Map<String, dynamic>> getMaintenanceHistory({
    bool requiresAuth = true,
    String? sessionId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final endpoint = requiresAuth
          ? '/v1/user/appliance-maintenance/history?limit=$limit&offset=$offset'
          : '/v1/user/public/appliance-maintenance/history?session_id=$sessionId&limit=$limit&offset=$offset';

      return await get(endpoint, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب تاريخ الصيانة: $e'};
    }
  }

  /// ✅ مسح محادثة الصيانة
  Future<Map<String, dynamic>> clearMaintenanceConversation({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await delete(
          '/v1/user/appliance-maintenance/clear',
          requiresAuth: true,
        );
      } else {
        return await post(
          '/v1/user/public/appliance-maintenance/clear',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح محادثة الصيانة: $e'};
    }
  }





  // ═══════════════════════════════════════════
  // ✅ Appliance Support Chat APIs (دعم الأجهزة الكهربائية)
  // ═══════════════════════════════════════════

  /// ✅ بدء جلسة دعم الأجهزة الكهربائية للضيف
  Future<Map<String, dynamic>> startGuestApplianceSupportSession() async {
    try {
      return await post(
        '/v1/user/public/appliance-support/start',
        requiresAuth: false,
        data: {},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء جلسة الدعم: $e'};
    }
  }

  /// ✅ إرسال رسالة نصية لدعم الأجهزة الكهربائية
  Future<Map<String, dynamic>> sendApplianceSupportMessage({
    required String message,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/appliance-support/send'
            : '/v1/user/public/appliance-support/send',
        requiresAuth: requiresAuth,
        data: {
          'message': message,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الرسالة: $e'};
    }
  }

  /// ✅ إرسال صورة لدعم الأجهزة الكهربائية
  Future<Map<String, dynamic>> sendApplianceSupportImage({
    required File imageFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/appliance-support/send-image'
              : '${AppConstants.baseUrl}/v1/user/public/appliance-support/send-image',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصورة: $e'};
    }
  }

  /// ✅ إرسال رسالة صوتية لدعم الأجهزة الكهربائية
  Future<Map<String, dynamic>> sendApplianceSupportVoice({
    required File audioFile,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/appliance-support/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/appliance-support/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصوت: $e'};
    }
  }

  /// ✅ جلب تاريخ محادثة دعم الأجهزة الكهربائية
  Future<Map<String, dynamic>> getApplianceSupportHistory({
    bool requiresAuth = true,
    String? sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final endpoint = requiresAuth
          ? '/v1/user/appliance-support/history?limit=$limit&offset=$offset'
          : '/v1/user/public/appliance-support/history?session_id=$sessionId&limit=$limit&offset=$offset';

      return await get(endpoint, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المحادثة: $e'};
    }
  }

  /// ✅ مسح محادثة دعم الأجهزة الكهربائية
  Future<Map<String, dynamic>> clearApplianceSupportConversation({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await delete(
          '/v1/user/appliance-support/clear',
          requiresAuth: true,
        );
      } else {
        return await post(
          '/v1/user/public/appliance-support/clear',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح المحادثة: $e'};
    }
  }

  // ═══════════════════════════════════════════
  // ✅ Lighting Support Chat APIs (دعم الإنارة والديكور)
  // ═══════════════════════════════════════════

  /// ✅ بدء جلسة دعم الإنارة للضيف
  Future<Map<String, dynamic>> startGuestLightingSupportSession() async {
    try {
      return await post(
        '/v1/user/public/lighting-support/start',
        requiresAuth: false,
        data: {},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء جلسة الدعم: $e'};
    }
  }

  /// ✅ إرسال رسالة نصية لدعم الإنارة
  Future<Map<String, dynamic>> sendLightingSupportMessage({
    required String message,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      final response = await post(
        requiresAuth
            ? '/v1/user/lighting-support/send'
            : '/v1/user/public/lighting-support/send',
        requiresAuth: requiresAuth,
        data: {
          'message': message,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
          if (!requiresAuth && governorate != null) 'governorate': governorate,
        },
      );
      return response;
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الرسالة: $e'};
    }
  }

  /// ✅ إرسال صورة لدعم الإنارة
  Future<Map<String, dynamic>> sendLightingSupportImage({
    required File imageFile,
    String message = '',
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/lighting-support/send-image'
              : '${AppConstants.baseUrl}/v1/user/public/lighting-support/send-image',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (message.isNotEmpty) {
        request.fields['message'] = message;
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصورة: $e'};
    }
  }

  /// ✅ إرسال رسالة صوتية لدعم الإنارة
  Future<Map<String, dynamic>> sendLightingSupportVoice({
    required File audioFile,
    bool requiresAuth = true,
    String? sessionId,
    String? governorate,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          requiresAuth
              ? '${AppConstants.baseUrl}/v1/user/lighting-support/send-voice'
              : '${AppConstants.baseUrl}/v1/user/public/lighting-support/send-voice',
        ),
      );

      if (requiresAuth && _token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (!requiresAuth) {
        if (sessionId != null) request.fields['session_id'] = sessionId;
        if (governorate != null) request.fields['governorate'] = governorate;
      }

      final bytes = await audioFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'voice.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      return _handleResponse(response);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إرسال الصوت: $e'};
    }
  }

  /// ✅ جلب تاريخ محادثة دعم الإنارة
  Future<Map<String, dynamic>> getLightingSupportHistory({
    bool requiresAuth = true,
    String? sessionId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final endpoint = requiresAuth
          ? '/v1/user/lighting-support/history?limit=$limit&offset=$offset'
          : '/v1/user/public/lighting-support/history?session_id=$sessionId&limit=$limit&offset=$offset';

      return await get(endpoint, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المحادثة: $e'};
    }
  }

  /// ✅ مسح محادثة دعم الإنارة
  Future<Map<String, dynamic>> clearLightingSupportConversation({
    bool requiresAuth = true,
    String? sessionId,
  }) async {
    try {
      if (requiresAuth) {
        return await delete(
          '/v1/user/lighting-support/clear',
          requiresAuth: true,
        );
      } else {
        return await post(
          '/v1/user/public/lighting-support/clear',
          requiresAuth: false,
          data: {'session_id': sessionId},
        );
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في مسح المحادثة: $e'};
    }
  }


}