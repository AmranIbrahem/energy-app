// lib/screens/appliances/guest_appliance_schedule_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';

class GuestApplianceScheduleScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final String? initialGovernorate;

  const GuestApplianceScheduleScreen({
    super.key,
    required this.apiService,
    required this.storageService,
    this.initialGovernorate,
  });

  @override
  State<GuestApplianceScheduleScreen> createState() =>
      _GuestApplianceScheduleScreenState();
}

class _GuestApplianceScheduleScreenState
    extends State<GuestApplianceScheduleScreen> {
  int _currentStep = 0;
  String? _systemVoltage;
  String? _inverterPower;
  String? _batteryType;
  String? _governorate;

  // قيم الألواح الشمسية
  String? _panelCount;
  String? _panelWatts;
  // قيم البطاريات
  String? _batteryCount;
  String? _batteryAh;

  final List<DeviceItem> _devices = [];
  List<dynamic> _suggestedDevices = [];
  bool _isLoadingDevices = true;

  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _devicePowerController = TextEditingController();
  final TextEditingController _deviceDayHoursController =
  TextEditingController();
  final TextEditingController _deviceNightHoursController =
  TextEditingController();

  // متغيرات للقيم اليدوية
  final TextEditingController _panelCountController = TextEditingController();
  final TextEditingController _panelWattsController = TextEditingController();
  final TextEditingController _batteryCountController = TextEditingController();
  final TextEditingController _batteryAhController = TextEditingController();

  bool _isGenerating = false;
  Map<String, dynamic>? _result;

  // ألوان محدثة
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color warmAccent = Color(0xFFF59E0B);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color dayColor = Color(0xFFF59E0B);
  static const Color nightColor = Color(0xFF6366F1);
  static const Color successGreen = Color(0xFF10B981);

  // خيارات الاختيارات
  final List<String> _voltages = ['12', '24', '48'];
  final List<String> _inverterPowers = [
    'أقل من 1000W',
    '1000W - 3000W',
    'أكثر من 3000W'
  ];
  final List<String> _batteryTypes = ['أسيد', 'جل', 'ليثيوم'];

  // خيارات القوائم المنسدلة
  final List<String> _panelCountOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'أخرى'];
  final List<String> _panelWattsOptions = ['450W', '550W', '590W', '620W', '710W', 'أخرى'];
  final List<String> _batteryCountOptions = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'أخرى'];
  final List<String> _batteryAhOptions = ['100Ah', '150Ah', '200Ah', '250Ah', '300Ah', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _governorate =
        widget.initialGovernorate ?? widget.storageService.getGuestGovernorate() ?? 'دمشق';
    _fetchDeviceTemplates();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _devicePowerController.dispose();
    _deviceDayHoursController.dispose();
    _deviceNightHoursController.dispose();
    _panelCountController.dispose();
    _panelWattsController.dispose();
    _batteryCountController.dispose();
    _batteryAhController.dispose();
    super.dispose();
  }

  // ✅ جلب الأجهزة المقترحة
  Future<void> _fetchDeviceTemplates() async {
    setState(() => _isLoadingDevices = true);
    try {
      final response = await widget.apiService.get(
        '/v1/user/public/device-templates',
        requiresAuth: false,
      );

      if (mounted) {
        final data = response['data'];
        List<dynamic> devices = [];

        if (data is Map) {
          if (data.containsKey('devices')) {
            devices = List<dynamic>.from(data['devices'] ?? []);
          } else if (data.containsKey('data') && data['data'] is Map) {
            devices = List<dynamic>.from(data['data']['devices'] ?? []);
          } else if (data.containsKey('data') && data['data'] is List) {
            devices = List<dynamic>.from(data['data']);
          }
        } else if (data is List) {
          devices = data;
        }

        setState(() {
          _suggestedDevices = devices;
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDevices = false);
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'local_laundry_service':
        return Icons.local_laundry_service_rounded;
      case 'microwave':
        return Icons.microwave_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'desktop_windows':
        return Icons.desktop_windows_rounded;
      case 'router':
        return Icons.router_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'light':
        return Icons.light_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  void _addSuggestedDevice(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    setState(() {
      _deviceNameController.text = device['name_ar'] ?? '';
      _devicePowerController.text = (device['power_watts'] ?? 0).toString();
      _deviceDayHoursController.text =
          (device['default_day_hours'] ?? 1).toString();
      _deviceNightHoursController.text =
          (device['default_night_hours'] ?? 0).toString();
    });
  }

  void _addDevice() {
    final name = _deviceNameController.text.trim();
    final powerText = _devicePowerController.text.trim();
    final dayHoursText = _deviceDayHoursController.text.trim();
    final nightHoursText = _deviceNightHoursController.text.trim();

    if (name.isEmpty || powerText.isEmpty) return;

    final power = double.tryParse(powerText);
    if (power == null || power <= 0) return;

    final dayHours = double.tryParse(dayHoursText) ?? 0;
    final nightHours = double.tryParse(nightHoursText) ?? 0;

    setState(() {
      _devices.add(DeviceItem(
        name: name,
        power: power,
        dayHours: dayHours,
        nightHours: nightHours,
      ));
      _deviceNameController.clear();
      _devicePowerController.clear();
      _deviceDayHoursController.clear();
      _deviceNightHoursController.clear();
    });
  }

  void _removeDevice(int index) {
    setState(() => _devices.removeAt(index));
  }

  Future<void> _generateSchedule() async {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أضف جهاز واحد على الأقل', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final appliancesText = _devices.map((d) {
        final parts = ['${d.name} ${d.power}W'];
        if (d.dayHours > 0) parts.add('نهار ${d.dayHours}h');
        if (d.nightHours > 0) parts.add('ليل ${d.nightHours}h');
        return parts.join(' - ');
      }).join('\n');

      // ✅ استخراج القيم اليدوية إن وجدت
      int? panelCount;
      if (_panelCount == 'أخرى') {
        panelCount = int.tryParse(_panelCountController.text.trim());
      } else if (_panelCount != null && _panelCount!.isNotEmpty) {
        panelCount = int.tryParse(_panelCount!);
      }

      int? panelWatts;
      if (_panelWatts == 'أخرى') {
        panelWatts = int.tryParse(_panelWattsController.text.trim());
      } else if (_panelWatts != null && _panelWatts!.isNotEmpty) {
        panelWatts = int.tryParse(_panelWatts!.replaceAll('W', ''));
      }

      int? batteryCount;
      if (_batteryCount == 'أخرى') {
        batteryCount = int.tryParse(_batteryCountController.text.trim());
      } else if (_batteryCount != null && _batteryCount!.isNotEmpty) {
        batteryCount = int.tryParse(_batteryCount!);
      }

      int? batteryAh;
      if (_batteryAh == 'أخرى') {
        batteryAh = int.tryParse(_batteryAhController.text.trim());
      } else if (_batteryAh != null && _batteryAh!.isNotEmpty) {
        batteryAh = int.tryParse(_batteryAh!.replaceAll('Ah', ''));
      }

      final response = await widget.apiService.generateApplianceSchedule(
        systemVoltage: _systemVoltage ?? '',
        inverterPower: _inverterPower ?? '',
        batteryType: _batteryType ?? '',
        appliances: appliancesText,
        requiresAuth: false,
        sessionId: widget.storageService.getGuestSessionId() ??
            'guest_${DateTime.now().millisecondsSinceEpoch}',
        governorate: _governorate,
        panelCount: panelCount,
        panelWatts: panelWatts,
        batteryCount: batteryCount,
        batteryAh: batteryAh,
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _result = Map<String, dynamic>.from(response['data'] ?? {});
          _isGenerating = false;
        });
      } else {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'حدث خطأ',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في الاتصال', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue, accentCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: Text(
          'مدير جدول التشغيل',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isGenerating
            ? _buildLoadingScreen()
            : _result != null
            ? _buildResult()
            : _buildWizard(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [primaryBlue, accentCyan],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'جاري إنشاء الجدول...',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار قليلاً',
            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildWizard() {
    return Column(
      children: [
        // مؤشر الخطوات المتقدم
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 35 : 20,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                            colors: [successGreen, successGreen.withOpacity(0.7)])
                            : isCurrent
                            ? LinearGradient(
                            colors: [primaryBlue, secondaryBlue])
                            : null,
                        color: !isCompleted && !isCurrent
                            ? Colors.grey.shade300
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isCurrent
                            ? [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : [],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        // المحتوى
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildStep(),
          ),
        ),

        // الأزرار السفلية
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: primaryBlue.withOpacity(0.5),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, size: 18, color: primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          'السابق',
                          style: GoogleFonts.cairo(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isStepValid()
                      ? () {
                    if (_currentStep < 5) {
                      setState(() => _currentStep++);
                    } else {
                      _generateSchedule();
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStepValid() ? primaryBlue : Colors.grey.shade300,
                    foregroundColor: _isStepValid() ? Colors.white : Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: _isStepValid() ? 2 : 0,
                    shadowColor: _isStepValid() ? primaryBlue.withOpacity(0.3) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < 5 ? 'التالي' : 'إنشاء الجدول',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: _isStepValid() ? Colors.white : Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      if (_isStepValid()) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep < 5 ? Icons.arrow_back : Icons.auto_awesome,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _systemVoltage != null && _systemVoltage!.isNotEmpty;
      case 1:
      // ✅ التحقق من الألواح
        if (_panelCount == null || _panelWatts == null) return false;
        if (_panelCount == 'أخرى' && _panelCountController.text.trim().isEmpty) return false;
        if (_panelWatts == 'أخرى' && _panelWattsController.text.trim().isEmpty) return false;
        return true;
      case 2:
      // ✅ التحقق من البطاريات
        if (_batteryCount == null || _batteryAh == null || _batteryType == null) return false;
        if (_batteryCount == 'أخرى' && _batteryCountController.text.trim().isEmpty) return false;
        if (_batteryAh == 'أخرى' && _batteryAhController.text.trim().isEmpty) return false;
        return true;
      case 3:
        return _inverterPower != null && _inverterPower!.isNotEmpty;
      case 4:
        return _devices.isNotEmpty;
      default:
        return false;
    }
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildSelectionStep(
          key: const ValueKey('voltage'),
          title: 'فولتية النظام',
          subtitle: 'ما هو جهد نظامك؟',
          icon: Icons.electrical_services_rounded,
          options: _voltages,
          selected: _systemVoltage,
          onSelect: (v) => setState(() => _systemVoltage = v),
        );
      case 1:
        return _buildPanelsStep();
      case 2:
        return _buildBatteriesStep();
      case 3:
        return _buildSelectionStep(
          key: const ValueKey('inverter'),
          title: 'قدرة الإنفرتر',
          subtitle: 'ما هي قدرة الإنفرتر؟',
          icon: Icons.power_rounded,
          options: _inverterPowers,
          selected: _inverterPower,
          onSelect: (v) => setState(() => _inverterPower = v),
        );
      case 4:
        return _buildDevicesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> options,
    required String? selected,
    required Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 45, color: primaryBlue),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkColor,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          ),
          const SizedBox(height: 32),
          ...options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : darkColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ✅ خطوة الألواح الشمسية
  Widget _buildPanelsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.solar_power_rounded, size: 45, color: primaryBlue),
          ),
          const SizedBox(height: 24),
          Text(
            'الألواح الشمسية',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كم عدد الألواح وما قدرتها؟',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          ),
          const SizedBox(height: 32),
          Text(
            'عدد الألواح',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: _panelCount,
            options: _panelCountOptions,
            hint: 'اختر عدد الألواح أو اضغط "أخرى" للكتابة',
            icon: Icons.grid_on_rounded,
            onChanged: (value) => setState(() => _panelCount = value),
            manualController: _panelCountController,
            manualHint: 'أدخل عدد الألواح',
          ),
          const SizedBox(height: 24),
          Text(
            'قدرة اللوح (واط)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: _panelWatts,
            options: _panelWattsOptions,
            hint: 'اختر قدرة اللوح أو اضغط "أخرى" للكتابة',
            icon: Icons.power_rounded,
            onChanged: (value) => setState(() => _panelWatts = value),
            manualController: _panelWattsController,
            manualHint: 'أدخل قدرة اللوح بالواط',
          ),
        ],
      ),
    );
  }

  // ✅ خطوة البطاريات
  Widget _buildBatteriesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.battery_charging_full_rounded, size: 45, color: primaryBlue),
          ),
          const SizedBox(height: 24),
          Text(
            'البطاريات',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'عدد البطاريات ونوعها وسعتها',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          ),
          const SizedBox(height: 32),
          Text(
            'عدد البطاريات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: _batteryCount,
            options: _batteryCountOptions,
            hint: 'اختر عدد البطاريات أو اضغط "أخرى" للكتابة',
            icon: Icons.battery_full_rounded,
            onChanged: (value) => setState(() => _batteryCount = value),
            manualController: _batteryCountController,
            manualHint: 'أدخل عدد البطاريات',
          ),
          const SizedBox(height: 24),
          Text(
            'سعة البطارية (Ah)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdownField(
            value: _batteryAh,
            options: _batteryAhOptions,
            hint: 'اختر سعة البطارية أو اضغط "أخرى" للكتابة',
            icon: Icons.electric_bolt_rounded,
            onChanged: (value) => setState(() => _batteryAh = value),
            manualController: _batteryAhController,
            manualHint: 'أدخل سعة البطارية بالأمبير',
          ),
          const SizedBox(height: 24),
          Text(
            'نوع البطاريات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _batteryTypes.map((type) {
              final isSelected = _batteryType == type;
              return GestureDetector(
                onTap: () => setState(() => _batteryType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    type,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : darkColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ حقل قائمة منسدلة موحد
  Widget _buildDropdownField({
    required String? value,
    required List<String> options,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
    TextEditingController? manualController,
    String? manualHint,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(icon, size: 20, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    hint,
                    style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                  ),
                ],
              ),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        option,
                        style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: primaryBlue,
                size: 24,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
              style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (value == 'أخرى' && manualController != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: manualController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: manualHint ?? 'أدخل القيمة',
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, size: 20, color: primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ✅ خطوة الأجهزة
  Widget _buildDevicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.05), accentCyan.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.devices_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأجهزة المراد جدولتها',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اختر من القائمة أو أضف يدوياً',
                        style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                      ),
                    ],
                  ),
                ),
                if (_devices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_devices.length}',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'أجهزة شائعة:',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingDevices)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedDevices.length,
                itemBuilder: (context, index) {
                  final device = _suggestedDevices[index];
                  return GestureDetector(
                    onTap: () => _addSuggestedDevice(device),
                    child: Container(
                      width: 95,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            primaryBlue.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconFromString(device['icon'] ?? 'devices'),
                              size: 22,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            device['name_ar'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${device['power_watts']}W',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryBlue.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'أو أضف جهاز غير موجود بالقائمة:',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceNameController,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اسم الجهاز (مثال: مضخة ماء، مكواة...)',
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _devicePowerController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'القدرة (واط)',
              hintStyle: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deviceDayHoursController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ساعات النهار ☀️',
                    hintStyle: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: dayColor, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _deviceNightHoursController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ساعات الليل 🌙',
                    hintStyle: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: nightColor, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addDevice,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'إضافة الجهاز',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shadowColor: primaryBlue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_devices.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'الأجهزة المضافة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_devices.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_devices.length, (index) {
              final d = _devices[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue.withOpacity(0.08), accentCyan.withOpacity(0.03)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.devices_rounded,
                        size: 18,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkColor,
                            ),
                          ),
                          Text(
                            '${d.power}W',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (d.dayHours > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: dayColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '☀️ ${d.dayHours}h',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: dayColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (d.nightHours > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: nightColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🌙 ${d.nightHours}h',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: nightColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _removeDevice(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [successGreen.withOpacity(0.1), accentCyan.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: successGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: successGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نصيحة: اختر الوقت المناسب لتشغيل كل جهاز للحصول على أفضل كفاءة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: darkColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final morning = (_result?['morning'] as List?) ?? [];
    final afternoon = (_result?['afternoon'] as List?) ?? [];
    final evening = (_result?['evening'] as List?) ?? [];
    final night = (_result?['night'] as List?) ?? [];
    final warnings = (_result?['warnings'] as List?) ?? [];
    final tips = (_result?['tips'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم إنشاء الجدول بنجاح!',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'عدد الأجهزة: ${_devices.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTimeSection('🌅 الصباح', morning, Colors.orange),
          const SizedBox(height: 12),
          _buildTimeSection('☀️ الظهر', afternoon, Colors.amber),
          const SizedBox(height: 12),
          _buildTimeSection('🌇 المساء', evening, Colors.deepOrange),
          const SizedBox(height: 12),
          _buildTimeSection('🌙 الليل', night, Colors.indigo),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تحذيرات',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...warnings.map((w) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            w.toString(),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: darkColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: successGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lightbulb_rounded, color: successGreen, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'نصائح',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...tips.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: successGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.toString(),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: darkColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _result = null;
                  _currentStep = 0;
                  _devices.clear();
                  _systemVoltage = null;
                  _inverterPower = null;
                  _batteryType = null;
                  _panelCount = null;
                  _panelWatts = null;
                  _batteryCount = null;
                  _batteryAh = null;
                  _panelCountController.clear();
                  _panelWattsController.clear();
                  _batteryCountController.clear();
                  _batteryAhController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shadowColor: primaryBlue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'جدول جديد',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, List<dynamic> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} أجهزة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Row(
              children: [
                Icon(Icons.timer_off_rounded, size: 16, color: mediumGray),
                const SizedBox(width: 6),
                Text(
                  'لا توجد أجهزة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: mediumGray,
                  ),
                ),
              ],
            )
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class DeviceItem {
  final String name;
  final double power;
  final double dayHours;
  final double nightHours;

  DeviceItem({
    required this.name,
    required this.power,
    this.dayHours = 0,
    this.nightHours = 0,
  });
}