// lib/screens/splash_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:GeniusHouse/screens/entry_hub_screen.dart';
import 'package:GeniusHouse/screens/governorate_selection_screen.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/onboarding_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const SplashScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particlesController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particlesOpacity;

  final List<_Particle> _particles = [];
  final int _numberOfParticles = 25;

  @override
  void initState() {
    super.initState();

    _initializeParticles();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 25000),
    )..repeat();

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    _particlesOpacity = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();

    Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _numberOfParticles; i++) {
      _particles.add(_Particle(
        position: Offset(
          random.nextDouble() - 0.5,
          random.nextDouble() - 0.5,
        ),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.2,
        angle: random.nextDouble() * 2 * math.pi,
        distance: random.nextDouble() * 180 + 60,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  void _navigateToNext() async {
    if (!mounted) return;

    await widget.authService.refreshAuthState();

    if (widget.authService.isAuthenticated) {
      final tokenValid = await widget.authService.handleTokenExpiry();
      if (!tokenValid) {}
    }

    final isOnboardingSeen = widget.storageService.isOnboardingSeen();
    final isAuthenticated = widget.authService.isAuthenticated;
    final isGuest = widget.authService.isGuest;
    final governorate = widget.storageService.getGovernorate();

    Widget destination;

    if (!isOnboardingSeen) {
      destination = OnboardingScreen(
        authService: widget.authService,
        storageService: widget.storageService,
      );
    } else if (isAuthenticated ||
        (isGuest && governorate != null && governorate.isNotEmpty)) {
      final showHub = widget.storageService.isAlwaysShowHub();

      if (showHub) {
        destination = EntryHubScreen(
          authService: widget.authService,
          storageService: widget.storageService,
          apiService: ApiService(storageService: widget.storageService),
        );
      } else {
        destination = HomeScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        );
      }
    } else {
      destination = GovernorateSelectionScreen(
        authService: widget.authService,
        storageService: widget.storageService,
        isFromOnboarding: false,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue,
              Color(0xFF1E40AF),
              secondaryBlue,
              Color(0xFF1E3A8A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._buildAnimatedParticles(),
            _buildDecorativeCircles(),
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(),
                    const SizedBox(height: 35),
                    _buildAppTitle(),
                    const SizedBox(height: 8),
                    _buildTagline(),
                    const SizedBox(height: 50),
                    _buildLoadingIndicator(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particlesController,
        builder: (context, child) {
          final angle = particle.angle +
              (_particlesController.value * 2 * math.pi * particle.speed);
          final x = math.cos(angle) * particle.distance;
          final y = math.sin(angle) * particle.distance;

          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - particle.size / 2,
            top: MediaQuery.of(context).size.height / 2 + y - particle.size / 2,
            child: Opacity(
              opacity: _particlesOpacity.value,
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildDecorativeCircles() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -120,
              right: -120,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.2,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1.5,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.4,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              right: -80,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.6,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: -30,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.15,
                child: CustomPaint(
                  size: const Size(120, 220),
                  painter: _CurvedLinePainter(),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: -30,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.2,
                child: CustomPaint(
                  size: const Size(100, 180),
                  painter: _CurvedLinePainter(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_scaleAnimation, _pulseController, _rotationController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.08,
            child: child,
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_nex_icon.jpg',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.bolt_rounded,
                size: 65,
                color: primaryBlue,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Column(
      children: [
        Text(
          'New Energy',
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Experience',
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Colors.yellow.shade300,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: Colors.yellow.shade300,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'كل ما يحتاجه منزلك في مكان واحد',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.25),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2.5,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final Offset position;
  final double size;
  final double speed;
  final double angle;
  final double distance;

  _Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.distance,
  });
}

class _CurvedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.3,
        size.height * 0.9,
      );

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path2 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.3,
        size.width * 0.1,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.8,
        size.width * 0.8,
        size.height,
      );

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
