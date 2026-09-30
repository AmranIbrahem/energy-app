// lib/screens/appliances/appliance_compatibility_screen.dart

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplianceCompatibilityScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const ApplianceCompatibilityScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<ApplianceCompatibilityScreen> createState() =>
      _ApplianceCompatibilityScreenState();
}

class _ApplianceCompatibilityScreenState
    extends State<ApplianceCompatibilityScreen> {
  int _currentStep = 0;
  String? _systemVoltage;
  String? _inverterPower;
  String? _batteryType;
  final TextEditingController _appliancesController = TextEditingController();

  bool _isChecking = false;
  Map<String, dynamic>? _result;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);

  final List<String> _voltages = ['12', '24', '48'];
  final List<String> _inverterPowers = [
    'أقل من 1000W',
    '1000W - 3000W',
    'أكثر من 3000W',
  ];
  final List<String> _batteryTypes = ['أسيد', 'جل', 'ليثيوم'];

  Future<void> _checkCompatibility() async {
    setState(() => _isChecking = true);

    try {
      final response = await widget.apiService.post(
        '/v1/user/appliance-compatibility/check',
        requiresAuth: true,
        data: {
          'system_voltage': _systemVoltage,
          'inverter_power': _inverterPower,
          'battery_type': _batteryType,
          'appliances': _appliancesController.text,
        },
      );

      if (response['status'] == 'success' && mounted) {
        setState(() {
          _result = response['data'] as Map<String, dynamic>;
          _isChecking = false;
        });
      } else {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('حدث خطأ في الفحص', style: GoogleFonts.cairo())),
        );
      }
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('فحص التوافق',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: _result != null ? _buildResult() : _buildWizard(),
    );
  }

  Widget _buildWizard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: index <= _currentStep ? 30 : 10,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? primaryBlue
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: _buildStep(),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('السابق',
                        style: GoogleFonts.cairo(color: primaryBlue)),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentStep < 3
                      ? () => setState(() => _currentStep++)
                      : _isChecking
                          ? null
                          : _checkCompatibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _currentStep < 3 ? 'التالي' : 'فحص التوافق',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildSelectionStep(
          title: 'فولتية النظام',
          subtitle: 'ما هو جهد نظامك الشمسي؟',
          options: _voltages,
          selected: _systemVoltage,
          onSelect: (value) => setState(() => _systemVoltage = value),
        );
      case 1:
        return _buildSelectionStep(
          title: 'قدرة الإنفرتر',
          subtitle: 'ما هي قدرة الإنفرتر لديك؟',
          options: _inverterPowers,
          selected: _inverterPower,
          onSelect: (value) => setState(() => _inverterPower = value),
        );
      case 2:
        return _buildSelectionStep(
          title: 'نوع البطاريات',
          subtitle: 'ما هو نوع البطاريات لديك؟',
          options: _batteryTypes,
          selected: _batteryType,
          onSelect: (value) => setState(() => _batteryType = value),
        );
      case 3:
        return _buildAppliancesInput();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required String? selected,
    required Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ...options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primaryBlue : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF111827),
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

  Widget _buildAppliancesInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأجهزة المراد فحصها',
              style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text('اكتب أجهزتك مع الاستطاعة التقريبية',
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          TextField(
            controller: _appliancesController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'مثال:\n- براد 200W\n- غسالة 500W\n- مكيف 1500W\n- تلفاز 100W',
              hintStyle:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          if (summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(summary,
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: const Color(0xFF111827))),
            ),
          const SizedBox(height: 16),
          if (compatible.isNotEmpty) ...[
            Text('✅ الأجهزة المتوافقة',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
            const SizedBox(height: 8),
            ...compatible.map((item) => _buildResultCard(item, Colors.green)),
            const SizedBox(height: 16),
          ],
          if (warning.isNotEmpty) ...[
            Text('⚠️ تحتاج انتباه',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700)),
            const SizedBox(height: 8),
            ...warning.map((item) => _buildResultCard(item, Colors.orange)),
            const SizedBox(height: 16),
          ],
          if (incompatible.isNotEmpty) ...[
            Text('❌ غير متوافقة',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700)),
            const SizedBox(height: 8),
            ...incompatible.map((item) => _buildResultCard(item, Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _result = null;
                _currentStep = 0;
                _systemVoltage = null;
                _inverterPower = null;
                _batteryType = null;
                _appliancesController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('فحص جديد',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, color: Colors.white)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color.shade700)),
              ),
              if (watts.isNotEmpty)
                Text('$watts W',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color.shade600)),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note,
                style: GoogleFonts.cairo(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}
