// lib/screens/auth/email_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final String email;
  final String? token; // في حالة التسجيل، قد يكون لدينا توكن
  final bool isFromLogin; // هل أتى من تسجيل الدخول أم التسجيل

  const EmailVerificationScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.email,
    this.token,
    this.isFromLogin = false,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _codeControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // تحقق تلقائي عند إدخال آخر رقم
    if (index == 5 && value.length == 1) {
      _verifyEmail();
    }
  }

  String _getVerificationCode() {
    return _codeControllers.map((controller) => controller.text).join();
  }

  // Future<void> _verifyEmail() async {
  //   final code = _getVerificationCode();
  //   if (code.length != 6) {
  //     _showError('الرجاء إدخال رمز التحقق كاملاً');
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final result = await widget.authService.verifyEmail(
  //       email: widget.email,
  //       code: code,
  //     );
  //
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //
  //       if (result['success'] == true) {
  //         _showSuccess('تم تأكيد البريد الإلكتروني بنجاح!');
  //
  //         // الانتظار قليلاً ثم الانتقال إلى الشاشة الرئيسية
  //         await Future.delayed(const Duration(seconds: 1));
  //
  //         if (mounted) {
  //           if (widget.isFromLogin) {
  //             // إذا كان من تسجيل الدخول، نقوم بتسجيل الدخول الآن
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => HomeScreen(
  //                   authService: widget.authService,
  //                   storageService: widget.storageService,
  //                 ),
  //               ),
  //             );
  //           } else {
  //             // إذا كان من التسجيل، ننتقل مباشرة
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => HomeScreen(
  //                   authService: widget.authService,
  //                   storageService: widget.storageService,
  //                 ),
  //               ),
  //             );
  //           }
  //         }
  //       } else {
  //         _showError(result['message'] ?? 'رمز التحقق غير صحيح');
  //         _clearAllFields();
  //         _focusNodes[0].requestFocus();
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //       _showError('حدث خطأ في التحقق. الرجاء المحاولة مرة أخرى');
  //       _clearAllFields();
  //       _focusNodes[0].requestFocus();
  //     }
  //   }
  // }


  Future<void> _verifyEmail() async {
    final code = _getVerificationCode();
    if (code.length != 6) {
      _showError('الرجاء إدخال رمز التحقق كاملاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await widget.authService.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          _showSuccess('تم تأكيد البريد الإلكتروني بنجاح!');

          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            if (widget.isFromLogin) {
              // ✅ من تسجيل الدخول → اذهب للتطبيق مباشرة
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    authService: widget.authService,
                    storageService: widget.storageService,
                  ),
                ),
                    (route) => false,
              );
            } else {
              // ✅ من التسجيل → اذهب إلى شاشة تسجيل الدخول
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    authService: widget.authService,
                    storageService: widget.storageService,
                  ),
                ),
                    (route) => false,
              );
            }
          }
        } else {
          _showError(result['message'] ?? 'رمز التحقق غير صحيح');
          _clearAllFields();
          _focusNodes[0].requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ في التحقق. الرجاء المحاولة مرة أخرى');
        _clearAllFields();
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      final result = await widget.authService.resendVerificationCode(
        email: widget.email,
      );

      if (mounted) {
        setState(() {
          _isResending = false;
          _resendCountdown = 60;
        });

        if (result['success'] == true) {
          _showSuccess('تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني');
          _startResendCountdown();
        } else {
          _showError(result['message'] ?? 'فشل في إعادة إرسال الرمز');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        _showError('حدث خطأ. الرجاء المحاولة مرة أخرى');
      }
    }
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

  void _clearAllFields() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
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
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.3, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: AnimationLimiter(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children:
                    AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 800),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        const SizedBox(height: 40),
                        _buildModernTopBar(),
                        const SizedBox(height: 30),
                        _buildEmailIcon(),
                        const SizedBox(height: 30),
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _buildDescription(),
                        const SizedBox(height: 40),
                        _buildCodeInputFields(),
                        const SizedBox(height: 30),
                        _buildVerifyButton(),
                        const SizedBox(height: 20),
                        _buildResendSection(),
                        const SizedBox(height: 30),
                        _buildBackToLogin(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.5,
          colors: [
            primaryBlue.withOpacity(0.08),
            secondaryBlue.withOpacity(0.04),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildModernTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
                shadowColor: primaryBlue.withOpacity(0.1),
                child: InkWell(
                  onTap: _goToLogin,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'NEX',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: darkColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailIcon() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: secondaryBlue.withOpacity(0.15),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'تأكيد البريد الإلكتروني',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'تم إرسال رمز تحقق مكون من 6 أرقام إلى',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _codeControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryBlue.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: primaryBlue.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: primaryBlue,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: lightGray,
            ),
            onChanged: (value) => _onCodeChanged(value, index),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
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
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'تأكيد البريد الإلكتروني',
                    style: TextStyle(
                      fontSize: 17,
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

  Widget _buildResendSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لم تستلم الرمز؟',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: mediumGray,
              ),
            ),
            const SizedBox(width: 4),
            _isResending
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryBlue,
              ),
            )
                : TextButton(
              onPressed: _resendCountdown > 0 ? null : _resendCode,
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue,
              ),
              child: Text(
                _resendCountdown > 0
                    ? 'إعادة الإرسال ($_resendCountdown ثانية)'
                    : 'إعادة إرسال الرمز',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _resendCountdown > 0
                      ? mediumGray
                      : primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return TextButton.icon(
      onPressed: _goToLogin,
      icon: const Icon(
        Icons.arrow_back_rounded,
        color: mediumGray,
        size: 18,
      ),
      label: Text(
        'العودة إلى تسجيل الدخول',
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: mediumGray,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: mediumGray,
      ),
    );
  }
}

class FadeInAnimation extends StatelessWidget {
  final Widget child;

  const FadeInAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}