// lib/services/text_ad_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:GeniusHouse/services/auth_service.dart';

class TextAdService {
  final String baseUrl;
  final AuthService authService;

  TextAdService({
    required this.baseUrl,
    required this.authService,
  });

  Future<List<Map<String, dynamic>>> getActiveTextAds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/user/public/text-ads'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching text ads: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCarouselTextAds({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/user/public/text-ads/carousel?limit=$limit'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching carousel text ads: $e');
      return [];
    }
  }
}
