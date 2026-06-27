// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'package:GeniusHouse/screens/legal/terms_screen.dart';
import 'package:GeniusHouse/screens/legal/privacy_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:GeniusHouse/screens/onboarding_screen.dart';
import 'dart:ui' as ui;

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();
  final _referralCodeController = TextEditingController();

  String _selectedUserType = 'customer';
  String? _selectedGovernorate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  late AnimationController _animationController;
  int _currentStep = 0;

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _referralCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showModernErrorSnackBar('الرجاء الموافقة على الشروط وسياسة الخصوصية');
      return;
    }

    setState(() => _isLoading = true);

    final result = await widget.authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      governorate: _selectedGovernorate!,
      district: _districtController.text.trim(),
      address: _addressController.text.trim(),
      userType: _selectedUserType,
      referralCode: _referralCodeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        await widget.authService.sendFcmTokenToServer();

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(
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
      } else {
        _showModernErrorSnackBar(result['message'] ?? 'فشل إنشاء الحساب');
      }
    }
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

  void _showTermsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
  }

  void _showPrivacyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
    );
  }

  void _showModernErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
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
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 800),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildModernTopBar(),
                      const SizedBox(height: 5),
                      _buildAnimatedLogo(),
                      const SizedBox(height: 16),
                      _buildModernTitle(),
                      const SizedBox(height: 12),
                      _buildModernDescription(),
                      const SizedBox(height: 25),
                      _buildStepIndicator(),
                      const SizedBox(height: 20),
                      _buildModernRegisterForm(),
                      const SizedBox(height: 20),
                      _buildLoginLink(),
                      const SizedBox(height: 30),
                    ],
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
          center: const Alignment(-0.3, -0.5),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => OnboardingScreen(
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
                    },
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

          
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Container(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: secondaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GeniusHouse',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: darkColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 90,
            height: 90,
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
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 45,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTitle() {
    return Column(
      children: [
        Text(
          'إنشاء حساب جديد',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _buildModernDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stars_rounded,
            color: secondaryBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'قم بإنشاء حساب للاستفادة من العروض الحصرية ومتابعة طلباتك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: mediumGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStepCircle(0, 'المعلومات الشخصية'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1 ? primaryBlue : Colors.grey.shade300,
            ),
          ),
          _buildStepCircle(1, 'العنوان'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2 ? primaryBlue : Colors.grey.shade300,
            ),
          ),
          _buildStepCircle(2, 'كلمة المرور'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 3 ? primaryBlue : Colors.grey.shade300,
            ),
          ),
          _buildStepCircle(3, 'رمز الدعوة'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryBlue : Colors.grey.shade200,
            border: isCurrent
                ? Border.all(color: primaryBlue, width: 3)
                : null,
            boxShadow: isActive
                ? [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: GoogleFonts.cairo(
                color: isActive ? Colors.white : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: isActive ? primaryBlue : Colors.grey.shade500,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildModernRegisterForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: primaryBlue.withOpacity(0.05),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_currentStep == 0) ...[
              _buildModernNameField(),
              const SizedBox(height: 16),
              _buildModernEmailField(),
              const SizedBox(height: 16),
              _buildModernPhoneField(),
              const SizedBox(height: 16),
              _buildModernUserTypeField(),
            ],

            if (_currentStep == 1) ...[
              _buildModernGovernorateField(),
              const SizedBox(height: 16),
              _buildModernDistrictField(),
              const SizedBox(height: 16),
              _buildModernAddressField(),
            ],

            if (_currentStep == 2) ...[
              _buildModernPasswordField(),
              const SizedBox(height: 16),
              _buildModernConfirmPasswordField(),
            ],

            if (_currentStep == 3) ...[
              _buildModernReferralCodeField(),
              const SizedBox(height: 20),
              _buildTermsAndConditionsSection(),
            ],

            const SizedBox(height: 24),

            
            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(child: _buildBackButton()),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: _currentStep < 3
                      ? _buildNextButton()
                      : _buildRegisterButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildTermsAndConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _acceptedTerms ? primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _acceptedTerms ? primaryBlue : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _acceptedTerms
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                        children: [
                          const TextSpan(text: 'أوافق على '),
                          TextSpan(
                            text: 'الشروط والأحكام',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' و '),
                          TextSpan(
                            text: 'سياسة الخصوصية',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLinkButton(
                icon: Icons.description_rounded,
                label: 'الشروط والأحكام',
                onTap: _showTermsScreen,
              ),
              _buildLinkButton(
                icon: Icons.privacy_tip_rounded,
                label: 'سياسة الخصوصية',
                onTap: _showPrivacyScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildModernNameField() {
    return TextFormField(
      controller: _nameController,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration('الاسم الكامل', Icons.person_outline_rounded),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال الاسم الكامل';
        if (value.length < 3) return 'الاسم يجب أن يكون 3 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildModernEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textDirection: TextDirection.ltr,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration('البريد الإلكتروني', Icons.email_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
        if (!value.contains('@')) return 'البريد الإلكتروني يجب أن يحتوي على @';
        if (!Helpers.isValidEmail(value)) return 'الرجاء إدخال بريد إلكتروني صحيح (مثال: name@domain.com)';
        return null;
      },
    );
  }

  Widget _buildModernPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration('رقم الهاتف (مثال: +963933314341)', Icons.phone_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
        if (!Helpers.isValidPhone(value)) return 'الرجاء إدخال رقم هاتف صحيح (يبدأ بـ +963)';
        return null;
      },
    );
  }

  Widget _buildModernUserTypeField() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      decoration: _buildInputDecoration('نوع الحساب', Icons.business_center_rounded),
      items: const [
        DropdownMenuItem(value: 'customer', child: Text('عميل عادي')),
        DropdownMenuItem(value: 'dealer', child: Text('تاجر')),
      ],
      onChanged: (value) => setState(() => _selectedUserType = value!),
    );
  }

  
  Widget _buildModernGovernorateField() {
    return DropdownButtonFormField<String>(
      value: _selectedGovernorate,
      decoration: _buildInputDecoration('المحافظة', Icons.location_city_rounded),
      items: AppConstants.syrianGovernorates.map((gov) {
        return DropdownMenuItem(value: gov, child: Text(gov));
      }).toList(),
      onChanged: (value) => setState(() => _selectedGovernorate = value),
      validator: (value) => value == null ? 'الرجاء اختيار المحافظة' : null,
    );
  }

  Widget _buildModernDistrictField() {
    return TextFormField(
      controller: _districtController,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration('المنطقة', Icons.location_on_outlined),
      validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال المنطقة' : null,
    );
  }

  Widget _buildModernAddressField() {
    return TextFormField(
      controller: _addressController,
      textDirection: TextDirection.rtl,
      maxLines: 2,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration('العنوان التفصيلي', Icons.home_outlined),
      validator: (value) => value == null || value.isEmpty ? 'الرجاء إدخال العنوان' : null,
    );
  }

  
  Widget _buildModernPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textDirection: TextDirection.ltr,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration(
        'كلمة المرور',
        Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: mediumGray,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
        if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _buildModernConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textDirection: TextDirection.ltr,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration(
        'تأكيد كلمة المرور',
        Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: mediumGray,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
        if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
        return null;
      },
    );
  }

  Widget _buildModernReferralCodeField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إذا كان لديك رمز دعوة من صديق، يمكنك إدخاله هنا للحصول على مكافأة!',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _referralCodeController,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
            'رمز الدعوة (اختياري)',
            Icons.verified_user_rounded,
          ).copyWith(
            hintText: 'مثال: ABC12345',
            hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 6) {
              return 'رمز الدعوة يجب أن يكون 6 أحرف على الأقل (اختياري)';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: mediumGray),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        child: Icon(icon, color: secondaryBlue, size: 20),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildNextButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep++),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('التالي',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return OutlinedButton(
      onPressed: () => setState(() => _currentStep--),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(double.infinity, 55),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_rounded, size: 18),
          SizedBox(width: 8),
          Text('رجوع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isLoading
                  ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('إنشاء حساب',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('لديك حساب بالفعل؟', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        TextButton(
          onPressed: _goToLogin,
          style: TextButton.styleFrom(foregroundColor: primaryBlue),
          child: Text('تسجيل دخول', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
        ),
      ],
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