import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/auth_service.dart';
import 'package:http/http.dart' as http;

class SolarSystemService {
  final String baseUrl;
  final AuthService authService;

  SolarSystemService({
    required this.baseUrl,
    required this.authService,
  });

  Future<String?> _getToken() async {
    await authService.refreshAuthState();
    return authService.token;
  }

  Future<Map<String, dynamic>> getUserSolarSystems({int page = 1}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/nex/v1/user/solar-systems?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في جلب المنظومات'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم: $e'};
    }
  }

  Future<Map<String, dynamic>> getSolarSystemDetails(int systemId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/nex/v1/user/solar-systems/$systemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في جلب تفاصيل المنظومة'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم'};
    }
  }

  Future<Map<String, dynamic>> addSolarSystem({
    required String installationDate,
    required bool isNew,
    String? previousIssues,
    String? notes,
    required int panelsCount,
    required double panelWattage,
    String? panelBrand,
    File? panelImage,
    String? inverterType,
    required double inverterPower,
    required int inverterCount,
    String? inverterBrand,
    File? inverterImage,
    required int batteriesCount,
    required double batteryCapacity,
    String? batteryType,
    String? batteryBrand,
    File? batteryImage,
    String? detailsNotes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/nex/v1/user/solar-systems/store'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['installation_date'] = installationDate;
      request.fields['is_new'] = isNew ? 'true' : 'false';
      request.fields['panels_count'] = panelsCount.toString();
      request.fields['panel_wattage'] = panelWattage.toString();
      request.fields['inverter_power'] = inverterPower.toString();
      request.fields['inverter_count'] = inverterCount.toString();
      request.fields['batteries_count'] = batteriesCount.toString();
      request.fields['battery_capacity'] = batteryCapacity.toString();

      if (previousIssues != null && previousIssues.isNotEmpty) {
        request.fields['previous_issues'] = previousIssues;
      }
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }
      if (panelBrand != null && panelBrand.isNotEmpty) {
        request.fields['panel_brand'] = panelBrand;
      }
      if (inverterType != null && inverterType.isNotEmpty) {
        request.fields['inverter_type'] = inverterType;
      }
      if (inverterBrand != null && inverterBrand.isNotEmpty) {
        request.fields['inverter_brand'] = inverterBrand;
      }
      if (batteryType != null && batteryType.isNotEmpty) {
        request.fields['battery_type'] = batteryType;
      }
      if (batteryBrand != null && batteryBrand.isNotEmpty) {
        request.fields['battery_brand'] = batteryBrand;
      }
      if (detailsNotes != null && detailsNotes.isNotEmpty) {
        request.fields['details_notes'] = detailsNotes;
      }

      if (panelImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('panel_image', panelImage.path));
      }
      if (inverterImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'inverter_image', inverterImage.path));
      }
      if (batteryImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'battery_image', batteryImage.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إضافة المنظومة بنجاح',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'حدث خطأ في إضافة المنظومة'
      };
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في الاتصال بالخادم: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSolarSystem(int systemId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/nex/v1/user/solar-systems/$systemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ في حذف المنظومة'};
    }
  }
}
