import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart' hide FadeInAnimation;
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'dart:ui' as ui;

class OnboardingScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const OnboardingScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final AnimationController _particleController;
  late final AnimationController _colorTransitionController;
  late final AnimationController _floatingController;
  int _currentPage = 0;


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);

  final List<OnboardingModel> _onboardingData = [
    OnboardingModel(
      animationPath: 'assets/animations/solar-panel.json',
      title: 'طاقة شمسية',
      subtitle: 'لمنزلك',
      description: 'وفر حتى 70% من فواتير الكهرباء مع أحدث تقنيات الطاقة الشمسية',
      color: primaryBlue,
      secondaryColor: secondaryBlue,
      gradientColors: [primaryBlue, secondaryBlue],
      icon: Icons.solar_power_rounded,
    ),
    OnboardingModel(
      animationPath: 'assets/animations/successful-food-delivery.json',
      title: 'جودة معتمدة',
      subtitle: 'وعالمية',
      description: 'منتجات معتمدة بأعلى المعايير العالمية وضمان يصل إلى 25 سنة',
      color: darkColor,
      secondaryColor: mediumGray,
      gradientColors: [darkColor, mediumGray],
      icon: Icons.verified_rounded,
    ),
    OnboardingModel(
      animationPath: 'assets/animations/tech-support.json',
      title: 'دعم فني',
      subtitle: 'متكامل',
      description: 'فريق محترف يدعمك على مدار الساعة من التركيب حتى الصيانة',
      color: secondaryBlue,
      secondaryColor: accentBlue,
      gradientColors: [secondaryBlue, accentBlue],
      icon: Icons.support_agent_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _colorTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _particleController.dispose();
    _colorTransitionController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await widget.storageService.setOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          _buildAnimatedBackground(),


          _buildParticleEffect(),


          SafeArea(
            child: Column(
              children: [

                _buildTopBar(),


                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _animationController.reset();
                      _animationController.forward();
                      _colorTransitionController.reset();
                      _colorTransitionController.forward();
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
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
                        child: OnboardingPageContent(
                          key: ValueKey(index),
                          data: _onboardingData[index],
                          animationController: _animationController,
                          floatingController: _floatingController,
                          isActive: _currentPage == index,
                        ),
                      );
                    },
                  ),
                ),


                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _colorTransitionController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                _currentPage == 0 ? -0.4 : _currentPage == 1 ? 0 : 0.4,
                -0.4,
              ),
              radius: 1.3,
              colors: [
                _onboardingData[_currentPage].color.withOpacity(0.08),
                _onboardingData[_currentPage].secondaryColor.withOpacity(0.03),
                Colors.white,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleEffect() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_particleController, _colorTransitionController]),
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              progress: _particleController.value,
              color: _onboardingData[_currentPage].color,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      Text(
                        'GeniusHouse',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),


          if (_currentPage < _onboardingData.length - 1)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Material(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: primaryBlue.withOpacity(0.1),
                    child: InkWell(
                      onTap: _skipToEnd,
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تخطي',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mediumGray,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: mediumGray,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AnimationLimiter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 500),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 20,
              child: FadeInAnimation(child: widget),
            ),
            children: [

              _buildPageIndicator(),

              const SizedBox(height: 24),


              if (_currentPage == _onboardingData.length - 1) ...[
                _buildGetStartedButton(),
                const SizedBox(height: 12),
                _buildLoginButton(),
              ] else
                _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_floatingController.value * math.pi) * 3),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(25),
        ),
        child: SmoothPageIndicator(
          controller: _pageController,
          count: _onboardingData.length,
          effect: ExpandingDotsEffect(
            activeDotColor: _onboardingData[_currentPage].color,
            dotColor: Colors.grey.shade300,
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 3.5,
            spacing: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _onboardingData[_currentPage].gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _onboardingData[_currentPage].color.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'التالي',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGetStartedButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'ابدأ مع GeniusHouse',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: TextButton(
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20, color: mediumGray),
                  const SizedBox(width: 8),
                  Text(
                    'لديك حساب؟ تسجيل دخول',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class OnboardingModel {
  final String animationPath;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final Color secondaryColor;
  final List<Color> gradientColors;
  final IconData icon;

  OnboardingModel({
    required this.animationPath,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.secondaryColor,
    required this.gradientColors,
    required this.icon,
  });
}


class OnboardingPageContent extends StatelessWidget {
  final OnboardingModel data;
  final AnimationController animationController;
  final AnimationController floatingController;
  final bool isActive;

  const OnboardingPageContent({
    super.key,
    required this.data,
    required this.animationController,
    required this.floatingController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimationLimiter(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 700),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 40,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const SizedBox(height: 10),


              _buildAnimatedIllustration(),

              const SizedBox(height: 35),


              _buildTitleSection(),

              const SizedBox(height: 20),


              _buildDescription(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIllustration() {
    return AnimatedBuilder(
      animation: floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(floatingController.value * math.pi) * 8),
          child: child,
        );
      },
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.color.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 12,
                  ),
                  BoxShadow(
                    color: data.color.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Lottie.asset(
                data.animationPath,
                width: 220,
                height: 220,
                repeat: true,
                reverse: false,
                animate: isActive,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: data.color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: data.color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.description,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);


    final largePaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final x = (i * 53 + random.nextDouble() * 20) % size.width;
      final y = ((i * 41 + progress * size.height * 0.6) % size.height);
      final radius = 2.5 + random.nextDouble() * 2;
      canvas.drawCircle(Offset(x, y), radius, largePaint);
    }


    final smallPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = (i * 67 + random.nextDouble() * 30) % size.width;
      final y = ((i * 37 + progress * size.height * 0.4) % size.height);
      canvas.drawCircle(Offset(x, y), 1.2, smallPaint);
    }


    final glowPaint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < 10; i++) {
      final x = (i * 89 + random.nextDouble() * 40) % size.width;
      final y = ((i * 59 + progress * size.height * 0.3) % size.height);
      canvas.drawCircle(Offset(x, y), 5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}