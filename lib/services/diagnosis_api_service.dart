import 'package:GeniusHouse/services/api_service.dart';

class DiagnosisApiService {
  final ApiService _api;

  DiagnosisApiService({required ApiService api}) : _api = api;

  Future<Map<String, dynamic>> listFaults({
    String? category,
    String? device,
  }) async {
    final params = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (device != null && device.isNotEmpty) {
      params['device'] = device;
    }

    return await _api.get(
      '/v1/user/public/diagnosis/faults',
      queryParams: params.isEmpty ? null : params,
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> startSession({
    required String mode,
    String? description,
    String? category,
    String? manufacturer,
    String? familyId,
    String? code,
    String? faultId,
    String? sessionId,
  }) async {
    final data = <String, dynamic>{'mode': mode};

    if (description != null && description.isNotEmpty) {
      data['description'] = description;
    }
    if (category != null && category.isNotEmpty) data['category'] = category;
    if (manufacturer != null && manufacturer.isNotEmpty) {
      data['manufacturer'] = manufacturer;
    }
    if (familyId != null && familyId.isNotEmpty) data['family_id'] = familyId;
    if (code != null && code.isNotEmpty) data['code'] = code;
    if (faultId != null && faultId.isNotEmpty) {
      data['fault_id'] = faultId;
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      data['session_id'] = sessionId;
    }

    return await _api.post(
      '/v1/user/public/diagnosis/sessions',
      data: data,
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> answer({
    required String sessionId,
    required int questionIndex,
    required String answer,
  }) async {
    return await _api.post(
      '/v1/user/public/diagnosis/sessions/$sessionId/answers',
      data: {
        'question_index': questionIndex,
        'answer': answer,
      },
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> completeStep({
    required String sessionId,
    required int stepIndex,
    String outcome = 'completed',
  }) async {
    return await _api.post(
      '/v1/user/public/diagnosis/sessions/$sessionId/steps/$stepIndex/complete',
      data: {'outcome': outcome},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> recordOutcome({
    required String sessionId,
    required String outcome,
  }) async {
    return await _api.post(
      '/v1/user/public/diagnosis/sessions/$sessionId/outcome',
      data: {'outcome': outcome},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> lookupCode({
    required String manufacturer,
    required String familyId,
    required String code,
  }) async {
    return await _api.post(
      '/v1/user/public/inverter-code-lookups',
      data: {
        'manufacturer': manufacturer,
        'family_id': familyId,
        'code': code,
      },
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> listFamilies({
    required String manufacturer,
  }) async {
    return await _api.get(
      '/v1/user/public/inverter-families',
      queryParams: {'manufacturer': manufacturer},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> showSession({
    required String sessionId,
  }) async {
    return await _api.get(
      '/v1/user/public/diagnosis/sessions/$sessionId',
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> deviceTree({
    required String category,
  }) async {
    return await _api.get(
      '/v1/user/public/diagnosis/device-tree',
      queryParams: {'category': category},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> search({
    required String query,
    String? category,
  }) async {
    final params = <String, dynamic>{'q': query};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }

    return await _api.get(
      '/v1/user/public/diagnosis/search',
      queryParams: params,
      requiresAuth: false,
    );
  }
}
