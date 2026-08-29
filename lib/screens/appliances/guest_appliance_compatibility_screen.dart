// lib/screens/appliances/guest_appliance_compatibility_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';

class GuestApplianceCompatibilityScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final String? initialGovernorate;

  const GuestApplianceCompatibilityScreen({
    super.key,
    required this.apiService,
    required this.storageService,
    this.initialGovernorate,
  });

  @override
  State<GuestApplianceCompatibilityScreen> createState() => _GuestApplianceCompatibilityScreenState();
}

class _GuestApplianceCompatibilityScreenState extends State<GuestApplianceCompatibilityScreen> {
  int _currentStep = 0;

  String? _systemVoltage;
  String? _inverterPower;
  String? _batteryType;
  String? _governorate;

  final List<DeviceItem> _devices = [];
  List<dynamic> _suggestedDevices = [];
  bool _isLoadingDevices = true;

  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _devicePowerController = TextEditingController();
  final TextEditingController _deviceDayHoursController = TextEditingController();
  final TextEditingController _deviceNightHoursController = TextEditingController();

  bool _isChecking = false;
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

  @override
  void initState() {
    super.initState();
    _governorate = widget.initialGovernorate ?? widget.storageService.getGuestGovernorate() ?? 'دمشق';
    _fetchDeviceTemplates();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _devicePowerController.dispose();
    _deviceDayHoursController.dispose();
    _deviceNightHoursController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceTemplates() async {
    setState(() => _isLoadingDevices = true);
    try {
      final response = await widget.apiService.get('/v1/user/public/device-templates', requiresAuth: false);
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
      case 'ac_unit': return Icons.ac_unit_rounded;
      case 'kitchen': return Icons.kitchen_rounded;
      case 'local_laundry_service': return Icons.local_laundry_service_rounded;
      case 'microwave': return Icons.microwave_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'laptop': return Icons.laptop_rounded;
      case 'desktop_windows': return Icons.desktop_windows_rounded;
      case 'router': return Icons.router_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'water_drop': return Icons.water_drop_rounded;
      case 'air': return Icons.air_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'light': return Icons.light_rounded;
      default: return Icons.devices_rounded;
    }
  }

  void _addSuggestedDevice(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    setState(() {
      _deviceNameController.text = device['name_ar'] ?? '';
      _devicePowerController.text = (device['power_watts'] ?? 0).toString();
      _deviceDayHoursController.text = (device['default_day_hours'] ?? 1).toString();
      _deviceNightHoursController.text = (device['default_night_hours'] ?? 0).toString();
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
      _devices.add(DeviceItem(name: name, power: power, dayHours: dayHours, nightHours: nightHours));
      _deviceNameController.clear();
      _devicePowerController.clear();
      _deviceDayHoursController.clear();
      _deviceNightHoursController.clear();
    });
  }

  void _removeDevice(int index) {
    HapticFeedback.lightImpact();
    setState(() => _devices.removeAt(index));
  }

  Future<void> _checkCompatibility() async {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أضف جهاز واحد على الأقل', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isChecking = true);
    try {
      final appliancesText = _devices.map((d) {
        final parts = ['${d.name} ${d.power}W'];
        if (d.dayHours > 0) parts.add('نهار ${d.dayHours}h');
        if (d.nightHours > 0) parts.add('ليل ${d.nightHours}h');
        return parts.join(' - ');
      }).join('\n');

      final response = await widget.apiService.post(
        '/v1/user/public/appliance-compatibility/check',
        requiresAuth: false,
        data: {
          'session_id': widget.storageService.getGuestSessionId() ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
          'governorate': _governorate,
          'system_voltage': _systemVoltage,
          'inverter_power': _inverterPower,
          'battery_type': _batteryType,
          'appliances': appliancesText,
        },
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _result = Map<String, dynamic>.from(response['data'] ?? {});
          _isChecking = false;
        });
      } else {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'حدث خطأ', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isChecking = false);
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
          'فحص التوافق',
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
        child: _isChecking
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
            'جاري فحص التوافق...',
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
            children: List.generate(4, (index) {
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
                            ? LinearGradient(colors: [successGreen, successGreen.withOpacity(0.7)])
                            : isCurrent
                            ? LinearGradient(colors: [primaryBlue, secondaryBlue])
                            : null,
                        color: !isCompleted && !isCurrent ? Colors.grey.shade300 : null,
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
                    const SizedBox(height: 4),
                    Text(
                      index == 0 ? 'الفولتية' :
                      index == 1 ? 'الإنفرتر' :
                      index == 2 ? 'البطاريات' : 'الأجهزة',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? primaryBlue : mediumGray,
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
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _checkCompatibility();
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
                        _currentStep < 3 ? 'التالي' : 'فحص التوافق',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: _isStepValid() ? Colors.white : Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      if (_isStepValid()) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep < 3 ? Icons.arrow_back : Icons.check_circle_rounded,
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
        return _inverterPower != null && _inverterPower!.isNotEmpty;
      case 2:
        return _batteryType != null && _batteryType!.isNotEmpty;
      case 3:
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
          subtitle: 'ما هو جهد نظامك الشمسي؟',
          icon: Icons.electrical_services_rounded,
          options: _voltages,
          selected: _systemVoltage,
          onSelect: (value) => setState(() => _systemVoltage = value),
        );
      case 1:
        return _buildSelectionStep(
          key: const ValueKey('inverter'),
          title: 'قدرة الإنفرتر',
          subtitle: 'ما هي قدرة الإنفرتر لديك؟',
          icon: Icons.power_rounded,
          options: _inverterPowers,
          selected: _inverterPower,
          onSelect: (value) => setState(() => _inverterPower = value),
        );
      case 2:
        return _buildSelectionStep(
          key: const ValueKey('battery'),
          title: 'نوع البطاريات',
          subtitle: 'ما هو نوع البطاريات لديك؟',
          icon: Icons.battery_charging_full_rounded,
          options: _batteryTypes,
          selected: _batteryType,
          onSelect: (value) => setState(() => _batteryType = value),
        );
      case 3:
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
          // أيقونة دائرية متدرجة
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

          // خيارات الاختيار
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

  Widget _buildDevicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
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
                        'الأجهزة المراد فحصها',
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

          // الأجهزة الجاهزة
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

          // منطقة الإضافة اليدوية
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

          // حقول الإضافة اليدوية
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

          // زر إضافة الجهاز
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

          // الأجهزة المضافة
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

          // رسالة تحفيزية
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
                    'نصيحة: تأكد من أن مجموع قدرة الأجهزة لا يتجاوز قدرة النظام',
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

  // ✅ شاشة النتائج
  Widget _buildResult() {
    final compatible = (_result?['compatible'] as List?) ?? [];
    final warning = (_result?['warning'] as List?) ?? [];
    final incompatible = (_result?['incompatible'] as List?) ?? [];
    final summary = _result?['summary']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ملخص النتائج
          if (summary.isNotEmpty) ...[
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // الأجهزة المتوافقة
          if (compatible.isNotEmpty) ...[
            _buildSectionHeader('الأجهزة المتوافقة', Icons.check_circle_rounded, Colors.green, compatible.length),
            const SizedBox(height: 8),
            ...compatible.map((item) => _buildResultCard(item, Colors.green)),
            const SizedBox(height: 16),
          ],

          // تحتاج انتباه
          if (warning.isNotEmpty) ...[
            _buildSectionHeader('تحتاج انتباه', Icons.warning_rounded, Colors.orange, warning.length),
            const SizedBox(height: 8),
            ...warning.map((item) => _buildResultCard(item, Colors.orange)),
            const SizedBox(height: 16),
          ],

          // غير متوافقة
          if (incompatible.isNotEmpty) ...[
            _buildSectionHeader('غير متوافقة', Icons.cancel_rounded, Colors.red, incompatible.length),
            const SizedBox(height: 8),
            ...incompatible.map((item) => _buildResultCard(item, Colors.red)),
          ],

          const SizedBox(height: 24),

          // زر فحص جديد
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _result = null;
                  _currentStep = 0;
                  _devices.clear();
                  _systemVoltage = null;
                  _inverterPower = null;
                  _batteryType = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              label: Text(
                'فحص جديد',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, MaterialColor color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic item, MaterialColor color) {
    final name = item['name']?.toString() ?? '';
    final watts = item['watts']?.toString() ?? '';
    final note = item['note']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.power_rounded, color: color.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ),
              if (watts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$watts W',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color.shade600,
                    ),
                  ),
                ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
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