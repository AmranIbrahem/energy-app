// lib/screens/solar/solar_wizard_screen.dart

import 'dart:math';
import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/screens/solar/solar_projects_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/solar_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/system_builder_draft_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class DeviceVariant {
  final int id;
  final String? variantLabel;
  final String name;
  final double power;
  final double defaultDayHours;
  final double defaultNightHours;
  final bool heavy;
  final double surgeMultiplier;
  final double runtimeFactor;

  DeviceVariant({
    required this.id,
    this.variantLabel,
    required this.name,
    required this.power,
    required this.defaultDayHours,
    required this.defaultNightHours,
    required this.heavy,
    required this.surgeMultiplier,
    required this.runtimeFactor,
  });

  factory DeviceVariant.fromJson(Map<String, dynamic> json) {
    return DeviceVariant(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      variantLabel: (json['variant_label'] ?? '').toString().trim().isEmpty
          ? null
          : json['variant_label'].toString(),
      name: json['name_ar'] ?? 'جهاز',
      power: double.tryParse((json['power_watts'] ?? 0).toString()) ?? 0,
      defaultDayHours:
          double.tryParse((json['default_day_hours'] ?? 1).toString()) ?? 1,
      defaultNightHours:
          double.tryParse((json['default_night_hours'] ?? 0).toString()) ?? 0,
      heavy:
          json['heavy'] == true || json['heavy'] == 1 || json['heavy'] == '1',
      surgeMultiplier:
          double.tryParse((json['surge_multiplier'] ?? 1).toString()) ?? 1,
      runtimeFactor:
          double.tryParse((json['runtime_factor'] ?? 1).toString()) ?? 1,
    );
  }

  String get displayLabel {
    if (variantLabel != null && variantLabel!.isNotEmpty) {
      return '$variantLabel · ${power.toStringAsFixed(0)}W';
    }
    return '${name} · ${power.toStringAsFixed(0)}W';
  }
}

class DeviceGroup {
  final String groupKey;
  final String name;
  final String iconName;
  final int sort;
  final List<DeviceVariant> variants;

