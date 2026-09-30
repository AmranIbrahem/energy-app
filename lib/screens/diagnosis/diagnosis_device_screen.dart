// lib/screens/diagnosis/diagnosis_device_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/diagnosis_models.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/diagnosis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diagnosis_device_options_screen.dart';

class DiagnosisDeviceScreen extends StatefulWidget {
  final ApiService apiService;
  final String category;
  final String categoryLabel;
  final Color categoryColor;

  const DiagnosisDeviceScreen({
    super.key,
    required this.apiService,
    required this.category,
    required this.categoryLabel,
    required this.categoryColor,
  });

  @override
  State<DiagnosisDeviceScreen> createState() => _DiagnosisDeviceScreenState();
}

class _DiagnosisDeviceScreenState extends State<DiagnosisDeviceScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color red = Color(0xFFDC2626);

  late final DiagnosisApiService _api;

  DeviceTree? _tree;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = DiagnosisApiService(api: widget.apiService);
    _loadTree();
  }

  Future<void> _loadTree() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.deviceTree(category: widget.category);

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _tree = DeviceTree.fromJson(Map<String, dynamic>.from(res['data']));
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = res['message']?.toString() ?? 'فشل تحميل الأجهزة';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'electrical_services':
        return Icons.electrical_services_rounded;
      case 'battery_charging_full':
        return Icons.battery_charging_full_rounded;
      case 'solar_power':
        return Icons.solar_power_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'power':
        return Icons.power_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'output':
        return Icons.output_rounded;
      case 'account_tree':
        return Icons.account_tree_rounded;
      case 'power_off':
        return Icons.power_off_rounded;
      case 'speed':
        return Icons.speed_rounded;
      case 'toggle_on':
        return Icons.toggle_on_rounded;
      case 'cable':
        return Icons.cable_rounded;
      case 'shield_alert':
        return Icons.shield_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'light':
        return Icons.light_rounded;
      case 'tune':
        return Icons.tune_rounded;
      case 'visibility':
        return Icons.visibility_rounded;
      case 'wb_twilight':
        return Icons.wb_twilight_rounded;
      case 'settings_input_component':
        return Icons.settings_input_component_rounded;
      default:
        return Icons.devices_rounded;
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
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _errorMessage != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر الجهاز الذي تواجه فيه المشكلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.categoryColor),
          const SizedBox(height: 16),
          Text('جاري تحميل الأجهزة...',
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline_rounded, color: red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTree,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('حاول مرة أخرى', style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.categoryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final devices = _tree?.devices ?? [];
    if (devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد أجهزة مسجلة لهذا القسم.',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${devices.length} أجهزة متاحة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ...devices.map(_buildDeviceCard),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceInfo device) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisDeviceOptionsScreen(
              apiService: widget.apiService,
              category: widget.category,
              device: device,
              categoryColor: widget.categoryColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.categoryColor,
                    widget.categoryColor.withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFromName(device.icon),
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${device.faultsCount} أعطال',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (device.hasCodes) ...[
                        const SizedBox(width: 8),
                        _buildBadge('رموز', secondaryBlue),
                      ],
                      if (device.hasDanger) ...[
                        const SizedBox(width: 6),
                        _buildBadge('خطر', red),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_rounded,
                color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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
