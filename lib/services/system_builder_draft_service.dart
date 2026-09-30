import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemBuilderDraftService extends ChangeNotifier {
  static final SystemBuilderDraftService _instance =
      SystemBuilderDraftService._internal();

  static SystemBuilderDraftService get instance => _instance;

  SystemBuilderDraftService._internal();

  List<Map<String, dynamic>> _panels = [];
  List<Map<String, dynamic>> _inverters = [];
  List<Map<String, dynamic>> _batteries = [];
  List<Map<String, dynamic>> _cables = [];
  List<Map<String, dynamic>> _panelBoards = [];

  List<Map<String, dynamic>> get panels => List.unmodifiable(_panels);

  List<Map<String, dynamic>> get inverters => List.unmodifiable(_inverters);

  List<Map<String, dynamic>> get batteries => List.unmodifiable(_batteries);

  List<Map<String, dynamic>> get cables => List.unmodifiable(_cables);

  List<Map<String, dynamic>> get panelBoards => List.unmodifiable(_panelBoards);

  bool get hasDraft =>
      _panels.isNotEmpty ||
      _inverters.isNotEmpty ||
      _batteries.isNotEmpty ||
      _cables.isNotEmpty ||
      _panelBoards.isNotEmpty;

  int get totalItems {
    int count = 0;
    for (var p in _panels) count += (p['quantity'] ?? 1) as int;
    for (var i in _inverters) count += (i['quantity'] ?? 1) as int;
    for (var b in _batteries) count += (b['quantity'] ?? 1) as int;
    for (var c in _cables) count += (c['quantity'] ?? 1) as int;
    for (var pb in _panelBoards) count += (pb['quantity'] ?? 1) as int;
    return count;
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString('system_builder_draft');
    if (draftJson != null && draftJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(draftJson);
        _panels = List<Map<String, dynamic>>.from(decoded['panels'] ?? []);
        _inverters =
            List<Map<String, dynamic>>.from(decoded['inverters'] ?? []);
        _batteries =
            List<Map<String, dynamic>>.from(decoded['batteries'] ?? []);
        _cables = List<Map<String, dynamic>>.from(decoded['cables'] ?? []);
        _panelBoards =
            List<Map<String, dynamic>>.from(decoded['panel_boards'] ?? []);
        notifyListeners();
      } catch (e) {
        // print('❌ Error loading system builder draft: $e');
        _clearAll();
      }
    }
  }

  Future<void> saveDraft({
    required List<Map<String, dynamic>> panels,
    required List<Map<String, dynamic>> inverters,
    required List<Map<String, dynamic>> batteries,
    required List<Map<String, dynamic>> cables,
    required List<Map<String, dynamic>> panelBoards,
  }) async {
    _panels = List.from(panels);
    _inverters = List.from(inverters);
    _batteries = List.from(batteries);
    _cables = List.from(cables);
    _panelBoards = List.from(panelBoards);
    notifyListeners();
    await _persist();
  }

  Future<void> clearDraft() async {
    _clearAll();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = json.encode({
      'panels': _panels,
      'inverters': _inverters,
      'batteries': _batteries,
      'cables': _cables,
      'panel_boards': _panelBoards,
    });
    await prefs.setString('system_builder_draft', draftJson);
  }

  void _clearAll() {
    _panels = [];
    _inverters = [];
    _batteries = [];
    _cables = [];
    _panelBoards = [];
  }
}