  DeviceGroup({
    required this.groupKey,
    required this.name,
    required this.iconName,
    required this.sort,
    required this.variants,
  });

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      groupKey: json['group_key'] ?? '',
      name: json['name_ar'] ?? '',
      iconName: json['icon'] ?? 'devices',
      sort: int.tryParse((json['sort'] ?? 0).toString()) ?? 0,
      variants: (json['variants'] as List? ?? [])
          .map((e) => DeviceVariant.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DeviceSection {
  final String sectionKey;
  final String title;
  final List<DeviceGroup> groups;

  DeviceSection({
    required this.sectionKey,
    required this.title,
    required this.groups,
  });

  factory DeviceSection.fromJson(Map<String, dynamic> json) {
    return DeviceSection(
      sectionKey: json['section_key'] ?? '',
      title: json['title_ar'] ?? '',
      groups: (json['groups'] as List? ?? [])
          .map((e) => DeviceGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SelectedDevice {
  final String rowId;
  final DeviceGroup group;
  final DeviceVariant variant;
  int quantity;
  double dayHours;
  double nightHours;
  double? customPower;

  SelectedDevice({
    required this.rowId,
    required this.group,
    required this.variant,
    this.quantity = 1,
    double? dayHours,
    double? nightHours,
    this.customPower,
  })  : dayHours = dayHours ?? variant.defaultDayHours,
        nightHours = nightHours ?? variant.defaultNightHours;

  double get effectivePower => customPower ?? variant.power;

  double get totalPower => effectivePower * quantity;

  bool get isHeavy => variant.heavy;

  int get variantId => variant.id;
}

class SolarWizardScreen extends StatefulWidget {
  final ApiService? apiService;
  final StorageService? storageService;

  const SolarWizardScreen({
    Key? key,
    this.apiService,
    this.storageService,
  }) : super(key: key);

  @override
  State<SolarWizardScreen> createState() => _SolarWizardScreenState();
}

class _SolarWizardScreenState extends State<SolarWizardScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late final StorageService _storageService;
  final Random _rand = Random();
  bool _isSavingDraft = false;

  bool get _isSypPreferred {
    try {
      return _storageService.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _fmt(double amount) {
    final num = amount.toStringAsFixed(2);
    return _isSypPreferred ? '$num SYP' : '\$$num';
  }

  String _fmtHours(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  String _newRowId(String prefix) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = _rand.nextInt(9999);
    return '$prefix-$ts$r';
  }

  int _currentStep = 0;
  static const int _totalSteps = 6;

  String _placeType = 'house';

  String? _selectedCity;
  final TextEditingController _areaController = TextEditingController();
  String? _electricalSupply;

  List<DeviceSection> _sections = [];
  bool _isLoadingSections = true;
  bool _showMoreSections = false;

  List<SelectedDevice> _selectedDevices = [];

  final Map<String, int> _daySimultaneous = {};
  final Map<String, int> _nightSimultaneous = {};

  bool _isSubmitting = false;
  Map<String, dynamic>? _designResult;
  String? _aiExplanation;
  String? _sessionId;
  bool _showFullAIExplanation = false;
  final Map<String, bool> _expandedPlans = {};

  bool _splitHintDismissed = false;
  bool _splitHintSeenOnce = false;

  final List<String> _syrianGovernorates = const [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'درعا',
    'السويداء',
    'القنيطرة',
    'دير الزور',
    'الرقة',
    'الحسكة'
  ];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageService();
    _apiService =
        widget.apiService ?? ApiService(storageService: _storageService);
    _loadSections();
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    setState(() => _isLoadingSections = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/device-templates/$_placeType/grouped',
        requiresAuth: false,
      );

      final data = response['data'];
      final isOk = response['success'] == true || data != null;

      if (mounted && isOk && data is Map) {
        final sectionsJson = (data['sections'] as List?) ?? [];
        setState(() {
          _sections = sectionsJson
              .map((e) => DeviceSection.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _isLoadingSections = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingSections = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSections = false);
        _showSnackBar('خطأ في تحميل الأجهزة: $e');
      }
    }
  }

  List<SelectedDevice> _heavyDayLoads() =>
      _selectedDevices.where((d) => d.isHeavy && d.dayHours > 0).toList();

  List<SelectedDevice> _heavyNightLoads() =>
      _selectedDevices.where((d) => d.isHeavy && d.nightHours > 0).toList();

  void _initSimultaneityDefaults() {
    final dayHeavy = _heavyDayLoads();
    final nightHeavy = _heavyNightLoads();

    if (dayHeavy.length == 1) {
      _daySimultaneous.putIfAbsent(
          dayHeavy[0].rowId, () => dayHeavy[0].quantity);
    }
    if (nightHeavy.length == 1) {
      _nightSimultaneous.putIfAbsent(
          nightHeavy[0].rowId, () => nightHeavy[0].quantity);
    }

    _daySimultaneous
        .removeWhere((rid, _) => !dayHeavy.any((d) => d.rowId == rid));
    _nightSimultaneous
        .removeWhere((rid, _) => !nightHeavy.any((d) => d.rowId == rid));

    for (final rid in _daySimultaneous.keys.toList()) {
      final q = _daySimultaneous[rid]!;
      for (final d in dayHeavy) {
        if (d.rowId == rid && q > d.quantity) {
          _daySimultaneous[rid] = d.quantity;
          break;
        }
      }
    }
    for (final rid in _nightSimultaneous.keys.toList()) {
      final q = _nightSimultaneous[rid]!;
      for (final d in nightHeavy) {
        if (d.rowId == rid && q > d.quantity) {
          _nightSimultaneous[rid] = d.quantity;
          break;
        }
      }
    }
  }

  bool _isSimultaneityValid() {
    final dayHeavy = _heavyDayLoads();
    if (dayHeavy.isNotEmpty) {
      for (final d in dayHeavy) {
        final q = _daySimultaneous[d.rowId];
        if (q != null && (q < 1 || q > d.quantity)) return false;
      }
    }

    final nightHeavy = _heavyNightLoads();
    if (nightHeavy.isNotEmpty) {
      for (final d in nightHeavy) {
        final q = _nightSimultaneous[d.rowId];
        if (q != null && (q < 1 || q > d.quantity)) return false;
      }
    }

    return true;
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _selectedCity != null &&
            _selectedCity!.isNotEmpty &&
            _electricalSupply != null;
      case 2:
        return _selectedDevices.isNotEmpty;
      case 3:
        return _selectedDevices.every(
              (d) => d.dayHours > 0 || d.nightHours > 0,
            ) &&
            _selectedDevices.every(
              (d) => (d.dayHours + d.nightHours) <= 24,
            );
      case 4:
        return _isSimultaneityValid();
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _goNext() {
    if (_currentStep == 3) {
      setState(() {
        _initSimultaneityDefaults();
        _currentStep = 4;
      });
    } else if (_currentStep == 4) {
      setState(() => _currentStep = 5);
      _submitDesign();
    } else if (_currentStep == 5) {
      setState(() {
        _designResult = null;
        _aiExplanation = null;
        _showFullAIExplanation = false;
        _expandedPlans.clear();
        _currentStep = 2;
      });
    } else {
      setState(() => _currentStep++);
    }
  }

  Future<void> _openVariantSheet(DeviceGroup group) async {
    if (group.variants.length == 1) {
      _addVariant(group, group.variants.first);
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantSheet(group: group),
    );

    if (result != null && mounted) {
      final variant = result['variant'] as DeviceVariant;
      final quantity = result['quantity'] as int;
      final customPower = result['customPower'] as double?;
      _addVariant(group, variant, quantity: quantity, customPower: customPower);
    }
  }

  void _addVariant(
    DeviceGroup group,
    DeviceVariant variant, {
    int quantity = 1,
    double? customPower,
  }) {
    final newDayHours = variant.defaultDayHours;
    final newNightHours = variant.defaultNightHours;

    final existingIndex = _selectedDevices.indexWhere(
      (d) =>
          d.variantId == variant.id &&
          d.customPower == customPower &&
          d.dayHours == newDayHours &&
          d.nightHours == newNightHours,
    );

    if (existingIndex != -1) {
      setState(() => _selectedDevices[existingIndex].quantity += quantity);
    } else {
      setState(() {
        _selectedDevices.add(SelectedDevice(
          rowId: _newRowId('r'),
          group: group,
          variant: variant,
          quantity: quantity,
          customPower: customPower,
        ));
      });
    }
    _showSnackBar('تمت إضافة ${group.name} × $quantity', isSuccess: true);
  }

  void _removeDevice(int index) {
    setState(() {
      if (_selectedDevices[index].quantity > 1) {
        _selectedDevices[index].quantity--;
      } else {
        _selectedDevices.removeAt(index);
      }
    });
  }

  void _deleteDevice(int index) {
    setState(() {
      final removed = _selectedDevices.removeAt(index);
      _daySimultaneous.remove(removed.rowId);
      _nightSimultaneous.remove(removed.rowId);
    });
  }

  void _splitDevice(int index) {
    final device = _selectedDevices[index];
    if (device.quantity <= 1) {
      _showSnackBar('لا يمكن تقسيم صف بكمية 1', isSuccess: false);
      return;
    }
    setState(() {
      device.quantity -= 1;
      _selectedDevices.insert(
        index + 1,
        SelectedDevice(
          rowId: _newRowId(device.variant.id == -1 ? 'c' : 'r'),
          group: device.group,
          variant: device.variant,
          quantity: 1,
          dayHours: device.dayHours,
          nightHours: device.nightHours,
          customPower: device.customPower,
        ),
      );
    });
    _showSnackBar(
      '✅ تم تقسيم الصف — يمكنك الآن تعديل ساعات كل صف على حدة',
      isSuccess: true,
    );
  }

  void _addCustomDevice() {
    showDialog(
      context: context,
      builder: (context) => _CustomDeviceDialog(
        onAdd: (name, power, dayHours, nightHours) {
          final group = DeviceGroup(
            groupKey: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            iconName: 'custom',
            sort: 999,
            variants: [],
          );
          final variant = DeviceVariant(
            id: -1,
            variantLabel: null,
            name: name,
            power: power,
            defaultDayHours: dayHours,
            defaultNightHours: nightHours,
            heavy: power >= 500,
            surgeMultiplier: 1.0,
            runtimeFactor: 1.0,
          );
          setState(() {
            _selectedDevices.add(SelectedDevice(
              rowId: _newRowId('c'),
              group: group,
              variant: variant,
              dayHours: dayHours,
              nightHours: nightHours,
            ));
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submitDesign() async {
    setState(() => _isSubmitting = true);

    try {
      final token = _storageService.getToken();
      final isGuest = token == null || token.isEmpty;

      final selectedLoads = <Map<String, dynamic>>[];
      final customLoads = <Map<String, dynamic>>[];

      for (final d in _selectedDevices) {
        if (d.variant.id == -1) {
          customLoads.add({
            'row_id': d.rowId,
            'name_ar': d.variant.name,
            'rated_power_w': d.effectivePower,
            'quantity': d.quantity,
            'day_hours': d.dayHours,
            'night_hours': d.nightHours,
          });
        } else {
          selectedLoads.add({
            'row_id': d.rowId,
            'load_id': d.variant.id,
            'quantity': d.quantity,
            'day_hours': d.dayHours,
            'night_hours': d.nightHours,
          });
        }
      }

      final daytimeSim = _daySimultaneous.entries
          .map((e) => {
                'row_id': e.key,
                'simultaneous_quantity': e.value,
              })
          .toList();

      final nighttimeSim = _nightSimultaneous.entries
          .map((e) => {
                'row_id': e.key,
                'simultaneous_quantity': e.value,
              })
          .toList();

      final request = <String, dynamic>{
        'design_mode': 'home',
        'electrical_supply': _electricalSupply ?? 'unknown',
        'place_type': _placeType,
        'location': {
          'city_ar': _selectedCity,
          if (_areaController.text.trim().isNotEmpty)
            'area_ar': _areaController.text.trim(),
        },
        'selected_loads': selectedLoads,
        'custom_loads': customLoads,
        'daytime_simultaneous': daytimeSim,
        'nighttime_simultaneous': nighttimeSim,
        'is_syp': _isSypPreferred,
        if (_sessionId != null && _sessionId!.isNotEmpty)
          'session_id': _sessionId,
      };

      final endpoint = isGuest
          ? '/v1/user/public/solar-design/design'
          : '/v1/user/solar-design/design';

      final response = await _apiService.post(
        endpoint,
        data: request,
        requiresAuth: !isGuest,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _designResult = data['engine_result'];
          _aiExplanation = data['ai_explanation'];
          _sessionId = data['session_id'];
          _showFullAIExplanation = false;
          _expandedPlans.clear();
        });

        if (isGuest && _sessionId != null && _sessionId!.isNotEmpty) {
          try {
            await _storageService.saveGuestSolarSessionId(_sessionId!);
          } catch (_) {}
        }
      } else {
        final errorMessage =
            response['message']?.toString() ?? 'فشل التصميم، حاول مرة أخرى';
        _showErrorDialog(errorMessage);
        setState(() => _currentStep = 4);
      }
    } catch (e) {
      if (!mounted) return;
      String cleanMessage = 'حدث خطأ غير متوقع أثناء التصميم';
      final errorStr = e.toString();
      if (errorStr.contains('hours exceed 24') ||
          errorStr.contains('أكثر من 24')) {
        cleanMessage =
            'أحد الأجهزة يعمل أكثر من 24 ساعة يومياً. يرجى تعديل الساعات.';
      } else if (errorStr.contains('not valid for') ||
          errorStr.contains('غير متاح')) {
        cleanMessage = 'أحد الأجهزة غير متوافق مع نوع المكان المختار.';
      } else if (errorStr.contains('timeout')) {
        cleanMessage = 'الاتصال بالسيرفر استغرق وقتاً طويلاً. حاول مرة أخرى.';
      } else {
        cleanMessage = 'حدث خطأ: $e';
      }
      _showErrorDialog(cleanMessage);
      setState(() => _currentStep = 4);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text('تعذّر إتمام التصميم',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.red.shade800, height: 1.6),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('حسناً، سأعدّل',
                  style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  const Color(0xFF3B82F6).withOpacity(0.15),
                  const Color(0xFF60A5FA).withOpacity(0.08),
                ]),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Color(0xFF1E3A8A), size: 48),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text(
              'سارع بالإطلاق قريباً!\nسنُرسل لك إشعاراً بمجرد توفّر هذا القسم.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('حسناً، سأنتظر',
                    style: GoogleFonts.cairo(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomPowerDialog(int index) async {
    final device = _selectedDevices[index];
    final controller =
        TextEditingController(text: device.effectivePower.toStringAsFixed(0));

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل الاستطاعة',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${device.group.name} — ${device.variant.variantLabel ?? ''}',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
                'الاستطاعة الأصلية: ${device.variant.power.toStringAsFixed(0)}W',
                style: GoogleFonts.cairo(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A)),
              decoration: InputDecoration(
                suffixText: 'واط',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedDevices[index].customPower = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildAppBarWithCurve(),
            _buildStepperHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildCurrentStep(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarWithCurve() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      'تصميم منظومة شمسية',
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.bookmarks_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: _openDrafts,
                    tooltip: 'المسودات',
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 24),
                    onPressed: _showHelpDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final stepLabels = [
      'النوع',
      'الموقع',
      'الأجهزة',
      'الساعات',
      'التزامن',
      'النتائج',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : (isDone
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey.shade300),
                        border: isActive
                            ? Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.4),
                                width: 3)
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF3B82F6)
                                        .withOpacity(0.35),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : Text('${index + 1}',
                                style: GoogleFonts.cairo(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                )),
                      ),
                    ),
                    if (index == _totalSteps - 1) const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stepLabels[index],
                  style: GoogleFonts.cairo(
                    fontSize: 8,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    String buttonText = 'التالي';
    if (_currentStep == 4) buttonText = 'صمم منظومتي';
    if (_currentStep == 5) buttonText = 'إعادة التصميم';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 5)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('السابق', style: GoogleFonts.cairo(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ),
          if (_currentStep > 0 && _currentStep < 5) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : _canProceed()
                      ? _goNext
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(buttonText,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Type();
      case 1:
        return _buildStep1Location();
      case 2:
        return _buildStep2Loads();
      case 3:
        return _buildStep3Hours();
      case 4:
        return _buildStep4Simultaneity();
      case 5:
        return _buildStep5Results();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0Type() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نوع المنظومة',
              style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Text('اختر نوع المنظومة التي تريد تصميمها',
              style:
                  GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          _buildTypeCard(
            icon: Icons.home_rounded,
            title: 'منزلي',
            subtitle: 'سكني - متاح الآن',
            isAvailable: true,
            isSelected: true,
            onTap: () {},
          ),
          const SizedBox(height: 14),
          _buildTypeCard(
            icon: Icons.storefront_rounded,
            title: 'صناعي',
            subtitle: 'قريباً — قيد التطوير',
            isAvailable: false,
            isSelected: false,
            onTap: () => _showComingSoonDialog('المنظومات الصناعية'),
          ),
          const SizedBox(height: 14),
          _buildTypeCard(
            icon: Icons.agriculture_rounded,
            title: 'زراعي',
            subtitle: 'قريباً — قيد التطوير',
            isAvailable: false,
            isSelected: false,
            onTap: () => _showComingSoonDialog('المنظومات الزراعية'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isAvailable,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      blurRadius: 12)
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 8)
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 30,
                color:
                    isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isAvailable
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (!isAvailable)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('قريباً',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700)),
              )
            else if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Location() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الموقع ونوع الكهرباء',
              style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Text('حدد موقع التركيب ونوع الكهرباء في المكان',
              style:
                  GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: _inputDecoration(
                      'المدينة *', Icons.location_city_rounded),
                  items: _syrianGovernorates
                      .map((city) => DropdownMenuItem<String>(
                          value: city,
                          child: Text(city,
                              style: GoogleFonts.cairo(fontSize: 15))))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _areaController,
                  decoration:
                      _inputDecoration('المنطقة (اختياري)', Icons.map_rounded),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('نوع الكهرباء في المكان *',
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A))),
                ),
                const SizedBox(height: 10),
                _buildElectricalOption(
                    'single_220', 'أحادي 220V', Icons.electric_bolt_rounded),
                const SizedBox(height: 8),
                _buildElectricalOption(
                    'three_380', 'ثلاثي 380V', Icons.electric_bolt_rounded),
                const SizedBox(height: 8),
                _buildElectricalOption(
                    'unknown', 'لا أعرف', Icons.help_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectricalOption(String value, String label, IconData icon) {
    final isSelected = _electricalSupply == value;
    return GestureDetector(
      onTap: () => setState(() => _electricalSupply = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade500,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade700)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Loads() {
    if (_isLoadingSections) {
      return const Center(
          key: ValueKey('step2-loading'),
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }

    return CustomScrollView(
      key: const ValueKey('step2'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شو الأجهزة اللي بدك تشغّلها؟',
                    style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text('اختر الأجهزة وحدد الكميات',
                    style: GoogleFonts.cairo(
                        fontSize: 15, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _addCustomDevice,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text('إضافة جهاز غير موجود',
                  style: GoogleFonts.cairo(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        if (_sections.isNotEmpty) ...[
          _buildSectionSliver(_sections.first),
        ],
        if (_sections.length > 1) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _showMoreSections = !_showMoreSections),
                icon: Icon(
                    _showMoreSections
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22),
                label: Text(
                  _showMoreSections
                      ? 'إخفاء الأقسام الإضافية'
                      : 'عرض المزيد من الأجهزة',
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          if (_showMoreSections) ..._sections.skip(1).map(_buildSectionSliver),
        ],
        if (_selectedDevices.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأجهزة المختارة (${_selectedDevices.length})',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 10),
                  ..._selectedDevices
                      .asMap()
                      .entries
                      .map((e) => _buildSelectedDeviceRow(e.key, e.value)),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildSectionSliver(DeviceSection section) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(section.title,
                  style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: section.groups.length,
              itemBuilder: (context, index) =>
                  _buildGroupCard(section.groups[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(DeviceGroup group) {
    final selectedCount = _selectedDevices
        .where((d) => d.group.groupKey == group.groupKey)
        .fold<int>(0, (sum, d) => sum + d.quantity);

    return GestureDetector(
      onTap: () => _openVariantSheet(group),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedCount > 0
                ? const Color(0xFF3B82F6)
                : const Color(0xFF3B82F6).withOpacity(0.15),
            width: selectedCount > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getIconFromString(group.iconName),
                      size: 32, color: const Color(0xFF1E3A8A)),
                  const SizedBox(height: 8),
                  Text(
                    group.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (group.variants.length > 1) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${group.variants.length} خيارات',
                      style: GoogleFonts.cairo(
                          fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedCount > 0)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$selectedCount',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDeviceRow(int index, SelectedDevice device) {
    final hasCustomPower = device.customPower != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_getIconFromString(device.group.iconName),
                size: 20, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.group.name,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Row(
                  children: [
                    if (device.variant.variantLabel != null) ...[
                      Text(device.variant.variantLabel!,
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 4),
                    ],
                    Text('· ${device.effectivePower.toStringAsFixed(0)}W',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: hasCustomPower
                                ? Colors.orange.shade700
                                : Colors.grey.shade500,
                            fontWeight: hasCustomPower
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded,
                size: 18,
                color: hasCustomPower
                    ? Colors.orange.shade700
                    : Colors.grey.shade500),
            onPressed: () => _showCustomPowerDialog(index),
            tooltip: 'تعديل الاستطاعة',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  onPressed: () => _removeDevice(index),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF1E3A8A),
                ),
                Text('${device.quantity}',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E3A8A))),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  onPressed: () => setState(() => device.quantity++),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF1E3A8A),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            onPressed: () => _deleteDevice(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Hours() {
    final splittableCount =
        _selectedDevices.where((d) => d.quantity > 1).length;

    return Column(
      key: const ValueKey('step3'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ساعات التشغيل',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 4),
              Text('حدد ساعات التشغيل لكل صف على حدة',
                  style: GoogleFonts.cairo(
                      fontSize: 15, color: Colors.grey.shade600)),
            ],
          ),
        ),
        if (splittableCount > 0 && !_splitHintDismissed)
          _buildSplitHintBanner(splittableCount),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'كل صف = نوع جهاز بساعاته الخاصة. لو عندك وحدات من نفس النوع بساعات مختلفة، استخدم زر "تقسيم" لفصلهن.',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: const Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _selectedDevices.length,
            itemBuilder: (context, index) =>
                _buildHourRow(index, _selectedDevices[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitHintBanner(int splittableCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.12),
              const Color(0xFFA78BFA).withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.call_split_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 هل تحتاج ساعات مختلفة؟',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6D28D9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'لديك $splittableCount جهاز بكمية أكثر من 1. استخدم زر "تقسيم" البنفسجي لفصل وحدات بساعات مختلفة.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF6D28D9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _splitHintDismissed = true),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF6D28D9)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'إخفاء',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_split_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'تقسيم',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '← هذا شكل الزر الذي ستجده بجانب كل جهاز بكمية > 1',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF6D28D9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourRow(int index, SelectedDevice device) {
    final canSplit = device.quantity > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canSplit
              ? const Color(0xFF8B5CF6).withOpacity(0.3)
              : Colors.grey.shade200,
          width: canSplit ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconFromString(device.group.iconName),
                  size: 20, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${device.group.name}${device.variant.variantLabel != null ? ' · ${device.variant.variantLabel}' : ''}',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (canSplit)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _splitDevice(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF7C3AED),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.call_split_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'تقسيم',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('× ${device.quantity}',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHourField(
                  label: 'نهار',
                  value: device.dayHours,
                  otherValue: device.nightHours,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.wb_sunny_rounded,
                  onChanged: (v) => setState(() => device.dayHours = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHourField(
                  label: 'مساء',
                  value: device.nightHours,
                  otherValue: device.dayHours,
                  color: const Color(0xFF6366F1),
                  icon: Icons.nightlight_round,
                  onChanged: (v) => setState(() => device.nightHours = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourField({
    required String label,
    required double value,
    required double otherValue,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    final controller = TextEditingController(text: _fmtHours(value));
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);

    const maxTotal = 24.0;
    final wouldExceed = (value + otherValue) > maxTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _hourBtn(
              icon: Icons.remove_rounded,
              color: color,
              onTap: () => onChanged(value > 0.5 ? value - 0.5 : 0.0),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: color.withOpacity(0.06),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withOpacity(0.2))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color, width: 1.5)),
                  errorText: wouldExceed ? 'تجاوز 24' : null,
                ),
                onChanged: (text) {
                  final v = double.tryParse(text);
                  if (v != null && v >= 0) {
                    if (v + otherValue > maxTotal) {
                      _showSnackBar(
                        'مجموع الساعات لا يمكن أن يتجاوز 24',
                        isSuccess: false,
                      );
                      return;
                    }
                    onChanged(v);
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            _hourBtn(
              icon: Icons.add_rounded,
              color: color,
              onTap: () {
                final newVal = value + 0.5;
                if (newVal + otherValue > maxTotal) {
                  _showSnackBar(
                    'مجموع الساعات لا يمكن أن يتجاوز 24',
                    isSuccess: false,
                  );
                  return;
                }
                onChanged(newVal);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _hourBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildStep4Simultaneity() {
    return DefaultTabController(
      key: const ValueKey('step4-simultaneity'),
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تزامن الأحمال الثقيلة',
                    style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text('حدد الأحمال التي تعمل معاً في كل فترة',
                    style: GoogleFonts.cairo(
                        fontSize: 15, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ],
            ),
            child: TabBar(
              labelStyle:
                  GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
              indicator: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.wb_sunny_rounded, size: 20),
                  text: 'النهار',
                  height: 60,
                ),
                Tab(
                  icon: Icon(Icons.nightlight_round, size: 20),
                  text: 'المساء',
                  height: 60,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSimultaneityTab(period: 'day'),
                _buildSimultaneityTab(period: 'night'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimultaneityTab({required String period}) {
    final isDay = period == 'day';
    final accentColor =
        isDay ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
    final periodLabel = isDay ? 'النهار' : 'المساء';
    final loads = isDay ? _heavyDayLoads() : _heavyNightLoads();
    final map = isDay ? _daySimultaneous : _nightSimultaneous;

    if (loads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'لا توجد أحمال ثقيلة تعمل في $periodLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'لا تحتاج إلى تحديد أي تزامن في هذه الفترة.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCount = loads.where((d) => map.containsKey(d.rowId)).length;
    final isSingle = loads.length == 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(
                isSingle ? Icons.info_outline_rounded : Icons.checklist_rounded,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSingle
                      ? 'يوجد حمل ثقيل واحد فقط في $periodLabel — «${loads.first.group.name}». حدد كم وحدة تعمل منه.'
                      : 'لديك ${loads.length} أحمال ثقيلة في $periodLabel. اختر حمل واحد أو أكثر ليعملوا معًا، وحدد عدد الوحدات لكل منها.',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade800, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...loads.map((d) => _buildSimultaneityRow(
              device: d,
              map: map,
              color: accentColor,
              forced: isSingle,
            )),

        /* ✅ عرض عدد الأحمال المختارة — لتوضيح الحالة للمستخدم */
        if (!isSingle) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedCount > 0
                  ? accentColor.withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedCount > 0
                    ? accentColor.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedCount > 0
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: selectedCount > 0 ? accentColor : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCount > 0
                        ? 'اخترت $selectedCount ${selectedCount == 1 ? "حمل" : "أحمال"} تعمل معًا في $periodLabel.'
                        : 'لم تختر أي حمل — جميع الأحمال الثقيلة ستُعتبر غير متزامنة (الأكثر أماناً).',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: selectedCount > 0
                            ? accentColor
                            : Colors.grey.shade700,
                        fontWeight: selectedCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSimultaneityRow({
    required SelectedDevice device,
    required Map<String, int> map,
    required Color color,
    bool forced = false,
  }) {
    final selected = forced || map.containsKey(device.rowId);
    final qty = map[device.rowId] ?? device.quantity;

    return GestureDetector(
      onTap: forced
          ? null
          : () {
              setState(() {
                if (selected) {
                  map.remove(device.rowId);
                } else {
                  map[device.rowId] = device.quantity;
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!forced)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : Colors.transparent,
                      border: Border.all(
                        color: selected ? color : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                if (!forced) const SizedBox(width: 10),
                Icon(_getIconFromString(device.group.iconName),
                    size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${device.group.name}${device.variant.variantLabel != null ? ' · ${device.variant.variantLabel}' : ''}',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937)),
                  ),
                ),
                Text('× ${device.quantity}',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'كم وحدة تعمل معًا؟',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937)),
                      ),
                    ),
                    _simQtyBtn(
                      icon: Icons.remove_rounded,
                      color: color,
                      onTap: () {
                        if (qty > 1) {
                          setState(() => map[device.rowId] = qty - 1);
                        }
                      },
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text('$qty',
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ),
                    _simQtyBtn(
                      icon: Icons.add_rounded,
                      color: color,
                      onTap: () {
                        if (qty < device.quantity) {
                          setState(() => map[device.rowId] = qty + 1);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _simQtyBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildStep5Results() {
    if (_isSubmitting || _designResult == null) {
      return Center(
        key: const ValueKey('step5-loading'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              const SizedBox(height: 24),
              Text('جاري حساب المنظومة...',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              Text(
                'يقوم الذكاء الاصطناعي بتحليل منظومتك واختيار المنتجات المناسبة.\nقد يستغرق هذا 30-90 ثانية.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.6),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() {
                  _isSubmitting = false;
                  _currentStep = 4;
                }),
                child: Text('إلغاء والمحاولة لاحقاً',
                    style: GoogleFonts.cairo(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    final plans = _designResult!['plans'] as List? ?? [];
    final dailyEnergy = _designResult!['daily_energy_wh'] ?? 0;
    final daytimeEnergy = _designResult!['daytime_energy_wh'] ?? 0;
    final nightEnergy = _designResult!['night_energy_wh'] ?? 0;
    final continuousW = _designResult!['design_continuous_w'] ?? 0;
    final surgeW = _designResult!['design_surge_w'] ?? 0;
    final warnings = _designResult!['warnings_ar'] as List? ?? [];
    final assumptions = _designResult!['assumptions'] as List? ?? [];
    final savingsScenarios = _designResult!['savings_scenarios'] as List? ?? [];
    final budgetAssessment = _designResult!['budget_assessment'] as Map?;
    final status = _designResult!['status'] ?? '';

    final validPlans = plans.where((p) => p['valid'] == true).toList();
    final hasIdenticalPlans = _arePlansIdentical(validPlans);

    return ListView(
      key: const ValueKey('step5-results'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusBanner(status),
        const SizedBox(height: 12),
        _buildSummaryCard(
            dailyEnergy, daytimeEnergy, nightEnergy, continuousW, surgeW),
        const SizedBox(height: 16),
        if (_aiExplanation != null && _aiExplanation!.isNotEmpty) ...[
          _buildExpandableAIExplanation(),
          const SizedBox(height: 16),
        ],
        if (budgetAssessment != null) ...[
          _buildBudgetAssessmentCard(budgetAssessment),
          const SizedBox(height: 16),
        ],
        if (warnings.isNotEmpty) ...[
          _buildSectionContainer(
            title: '⚠️ تحذيرات',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
            children: warnings
                .map((w) => Text('• $w',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey.shade800)))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        Text('الخطط المتاحة',
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A))),
        const SizedBox(height: 12),
        if (hasIdenticalPlans && validPlans.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 جميع الخطط تستخدم نفس المكونات. الفرق هو هامش الأمان للعاكس.',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: const Color(0xFF1E3A8A)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        ...plans.map((plan) => _buildPlanCard(plan)),
        const SizedBox(height: 16),
        if (assumptions.isNotEmpty) ...[
          _buildSectionContainer(
            title: '📋 الافتراضات',
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF3B82F6),
            children: assumptions
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${a['message_ar'] ?? ''}',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: Colors.grey.shade700)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (savingsScenarios.isNotEmpty) ...[
          _buildSectionContainer(
            title: '💡 سيناريوهات التوفير',
            icon: Icons.savings_rounded,
            color: const Color(0xFF10B981),
            children: savingsScenarios
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['title_ar'] ?? '',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: const Color(0xFF1E3A8A))),
                          Text(s['message_ar'] ?? '',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildStatusBanner(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(status), color: _getStatusColor(status)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_getStatusLabel(status),
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _getStatusColor(status))),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(num dailyEnergy, num daytimeEnergy, num nightEnergy,
      num continuousW, num surgeW) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1E3A8A).withOpacity(0.1),
          const Color(0xFF3B82F6).withOpacity(0.05)
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('📊 ملخص المنظومة',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildSummaryItem('الطاقة اليومية', '${_fmtNum(dailyEnergy)} Wh'),
            _buildSummaryItem('الحمل المتزامن', '${_fmtNum(continuousW)} W'),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildSummaryItem('طاقة النهار', '${_fmtNum(daytimeEnergy)} Wh'),
            _buildSummaryItem('طاقة المساء', '${_fmtNum(nightEnergy)} Wh'),
          ]),
          const SizedBox(height: 8),
          _buildSummaryItem('حمل الإقلاع', '${_fmtNum(surgeW)} W'),
        ],
      ),
    );
  }

  String _fmtNum(dynamic n) {
    final v = double.tryParse(n.toString()) ?? 0;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Widget _buildBudgetAssessmentCard(Map assessment) {
    final status = assessment['status'] ?? 'not_provided';
    final message = assessment['message_ar'] ?? '';
    final actions = assessment['actions_ar'] as List? ?? [];
    final difference = assessment['difference'];

    Color color;
    IconData icon;
    switch (status) {
      case 'below_minimum':
        color = Colors.red;
        icon = Icons.error_outline_rounded;
        break;
      case 'above_need':
        color = Colors.orange;
        icon = Icons.trending_up_rounded;
        break;
      case 'within_need':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    final diffAmount = difference != null
        ? double.tryParse(difference['amount'].toString()) ?? 0.0
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text('تقييم الميزانية',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ]),
          const SizedBox(height: 8),
          Text(message,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
          if (difference != null && difference['amount'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'الفارق: ${_fmt(diffAmount)}',
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(a,
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableAIExplanation() {
    final fullText = _aiExplanation!;
    final isExpanded = _showFullAIExplanation;
    final previewText =
        fullText.length > 200 ? '${fullText.substring(0, 200)}...' : fullText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text('✨ تحليل ذكي',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.purple.shade700)),
          ]),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isExpanded ? fullText : previewText,
              style: GoogleFonts.cairo(
                  fontSize: 13, height: 1.7, color: Colors.grey.shade800),
            ),
          ),
          if (fullText.length > 200) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => _showFullAIExplanation = !_showFullAIExplanation),
                icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.purple),
                label: Text(
                  isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل الكاملة',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _arePlansIdentical(List<dynamic> plans) {
    if (plans.length < 2) return false;
    final firstProducts = (plans[0]['products'] as List? ?? [])
        .map((p) => '${p['product_id']}_${p['quantity']}')
        .toSet();
    for (var i = 1; i < plans.length; i++) {
      final products = (plans[i]['products'] as List? ?? [])
          .map((p) => '${p['product_id']}_${p['quantity']}')
          .toSet();
      if (firstProducts.length != products.length ||
          !firstProducts.containsAll(products)) return false;
    }
    return true;
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final valid = plan['valid'] ?? false;
    final recommended = plan['recommended'] ?? false;
    final title = plan['title_ar'] ?? 'خطة';
    final planKey = plan['key']?.toString() ?? title;
    final products = plan['products'] as List? ?? [];

    final inverterW = _readNum(plan['inverter_rated_w']);
    final pvArrayW = _readNum(plan['pv_array_w']);
    final targetInverterW = _readNum(plan['target_inverter_w']);
    final headroomPct = _readNum(plan['inverter_headroom_pct']);

    final inverterCount = _readInt(plan['inverter_count'], fallback: 1);
    final totalInverterW =
        _readNum(plan['total_inverter_w'], fallback: inverterW);
    final panelsPerInv = _readInt(plan['panels_per_inverter']);

    final batteryCount = _readInt(plan['battery_count'], fallback: 0);
    final batteryNominalWh = _readNum(plan['battery_nominal_wh']);
    final totalBatteryWh =
        _readNum(plan['total_battery_wh'], fallback: batteryNominalWh);

    final constraintsAr = plan['constraints_ar'] as List? ?? [];
    final compatibility = plan['compatibility'] as List? ?? [];
    final noteAr = plan['note_ar'] ?? '';
    final unverifiedItems = plan['unverified_items_ar'] as List? ?? [];
    final localCount = plan['local_product_count'] ?? 0;
    final shippedCount = plan['shipped_product_count'] ?? 0;

    final blockingErrors = plan['blocking_errors'] as List? ?? [];
    final planWarnings = plan['warnings_ar'] as List? ?? [];

    final equipmentTotal = plan['equipment_total']?['amount'] ?? 0;
    final standardAddons = plan['standard_addons'] as List? ?? [];
    final estimatedTotal = plan['estimated_total']?['amount'] ?? equipmentTotal;
    final addonsTotal = standardAddons.fold<num>(
        0,
        (sum, a) =>
            sum +
            (double.tryParse(a['total']?['amount']?.toString() ?? '0') ?? 0));

    final isExpanded = _expandedPlans[planKey] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: valid ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recommended
              ? const Color(0xFF10B981)
              : valid
                  ? Colors.grey.shade300
                  : Colors.grey.shade200,
          width: recommended ? 2 : 1,
        ),
        boxShadow: valid
            ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* Header */
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: recommended
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                recommended
                    ? Icons.star_rounded
                    : valid
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                color: recommended
                    ? const Color(0xFF10B981)
                    : valid
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: valid
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade500)),
            ),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('⭐ موصى به',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981))),
              ),
          ]),
          const SizedBox(height: 12),
          if (valid) ...[
            /* ─── المواصفات الأساسية ─── */
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildPlanSpec(
                'العاكس',
                inverterCount > 1
                    ? '× $inverterCount عاكس ${_fmtNum(inverterW)}W'
                    : '${_fmtNum(inverterW)} W',
              ),
              _buildPlanSpec(
                'الألواح',
                inverterCount > 1 && panelsPerInv > 0
                    ? '${_fmtNum(pvArrayW)} W ($panelsPerInv/عاكس)'
                    : '${_fmtNum(pvArrayW)} W',
              ),
              if (batteryNominalWh > 0)
                _buildPlanSpec(
                  'البطاريات',
                  batteryCount > 1
                      ? '× $batteryCount بطارية (${(totalBatteryWh / 1000).toStringAsFixed(1)} kWh)'
                      : '${(batteryNominalWh / 1000).toStringAsFixed(1)} kWh',
                ),
            ]),
            const SizedBox(height: 8),

            /* الهدف والهامش */
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlanSpec('🎯 الهدف', '${_fmtNum(targetInverterW)} W'),
                    _buildPlanSpec('📐 الهامش', '${_fmtNum(headroomPct)}%'),
                  ]),
            ),
            const SizedBox(height: 10),

            /* شارات التكوين المتوازي */
            if (inverterCount > 1 || batteryCount > 1) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (inverterCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.link_rounded,
                            size: 12, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        Text('ربط $inverterCount عواكس متوازية',
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7C3AED))),
                      ]),
                    ),
                  if (batteryCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.link_rounded,
                            size: 12, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text('ربط $batteryCount بطاريات متوازية',
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669))),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            /* شارات محلي / مشحون */
            if (localCount + shippedCount > 0)
              Wrap(
                spacing: 6,
                children: [
                  if (localCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('🏠 $localCount محلي',
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                    ),
                  if (shippedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('📦 $shippedCount مشحون',
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700)),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),

            /* المنتجات */
            Text('المنتجات:',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            ...products.map((p) => _buildProductRow(p)),

            /* مجموع المنتجات */
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مجموع المنتجات:',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey.shade700)),
                  Text(_fmt(double.tryParse(equipmentTotal.toString()) ?? 0),
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A))),
                ],
              ),
            ),

            /* الإضافات القياسية */
            if (standardAddons.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      size: 14, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 8),
                Text('الإضافات القياسية (تقديرية):',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFFF59E0B))),
              ]),
              const SizedBox(height: 10),
              ...standardAddons.map((a) => _buildAddonRow(a)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('مجموع الإضافات:',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.amber.shade900)),
                    Text(_fmt(double.tryParse(addonsTotal.toString()) ?? 0),
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ],

            /* المجموع التقديري */
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.payments_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('المجموع التقديري:',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ]),
                  Text(_fmt(double.tryParse(estimatedTotal.toString()) ?? 0),
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white)),
                ],
              ),
            ),

            /* النص الإلزامي */
            if (standardAddons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الأسعار والكميات تقديرية وقابلة للتعديل بعد الكشف. السعر لا يشمل تمديدات الكهرباء داخل المنزل. إذا لم يناسب السطح القاعدة الكلاسيكية يعاد تسعير القاعدة بعد الكشف.',
                        style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            /* الأخطاء القاطعة */
            if (blockingErrors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.block_rounded,
                          color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text('خطأ قاطع — يمنع التأكيد',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red.shade800)),
                    ]),
                    const SizedBox(height: 6),
                    ...blockingErrors.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• ${e['message_ar'] ?? ''}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.red.shade700)),
                        )),
                  ],
                ),
              ),
            ],

            /* التحذيرات */
            if (planWarnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text('تحذير — لا يمنع الشراء',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color(0xFFF59E0B))),
                    ]),
                    const SizedBox(height: 6),
                    ...planWarnings.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• ${w['message_ar'] ?? ''}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.grey.shade700)),
                        )),
                  ],
                ),
              ),
            ],

            /* زر التفاصيل */
            if (constraintsAr.isNotEmpty ||
                compatibility.isNotEmpty ||
                noteAr.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _expandedPlans[planKey] = !isExpanded),
                  icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: const Color(0xFF1E3A8A)),
                  label: Text(
                    isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A)),
                  ),
                ),
              ),
            ],

            /* التفاصيل */
            if (isExpanded) ...[
              if (constraintsAr.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...constraintsAr.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.rule_rounded,
                                size: 14, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(c,
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey.shade700))),
                          ]),
                    )),
              ],
              if (compatibility.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...compatibility.map((c) {
                  final ok = c['ok'] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(
                          ok
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 14,
                          color: ok ? const Color(0xFF10B981) : Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('${c['message_ar'] ?? ''}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.grey.shade700))),
                    ]),
                  );
                }),
              ],
              if (unverifiedItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('عناصر تحتاج تأكيد',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: const Color(0xFFF59E0B))),
                        ...unverifiedItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('• $item',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.grey.shade700)),
                            )),
                      ]),
                ),
              ],
              if (noteAr.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(noteAr.toString(),
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic)),
              ],
            ],

            /* أزرار الإجراءات */
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addPlanToManualBuilder(products),
                    icon: const Icon(Icons.design_services_rounded, size: 16),
                    label: Text('أضف للتصميم',
                        style: GoogleFonts.cairo(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSavingDraft
                        ? null
                        : () => _saveDraft(planKey: plan['key']?.toString()),
                    icon: _isSavingDraft
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark_add_rounded, size: 16),
                    label: Text('حفظ',
                        style: GoogleFonts.cairo(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _discussPlanWithAI(plan),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: Text('ناقش',
                        style: GoogleFonts.cairo(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        plan['note_ar'] ?? 'لا توجد منتجات متوافقة لهذه الخطة',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.red.shade700))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  double _readNum(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _readInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  Widget _buildAddonRow(Map<String, dynamic> addon) {
    final title = addon['title_ar']?.toString() ?? '';
    final quantity = addon['quantity'] ?? 0;
    final unitLabel = addon['unit_label_ar']?.toString() ?? '';
    final unitPrice = addon['unit_price']?['amount'] ?? 0;
    final total = addon['total']?['amount'] ?? 0;
    final key = addon['key']?.toString() ?? '';

    IconData icon;
    Color color;
    switch (key) {
      case 'solar_cable':
        icon = Icons.cable_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'protection_panel':
        icon = Icons.electrical_services_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case 'classic_mounting_base':
        icon = Icons.construction_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'installation':
        icon = Icons.handyman_rounded;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.add_rounded;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtNum(quantity)} $unitLabel × ${_fmt(double.tryParse(unitPrice.toString()) ?? 0)}',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmt(double.tryParse(total.toString()) ?? 0),
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final imageUrl = p['image']?.toString() ?? '';
    final productName = p['title_ar']?.toString() ?? '';
    final productSlug = p['slug']?.toString() ?? '';
    final productPrice = p['price']?.toString() ?? '0';
    final productFinalPrice = p['final_price']?.toString() ?? '0';
    final productBrand = p['brand']?.toString() ?? '';
    final productModel = p['model']?.toString() ?? '';
    final quantity = p['quantity'] ?? 1;
    final discountPercentage = p['discount_percentage'] ?? 0;
    final parallelGroup = p['parallel_group']?.toString();

    return GestureDetector(
      onTap: () {
        if (productSlug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                  productSlug: productSlug, apiService: _apiService),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: parallelGroup != null
                ? const Color(0xFF7C3AED).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                            width: 55, height: 55, color: Colors.grey.shade300),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    )
                  : Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(productName,
                            style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_left_rounded,
                        size: 16, color: Colors.grey),
                  ]),
                  if (productBrand.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                        '$productBrand ${productModel.isNotEmpty ? "- $productModel" : ""}',
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (parallelGroup != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        parallelGroup == 'inverter_parallel'
                            ? '🔗 ربط متوازي'
                            : '🔗 تجميع متوازي',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (discountPercentage > 0) ...[
                      Text(_fmt(double.tryParse(productPrice) ?? 0),
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                        '${_fmt(double.tryParse(productFinalPrice) ?? 0)} × $quantity',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft({String? planKey}) async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      _showSnackBar('لا توجد جلسة لحفظ المسودة');
      return;
    }

    setState(() => _isSavingDraft = true);

    try {
      final token = _storageService.getToken();
      final isGuest = token == null || token.isEmpty;

      final res = await _apiService.solarSaveDraft(
        sessionId: _sessionId!,
        planKey: planKey,
        isSyp: _isSypPreferred,
        requiresAuth: !isGuest,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final num = res['data']?['project_number'] ?? '';
        _showSnackBar('تم الحفظ كمسودة: $num ✅', isSuccess: true);
      } else {
        _showSnackBar(res['message']?.toString() ?? 'فشل الحفظ');
      }
    } catch (e) {
      if (mounted) _showSnackBar('خطأ في الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  void _openDrafts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolarProjectsScreen(
          apiService: _apiService,
          storageService: _storageService,
        ),
      ),
    );
  }

  void _addPlanToManualBuilder(List<dynamic> products) {
    final panels = <Map<String, dynamic>>[];
    final inverters = <Map<String, dynamic>>[];
    final batteries = <Map<String, dynamic>>[];

    for (var p in products) {
      final product = Map<String, dynamic>.from(p);
      final type = product['product_type']?.toString() ?? '';
      final price =
          double.tryParse(product['final_price']?.toString() ?? '0') ?? 0;
      final quantity = product['quantity'] ?? 1;
      final item = {
        'id': product['product_id'],
        'name': product['title_ar'] ?? '',
        'price': price,
        'quantity': quantity,
        if (product['parallel_group'] != null)
          'parallel_group': product['parallel_group'],
      };
      switch (type) {
        case 'inverter':
          inverters.add(item);
          break;
        case 'battery':
          batteries.add(item);
          break;
        case 'solar_panel':
          panels.add(item);
          break;
      }
    }

    SystemBuilderDraftService.instance.saveDraft(
      panels: panels,
      inverters: inverters,
      batteries: batteries,
      cables: [],
      panelBoards: [],
    );

    _showSnackBar('تم حفظ مكونات الخطة في مسودة التصميم اليدوي 📋',
        isSuccess: true);
  }

  void _discussPlanWithAI(Map<String, dynamic> plan) {
    final products = plan['products'] as List? ?? [];
    final standardAddons = plan['standard_addons'] as List? ?? [];
    final equipmentTotal = plan['equipment_total']?['amount'] ?? 0;
    final estimatedTotal = plan['estimated_total']?['amount'] ?? equipmentTotal;
    final title = plan['title_ar'] ?? 'خطة';

    final inverterW = _readNum(plan['inverter_rated_w']);
    final pvArrayW = _readNum(plan['pv_array_w']);
    final inverterCount = _readInt(plan['inverter_count'], fallback: 1);
    final batteryCount = _readInt(plan['battery_count'], fallback: 0);
    final panelsPerInv = _readInt(plan['panels_per_inverter']);
    final totalInverterW =
        _readNum(plan['total_inverter_w'], fallback: inverterW);
    final totalBatteryWh = _readNum(plan['total_battery_wh'],
        fallback: _readNum(plan['battery_nominal_wh']));

    final message = StringBuffer();
    message.writeln('🛒 **عرض خطة منظومة شمسية**');
    message.writeln('📋 **الخطة:** $title');
    message.writeln('');
    message.writeln('⚡ **المواصفات:**');
    if (inverterCount > 1) {
      message.writeln(
          '• العواكس: $inverterCount × عاكس ${_fmtNum(inverterW)} واط (إجمالي ${_fmtNum(totalInverterW)} واط، ربط متوازي)');
    } else {
      message.writeln('• العاكس: ${_fmtNum(inverterW)} واط');
    }
    if (inverterCount > 1 && panelsPerInv > 0) {
      message.writeln(
          '• الألواح: ${_fmtNum(pvArrayW)} واط (موزعة $panelsPerInv لوح/عاكس)');
    } else {
      message.writeln('• الألواح: ${_fmtNum(pvArrayW)} واط');
    }
    if (totalBatteryWh > 0) {
      if (batteryCount > 1) {
        final unitKwh =
            (totalBatteryWh / batteryCount / 1000).toStringAsFixed(1);
        final totalKwh = (totalBatteryWh / 1000).toStringAsFixed(1);
        message.writeln(
            '• البطاريات: $batteryCount × بطارية $unitKwh كيلوواط ساعة (إجمالي $totalKwh كيلوواط ساعة، تجميع متوازي)');
      } else {
        message.writeln(
            '• البطاريات: ${(totalBatteryWh / 1000).toStringAsFixed(1)} كيلوواط ساعة');
      }
    }
    message.writeln('');
    message.writeln('📦 **المنتجات:**');
    for (var p in products) {
      final price = double.tryParse(p['final_price']?.toString() ?? '0') ?? 0;
      message.writeln('• ${p['title_ar']} × ${p['quantity']} — ${_fmt(price)}');
    }
    message.writeln('');
    message.writeln(
        '💰 **مجموع المنتجات:** ${_fmt(double.tryParse(equipmentTotal.toString()) ?? 0)}');

    if (standardAddons.isNotEmpty) {
      message.writeln('');
      message.writeln('🔧 **الإضافات القياسية (تقديرية):**');
      for (var a in standardAddons) {
        final totalAmt =
            double.tryParse(a['total']?['amount']?.toString() ?? '0') ?? 0;
        message.writeln(
            '• ${a['title_ar']} - ${a['quantity']} ${a['unit_label_ar']} — ${_fmt(totalAmt)}');
      }
      message.writeln('');
      message.writeln(
          '💰 **المجموع التقديري الكلي:** ${_fmt(double.tryParse(estimatedTotal.toString()) ?? 0)}');
    }

    message.writeln('');
    message.writeln('🔌 **الأجهزة:**');
    for (var d in _selectedDevices) {
      message.writeln(
          '• ${d.group.name} (${d.effectivePower.toStringAsFixed(0)}W) × ${d.quantity} | نهار: ${d.dayHours} | مساء: ${d.nightHours}');
    }
    message.writeln('');
    message.writeln('أريد مناقشة هذه الخطة.');

    final token = _storageService.getToken();
    final isGuest = token == null || token.isEmpty;

    if (isGuest) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GuestChatScreen(
                    apiService: _apiService,
                    storageService: _storageService,
                    initialMessage: message.toString(),
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatScreen(
                    authService: AuthService(storageService: _storageService),
                    apiService: _apiService,
                    initialMessage: message.toString(),
                  )));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A))),
    ]);
  }

  Widget _buildPlanSpec(String label, String value) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A))),
    ]);
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ]),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'complete':
        return const Color(0xFF10B981);
      case 'needs_review':
        return const Color(0xFFF59E0B);
      case 'no_product_match':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'complete':
        return Icons.check_circle_rounded;
      case 'needs_review':
        return Icons.info_rounded;
      case 'no_product_match':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'complete':
        return '✅ مكتمل - كل شيء متوافق';
      case 'needs_review':
        return '⚠️ يحتاج مراجعة - بعض المعلومات غير مؤكدة';
      case 'no_product_match':
        return '❌ لا توجد منتجات متوافقة';
      default:
        return status;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFF1E3A8A), size: 28),
          const SizedBox(width: 10),
          Text('كيفية الاستخدام',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpItem('1. نوع المنظومة', 'اختر المنظومة المناسبة'),
              _HelpItem('2. الموقع والكهرباء', 'حدد المدينة ونوع الكهرباء'),
              _HelpItem('3. الأجهزة', 'اختر الأجهزة من البطاقات'),
              _HelpItem('4. الساعات', 'حدد ساعات التشغيل لكل صف'),
              _HelpItem('5. التزامن', 'حدد الأحمال الثقيلة المتزامنة'),
              _HelpItem('6. النتائج', 'اعرض الخطط واختر الأنسب'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('فهمت', style: GoogleFonts.cairo())),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'local_laundry_service':
        return Icons.local_laundry_service_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'lightbulb':
      case 'light':
        return Icons.lightbulb_rounded;
      case 'router':
        return Icons.router_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'desktop_windows':
        return Icons.desktop_windows_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'microwave':
        return Icons.microwave_rounded;
      case 'iron':
        return Icons.iron_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'water':
        return Icons.water_rounded;
      case 'cctv':
        return Icons.videocam_rounded;
      case 'pos':
        return Icons.point_of_sale_rounded;
      case 'print':
        return Icons.print_rounded;
      case 'garage':
        return Icons.garage_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'server':
        return Icons.dns_rounded;
      case 'build':
        return Icons.build_rounded;
      case 'custom':
        return Icons.settings_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}

