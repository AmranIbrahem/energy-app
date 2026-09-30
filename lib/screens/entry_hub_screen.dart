// lib/screens/entry_hub_screen.dart

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/lighting/lighting_projects_screen.dart';
import 'package:GeniusHouse/screens/services/maintenance_services_screen.dart';
import 'package:GeniusHouse/screens/settings_screen.dart';
import 'package:GeniusHouse/screens/solar/solar_wizard_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EntryHubScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final ApiService apiService;

  const EntryHubScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.apiService,
  });

  @override
  State<EntryHubScreen> createState() => _EntryHubScreenState();
}

class _EntryHubScreenState extends State<EntryHubScreen>
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1E3A8A);

  static const int _animatedItems = 5;

  late AnimationController _entranceController;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  late Animation<double> _headerFade;
  late Animation<double> _headerSlide;

  final List<Animation<double>> _rowFade = [];
  final List<Animation<double>> _rowSlide = [];
  final List<Animation<double>> _rowScale = [];

  late Animation<double> _bgRotation;
  late Animation<double> _bgPulse;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 30000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    for (int i = 0; i < _animatedItems; i++) {
      final start = 0.20 + (i * 0.10);
      final end = (start + 0.45).clamp(0.0, 1.0);

      _rowFade.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _rowSlide.add(
        Tween<double>(begin: 70.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
      _rowScale.add(
        Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    _bgRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.linear),
    );
    _bgPulse = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openBrowse() {
    _navigateTo(HomeScreen(
      authService: widget.authService,
      storageService: widget.storageService,
    ));
  }

  void _openServices() {
    _navigateTo(MaintenanceServicesScreen(
      apiService: widget.apiService,
      authService: widget.authService,
    ));
  }

  void _openSolar() {
    _navigateTo(SolarWizardScreen(
      storageService: widget.storageService,
      apiService: widget.apiService,
    ));
  }

  void _openLighting() {
    _navigateTo(LightingProjectsScreen(
      storageService: widget.storageService,
      apiService: widget.apiService,
    ));
  }

  void _openSettings() {
    _navigateTo(const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
                Color(0xFF1E40AF),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              _buildAnimatedBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildRows(),
                      const SizedBox(height: 20),
                      _buildSettingsHintCard(),
                      const SizedBox(height: 16),
                      _buildFooterHint(),
                      const SizedBox(height: 20),
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

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bgController, _pulseController]),
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -150,
              right: -150,
              child: Transform.rotate(
                angle: _bgRotation.value * 0.15,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(_bgPulse.value * 0.15),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Transform.rotate(
                angle: -_bgRotation.value * 0.2,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyanAccent.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Transform.rotate(
                angle: _bgRotation.value * 0.08,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.03),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            ..._buildFloatingDots(),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingDots() {
    final random = math.Random(42);
    final dots = <Widget>[];
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final size = random.nextDouble() * 3 + 1.5;
      dots.add(
        Positioned(
          left: x * MediaQuery.of(context).size.width,
          top: y * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: 0.25 + (_bgPulse.value * 0.4),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return dots;
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _headerFade.value,
          child: Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.35),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: primaryBlue.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_nex_icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.bolt_rounded,
                  size: 40,
                  color: primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مرحباً بك في NEX',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.yellow.shade300,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'اختر ما تريد البدء به',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    final rows = [
      _HubRowData(
        title: 'تصفح التطبيق',
        subtitle: 'اكتشف كل الميزات المتوفرة',
        icon: Icons.apps_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF1E40AF)],
        glowColor: const Color(0xFF3B82F6),
        onTap: _openBrowse,
      ),
      _HubRowData(
        title: 'خدمات الصيانة',
        subtitle: 'تركيب وصيانة فورية',
        icon: Icons.home_repair_service_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF047857)],
        glowColor: const Color(0xFF10B981),
        onTap: _openServices,
      ),
      _HubRowData(
        title: 'منظومة شمسية',
        subtitle: 'صمم نظامك خطوة بخطوة',
        icon: Icons.solar_power_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        glowColor: const Color(0xFFF59E0B),
        onTap: _openSolar,
      ),
      _HubRowData(
        title: 'إنارة ذكية',
        subtitle: 'ديكور وإضاءة منزلية',
        icon: Icons.lightbulb_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        glowColor: const Color(0xFF8B5CF6),
        onTap: _openLighting,
      ),
    ];

    return Column(
      children: List.generate(rows.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 14),
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              return Opacity(
                opacity: _rowFade[index].value,
                child: Transform.translate(
                  offset: Offset(_rowSlide[index].value, 0),
                  child: Transform.scale(
                    scale: _rowScale[index].value,
                    child: child,
                  ),
                ),
              );
            },
            child: _HubRowCard(
              data: rows[index],
              pulseAnimation: _pulseController,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettingsHintCard() {
    const int idx = 4;
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _rowFade[idx].value,
          child: Transform.translate(
            offset: Offset(_rowSlide[idx].value * 0.5, 0),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSettings,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.06);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'يمكنك التحكم بهذه الشاشة',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'من الإعدادات ← واجهة البداية',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.72),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterHint() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _rowFade[4].value,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: Colors.white.withOpacity(0.55),
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            'اختر صفاً للبدء',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubRowData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _HubRowData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });
}

class _HubRowCard extends StatefulWidget {
  final _HubRowData data;
  final AnimationController pulseAnimation;

  const _HubRowCard({required this.data, required this.pulseAnimation});

  @override
  State<_HubRowCard> createState() => _HubRowCardState();
}

class _HubRowCardState extends State<_HubRowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();

  void _onTapUp(_) => _pressController.reverse();

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: data.onTap,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(scale: _pressScale.value, child: child);
        },
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.07),
            border: Border.all(
              color: Colors.white.withOpacity(0.13),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: data.glowColor.withOpacity(0.22),
                blurRadius: 26,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          data.gradient[0].withOpacity(0.32),
                          data.gradient[1].withOpacity(0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.glowColor.withOpacity(0.18),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: data.gradient,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: widget.pulseAnimation,
                        builder: (context, child) {
                          final scale =
                              1.0 + (widget.pulseAnimation.value * 0.06);
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: data.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: data.glowColor.withOpacity(0.55),
                                blurRadius: 16,
                                spreadRadius: -2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            data.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.subtitle,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
