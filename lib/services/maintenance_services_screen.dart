import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/diagnosis/diagnosis_flow_screen.dart';
import 'package:GeniusHouse/screens/workshop/workshop_request_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceServicesScreen extends StatelessWidget {
  final ApiService apiService;
  final AuthService? authService;

  const MaintenanceServicesScreen({
    super.key,
    required this.apiService,
    this.authService,
  });

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
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
                      _buildServiceCard(
                        context,
                        title: 'تشخيص العطل',
                        subtitle:
                            'شخّص المشكلة عبر الرمز أو الوصف واحصل على خطوات آمنة فوراً.',
                        icon: Icons.medical_services_rounded,
                        colors: const [primaryBlue, secondaryBlue],
                        tags: const ['رمز الشاشة', 'وصف المشكلة', 'خطوات آمنة'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiagnosisFlowScreen(
                                apiService: apiService,
                                mode: 'symptom',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildServiceCard(
                        context,
                        title: 'طلب ورشة',
                        subtitle:
                            'اطلب فنياً موثوقاً لزيارة الموقع مع تحديد الوقت والعنوان.',
                        icon: Icons.handyman_rounded,
                        colors: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                        tags: const [
                          'فني متخصص',
                          'تحديد الموقع',
                          'أوقات متاحة'
                        ],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkshopRequestScreen(
                                apiService: apiService,
                                authService: authService,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      _buildInfoBox(
                        'نصيحة أمان',
                        'إذا لاحظت دخاناً أو شرراً أو رائحة احتراق، لا تلمس الجهاز واطلب فنياً عاجلاً.',
                        Icons.warning_amber_rounded,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        'متى أستخدم أيّ خيار؟',
                        'التشخيص الذكي مناسب للأعطال البسيطة، وطلب ورشة يناسب الأعطال المعقدة أو التي تحتاج فحصاً ميدانياً.',
                        Icons.lightbulb_outline_rounded,
                        const Color(0xFF10B981),
                      ),
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
                        'خدمات الصيانة والتركيب',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'اختر الخدمة المناسبة لاحتياجك',
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
                  child: const Icon(Icons.construction_rounded,
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
            child: const Icon(Icons.support_agent_rounded,
                color: secondaryBlue, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'نظام متكامل: شخّص المشكلة بنفسك أو اطلب فنياً محترفاً بضغطة زر.',
              style: GoogleFonts.cairo(
                  fontSize: 13, height: 1.7, color: mediumGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required List<String> tags,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_back_rounded, color: colors.first, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(subtitle,
                style: GoogleFonts.cairo(
                    fontSize: 13, height: 1.7, color: mediumGray)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.first.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(t,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.first,
                            )),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String body, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 3),
                Text(body,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        height: 1.6,
                        color: Colors.grey.shade800)),
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