class _VariantSheet extends StatefulWidget {
  final DeviceGroup group;

  const _VariantSheet({required this.group});

  @override
  State<_VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<_VariantSheet> {
  DeviceVariant? _selectedVariant;
  int _quantity = 1;
  double? _customPower;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.group.variants.first;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(_iconFor(widget.group.iconName),
                    size: 28, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.group.name,
                      style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A))),
                ),
              ]),
              const SizedBox(height: 6),
              Text('اختر النوع/المقاس:',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.group.variants.length,
                  itemBuilder: (context, index) {
                    final v = widget.group.variants[index];
                    final isSelected = _selectedVariant?.id == v.id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedVariant = v;
                        _customPower = null;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              v.displayLabel,
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF1E3A8A)
                                      : Colors.grey.shade700),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text('الاستطاعة (اختياري):',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _customPower?.toStringAsFixed(0) ?? '',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText:
                          _selectedVariant?.power.toStringAsFixed(0) ?? '',
                      suffixText: 'W',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (t) {
                      final v = double.tryParse(t.trim());
                      setState(
                          () => _customPower = (v != null && v > 0) ? v : null);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Text('الكمية:',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A))),
                const Spacer(),
                _qtyBtn(Icons.remove_rounded, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text('$_quantity',
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A))),
                ),
                _qtyBtn(Icons.add_rounded, () => setState(() => _quantity++)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'variant': _selectedVariant!,
                      'quantity': _quantity,
                      'customPower': _customPower,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('إضافة',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
        ),
        child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'local_laundry_service':
        return Icons.local_laundry_service_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'lightbulb':
      case 'light':
        return Icons.lightbulb_rounded;
      case 'router':
        return Icons.router_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'desktop_windows':
        return Icons.desktop_windows_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'microwave':
        return Icons.microwave_rounded;
      case 'iron':
        return Icons.iron_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'water':
        return Icons.water_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}

