// lib/services/solar_api_service.dart

import 'package:GeniusHouse/services/api_service.dart';

extension SolarApiService on ApiService {
  String _solarBase({required bool auth}) =>
      auth ? '/v1/user/solar-design' : '/v1/user/public/solar-design';

  Future<Map<String, dynamic>> solarSaveDraft({
    required String sessionId,
    String? planKey,
    bool isSyp = false,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_solarBase(auth: requiresAuth)}/save-draft',
        requiresAuth: requiresAuth,
        data: {
          'session_id': sessionId,
          if (planKey != null && planKey.isNotEmpty) 'plan_key': planKey,
          'is_syp': isSyp,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في حفظ المسودة: $e'};
    }
  }

  Future<Map<String, dynamic>> solarMyProjects({
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_solarBase(auth: requiresAuth)}/projects';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;
      return await get(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المشاريع: $e'};
    }
  }

  Future<Map<String, dynamic>> solarShowProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_solarBase(auth: requiresAuth)}/projects/$projectId';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;
      return await get(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في جلب المشروع: $e'};
    }
  }

  Future<Map<String, dynamic>> solarDeleteProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path = '${_solarBase(auth: requiresAuth)}/projects/$projectId';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;
      return await delete(url, requiresAuth: requiresAuth);
    } catch (e) {
      return {'error': true, 'message': 'خطأ في حذف المشروع: $e'};
    }
  }

  Future<Map<String, dynamic>> solarDuplicateProject({
    required int projectId,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      final path =
          '${_solarBase(auth: requiresAuth)}/projects/$projectId/duplicate';
      final url = (!requiresAuth && sessionId != null && sessionId.isNotEmpty)
          ? '$path?session_id=$sessionId'
          : path;
      return await post(url, requiresAuth: requiresAuth, data: {});
    } catch (e) {
      return {'error': true, 'message': 'خطأ في نسخ المشروع: $e'};
    }
  }

  Future<Map<String, dynamic>> solarCompareProjects({
    required List<int> projectIds,
    String? sessionId,
    bool requiresAuth = false,
  }) async {
    try {
      return await post(
        '${_solarBase(auth: requiresAuth)}/projects/compare',
        requiresAuth: requiresAuth,
        data: {
          'project_ids': projectIds,
          if (!requiresAuth && sessionId != null) 'session_id': sessionId,
        },
      );
    } catch (e) {
      return {'error': true, 'message': 'خطأ في المقارنة: $e'};
    }
  }
}
