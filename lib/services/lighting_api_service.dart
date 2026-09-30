// lib/services/lighting_api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:http/http.dart' as http;

extension LightingApiService on ApiService {
  // ═══════════════════════════════════════════════════════════
  // Base paths
  // ═══════════════════════════════════════════════════════════

  String _lightingBase({required bool auth}) =>
      auth ? '/v1/user/lighting-design' : '/v1/user/public/lighting-design';

  // ═══════════════════════════════════════════════════════════
  // 1) Config
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingDesignConfig({
    bool requiresAuth = false,
  }) async {
    try {
      return await get(
        '${_lightingBase(auth: requiresAuth)}/config',
        requiresAuth: requiresAuth,
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب الإعدادات: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 2) Start Session
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingDesignStart({
    String? governorate,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/start',
        requiresAuth: requiresAuth,
        data: {
          if (governorate != null && governorate.isNotEmpty)
            'governorate': governorate,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في بدء الجلسة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 3) Upload Room Photo (multipart)
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingUploadRoomPhoto({
    required String sessionId,
    required File photo,
    bool requiresAuth = false,
  }) async {
    try {
      final endpoint = '${_lightingBase(auth: requiresAuth)}/upload-photo';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
      );

      final token = storageService.getToken();
      if (requiresAuth && token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.fields['session_id'] = sessionId;
      request.files.add(
        await http.MultipartFile.fromPath('photo', photo.path),
      );

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final statusCode = streamed.statusCode;

      if (statusCode >= 200 && statusCode < 300) {
        try {
          return jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {
          return {
            'error': true,
            'message': 'خطأ في معالجة الرد',
            'statusCode': statusCode,
          };
        }
      }

      try {
        final err = jsonDecode(body);
        return {
          'error': true,
          'message': err['message'] ?? 'فشل رفع الصورة',
          'statusCode': statusCode,
          'errors': err['errors'],
        };
      } catch (_) {
        return {
          'error': true,
          'message': 'فشل رفع الصورة',
          'statusCode': statusCode,
        };
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في رفع الصورة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 4) Design
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingDesign({
    required Map<String, dynamic> room,
    String? sessionId,
    int? projectId,
    String? governorate,
    bool withAi = true,
    bool isSyp = false,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/design',
        requiresAuth: requiresAuth,
        data: {
          'room': room,
          'with_ai': withAi,
          'is_syp': isSyp,
          if (sessionId != null && sessionId.isNotEmpty)
            'session_id': sessionId,
          if (projectId != null) 'project_id': projectId,
          if (governorate != null && governorate.isNotEmpty)
            'governorate': governorate,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في التصميم: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 5) Recheck
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingRecheck({
    required Map<String, dynamic> room,
    required List<Map<String, dynamic>> items,
    bool isSyp = false,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/recheck',
        requiresAuth: requiresAuth,
        data: {
          'room': room,
          'items': items,
          'is_syp': isSyp,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في إعادة الفحص: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 6) Alternatives
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingAlternatives({
    required Map<String, dynamic> room,
    required String role,
    String? fixtureType,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/alternatives',
        requiresAuth: requiresAuth,
        data: {
          'room': room,
          'role': role,
          if (fixtureType != null && fixtureType.isNotEmpty)
            'fixture_type': fixtureType,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب البدائل: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 7) Replace Unavailable
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingReplaceUnavailable({
    required Map<String, dynamic> room,
    required Map<String, dynamic> unavailableItem,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/replace-unavailable',
        requiresAuth: requiresAuth,
        data: {'room': room, 'unavailable_item': unavailableItem},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في الاستبدال: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 8) Compare Attempts
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingCompareAttempts({
    required Map<String, dynamic> room,
    required Map<String, dynamic> first,
    required Map<String, dynamic> second,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/compare-attempts',
        requiresAuth: requiresAuth,
        data: {'room': room, 'first': first, 'second': second},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في المقارنة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 9) Project Summary
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingProjectSummary({
    required String projectId,
    required List<Map<String, dynamic>> rooms,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/project-summary',
        requiresAuth: requiresAuth,
        data: {'project_id': projectId, 'rooms': rooms},
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في ملخص المشروع: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 10) Visualization Payload
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingVisualizationPayload({
    required Map<String, dynamic> room,
    required List<Map<String, dynamic>> confirmedItems,
    required Map<String, dynamic> distribution,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/visualization-payload',
        requiresAuth: requiresAuth,
        data: {
          'room': room,
          'confirmed_items': confirmedItems,
          'distribution': distribution,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في تجهيز المعاينة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 11) Confirm Attempt
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingConfirmAttempt({
    required String sessionId,
    required Map<String, dynamic> room,
    required String planKey,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> distribution,
    required double equipmentAmount,
    required String equipmentCurrency,
    required double estimatedLux,
    required double totalPowerW,
    int? projectId,
    String? imageRef,
    bool isSyp = false,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/confirm-attempt',
        requiresAuth: requiresAuth,
        data: {
          'session_id': sessionId,
          if (projectId != null) 'project_id': projectId,
          'room': room,
          'plan_key': planKey,
          'items': items,
          'distribution': distribution,
          'equipment_total': {
            'amount': equipmentAmount,
            'currency': equipmentCurrency,
          },
          'estimated_lux': estimatedLux,
          'total_power_w': totalPowerW,
          'is_syp': isSyp,
          if (imageRef != null) 'image_ref': imageRef,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في اعتماد المحاولة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 11-b) Generate Room Image
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingGenerateRoomImage({
    required String sessionId,
    required int roomIdDb,
    required int attemptId,
    required List<Map<String, dynamic>> confirmedItems,
    required Map<String, dynamic> distribution,
    int? projectId,
    String aspectRatio = '4:3',
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_lightingBase(auth: requiresAuth)}/generate-room-image',
        requiresAuth: requiresAuth,
        data: {
          'session_id': sessionId,
          if (projectId != null) 'project_id': projectId,
          'room_id_db': roomIdDb,
          'attempt_id': attemptId,
          'confirmed_items': confirmedItems,
          'distribution': distribution,
          'aspect_ratio': aspectRatio,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في توليد الصورة: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 12) My Projects
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingMyProjects({
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_lightingBase(auth: requiresAuth)}/projects';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;

      return await get(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المشاريع: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 13) Show Project
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingShowProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_lightingBase(auth: requiresAuth)}/projects/$projectId';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;

      return await get(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المشروع: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 14) Session History
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingSessionHistory({
    required String sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      return await get(
        '${_lightingBase(auth: requiresAuth)}/sessions/$sessionId/history',
        requiresAuth: requiresAuth,
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب السجل: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 15) Delete Project
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingDeleteProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_lightingBase(auth: requiresAuth)}/projects/$projectId';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;

      return await delete(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في حذف المشروع: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 16) Confirm Project
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> lightingConfirmProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path =
          '${_lightingBase(auth: requiresAuth)}/projects/$projectId/confirm';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;

      return await post(url, requiresAuth: requiresAuth, data: {});
    } catch (e) {
      return {'error': true, 'message': 'خطأ في تأكيد المشروع: $e'};
    }
  }
}