class _CustomDeviceDialog extends StatefulWidget {
  final void Function(
      String name, double power, double dayHours, double nightHours) onAdd;

  const _CustomDeviceDialog({required this.onAdd});

  @override
  State<_CustomDeviceDialog> createState() => _CustomDeviceDialogState();
}

class _CustomDeviceDialogState extends State<_CustomDeviceDialog> {
  final _nameController = TextEditingController();
  final _powerController = TextEditingController();
  double _dayHours = 2;
  double _nightHours = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _powerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        const Icon(Icons.add_circle_outline_rounded,
            color: Color(0xFF10B981), size: 28),
        const SizedBox(width: 10),
        Text('إضافة جهاز جديد',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم الجهاز',
              labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
              prefixIcon:
                  const Icon(Icons.devices_rounded, color: Color(0xFF1E3A8A)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _powerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'الاستطاعة (واط)',
              labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
              prefixIcon:
                  const Icon(Icons.power_rounded, color: Color(0xFF1E3A8A)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Column(children: [
                Text('ساعات النهار',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: const Color(0xFFF59E0B))),
                const SizedBox(height: 4),
                _hoursControl(_dayHours, (v) => setState(() => _dayHours = v),
                    const Color(0xFFF59E0B)),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(children: [
                Text('ساعات المساء',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: const Color(0xFF6366F1))),
                const SizedBox(height: 4),
                _hoursControl(
                    _nightHours,
                    (v) => setState(() => _nightHours = v),
                    const Color(0xFF6366F1)),
              ]),
            ),
          ]),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال اسم الجهاز')));
              return;
            }
            final power = double.tryParse(_powerController.text.trim());
            if (power == null || power <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال استطاعة صحيحة')));
              return;
            }
            if (_dayHours + _nightHours > 24) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('مجموع الساعات لا يمكن أن يتجاوز 24')));
              return;
            }
            widget.onAdd(name, power, _dayHours, _nightHours);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('إضافة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _hoursControl(
      double value, ValueChanged<double> onChange, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: Icon(Icons.remove_rounded, size: 18, color: color),
          onPressed: () => onChange(value > 0.5 ? value - 0.5 : 0.0),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(_fmtLocal(value),
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        IconButton(
          icon: Icon(Icons.add_rounded, size: 18, color: color),
          onPressed: () => onChange(value + 0.5),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  String _fmtLocal(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String description;

  const _HelpItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF3B82F6), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E3A8A))),
                Text(description,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
