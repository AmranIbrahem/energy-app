// lib/services/auth_service.dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
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

  // Getters
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;

  // ✅ دالة لإعادة تحميل حالة المصادقة
  Future<void> refreshAuthState() async {
    await _loadAuthState();
    notifyListeners();
  }

  // Load auth state from storage
  Future<void> _loadAuthState() async {
    try {
      _token = storageService.getToken();
      _isAuthenticated = _token != null && _token!.isNotEmpty;
      _isGuest = storageService.isGuestMode();

      print('🟢 AuthService: Token = $_token');
      print('🟢 AuthService: isAuthenticated = $_isAuthenticated');
      print('🟢 AuthService: isGuest = $_isGuest');

      _updateApiToken();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading auth state: $e');
      _isAuthenticated = false;
      _isGuest = false;
      _token = null;
    }
  }

  void _updateApiToken() {
    if (_token != null && _token!.isNotEmpty) {
      _apiService.setToken(_token!);
      print('🟢 API Token updated: ${_token!.substring(0, min(20, _token!.length))}...');
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🟡 Attempting login for: $email');

      final response = await _apiService.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('🟢 Login response: $response');

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.setGuestMode(false);

        // ✅ حفظ بيانات المستخدم
        if (response.containsKey('data')) {
          await storageService.saveUserDataMap(response['data']);

          // حفظ اسم المستخدم بشكل منفصل
          if (response['data'].containsKey('name')) {
            await storageService.saveUserName(response['data']['name']);
          }
        }

        if (response.containsKey('data') && response['data'].containsKey('governorate')) {
          await storageService.saveGovernorate(response['data']['governorate']);
        }

        _updateApiToken();
        notifyListeners();

        return {'success': true, 'data': response};
      }

      return {'success': false, 'message': response['message'] ?? 'فشل تسجيل الدخول'};
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Register
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

      print('🟡 Attempting registration: $email');

      final response = await _apiService.post('/register', data: requestData);

      print('🟢 Register response: $response');

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.setGuestMode(false);

        // ✅ حفظ بيانات المستخدم
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

      return {'success': false, 'message': response['message'] ?? 'فشل إنشاء الحساب'};
    } catch (e) {
      print('❌ Register error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Continue as guest
  Future<void> continueAsGuest() async {
    _isAuthenticated = false;
    _isGuest = true;
    _token = null;

    await storageService.setGuestMode(true);
    await storageService.removeToken();

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _isGuest = false;
    _token = null;

    await storageService.clearAll();

    notifyListeners();
  }

  // Set governorate for guest
  Future<void> setGuestGovernorate(String governorate) async {
    await storageService.saveGovernorate(governorate);
    notifyListeners();
  }

  // Send FCM token
  Future<void> sendFcmTokenToServer() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiService.sendFcmToken(token);
        print('✅ FCM Token sent to server: $token');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataMap = storageService.getUserDataMap();
      if (userDataMap != null && userDataMap.isNotEmpty) {
        print('🟢 User data from storage: $userDataMap');
        return userDataMap;
      }

      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null && userDataJson.isNotEmpty) {
        final data = jsonDecode(userDataJson);
        print('🟢 User data from prefs: $data');
        return data;
      }

      print('⚠️ No user data found');
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // ✅ دالة للتحقق من صحة التوكن
  Future<bool> validateToken() async {
    try {
      final token = storageService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found');
        return false;
      }

      // يمكن إضافة استدعاء API للتحقق من صحة التوكن
      print('✅ Token exists: ${token.substring(0, min(20, token.length))}...');
      return true;
    } catch (e) {
      print('❌ Token validation error: $e');
      return false;
    }
  }
}