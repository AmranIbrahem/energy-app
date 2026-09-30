// lib/services/auth_service.dart

import 'dart:convert';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final StorageService storageService;
  final ApiService _apiService;

  String? _token;
  bool _isAuthenticated = false;
  bool _isGuest = false;

  AuthService({required this.storageService})
      : _apiService = ApiService(storageService: storageService) {
    _loadAuthState();
  }

  String? get token => _token;

  bool get isAuthenticated => _isAuthenticated;

  bool get isGuest => _isGuest;

  Future<void> refreshAuthState() async {
    await _loadAuthState();
    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    try {
      _token = storageService.getToken();
      _isAuthenticated = _token != null && _token!.isNotEmpty;
      _isGuest = storageService.isGuestMode();

      _updateApiToken();
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      _isGuest = false;
      _token = null;
    }
  }

  void _updateApiToken() {
    if (_token != null && _token!.isNotEmpty) {
      _apiService.setToken(_token!);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response['email_verification_required'] == true ||
          (response['data'] != null &&
              response['data']['email_verification_required'] == true)) {
        return {
          'success': false,
          'message': 'يجب تأكيد البريد الإلكتروني أولاً',
          'data': {
            'email_verification_required': true,
            'email': email,
          }
        };
      }

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.saveTokenCreatedAt(DateTime.now());
        await storageService.setGuestMode(false);
        if (response.containsKey('remember_token')) {
          await storageService.saveRememberToken(response['remember_token']);
        }

        if (response.containsKey('data')) {
          await storageService.saveUserDataMap(response['data']);

          if (response['data'].containsKey('name')) {
            await storageService.saveUserName(response['data']['name']);
          }
        }

        if (response.containsKey('data') &&
            response['data'].containsKey('governorate')) {
          await storageService.saveGovernorate(response['data']['governorate']);
        }

        _updateApiToken();
        notifyListeners();

        final userData = response['data'] ?? {};
        return {
          'success': true,
          'data': userData,
          'user_type': userData['user_type'] ?? response['role'],
          'token': response['token'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل تسجيل الدخول'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String governorate,
    required String district,
    required String address,
    required String userType,
    String? referralCode,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'governorate': governorate,
        'district': district,
        'address': address,
        'user_type': userType,
      };

      if (referralCode != null && referralCode.isNotEmpty) {
        requestData['referral_code'] = referralCode;
      }

      final response = await _apiService.post('/register', data: requestData);

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.setGuestMode(false);

        final userData = {
          'name': name,
          'email': email,
          'phone': phone,
          'governorate': governorate,
          'district': district,
          'address': address,
          'user_type': userType,
        };
        await storageService.saveUserDataMap(userData);
        await storageService.saveUserName(name);

        _updateApiToken();
        notifyListeners();

        return {'success': true, 'data': response};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل إنشاء الحساب'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        '/verify-email',
        data: {
          'email': email,
          'code': code,
        },
        requiresAuth: false,
      );

      if (response['status'] == true ||
          response['message'] == 'Email verified successfully.') {
        await refreshAuthState();
        return {'success': true, 'message': 'تم تأكيد البريد الإلكتروني بنجاح'};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل في تأكيد البريد الإلكتروني'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في التحقق من البريد الإلكتروني'
      };
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/resend-verification-code',
        data: {
          'email': email,
        },
        requiresAuth: false,
      );

      if (response['status'] == true ||
          response['message'] == 'Verification code sent successfully.') {
        return {'success': true, 'message': 'تم إرسال رمز التحقق بنجاح'};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل في إرسال رمز التحقق'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في إعادة إرسال الرمز'};
    }
  }

  Future<void> continueAsGuest() async {
    _isAuthenticated = false;
    _isGuest = true;
    _token = null;

    await storageService.setGuestMode(true);
    await storageService.removeToken();

    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isGuest = false;
    _token = null;

    await storageService.clearAll();
    await storageService.removeRememberToken();

    notifyListeners();
  }

  Future<void> setGuestGovernorate(String governorate) async {
    await storageService.saveGovernorate(governorate);
    notifyListeners();
  }

  Future<void> sendFcmTokenToServer() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiService.sendFcmToken(token);
      }
    } catch (e) {
      //
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataMap = storageService.getUserDataMap();
      if (userDataMap != null && userDataMap.isNotEmpty) {
        return userDataMap;
      }

      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null && userDataJson.isNotEmpty) {
        final data = jsonDecode(userDataJson);
        return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateToken() async {
    try {
      final token = storageService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetCode({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/forgot-password',
        data: {
          'email': email,
        },
        requiresAuth: false,
      );

      final isSuccess = response['status'] == true ||
          response['message']?.toString().contains('تم إرسال') == true ||
          response['message']?.toString().contains('success') == true;

      if (isSuccess) {
        return {
          'success': true,
          'message': response['message'] ??
              'تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني'
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل في إرسال رمز إعادة التعيين'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في إرسال الرمز'};
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        '/verify-reset-code',
        data: {
          'email': email,
          'code': code,
        },
        requiresAuth: false,
      );

      final isSuccess = response['status'] == true ||
          response['success'] == true ||
          (response['message']?.toString().contains('تم التحقق') ?? false) ||
          (response['message']?.toString().contains('نجاح') ?? false);

      if (isSuccess) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم التحقق من الرمز بنجاح',
          'email': email,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'رمز التحقق غير صحيح'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في التحقق من الرمز'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        '/reset-password',
        data: {
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: false,
      );

      final isSuccess = response['status'] == true ||
          response['success'] == true ||
          (response['message']?.toString().contains('بنجاح') ?? false) ||
          (response['message']?.toString().contains('success') ?? false);

      if (isSuccess) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم إعادة تعيين كلمة المرور بنجاح'
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'فشل في إعادة تعيين كلمة المرور'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في إعادة تعيين كلمة المرور'
      };
    }
  }

  Future<bool> refreshToken() async {
    try {
      final rememberToken = storageService.getRememberToken();
      if (rememberToken == null || rememberToken.isEmpty) {
        return false;
      }

      final response = await _apiService.post(
        '/refresh-token',
        data: {'remember_token': rememberToken},
        requiresAuth: false,
      );

      if (response.containsKey('data') && response['data'] != null) {
        final newToken = response['data']['token'];
        final newRememberToken = response['data']['remember_token'];

        _token = newToken;
        await storageService.saveToken(newToken!);
        await storageService.saveTokenCreatedAt(DateTime.now());

        if (newRememberToken != null) {
          await storageService.saveRememberToken(newRememberToken);
        }

        _isAuthenticated = true;
        _isGuest = false;
        _updateApiToken();
        notifyListeners();

        return true;
      }

      await _performLogout();
      return false;
    } catch (e) {
      await _performLogout();
      return false;
    }
  }

  Future<bool> handleTokenExpiry() async {
    final token = storageService.getToken();

    if (token == null || token.isEmpty) {
      final rememberToken = storageService.getRememberToken();
      if (rememberToken != null && rememberToken.isNotEmpty) {
        return await refreshToken();
      }
      return false;
    }

    if (storageService.isTokenExpired()) {
      return await refreshToken();
    }

    if (storageService.isTokenExpiringSoon()) {
      await refreshToken();
    }

    _isAuthenticated = true;
    return true;
  }

  Future<void> _performLogout() async {
    _isAuthenticated = false;
    _isGuest = false;
    _token = null;
    await storageService.removeToken();
    await storageService.removeRememberToken();
    notifyListeners();
  }

  Future<bool> refreshTokenDirectly(String rememberToken) async {
    try {
      final response = await _apiService.post(
        '/refresh-token',
        data: {'remember_token': rememberToken},
        requiresAuth: false,
      );

      if (response.containsKey('data') && response['data'] != null) {
        final newToken = response['data']['token'];
        final newRememberToken = response['data']['remember_token'];

        _token = newToken;
        await storageService.saveToken(newToken!);
        await storageService.saveTokenCreatedAt(DateTime.now());

        if (newRememberToken != null) {
          await storageService.saveRememberToken(newRememberToken);
        }

        _isAuthenticated = true;
        _isGuest = false;
        _updateApiToken();
        notifyListeners();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
