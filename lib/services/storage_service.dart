// lib/services/storage_service.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> saveCustomQuickActions(List<String> actions) async {
    await _preferences.setStringList('custom_quick_actions', actions);
  }

  List<String> getCustomQuickActions() {
    return _preferences.getStringList('custom_quick_actions') ?? [];
  }

  Future<void> saveQuickActionsExpanded(bool expanded) async {
    await _preferences.setBool('quick_actions_expanded', expanded);
  }

  bool isQuickActionsExpanded() {
    return _preferences.getBool('quick_actions_expanded') ?? false;
  }

  Future<void> saveGuestSolarSessionId(String sessionId) async {
    await _preferences.setString('guest_solar_session_id', sessionId);
  }

  String? getGuestSolarSessionId() {
    return _preferences.getString('guest_solar_session_id');
  }

  Future<void> clearGuestSolarSessionId() async {
    await _preferences.remove('guest_solar_session_id');
  }

  Future<void> saveToken(String token) async {
    await _preferences.setString('token', token);
  }

  String? getToken() {
    return _preferences.getString('token');
  }

  Future<void> removeToken() async {
    await _preferences.remove('token');
  }

  Future<void> saveUserData(String userData) async {
    await _preferences.setString('user_data', userData);
  }

  String? getUserData() {
    return _preferences.getString('user_data');
  }

  Future<void> saveGovernorate(String governorate) async {
    await _preferences.setString('governorate', governorate);
  }

  String? getGovernorate() {
    return _preferences.getString('governorate');
  }

  Future<void> setOnboardingSeen() async {
    await _preferences.setBool('onboarding_seen', true);
  }

  bool isOnboardingSeen() {
    return _preferences.getBool('onboarding_seen') ?? false;
  }

  Future<void> setGuestMode(bool isGuest) async {
    await _preferences.setBool('guest_mode', isGuest);
  }

  bool isGuestMode() {
    return _preferences.getBool('guest_mode') ?? false;
  }

  Future<void> clearAll() async {
    await _preferences.clear();
  }

  Future<void> saveUserDataMap(Map<String, dynamic> userData) async {
    await _preferences.setString('user_data_map', jsonEncode(userData));
  }

  Map<String, dynamic>? getUserDataMap() {
    final String? data = _preferences.getString('user_data_map');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> saveUserName(String name) async {
    await _preferences.setString('user_name', name);
  }

  String? getUserName() {
    return _preferences.getString('user_name');
  }

  Future<void> saveGuestSessionId(String sessionId) async {
    await _preferences.setString('guest_session_id', sessionId);
  }

  String? getGuestSessionId() {
    return _preferences.getString('guest_session_id');
  }

  Future<void> saveGuestGovernorate(String governorate) async {
    await _preferences.setString('guest_governorate', governorate);
  }

  String? getGuestGovernorate() {
    return _preferences.getString('guest_governorate');
  }

  Future<void> saveGuestChatMessages(String messagesJson) async {
    await _preferences.setString('guest_chat_messages', messagesJson);
  }

  String? getGuestChatMessages() {
    return _preferences.getString('guest_chat_messages');
  }

  Future<void> clearGuestData() async {
    await _preferences.remove('guest_session_id');
    await _preferences.remove('guest_governorate');
    await _preferences.remove('guest_chat_messages');
  }

  // ✅ Remember Token
  Future<void> saveRememberToken(String token) async {
    await _preferences.setString('remember_token', token);
  }

  String? getRememberToken() {
    return _preferences.getString('remember_token');
  }

  Future<void> removeRememberToken() async {
    await _preferences.remove('remember_token');
  }

  Future<void> saveTokenCreatedAt(DateTime dateTime) async {
    await _preferences.setString(
        'token_created_at', dateTime.toIso8601String());
  }

  DateTime? getTokenCreatedAt() {
    final String? data = _preferences.getString('token_created_at');
    if (data != null) {
      return DateTime.tryParse(data);
    }
    return null;
  }

  bool isTokenExpiringSoon() {
    final createdAt = getTokenCreatedAt();
    if (createdAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final thirtyDays = const Duration(days: 30);
    final fiveDays = const Duration(days: 5);

    return difference > (thirtyDays - fiveDays);
  }

  bool isTokenExpired() {
    final createdAt = getTokenCreatedAt();
    if (createdAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final thirtyDays = const Duration(days: 30);

    return difference > thirtyDays;
  }

  // ✅ Support Solar Chat Session ID
  Future<void> saveGuestSupportSessionId(String sessionId) async {
    await _preferences.setString('guest_support_session_id', sessionId);
  }

  String? getGuestSupportSessionId() {
    return _preferences.getString('guest_support_session_id');
  }

  Future<void> clearGuestSupportSessionId() async {
    await _preferences.remove('guest_support_session_id');
  }

  // ✅ Appliance Maintenance Session ID
  Future<void> saveGuestMaintenanceSessionId(String sessionId) async {
    await _preferences.setString('guest_maintenance_session_id', sessionId);
  }

  String? getGuestMaintenanceSessionId() {
    return _preferences.getString('guest_maintenance_session_id');
  }

  Future<void> clearGuestMaintenanceSessionId() async {
    await _preferences.remove('guest_maintenance_session_id');
  }

  // ✅ Appliance Support Chat Session ID
  Future<void> saveGuestApplianceSupportSessionId(String sessionId) async {
    await _preferences.setString(
        'guest_appliance_support_session_id', sessionId);
  }

  String? getGuestApplianceSupportSessionId() {
    return _preferences.getString('guest_appliance_support_session_id');
  }

  Future<void> clearGuestApplianceSupportSessionId() async {
    await _preferences.remove('guest_appliance_support_session_id');
  }

  // ✅ Lighting Support Chat Session ID
  Future<void> saveGuestLightingSupportSessionId(String sessionId) async {
    await _preferences.setString(
        'guest_lighting_support_session_id', sessionId);
  }

  String? getGuestLightingSupportSessionId() {
    return _preferences.getString('guest_lighting_support_session_id');
  }

  Future<void> clearGuestLightingSupportSessionId() async {
    await _preferences.remove('guest_lighting_support_session_id');
  }

  Future<void> saveLightingSessionId(String sessionId) async {
    await _preferences.setString('lighting_session_id', sessionId);
  }

  String? getLightingSessionId() {
    return _preferences.getString('lighting_session_id');
  }

  Future<void> removeLightingSessionId() async {
    await _preferences.remove('lighting_session_id');
  }

  Future<void> saveAlwaysShowHub(bool value) async {
    await _preferences.setBool('always_show_hub', value);
  }

  bool isAlwaysShowHub() {
    return _preferences.getBool('always_show_hub') ?? true;
  }

  Future<void> saveShowUnifiedReminder(bool value) async {
    await _preferences.setBool('show_unified_reminder', value);
  }

  bool isShowUnifiedReminder() {
    return _preferences.getBool('show_unified_reminder') ?? true;
  }

  static const String currencyUsdConst = 'usd';
  static const String currencySypConst = 'syp';

  Future<void> savePreferredCurrency(String currency) async {
    if (currency != currencyUsdConst && currency != currencySypConst) {
      currency = currencyUsdConst;
    }
    await _preferences.setString('preferred_currency', currency);
  }

  String getPreferredCurrency() {
    return _preferences.getString('preferred_currency') ?? currencyUsdConst;
  }

  bool isSypPreferred() {
    return getPreferredCurrency() == currencySypConst;
  }

  bool isUsdPreferred() {
    return getPreferredCurrency() == currencyUsdConst;
  }

  static String get currencyUsd => currencyUsdConst;

  static String get currencySyp => currencySypConst;
}
