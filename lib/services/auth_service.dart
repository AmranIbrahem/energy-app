import 'package:flutter/foundation.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  // Load auth state from storage
  Future<void> _loadAuthState() async {
    _token = storageService.getToken();
    _isAuthenticated = _token != null && _token!.isNotEmpty;
    _isGuest = storageService.isGuestMode();
    _updateApiToken();
    notifyListeners();
  }

  void _updateApiToken() {
    if (_token != null) {
      _apiService.setToken(_token!);
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.setGuestMode(false);

        if (response.containsKey('data') && response['data'].containsKey('governorate')) {
          await storageService.saveGovernorate(response['data']['governorate']);
        }

        _updateApiToken();
        notifyListeners();

        return {'success': true, 'data': response};
      }

      return {'success': false, 'message': response['message'] ?? 'فشل تسجيل الدخول'};
    } catch (e) {
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
  }) async {
    try {
      final response = await _apiService.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'governorate': governorate,
        'district': district,
        'address': address,
        'user_type': userType,
      });

      if (response.containsKey('token')) {
        _token = response['token'];
        _isAuthenticated = true;
        _isGuest = false;

        await storageService.saveToken(_token!);
        await storageService.setGuestMode(false);
        await storageService.saveGovernorate(governorate);

        _updateApiToken();
        notifyListeners();

        return {'success': true, 'data': response};
      }

      return {'success': false, 'message': response['message'] ?? 'فشل إنشاء الحساب'};
    } catch (e) {
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

  // دالة لجلب التوكن وإرساله للخادم
  Future<void> sendFcmTokenToServer() async {
    try {
      // الحصول على التوكن من Firebase
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        // إرسال التوكن إلى الخادم
        await _apiService.sendFcmToken(token);
        print('✅ FCM Token sent to server: $token');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }


}