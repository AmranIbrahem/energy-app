import 'dart:async';
import 'package:flutter/material.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/services/storage_service.dart';
import 'package:energy_store_app/screens/onboarding_screen.dart';
import 'package:energy_store_app/screens/governorate_selection_screen.dart';
import 'package:energy_store_app/screens/home_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    // Navigate after delay
    Timer(const Duration(seconds: 2), _navigateToNext);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNext() async {
    final isOnboardingSeen = widget.storageService.isOnboardingSeen();
    final isAuthenticated = widget.authService.isAuthenticated;
    final isGuest = widget.authService.isGuest;
    final governorate = widget.storageService.getGovernorate();

    // Case 1: First time - show onboarding
    if (!isOnboardingSeen) {
      _navigateToOnboarding();
      return;
    }

    // Case 2: Authenticated user - go to home
    if (isAuthenticated) {
      _navigateToHome();
      return;
    }

    // Case 3: Guest user with governorate - go to home
    if (isGuest && governorate != null && governorate.isNotEmpty) {
      _navigateToHome();
      return;
    }

    // Case 4: Guest user without governorate - show governorate selection
    if (isGuest && (governorate == null || governorate.isEmpty)) {
      _navigateToGovernorateSelection();
      return;
    }

    // Case 5: Not authenticated and not guest - show governorate selection (for new guests)
    _navigateToGovernorateSelection();
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _navigateToGovernorateSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GovernorateSelectionScreen(
          authService: widget.authService,
          storageService: widget.storageService,
          isFromOnboarding: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50),
              const Color(0xFF1B5E20),
              const Color(0xFF0D3B0F),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon / Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.solar_power,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // App Name
                  const Text(
                    'متجر الطاقة البديلة',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'الحل الأمثل للطاقة المتجددة في سوريا',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Loading indicator
                  Container(
                    width: 40,
                    height: 40,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}