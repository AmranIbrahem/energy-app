// lib/screens/diagnosis/diagnosis_home_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diagnosis_device_screen.dart';
import 'diagnosis_search_screen.dart';

class DiagnosisHomeScreen extends StatefulWidget {
  final ApiService apiService;

  const DiagnosisHomeScreen({super.key, required this.apiService});

  @override
  State<DiagnosisHomeScreen> createState() => _DiagnosisHomeScreenState();
}

class _DiagnosisHomeScreenState extends State<DiagnosisHomeScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);

  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'solar',
      'label': 'طاقة شمسية',
      'icon': Icons.solar_power_rounded,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFFFC107), Color(0xFFF59E0B)],
      'subtitle': 'محول، بطارية، ألواح',
    },
    {
      'id': 'electricity',
      'label': 'كهرباء منزلية',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFF3B82F6),
      'gradient': [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      'subtitle': 'قاطع، مقبس، تمديد',
    },
    {
      'id': 'lighting',
      'label': 'إنارة',
      'icon': Icons.lightbulb_rounded,
      'color': Color(0xFF8B5CF6),
      'gradient': [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
      'subtitle': 'لمبة، ديمر، حساس',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      'اختر القسم',
                      'ليعرض لك الأجهزة التي نستطيع مساعدتك فيها',
                    ),
                    const SizedBox(height: 14),
                    ..._categories.map(_buildCategoryCard),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                        'تشخيص العطل',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر القسم أو ابحث عن العطل',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
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
                  child: const Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisSearchScreen(
              apiService: widget.apiService,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: secondaryBlue.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: secondaryBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded,
                  color: secondaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ابحث عن عطل... (بطارية، شرر، ماء...)',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final color = cat['color'] as Color;
    final gradient = cat['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisDeviceScreen(
              apiService: widget.apiService,
              category: cat['id'],
              categoryLabel: cat['label'],
              categoryColor: color,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  Icon(cat['icon'] as IconData, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['subtitle'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_rounded, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: amber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.warning_amber_rounded, color: amber, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'إذا يوجد دخان أو شرر أو رائحة احتراق، اكتب ذلك فوراً ولا تلمس الجهاز.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                height: 1.6,
                color: Colors.amber.shade900,
              ),
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
