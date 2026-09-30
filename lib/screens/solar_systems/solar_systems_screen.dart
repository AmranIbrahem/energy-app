// lib/screens/solar_systems/solar_systems_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/solar_system_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'add_solar_system_screen.dart';

class SolarSystemsScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const SolarSystemsScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<SolarSystemsScreen> createState() => _SolarSystemsScreenState();
}

class _SolarSystemsScreenState extends State<SolarSystemsScreen>
    with TickerProviderStateMixin {
  late SolarSystemService _solarSystemService;
  List<dynamic> _solarSystems = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  final String _baseUrl = 'https://nexsy.shop';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _fadeAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;

  @override
  void initState() {
    super.initState();
    _solarSystemService = SolarSystemService(
      baseUrl: _baseUrl,
      authService: widget.authService,
    );

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadSolarSystems();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSolarSystems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _solarSystemService.getUserSolarSystems();

      if (result['success'] == true) {
        final data = result['data'];
        final systems = data['systems'] ?? [];

        setState(() {
          _solarSystems = systems;
          _isLoading = false;
          _isRefreshing = false;
        });

        _fadeAnimationController.forward(from: 0.0);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'حدث خطأ في تحميل المنظومات';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال بالخادم';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _loadSolarSystems();
  }

  void _navigateToAddSystem() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddSolarSystemScreen(authService: widget.authService),
      ),
    ).then((_) => _loadSolarSystems());
  }

  Future<void> _showSystemDetails(Map<String, dynamic> system) async {
    setState(() => _isLoading = true);

    try {
      final result =
          await _solarSystemService.getSolarSystemDetails(system['id']);

      if (result['success'] == true && mounted) {
        final data = result['data'];
        final systemData = data['system'];
        final statistics = data['statistics'];

        _showDetailsBottomSheet(systemData, statistics);
      } else {
        _showSnackBar(
            result['message'] ?? 'حدث خطأ في جلب التفاصيل', Colors.red);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ في جلب التفاصيل', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailsBottomSheet(
      Map<String, dynamic> system, Map<String, dynamic> statistics) {
    final details = system['details'] ?? {};
    final panels = details['panels'] ?? {};
    final inverter = details['inverter'] ?? {};
    final batteries = details['batteries'] ?? {};
    final maintenanceResponses = system['maintenance_responses'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child),
                          );
                        },
                        child: _buildDetailHeader(system),
                      ),
                      const SizedBox(height: 20),
                      _buildStatusBanner(system),
                      const SizedBox(height: 20),
                      if (panels['image'] != null && panels['image'].isNotEmpty)
                        _buildAnimatedImageCard('صورة الألواح الشمسية',
                            panels['image'], Icons.solar_power_rounded),
                      _buildDetailSection(
                        icon: Icons.solar_power_rounded,
                        title: 'الألواح الشمسية',
                        color: Colors.orange,
                        children: [
                          _buildDetailRow(
                              'عدد الألواح',
                              '${panels['count'] ?? 0} لوح',
                              Icons.grid_view_rounded),
                          _buildDetailRow(
                              'قدرة اللوح',
                              '${panels['wattage'] ?? 0} واط',
                              Icons.bolt_rounded),
                          _buildDetailRow(
                              'الماركة',
                              panels['brand'] ?? 'غير محدد',
                              Icons.branding_watermark_rounded),
                          _buildDetailRow(
                              'القدرة الكلية',
                              '${panels['total_wattage'] ?? 0} واط',
                              Icons.flash_on_rounded,
                              isHighlighted: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (inverter['image'] != null &&
                          inverter['image'].isNotEmpty)
                        _buildAnimatedImageCard('صورة الانفرتر',
                            inverter['image'], Icons.memory_rounded),
                      _buildDetailSection(
                        icon: Icons.memory_rounded,
                        title: 'الانفرتر',
                        color: Colors.blue,
                        children: [
                          _buildDetailRow(
                              'نوع الانفرتر',
                              inverter['type'] ?? 'غير محدد',
                              Icons.settings_rounded),
                          _buildDetailRow(
                              'قدرة الانفرتر',
                              '${inverter['power'] ?? 0} واط',
                              Icons.power_rounded),
                          _buildDetailRow('العدد', '${inverter['count'] ?? 1}',
                              Icons.numbers_rounded),
                          _buildDetailRow(
                              'الماركة',
                              inverter['brand'] ?? 'غير محدد',
                              Icons.branding_watermark_rounded),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (batteries['image'] != null &&
                          batteries['image'].isNotEmpty)
                        _buildAnimatedImageCard('صورة البطاريات',
                            batteries['image'], Icons.battery_std_rounded),
                      _buildDetailSection(
                        icon: Icons.battery_charging_full_rounded,
                        title: 'البطاريات',
                        color: Colors.green,
                        children: [
                          _buildDetailRow(
                              'عدد البطاريات',
                              '${batteries['count'] ?? 0} بطارية',
                              Icons.grid_view_rounded),
                          _buildDetailRow(
                              'سعة البطارية',
                              '${batteries['capacity'] ?? 0} أمبير/س',
                              Icons.storage_rounded),
                          _buildDetailRow(
                              'نوع البطارية',
                              batteries['type'] ?? 'غير محدد',
                              Icons.category_rounded),
                          _buildDetailRow(
                              'الماركة',
                              batteries['brand'] ?? 'غير محدد',
                              Icons.branding_watermark_rounded),
                          _buildDetailRow(
                              'السعة الكلية',
                              '${batteries['total_capacity'] ?? 0} أمبير/س',
                              Icons.battery_full_rounded,
                              isHighlighted: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        icon: Icons.analytics_rounded,
                        title: 'إحصائيات المنظومة',
                        color: Colors.purple,
                        children: [
                          _buildDetailRow(
                              'إجمالي القدرة',
                              '${statistics['total_panels_power'] ?? 0} واط',
                              Icons.bolt_rounded,
                              isHighlighted: true),
                          _buildDetailRow(
                              'إجمالي سعة البطاريات',
                              '${statistics['total_batteries_capacity'] ?? 0} أمبير/س',
                              Icons.battery_full_rounded),
                          _buildDetailRow(
                              'عمر المنظومة',
                              '${statistics['system_age_days'] ?? 0} يوم',
                              Icons.calendar_today_rounded),
                          _buildDetailRow(
                              'عدد ردود الصيانة',
                              '${statistics['total_responses'] ?? 0}',
                              Icons.support_agent_rounded),
                          _buildDetailRow(
                              'حالة الدفع',
                              system['status_paid'] == true
                                  ? 'مدفوعة'
                                  : 'غير مدفوعة',
                              Icons.payment_rounded,
                              isHighlighted: system['status_paid'] == true),
                        ],
                      ),
                      if (maintenanceResponses.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMaintenanceSection(maintenanceResponses),
                      ],
                      const SizedBox(height: 30),
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

  Widget _buildDetailHeader(Map<String, dynamic> system) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.1),
                  child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.solar_power_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(system['system_number'] ?? 'منظومة شمسية',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                    'تاريخ التركيب: ${system['installation_date'] ?? 'غير محدد'}',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: cardWhite, borderRadius: BorderRadius.circular(20)),
            child: Text(
              system['status'] == 'active' ? 'نشطة' : 'قيد الانتظار',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    system['status'] == 'active' ? primaryBlue : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic> system) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, double value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: system['status'] == 'active'
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.orange.shade50, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: system['status'] == 'active'
                  ? Colors.green.shade200
                  : Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              system['status'] == 'active'
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_bottom_rounded,
              color:
                  system['status'] == 'active' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 10),
            Text(
              system['status'] == 'active'
                  ? 'المنظومة نشطة وتعمل بكفاءة'
                  : 'المنظومة قيد المراجعة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w500,
                color: system['status'] == 'active'
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedImageCard(String title, String imageUrl, IconData icon) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade50]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.15),
                          secondaryBlue.withOpacity(0.08)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: primaryBlue),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkColor)),
                ],
              ),
            ),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade300
                        ]),
                      ),
                      child: const Center(
                          child: CircularProgressIndicator(color: primaryBlue)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade300
                        ]),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_rounded,
                              size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('تعذر تحميل الصورة',
                              style: GoogleFonts.cairo(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent
                          ],
                        ),
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

  Color _getStatusColor(String colorName) {
    switch (colorName) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1)
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: darkColor)),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(15),
                child: Column(children: children)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool isHighlighted = false}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
              offset: Offset(20 * (1 - animValue), 0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? primaryBlue.withOpacity(0.04) : lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isHighlighted
                  ? primaryBlue.withOpacity(0.15)
                  : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? primaryBlue.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 16, color: isHighlighted ? primaryBlue : Colors.grey),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.cairo(fontSize: 13, color: mediumGray))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isHighlighted ? primaryBlue.withOpacity(0.08) : cardWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted ? primaryBlue : darkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(List<dynamic> maintenanceResponses) {
    return _buildDetailSection(
      icon: Icons.support_agent_rounded,
      title: 'ردود فريق الصيانة',
      color: Colors.indigo,
      children: maintenanceResponses.map<Widget>((response) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Opacity(
                opacity: value,
                child:
                    Transform.scale(scale: 0.9 + (0.1 * value), child: child));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardWhite, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.indigo.shade100),
              boxShadow: [
                BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(response['type_color'])
                                .withOpacity(0.2),
                            _getStatusColor(response['type_color'])
                                .withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        response['type_name'] ?? 'عام',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(response['type_color']),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(response['created_at_human'] ?? '',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(response['title'] ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
                const SizedBox(height: 6),
                Text(response['content'] ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: mediumGray, height: 1.4)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                color == Colors.green
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
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
              ClipPath(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) =>
                                        Transform.scale(
                                      scale: 1.0 +
                                          (_pulseAnimationController.value *
                                              0.1),
                                      child: child,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.solar_power_rounded,
                                          color: Colors.white,
                                          size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'منظوماتي',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _navigateToAddSystem,
                              icon: const Icon(Icons.add_rounded,
                                  color: Colors.white),
                              tooltip: 'إضافة منظومة',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _solarSystems.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refresh,
                                color: primaryBlue,
                                backgroundColor: cardWhite,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _solarSystems.length,
                                  itemBuilder: (context, index) {
                                    final system = _solarSystems[index];
                                    return _buildSystemCard(system, index);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
        floatingActionButton: _solarSystems.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _navigateToAddSystem,
                icon: const Icon(Icons.add_rounded),
                label: Text('إضافة منظومة', style: GoogleFonts.cairo()),
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 5,
              )
            : null,
      ),
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> system, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: primaryBlue.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => _showSystemDetails(system),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: system['status'] == 'active'
                                ? [
                                    primaryBlue.withOpacity(0.15),
                                    secondaryBlue.withOpacity(0.08)
                                  ]
                                : [
                                    Colors.orange.withOpacity(0.2),
                                    Colors.orange.withOpacity(0.1)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.solar_power_rounded,
                          color: system['status'] == 'active'
                              ? primaryBlue
                              : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              system['system_number'] ?? 'منظومة شمسية',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  system['installation_date'] ?? 'غير محدد',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildDeleteButton(system),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: system['status'] == 'active'
                                ? [primaryBlue, secondaryBlue]
                                : [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: system['status'] == 'active'
                                  ? primaryBlue.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          system['status'] == 'active'
                              ? 'نشطة'
                              : 'قيد الانتظار',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          primaryBlue.withOpacity(0.3),
                          Colors.grey.shade200
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusIndicator(
                          'حالة الدفع',
                          system['status_paid'] == true
                              ? 'مدفوعة'
                              : 'غير مدفوعة',
                          system['status_paid'] == true
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          system['status_paid'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Container(
                          width: 1, height: 40, color: Colors.grey.shade200),
                      Expanded(
                        child: _buildStatusIndicator(
                          'نوع المنظومة',
                          system['type'] ?? 'شمسية',
                          Icons.energy_savings_leaf_rounded,
                          primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(Map<String, dynamic> system) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _confirmDeleteSystem(system),
        splashColor: Colors.red.withOpacity(0.1),
        highlightColor: Colors.red.withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
              color: cardWhite, borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardWhite,
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 60, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSolarSystems,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, double value, child) {
          return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                    scale: 1.0 + (_pulseAnimationController.value * 0.1),
                    child: child);
              },
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardWhite,
                  boxShadow: [
                    BoxShadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Icon(Icons.solar_power_rounded,
                    size: 70, color: primaryBlue.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 20),
            Text('لا توجد منظومات',
                style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
            const SizedBox(height: 10),
            Text('لم تقم بإضافة أي منظومة شمسية بعد',
                style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _navigateToAddSystem,
              icon: const Icon(Icons.add_rounded),
              label: Text('إضافة منظومة جديدة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSystem(Map<String, dynamic> system) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              'تأكيد الحذف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف المنظومة؟',
              style: GoogleFonts.cairo(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم المنظومة:',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    system['system_number'] ?? 'غير معروف',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تاريخ التركيب:',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    system['installation_date'] ?? 'غير محدد',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم حذف المنظومة وجميع بياناتها بشكل دائم',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('نعم، حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteSystem(system['id']);
    }
  }

  Future<void> _deleteSystem(int systemId) async {
    setState(() => _isLoading = true);

    try {
      final result = await _solarSystemService.deleteSolarSystem(systemId);

      if (result['success'] == true) {
        _showSnackBar(
            result['message'] ?? 'تم حذف المنظومة بنجاح', Colors.green);
        await _loadSolarSystems();
      } else {
        _showSnackBar(
            result['message'] ?? 'حدث خطأ في حذف المنظومة', Colors.red);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ في حذف المنظومة', Colors.red);
      setState(() => _isLoading = false);
    }
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
