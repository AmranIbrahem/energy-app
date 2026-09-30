import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'package:GeniusHouse/screens/auth/reset_password_screen.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const ForgotPasswordScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  late AnimationController _animationController;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await widget.authService.sendPasswordResetCode(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          final isSuccess = result['success'] == true ||
              result['status'] == 'success' ||
              result['status'] == true;

          if (isSuccess) {
            _isCodeSent = true;
            _showSuccess(result['message'] ?? 'تم إرسال رمز إعادة التعيين');
          } else {
            _showError(result['message'] ?? 'فشل في إرسال الرمز');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى');
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showError('الرجاء إدخال رمز التحقق');
      return;
    }

    if (code.length != 6) {
      _showError('الرجاء إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await widget.authService.verifyPasswordResetCode(
        email: _emailController.text.trim(),
        code: code,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        final isSuccess = result['success'] == true ||
            result['status'] == 'success' ||
            result['status'] == true ||
            (result['message']?.toString().contains('نجاح') ?? false) ||
            (result['message']?.toString().contains('success') ?? false);

        final message = result['message']?.toString() ?? '';
        final isVerificationSuccess =
            message.contains('تم التحقق من الرمز بنجاح') ||
                message.contains('رمز التحقق صحيح') ||
                message.contains('تم تأكيد الرمز');

        final isSuccessful = isSuccess || isVerificationSuccess;

        if (isSuccessful) {
          final email = _emailController.text.trim();

          _navigateToResetPassword(email);
        } else {
          _showError(result['message'] ?? 'رمز التحقق غير صحيح');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى');
      }
    }
  }

  void _navigateToResetPassword(String email) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ResetPasswordScreen(
          authService: widget.authService,
          storageService: widget.storageService,
          email: email,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
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
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 800),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: 40),
                          _buildTopBar(),
                          const SizedBox(height: 40),
                          _buildLockIcon(),
                          const SizedBox(height: 30),
                          _buildTitle(),
                          const SizedBox(height: 16),
                          _buildDescription(),
                          const SizedBox(height: 40),
                          if (!_isCodeSent) _buildEmailForm(),
                          if (_isCodeSent) _buildCodeForm(),
                          const SizedBox(height: 20),
                          _buildBackToLogin(),
                          const SizedBox(height: 30),
                        ],
                      ),
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

  Widget _buildTopBar() {
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
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: primaryBlue, size: 22),
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
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Text('NEX',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: darkColor)),
        ),
      ],
    );
  }

  Widget _buildLockIcon() {
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
                    spreadRadius: 5),
                BoxShadow(
                    color: secondaryBlue.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 8),
              ],
            ),
            child: const Center(
              child:
                  Icon(Icons.lock_reset_rounded, color: Colors.white, size: 55),
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
          _isCodeSent ? 'التحقق من الرمز' : 'نسيت كلمة المرور؟',
          style: GoogleFonts.cairo(
              fontSize: 28, fontWeight: FontWeight.bold, color: darkColor),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [primaryBlue, secondaryBlue]),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryBlue, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isCodeSent
                  ? 'تم إرسال رمز تحقق إلى ${_emailController.text}'
                  : 'أدخل بريدك الإلكتروني وسنرسل لك رمز إعادة تعيين كلمة المرور',
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              labelStyle: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
              prefixIcon: Icon(Icons.email_outlined, color: secondaryBlue),
              filled: true,
              fillColor: lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: errorColor, width: 2),
              ),
            ),
            validator: (v) =>
                v?.isEmpty == true ? 'الرجاء إدخال البريد الإلكتروني' : null,
          ),
          const SizedBox(height: 20),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15)
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendResetCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            : const Text(
                'إرسال الرمز',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCodeForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: darkColor,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.grey.shade300,
              ),
              counterText: '',
              filled: true,
              fillColor: lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: primaryBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: errorColor, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.length == 6) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_codeController.text.length == 6 && !_isLoading) {
                    _verifyCode();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 20),
          _buildVerifyButton(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading ? null : _sendResetCode,
            child: Text(
              'إعادة إرسال الرمز',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: secondaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15)
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            : const Text(
                'تحقق من الرمز',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLogin() {
    return TextButton.icon(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
        ),
      ),
      icon: const Icon(Icons.arrow_back_rounded, color: mediumGray, size: 18),
      label: Text(
        'العودة إلى تسجيل الدخول',
        style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
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
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
