import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color errorColor = Color(0xFFEF4444);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إرسال البريد الإلكتروني وكلمة المرور الجديدة فقط
      final result = await widget.authService.resetPassword(
        email: widget.email,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      print('🔑 Reset password result: $result');

      if (mounted) {
        setState(() => _isLoading = false);

        final isSuccess = result['success'] == true ||
            result['status'] == 'success' ||
            result['status'] == true ||
            (result['message']?.toString().contains('نجاح') ?? false);

        if (isSuccess) {
          _showSuccess('تم إعادة تعيين كلمة المرور بنجاح');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen(
                  authService: widget.authService,
                  storageService: widget.storageService,
                ),
              ),
            );
          }
        } else {
          _showError(result['message'] ?? 'فشل في إعادة تعيين كلمة المرور');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى');
        print('❌ Error resetting password: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
        ]),
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
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
                          _buildKeyIcon(),
                          const SizedBox(height: 30),
                          _buildTitle(),
                          const SizedBox(height: 16),
                          _buildDescription(),
                          const SizedBox(height: 40),
                          _buildPasswordForm(),
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
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_back_rounded, color: primaryBlue, size: 22),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.08), blurRadius: 10)],
          ),
          child: Text('NEX', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: darkColor)),
        ),
      ],
    );
  }

  Widget _buildKeyIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.35), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: const Center(child: Icon(Icons.key_rounded, color: Colors.white, size: 55)),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text('كلمة المرور الجديدة', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 8),
        Container(width: 60, height: 4, decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]), borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(16)),
      child: Text(
        'أدخل كلمة المرور الجديدة وتأكيدها',
        style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 20)],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              labelStyle: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: secondaryBlue),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
              if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
            decoration: InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              labelStyle: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: secondaryBlue),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
              if (v != _passwordController.text) return 'كلمة المرور غير متطابقة';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 15)],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                'إعادة تعيين كلمة المرور',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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