// lib/models/diagnosis_models.dart

class DiagnosticFault {
  final String id;
  final String category;
  final String device;
  final String title;
  final String severity;

  DiagnosticFault({
    required this.id,
    required this.category,
    required this.device,
    required this.title,
    required this.severity,
  });

  factory DiagnosticFault.fromJson(Map<String, dynamic> json) {
    return DiagnosticFault(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      device: (json['device'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      severity: (json['severity'] ?? 'normal').toString(),
    );
  }

  String get severityAr {
    switch (severity) {
      case 'danger':
        return 'خطر';
      case 'urgent':
        return 'عاجل';
      default:
        return 'عادي';
    }
  }
}

class InverterFamily {
  final String id;
  final String manufacturer;
  final String manufacturerLabel;
  final String label;
  final List<String> models;
  final String? sourceUrl;

  InverterFamily({
    required this.id,
    required this.manufacturer,
    required this.manufacturerLabel,
    required this.label,
    required this.models,
    this.sourceUrl,
  });

  factory InverterFamily.fromJson(Map<String, dynamic> json) {
    return InverterFamily(
      id: (json['id'] ?? '').toString(),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      manufacturerLabel: (json['manufacturer_label'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      models:
          (json['models'] as List?)?.map((e) => e.toString()).toList() ?? [],
      sourceUrl: json['source_url']?.toString(),
    );
  }
}

class InverterCodeResult {
  final String manufacturer;
  final String? manufacturerLabel;
  final String familyId;
  final String? familyLabel;
  final String code;
  final String meaning;
  final String resolutionMode;
  final List<String> userSteps;
  final String? sourceUrl;
  final String? sourcePages;
  final String? reviewStatus;

  InverterCodeResult({
    required this.manufacturer,
    this.manufacturerLabel,
    required this.familyId,
    this.familyLabel,
    required this.code,
    required this.meaning,
    required this.resolutionMode,
    required this.userSteps,
    this.sourceUrl,
    this.sourcePages,
    this.reviewStatus,
  });

  factory InverterCodeResult.fromJson(Map<String, dynamic> json) {
    return InverterCodeResult(
      manufacturer: (json['manufacturer'] ?? '').toString(),
      manufacturerLabel: json['manufacturer_label']?.toString(),
      familyId: (json['family_id'] ?? '').toString(),
      familyLabel: json['family_label']?.toString(),
      code: (json['code'] ?? '').toString(),
      meaning: (json['meaning'] ?? '').toString(),
      resolutionMode: (json['resolution_mode'] ?? 'maintenance').toString(),
      userSteps:
          (json['user_steps'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      sourceUrl: json['source_url']?.toString(),
      sourcePages: json['source_pages']?.toString(),
      reviewStatus: json['review_status']?.toString(),
    );
  }

  bool get isDanger => resolutionMode == 'danger';

  bool get isMaintenance => resolutionMode == 'maintenance';

  bool get isDirect => resolutionMode == 'direct';

  bool get isGuided => resolutionMode == 'guided';
}

class DiagnosisSessionResponse {
  final bool success;
  final String? sessionId;
  final int? sessionDbId;
  final String state;
  final String? safety;
  final String? message;

  final String? code;
  final String? meaning;
  final String? manufacturerLabel;
  final String? familyLabel;
  final String? resolutionMode;

  final int? questionIndex;
  final String? question;
  final int? totalQuestions;

  final int? stepIndex;
  final String? stepText;
  final int? totalSteps;
  final bool stepFinished;
  final bool askResolved;

  final String? faultId;
  final String? title;
  final String? result;
  final List<String>? causes;

  final List<String> matchedKeywords;
  final List<String> actions;
  final bool canRequestUrgent;
  final bool canRequestMaintenance;

  final Map<String, dynamic>? handoff;
  final Map<String, dynamic>? snapshot;

  final String? next;

  DiagnosisSessionResponse({
    required this.success,
    this.sessionId,
    this.sessionDbId,
    required this.state,
    this.safety,
    this.message,
    this.code,
    this.meaning,
    this.manufacturerLabel,
    this.familyLabel,
    this.resolutionMode,
    this.questionIndex,
    this.question,
    this.totalQuestions,
    this.stepIndex,
    this.stepText,
    this.totalSteps,
    this.stepFinished = false,
    this.askResolved = false,
    this.faultId,
    this.title,
    this.result,
    this.causes,
    this.matchedKeywords = const [],
    this.actions = const [],
    this.canRequestUrgent = false,
    this.canRequestMaintenance = false,
    this.handoff,
    this.snapshot,
    this.next,
  });

  factory DiagnosisSessionResponse.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;

    return DiagnosisSessionResponse(
      success: json['success'] == true,
      sessionId: data['session_id']?.toString(),
      sessionDbId: int.tryParse((data['session_db_id'] ?? 0).toString()),
      state: (data['state'] ?? '').toString(),
      safety: data['safety']?.toString(),
      message: data['message']?.toString(),
      code: data['code']?.toString(),
      meaning: data['meaning']?.toString(),
      manufacturerLabel: data['manufacturer_label']?.toString(),
      familyLabel: data['family_label']?.toString(),
      resolutionMode: data['resolution_mode']?.toString(),
      questionIndex: int.tryParse((data['question_index'] ?? '').toString()),
      question: data['question']?.toString(),
      totalQuestions: int.tryParse((data['total_questions'] ?? '').toString()),
      stepIndex: int.tryParse((data['step_index'] ?? '').toString()),
      stepText: data['step_text']?.toString(),
      totalSteps: int.tryParse((data['total_steps'] ?? '').toString()),
      stepFinished: data['step_finished'] == true,
      askResolved: data['ask_resolved'] == true,
      faultId: data['fault_id']?.toString(),
      title: data['title']?.toString(),
      result: data['result']?.toString(),
      causes: (data['causes'] as List?)?.map((e) => e.toString()).toList(),
      matchedKeywords: (data['matched_keywords'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      actions:
          (data['actions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      canRequestUrgent: data['can_request_urgent'] == true,
      canRequestMaintenance: data['can_request_maintenance'] == true,
      handoff: data['handoff'] is Map
          ? Map<String, dynamic>.from(data['handoff'])
          : null,
      snapshot: data['snapshot'] is Map
          ? Map<String, dynamic>.from(data['snapshot'])
          : null,
      next: data['next']?.toString(),
    );
  }

  bool get isQuestion => state == 'question';

  bool get isStep => state == 'step';

  bool get isResult => state == 'result';

  bool get isSafetyStop => state == 'safety_stop';

  bool get isNoMatch => state == 'no_match';

  bool get isSolved => state == 'solved';

  bool get isHandoff => state == 'handoff';

  bool get isDanger => safety == 'danger';
}

// ═══════════════════════════════════════════════════════════
// Device Tree Models
// ═══════════════════════════════════════════════════════════

class DeviceInfo {
  final String deviceKey;
  final String deviceName;
  final String icon;
  final int faultsCount;
  final bool hasCodes;
  final bool hasDanger;

  DeviceInfo({
    required this.deviceKey,
    required this.deviceName,
    required this.icon,
    required this.faultsCount,
    required this.hasCodes,
    required this.hasDanger,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceKey: (json['device_key'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      icon: (json['icon'] ?? 'devices').toString(),
      faultsCount: int.tryParse((json['faults_count'] ?? 0).toString()) ?? 0,
      hasCodes: json['has_codes'] == true,
      hasDanger: json['has_danger'] == true,
    );
  }
}

class DeviceTree {
  final String category;
  final String categoryLabel;
  final List<DeviceInfo> devices;

  DeviceTree({
    required this.category,
    required this.categoryLabel,
    required this.devices,
  });

  factory DeviceTree.fromJson(Map<String, dynamic> json) {
    return DeviceTree(
      category: (json['category'] ?? '').toString(),
      categoryLabel: (json['category_label'] ?? '').toString(),
      devices: (json['devices'] as List?)
              ?.map((e) => DeviceInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

class SearchResult {
  final String id;
  final String category;
  final String device;
  final String title;
  final String severity;

  SearchResult({
    required this.id,
    required this.category,
    required this.device,
    required this.title,
    required this.severity,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      device: (json['device'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      severity: (json['severity'] ?? 'normal').toString(),
    );
  }

  DiagnosticFault toFault() {
    return DiagnosticFault(
      id: id,
      category: category,
      device: device,
      title: title,
      severity: severity,
    );
  }
}

class SearchResponse {
  final String query;
  final int count;
  final List<SearchResult> results;

  SearchResponse({
    required this.query,
    required this.count,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: (json['query'] ?? '').toString(),
      count: int.tryParse((json['count'] ?? 0).toString()) ?? 0,
      results: (json['results'] as List?)
              ?.map((e) => SearchResult.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

const Map<String, int> deviceIconCodePoints = {
  'electrical_services': 0xe1b1,
  'battery_charging_full': 0xe1a3,
  'solar_power': 0xea93,
  'shield': 0xe32f,
  'swap_horiz': 0xe8d4,
  'power': 0xe8ac,
  'wifi': 0xe63e,
  'output': 0xebbe,
  'account_tree': 0xe97a,
  'power_off': 0xe8ad,
  'speed': 0xe9e4,
  'toggle_on': 0xec07,
  'cable': 0xe1b6,
  'shield_alert': 0xe32e,
  'warning': 0xe002,
  'lightbulb': 0xe0f0,
  'light': 0xe0f0,
  'tune': 0xe429,
  'visibility': 0xe8f4,
  'wb_twilight': 0xe1c6,
  'settings_input_component': 0xe8af,
  'devices': 0xe1b1,
};
