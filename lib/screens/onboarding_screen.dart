import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart' hide FadeInAnimation;
import 'package:energy_store_app/utils/constants.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/services/storage_service.dart';
import 'package:energy_store_app/screens/auth/login_screen.dart';
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
  int _currentPage = 0;

  final List<OnboardingModel> _onboardingData = [
    OnboardingModel(
      animationPath: 'assets/animations/solar-panel.json',
      title: 'طاقة شمسية',
      subtitle: 'لمنزلك',
      description: 'وفر حتى 70% من فواتير الكهرباء مع أحدث تقنيات الطاقة الشمسية',
      color: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF059669),
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    OnboardingModel(
      animationPath: 'assets/animations/successful-food-delivery.json',
      title: 'جودة معتمدة',
      subtitle: 'وعالمية',
      description: 'منتجات معتمدة بأعلى المعايير العالمية وضمان يصل إلى 25 سنة',
      color: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFD97706),
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    OnboardingModel(
      animationPath: 'assets/animations/tech-support.json',
      title: 'دعم فني',
      subtitle: 'متكامل',
      description: 'فريق محترف يدعمك على مدار الساعة من التركيب حتى الصيانة',
      color: const Color(0xFF3B82F6),
      secondaryColor: const Color(0xFF2563EB),
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _particleController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // خلفية متحركة مع تدرج متغير
          _buildAnimatedGradientBackground(),

          // تأثير جزيئات متحركة
          _buildParticleEffect(),

          // تأثير زجاجي على الخلفية
          _buildGlassBackground(),

          // المحتوى الرئيسي
          SafeArea(
            child: Column(
              children: [
                // شريط علوي متطور
                _buildModernTopBar(),

                // PageView مع أنيمشن
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _animationController.reset();
                      _animationController.forward();
                    },
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: OnboardingContent(
                          key: ValueKey(index),
                          data: _onboardingData[index],
                          animationController: _animationController,
                          isActive: _currentPage == index,
                        ),
                      );
                    },
                  ),
                ),

                // القسم السفلي
                _buildModernBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // خلفية متدرجة متحركة
  Widget _buildAnimatedGradientBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(_currentPage == 0 ? -0.5 : _currentPage == 1 ? 0 : 0.5, -0.5),
          radius: 1.2,
          colors: [
            _onboardingData[_currentPage].color.withOpacity(0.15),
            _onboardingData[_currentPage].secondaryColor.withOpacity(0.05),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  // تأثير الزجاج على الخلفية
  Widget _buildGlassBackground() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // تأثير جزيئات متحركة محسّن
  Widget _buildParticleEffect() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.2,
            child: CustomPaint(
              painter: AdvancedParticlePainter(
                progress: _particleController.value,
                currentPage: _currentPage,
                color: _onboardingData[_currentPage].color,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  // شريط علوي متطور
  Widget _buildModernTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // شعار التطبيق مع أنيمشن
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _onboardingData[_currentPage].gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: _onboardingData[_currentPage].color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
          ),

          // زر تخطي مع أنيمشن
          if (_currentPage < 2)
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.9),
                    child: InkWell(
                      onTap: _skipToEnd,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تخطي',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey.shade700,
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

  // القسم السفلي المتطور
  Widget _buildModernBottomSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 30,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // مؤشر صفحات متطور مع خلفية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: _onboardingData[_currentPage].color,
                    dotColor: Colors.grey.shade300,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 3,
                    spacing: 10,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // الأزرار مع أنيمشن
              if (_currentPage == 2)
                Column(
                  children: [
                    _buildPremiumGetStartedButton(),
                    const SizedBox(height: 12),
                    _buildPremiumLoginButton(),
                  ],
                )
              else
                _buildPremiumNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  // زر التالي المتطور
  Widget _buildPremiumNextButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _onboardingData[_currentPage].gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _onboardingData[_currentPage].color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'التالي',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // زر ابدأ الآن المتطور
  Widget _buildPremiumGetStartedButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.5),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'ابدأ رحلتك الخضراء',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
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

  // زر تسجيل الدخول المتطور
  Widget _buildPremiumLoginButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
              color: Colors.white,
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      authService: widget.authService,
                      storageService: widget.storageService,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'لديك حساب؟ تسجيل دخول',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.grey.shade700,
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

// موديل البيانات المحسن
class OnboardingModel {
  final String animationPath;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final Color secondaryColor;
  final List<Color> gradientColors;

  OnboardingModel({
    required this.animationPath,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.secondaryColor,
    required this.gradientColors,
  });
}

// محتوى الصفحة مع أنيمشنات متقدمة جداً
class OnboardingContent extends StatelessWidget {
  final OnboardingModel data;
  final AnimationController animationController;
  final bool isActive;

  const OnboardingContent({
    super.key,
    required this.data,
    required this.animationController,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 800),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              const SizedBox(height: 20),

              // لوتي أنيمشن مع تأثيرات
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        data.animationPath,
                        width: 240,
                        height: 240,
                        repeat: true,
                        reverse: false,
                        animate: isActive,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // العنوان مع تصميم مميز
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      data.color.withOpacity(0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: data.color,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // الوصف مع تصميم أنيق
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// جزيئات متحركة متطورة
class AdvancedParticlePainter extends CustomPainter {
  final double progress;
  final int currentPage;
  final Color color;

  AdvancedParticlePainter({
    required this.progress,
    required this.currentPage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final paintSmall = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // رسم جزيئات كبيرة
    for (int i = 0; i < 30; i++) {
      final x = (i * 51) % size.width;
      final y = ((i * 37) % size.height + progress * size.height * 0.5) % size.height;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }

    // رسم جزيئات صغيرة
    for (int i = 0; i < 80; i++) {
      final x = (i * 73) % size.width;
      final y = ((i * 43) % size.height + progress * size.height * 0.3) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, paintSmall);
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.currentPage != currentPage;
  }
}