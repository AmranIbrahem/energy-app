import 'package:shared_preferences/shared_preferences.dart';  // ✅ أضف /shared_preferences
import 'dart:convert';
class StorageService {
  static late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Token methods
  Future<void> saveToken(String token) async {
    await _preferences.setString('token', token);
  }

  String? getToken() {
    return _preferences.getString('token');
  }

  Future<void> removeToken() async {
    await _preferences.remove('token');
  }

  // User data methods
  Future<void> saveUserData(String userData) async {
    await _preferences.setString('user_data', userData);
  }

  String? getUserData() {
    return _preferences.getString('user_data');
  }

  // Governorate methods
  Future<void> saveGovernorate(String governorate) async {
    await _preferences.setString('governorate', governorate);
  }

  String? getGovernorate() {
    return _preferences.getString('governorate');
  }

  // Onboarding methods
  Future<void> setOnboardingSeen() async {
    await _preferences.setBool('onboarding_seen', true);
  }

  bool isOnboardingSeen() {
    return _preferences.getBool('onboarding_seen') ?? false;
  }

  // Guest mode methods
  Future<void> setGuestMode(bool isGuest) async {
    await _preferences.setBool('guest_mode', isGuest);
  }

  bool isGuestMode() {
    return _preferences.getBool('guest_mode') ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _preferences.clear();
  }

// أضف هذه الدوال في class StorageService

// حفظ بيانات المستخدم كـ Map
  Future<void> saveUserDataMap(Map<String, dynamic> userData) async {
    await _preferences.setString('user_data_map', jsonEncode(userData));
  }

// جلب بيانات المستخدم كـ Map
  Map<String, dynamic>? getUserDataMap() {
    final String? data = _preferences.getString('user_data_map');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

// حفظ اسم المستخدم
  Future<void> saveUserName(String name) async {
    await _preferences.setString('user_name', name);
  }

  String? getUserName() {
    return _preferences.getString('user_name');
  }
}