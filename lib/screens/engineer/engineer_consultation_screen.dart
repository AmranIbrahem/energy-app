// lib/screens/engineer/engineer_consultation_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'engineer_confirmation_screen.dart';

class EngineerConsultationScreen extends StatelessWidget {
  final ApiService apiService;
  final AuthService? authService;

  const EngineerConsultationScreen({
    super.key,
    required this.apiService,
    this.authService,
  });

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);

  static const List<Map<String, dynamic>> _domains = [
    {
      'key': 'electricity',
      'label': 'كهرباء',
      'subtitle': 'تمديدات، قواطع، أحمال',
      'icon': Icons.electrical_services_rounded,
      'color': Color(0xFF3B82F6),
      'gradient': [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    },
    {
      'key': 'solar',
      'label': 'طاقة شمسية',
      'subtitle': 'محولات، بطاريات، ألواح',
      'icon': Icons.solar_power_rounded,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFFFC107), Color(0xFFF59E0B)],
    },
    {
      'key': 'lighting',
      'label': 'إنارة',
      'subtitle': 'سبوت، ديمر، حساسات',
      'icon': Icons.lightbulb_rounded,
      'color': Color(0xFF8B5CF6),
      'gradient': [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F7FA)],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'اختر مجال الاستشارة',
                        'سيتم تحويلك إلى مهندس نيكس المتخصص',
                      ),
                      const SizedBox(height: 14),
                      ..._domains.map((d) => _buildDomainCard(context, d)),
                      const SizedBox(height: 24),
                      _buildInfoBox(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                        'استشارة مهندس',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'اسأل مهندس نيكس في تخصصك',
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
                  child: const Icon(Icons.engineering_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: secondaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.engineering_rounded,
                color: secondaryBlue, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'اختر مجال الاستشارة وسيتم تحويلك إلى مهندس نيكس المختص.',
              style: GoogleFonts.cairo(
                  fontSize: 13, height: 1.7, color: mediumGray),
            ),
          ),
        ],
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

  Widget _buildDomainCard(BuildContext context, Map<String, dynamic> domain) {
    final color = domain['color'] as Color;
    final gradient = domain['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => _openConfirmation(context, domain),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(domain['icon'] as IconData,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    domain['subtitle'] as String,
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

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: secondaryBlue.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: secondaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الاستشارة مبدئية، وقد تُحوَّل إلى طلب صيانة أو زيارة ميدانية إذا تطلّب الأمر.',
              style: GoogleFonts.cairo(
                  fontSize: 12, height: 1.7, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  void _openConfirmation(BuildContext context, Map<String, dynamic> domain) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EngineerConfirmationScreen(
          apiService: apiService,
          authService: authService,
          domainKey: domain['key'] as String,
          domainLabel: domain['label'] as String,
          domainColor: domain['color'] as Color,
          domainIcon: domain['icon'] as IconData,
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
