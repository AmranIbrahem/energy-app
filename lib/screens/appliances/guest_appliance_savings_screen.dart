// lib/screens/appliances/guest_appliance_savings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';

class GuestApplianceSavingsScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final String? initialGovernorate;

  const GuestApplianceSavingsScreen({
    super.key,
    required this.apiService,
    required this.storageService,
    this.initialGovernorate,
  });

  @override
  State<GuestApplianceSavingsScreen> createState() =>
      _GuestApplianceSavingsScreenState();
}

class _GuestApplianceSavingsScreenState
    extends State<GuestApplianceSavingsScreen> {
  int _currentStep = 0;

  final TextEditingController _applianceNameController = TextEditingController();
  final TextEditingController _normalWattsController = TextEditingController();
  final TextEditingController _inverterWattsController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _governorate;
  bool _isCalculating = false;
  bool _isLoadingAppliances = true;
  Map<String, dynamic>? _result;

  List<Map<String, dynamic>> _allAppliances = [];
  List<Map<String, dynamic>> _filteredAppliances = [];
  List<Map<String, dynamic>> _selectedAppliances = [];

  // ألوان الهوية البصرية
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warmOrange = Color(0xFFF59E0B);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _governorate = widget.initialGovernorate ??
        widget.storageService.getGuestGovernorate() ??
        'دمشق';
    _loadAppliances();
  }

  @override
  void dispose() {
    _applianceNameController.dispose();
    _normalWattsController.dispose();
    _inverterWattsController.dispose();
    _hoursController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ تحميل الأجهزة من الـ API
  Future<void> _loadAppliances() async {
    setState(() => _isLoadingAppliances = true);
    try {
      final response = await widget.apiService.getInverterAppliances();
      if (response['status'] == 'success' && mounted) {
        final data = response['data'] as Map<String, dynamic>;
        final appliancesList = data['appliances'] as List<dynamic>;
        setState(() {
          _allAppliances = appliancesList
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _filteredAppliances = List.from(_allAppliances);
          _isLoadingAppliances = false;
        });
      } else {
        setState(() => _isLoadingAppliances = false);
      }
    } catch (e) {
      setState(() => _isLoadingAppliances = false);
    }
  }

  // ✅ البحث الفوري
  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAppliances = List.from(_allAppliances);
      } else {
        _filteredAppliances = _allAppliances
            .where((appliance) =>
            (appliance['name_ar'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ✅ تحويل اسم الأيقونة النصي إلى IconData
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'kitchen': return Icons.kitchen_rounded;
      case 'tv': return Icons.tv_rounded;
      case 'ac_unit': return Icons.ac_unit_rounded;
      case 'local_laundry_service': return Icons.local_laundry_service_rounded;
      case 'water_drop': return Icons.water_drop_rounded;
      case 'water': return Icons.water_rounded;
      case 'microwave': return Icons.microwave_rounded;
      case 'blender': return Icons.blender_rounded;
      case 'light': return Icons.light_rounded;
      case 'lightbulb': return Icons.lightbulb_rounded;
      case 'router': return Icons.router_rounded;
      case 'speaker': return Icons.speaker_rounded;
      case 'desktop_windows': return Icons.desktop_windows_rounded;
      case 'laptop': return Icons.laptop_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'print': return Icons.print_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'iron': return Icons.iron_rounded;
      case 'heater': return Icons.heat_pump_rounded;
      case 'cleaning_services': return Icons.cleaning_services_rounded;
      case 'air': return Icons.air_rounded;
      case 'sports_esports': return Icons.sports_esports_rounded;
      case 'ev_station': return Icons.ev_station_rounded;
      case 'construction': return Icons.construction_rounded;
      case 'sewing': return Icons.chair_rounded;
      case 'hair_dryer': return Icons.air_rounded;
      case 'toast': return Icons.breakfast_dining_rounded;
      default: return Icons.power_rounded;
    }
  }

  // ✅ اختيار جهاز من القائمة - يفتح Bottom Sheet لتعديل الساعات
  void _selectAppliance(Map<String, dynamic> appliance) {
    HapticFeedback.lightImpact();

    final name = appliance['name_ar']?.toString() ?? '';
    final normalWatts = int.tryParse(appliance['normal_watts']?.toString() ?? '') ?? 0;
    final inverterWatts = int.tryParse(appliance['inverter_watts']?.toString() ?? '') ?? 0;
    final defaultHours = double.tryParse((appliance['default_hours_per_day'] ?? 1).toString()) ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddDeviceSheet(
        name: name,
        normalWatts: normalWatts,
        inverterWatts: inverterWatts,
        defaultHours: defaultHours,
      ),
    );
  }

  // ✅ Bottom Sheet لإضافة جهاز مع تعديل الساعات
  Widget _buildAddDeviceSheet({
    required String name,
    required int normalWatts,
    required int inverterWatts,
    required double defaultHours,
  }) {
    final hoursController = TextEditingController(text: defaultHours.toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.devices_rounded, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      Text(
                        '$normalWatts W → $inverterWatts W',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'ساعات التشغيل اليومية',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.cairo(fontSize: 16),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
                suffixIcon: Icon(Icons.schedule_rounded, color: primaryBlue, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final hours = double.tryParse(hoursController.text) ?? 1;
                      setState(() {
                        _selectedAppliances.add({
                          'name': name,
                          'normal_watts': normalWatts,
                          'inverter_watts': inverterWatts,
                          'hours_per_day': hours,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة $name', style: GoogleFonts.cairo()),
                          backgroundColor: successGreen,
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إضافة',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ✅ Bottom Sheet لإضافة جهاز مخصص
  void _showCustomDeviceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCustomDeviceSheet(),
    );
  }

  Widget _buildCustomDeviceSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_circle_rounded, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة جهاز مخصص',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _applianceNameController,
              style: GoogleFonts.cairo(fontSize: 14),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'اسم الجهاز',
                labelStyle: GoogleFonts.cairo(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _normalWattsController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontSize: 14),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'عادي (W)',
                      labelStyle: GoogleFonts.cairo(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inverterWattsController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontSize: 14),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'إنفرتر (W)',
                      labelStyle: GoogleFonts.cairo(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.cairo(fontSize: 14),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'ساعات يومياً',
                labelStyle: GoogleFonts.cairo(fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      _addManualDevice();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إضافة',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ إضافة جهاز يدوي
  void _addManualDevice() {
    final name = _applianceNameController.text.trim();
    final normalWatts = int.tryParse(_normalWattsController.text) ?? 0;
    final inverterWatts = int.tryParse(_inverterWattsController.text) ?? 0;
    final hours = double.tryParse(_hoursController.text) ?? 0;

    if (name.isEmpty || normalWatts <= 0 || inverterWatts <= 0 || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تعبئة جميع البيانات', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedAppliances.add({
        'name': name,
        'normal_watts': normalWatts,
        'inverter_watts': inverterWatts,
        'hours_per_day': hours,
      });
      _applianceNameController.clear();
      _normalWattsController.clear();
      _inverterWattsController.clear();
      _hoursController.clear();
    });
  }

  // ✅ حذف جهاز من القائمة
  void _removeSelectedAppliance(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAppliances.removeAt(index);
    });
  }

  // ✅ تعديل جهاز محدد
  void _editSelectedAppliance(int index) {
    final device = _selectedAppliances[index];
    final hoursController = TextEditingController(
      text: device['hours_per_day']?.toString() ?? '',
    );
    final normalWattsController = TextEditingController(
      text: device['normal_watts']?.toString() ?? '',
    );
    final inverterWattsController = TextEditingController(
      text: device['inverter_watts']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل الجهاز',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: normalWattsController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(fontSize: 14),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'عادي (W)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: inverterWattsController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(fontSize: 14),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'إنفرتر (W)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.cairo(fontSize: 14),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'ساعات يومياً',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedAppliances[index] = {
                      'name': device['name'],
                      'normal_watts': int.tryParse(normalWattsController.text) ?? 0,
                      'inverter_watts': int.tryParse(inverterWattsController.text) ?? 0,
                      'hours_per_day': double.tryParse(hoursController.text) ?? 0,
                    };
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'حفظ',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ حساب التوفير
  Future<void> _calculateSavings() async {
    if (_selectedAppliances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أضف جهاز واحد على الأقل', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);

    try {
      final response = await widget.apiService.calculateApplianceSavings(
        appliances: _selectedAppliances,
        requiresAuth: false,
        sessionId: widget.storageService.getGuestSessionId() ??
            'guest_${DateTime.now().millisecondsSinceEpoch}',
        governorate: _governorate,
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _result = Map<String, dynamic>.from(response['data'] ?? {});
          _isCalculating = false;
        });

        // الانتقال لشاشة النتائج
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _SavingsResultScreen(
              result: _result!,
              onReset: () {
                setState(() {
                  _result = null;
                  _selectedAppliances.clear();
                  _searchController.clear();
                  _filteredAppliances = List.from(_allAppliances);
                });
              },
            ),
          ),
        );
      } else {
        setState(() => _isCalculating = false);
      }
    } catch (e) {
      setState(() => _isCalculating = false);
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
          'حاسبة التوفير',
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
        child: _isCalculating
            ? _buildLoadingScreen()
            : _buildStepperForm(),
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
            'جاري الحساب...',
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

  Widget _buildStepperForm() {
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
            children: List.generate(3, (index) {
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
                            colors: [successGreen, successGreen.withOpacity(0.7)]
                        )
                            : isCurrent
                            ? LinearGradient(
                            colors: [primaryBlue, secondaryBlue]
                        )
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
                    const SizedBox(height: 4),
                    Text(
                      index == 0 ? 'الأجهزة' : index == 1 ? 'مراجعة' : 'حساب',
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
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _calculateSavings();
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
                        _currentStep < 2 ? 'التالي' : 'احسب التوفير',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: _isStepValid() ? Colors.white : Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      if (_isStepValid()) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _currentStep < 2 ? Icons.arrow_back : Icons.calculate_rounded,
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
        return _filteredAppliances.isNotEmpty || _allAppliances.isNotEmpty;
      case 1:
        return _selectedAppliances.isNotEmpty;
      case 2:
        return _selectedAppliances.isNotEmpty;
      default:
        return false;
    }
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildAppliancesStep();
      case 1:
        return _buildSelectedAppliancesStep();
      case 2:
        return _buildCalculateStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ✅ الخطوة 1: اختيار الأجهزة
  Widget _buildAppliancesStep() {
    return SingleChildScrollView(
      key: const ValueKey('appliances_step'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          _buildCustomDeviceButton(),
          const SizedBox(height: 16),
          if (_isLoadingAppliances)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            )
          else
            _buildAppliancesGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.cairo(fontSize: 14),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: '🔍 ابحث عن جهاز...',
          hintStyle: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.search_rounded, color: primaryBlue, size: 22),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildCustomDeviceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showCustomDeviceSheet,
        icon: const Icon(Icons.add_circle_rounded, color: primaryBlue),
        label: Text(
          'إضافة جهاز مخصص',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: primaryBlue,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: primaryBlue.withOpacity(0.3), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildAppliancesGrid() {
    if (_filteredAppliances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'لا توجد أجهزة مطابقة',
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredAppliances.length,
      itemBuilder: (context, index) {
        final appliance = _filteredAppliances[index];
        return _buildApplianceCard(appliance);
      },
    );
  }

  Widget _buildApplianceCard(Map<String, dynamic> appliance) {
    final name = appliance['name_ar']?.toString() ?? '';
    final normalWatts = appliance['normal_watts']?.toString() ?? '';
    final inverterWatts = appliance['inverter_watts']?.toString() ?? '';
    final savingsPercentage = appliance['savings_percentage']?.toString() ?? '';
    final iconName = appliance['icon']?.toString();

    return GestureDetector(
      onTap: () => _selectAppliance(appliance),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              primaryBlue.withOpacity(0.02),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryBlue.withOpacity(0.1),
            width: 1.5,
          ),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.1), accentCyan.withOpacity(0.05)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getIconData(iconName),
                size: 26,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$normalWatts W → $inverterWatts W',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: mediumGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (savingsPercentage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [successGreen.withOpacity(0.15), successGreen.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'توفير $savingsPercentage%',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ الخطوة 2: مراجعة الأجهزة المختارة
  Widget _buildSelectedAppliancesStep() {
    return SingleChildScrollView(
      key: const ValueKey('selected_step'),
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
                  child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأجهزة المختارة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'راجع الأجهزة قبل الحساب',
                        style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedAppliances.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedAppliances.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'لم تختر أي جهاز بعد',
                    style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ارجع للخطوة السابقة لاختيار الأجهزة',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_selectedAppliances.length, (index) {
              final device = _selectedAppliances[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                        size: 20,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device['name']?.toString() ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device['normal_watts']}W → ${device['inverter_watts']}W | ${device['hours_per_day']}h يومياً',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: secondaryBlue, size: 18),
                            onPressed: () => _editSelectedAppliance(index),
                            padding: const EdgeInsets.all(6),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => _removeSelectedAppliance(index),
                            padding: const EdgeInsets.all(6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ✅ الخطوة 3: الحساب
  Widget _buildCalculateStep() {
    return SingleChildScrollView(
      key: const ValueKey('calculate_step'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'جاهز للحساب',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'عدد الأجهزة: ${_selectedAppliances.length}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _calculateSavings,
              icon: const Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'احسب التوفير الآن',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: successGreen.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: successGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيتم حساب التوفير الشهري بناءً على الأجهزة المختارة',
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
}

// ✅ شاشة النتائج المنفصلة
class _SavingsResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onReset;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warmOrange = Color(0xFFF59E0B);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF6B7280);

  const _SavingsResultScreen({
    required this.result,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final appliancesResult = (result['appliances'] as List?) ?? [];
    final total = result['total'] as Map<String, dynamic>? ?? {};
    final recommendation = result['recommendation']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue, accentCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'نتائج الحساب',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة النجاح
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
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
                              'تم الحساب بنجاح!',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'النتائج أدناه',
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
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // مقارنة الأجهزة
              if (appliancesResult.isNotEmpty) ...[
                Text(
                  '📊 مقارنة الأجهزة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...appliancesResult.map((item) {
                  final name = item['name']?.toString() ?? '';
                  final normal = item['normal_consumption']?.toString() ?? '';
                  final inverter = item['inverter_consumption']?.toString() ?? '';
                  final savings = item['savings']?.toString() ?? '';
                  final percentage = item['savings_percentage']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.devices_rounded, color: primaryBlue, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              name,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniBar(
                                label: 'عادي',
                                value: normal,
                                color: Colors.red,
                                maxValue: 100,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniBar(
                                label: 'إنفرتر',
                                value: inverter,
                                color: successGreen,
                                maxValue: 100,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                label: 'التوفير',
                                value: savings,
                                color: secondaryBlue,
                                icon: Icons.savings_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInfoTile(
                                label: 'النسبة',
                                value: percentage,
                                color: warmOrange,
                                icon: Icons.percent_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // الإجمالي الشهري
              if (total.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            '💰 الإجمالي الشهري',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTotalRow('استهلاك عادي', total['normal_consumption']?.toString() ?? ''),
                      _buildTotalRow('استهلاك إنفرتر', total['inverter_consumption']?.toString() ?? ''),
                      const SizedBox(height: 8),
                      Divider(color: Colors.white.withOpacity(0.3), height: 1),
                      const SizedBox(height: 8),
                      _buildTotalRow('التوفير الشهري', total['savings']?.toString() ?? '', isHighlight: true),
                      _buildTotalRow('نسبة التوفير', total['savings_percentage']?.toString() ?? '', isHighlight: true),
                    ],
                  ),
                ),
              ],

              // التوصية
              if (recommendation.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: darkColor,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // زر حساب جديد
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onReset();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'حساب جديد',
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
        ),
      ),
    );
  }

  Widget _buildMiniBar({
    required String label,
    required String value,
    required Color color,
    required double maxValue,
  }) {
    final double? numericValue = double.tryParse(value);
    final double percentage = numericValue != null && maxValue > 0
        ? (numericValue / maxValue).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: mediumGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: mediumGray,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withOpacity(isHighlight ? 1 : 0.8),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.amber : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}