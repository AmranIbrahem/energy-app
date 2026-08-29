// lib/screens/auth/register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'package:GeniusHouse/screens/legal/terms_screen.dart';
import 'package:GeniusHouse/screens/legal/privacy_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:GeniusHouse/screens/onboarding_screen.dart';
import 'package:GeniusHouse/screens/auth/email_verification_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // ✅ Company fields
  final _companyNameArController = TextEditingController();
  final _companyDescriptionArController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyWhatsappController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyCommercialRegisterController = TextEditingController();
  final _companyMapUrlController = TextEditingController();
  final _companyDistrictController = TextEditingController();

  String? _companyGovernorate;
  String? _companyDistrict;
  File? _companyLogo;

  String _selectedUserType = 'customer';
  String? _selectedGovernorate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  late AnimationController _animationController;
  int _currentStep = 0;
  final ImagePicker _imagePicker = ImagePicker();

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

    // ✅ إضافة مستمع لتنسيق رقم الهاتف تلقائياً
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneNumber);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    _referralCodeController.dispose();
    _companyNameArController.dispose();
    _companyDescriptionArController.dispose();
    _companyPhoneController.dispose();
    _companyWhatsappController.dispose();
    _companyAddressController.dispose();
    _companyCommercialRegisterController.dispose();
    _companyMapUrlController.dispose();
    _animationController.dispose();
    _companyDistrictController.dispose();
    super.dispose();
  }

  // ✅ دالة تنسيق رقم الهاتف تلقائياً
  void _formatPhoneNumber() {
    String text = _phoneController.text;

    // إزالة المؤشر لتجنب الأخطاء
    final selection = _phoneController.selection;

    // إذا كان المستخدم قد كتب شيئاً
    if (text.isNotEmpty) {
      // إذا بدأ المستخدم بكتابة 0، نحذفها
      if (text.startsWith('0')) {
        text = text.substring(1);
      }

      // إذا بدأ الرقم بـ 963 بدون +، نضيف +
      if (text.startsWith('963') && !text.startsWith('+963')) {
        text = '+963$text';
      }

      // إذا لم يبدأ بـ +963، نضيفه تلقائياً
      if (!text.startsWith('+963') && text.isNotEmpty) {
        text = '+963$text';
      }

      // تحديث النص إذا تغير
      if (text != _phoneController.text) {
        _phoneController.text = text;
        // إعادة المؤشر إلى نهاية النص
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      }
    }
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
      // ✅ المنطقة والعنوان اختياريان - نرسل سلسلة فارغة إذا كانا فارغين
      district: _districtController.text.trim(),
      address: _addressController.text.trim(),
      userType: _selectedUserType,
      referralCode: _referralCodeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => EmailVerificationScreen(
              authService: widget.authService,
              storageService: widget.storageService,
              email: _emailController.text.trim(),
              token: result['data']['token'] ?? result['data']['data']?['token'],
              isFromLogin: false,
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
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        _showModernErrorSnackBar(result['message'] ?? 'فشل إنشاء الحساب');
      }
    }
  }

  Future<void> _registerCompany() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showModernErrorSnackBar('الرجاء الموافقة على الشروط وسياسة الخصوصية');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/user/public/company-requests'),
      );

      request.headers['Accept'] = 'application/json';

      // User Info
      request.fields['name'] = _nameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['password'] = _passwordController.text;
      request.fields['password_confirmation'] = _confirmPasswordController.text;
      request.fields['governorate'] = _selectedGovernorate ?? '';

      if (_referralCodeController.text.isNotEmpty) {
        request.fields['referral_code'] = _referralCodeController.text.trim();
      }

      // Company Info
      request.fields['company_name_ar'] = _companyNameArController.text.trim();
      request.fields['company_description_ar'] = _companyDescriptionArController.text.trim();
      request.fields['company_phone'] = _companyPhoneController.text.trim();
      request.fields['company_whatsapp'] = _companyWhatsappController.text.trim();
      request.fields['company_governorate'] = _companyGovernorate ?? _selectedGovernorate ?? '';
      request.fields['company_commercial_register'] = _companyCommercialRegisterController.text.trim();
      request.fields['company_map_url'] = _companyMapUrlController.text.trim();

      if (_companyLogo != null) {
        request.files.add(await http.MultipartFile.fromPath('company_logo', _companyLogo!.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (mounted) {
        setState(() => _isLoading = false);

        if (data['success'] == true || data['data'] != null) {
          _showSuccessDialog(data['message'] ?? 'تم تقديم طلب إنشاء حساب الشركة بنجاح');
        } else {
          String errorMsg = data['message'] ?? 'فشل تقديم الطلب';
          if (data['errors'] != null) {
            final errors = data['errors'];
            if (errors is Map) {
              errorMsg = errors.values.first?.toString() ?? errorMsg;
            }
          }
          _showModernErrorSnackBar(errorMsg);
        }
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showModernErrorSnackBar('حدث خطأ في الاتصال');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: primaryBlue, size: 28),
          const SizedBox(width: 10),
          Text('تم تقديم الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ]),
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => EmailVerificationScreen(
                    authService: widget.authService,
                    storageService: widget.storageService,
                    email: _emailController.text.trim(),
                    isFromLogin: false,
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تأكيد البريد الإلكتروني', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCompanyLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) {
      setState(() => _companyLogo = File(image.path));
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            LoginScreen(
              authService: widget.authService,
              storageService: widget.storageService,
            ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0.3, 0), end: Offset.zero).animate(
                  animation),
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
        context, MaterialPageRoute(builder: (context) => const TermsScreen()));
  }

  void _showPrivacyScreen() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const PrivacyScreen()));
  }

  void _showModernErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
        ]),
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
    final isCompany = _selectedUserType == 'company';

    return Scaffold(
      body: Stack(children: [
        _buildAnimatedBackground(),
        SafeArea(
          child: AnimationLimiter(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 800),
                  childAnimationBuilder: (widget) =>
                      SlideAnimation(
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
                    if (!isCompany) _buildStepIndicator(),
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
      ]),
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
            Colors.white
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildModernTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                    Navigator.pushReplacement(context, PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          OnboardingScreen(authService: widget.authService,
                              storageService: widget.storageService),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation,
                              child: SlideTransition(position: Tween<Offset>(
                                  begin: const Offset(-0.3, 0),
                                  end: Offset.zero).animate(animation),
                                  child: child)),
                      transitionDuration: const Duration(milliseconds: 500),
                    ));
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(padding: const EdgeInsets.all(10),
                      child: const Icon(
                          Icons.arrow_back_rounded, color: primaryBlue,
                          size: 22)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bolt_rounded, color: secondaryBlue, size: 16),
                  const SizedBox(width: 6),
                  Text('NEX', style: GoogleFonts.poppins(fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: darkColor,
                      letterSpacing: 0.5)),
                ]),
              ),
            );
          },
        ),
      ]),
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
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: primaryBlue.withOpacity(0.35),
                    blurRadius: 30,
                    spreadRadius: 5),
                BoxShadow(color: secondaryBlue.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 8)
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/images/app_nex_icon.jpg', width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(
                    Icons.person_add_rounded, color: Colors.white,
                    size: 45)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTitle() {
    final isCompany = _selectedUserType == 'company';
    return Column(children: [
      Text(isCompany ? 'تسجيل شركة جديدة' : 'إنشاء حساب جديد',
          style: GoogleFonts.cairo(fontSize: 28,
              fontWeight: FontWeight.bold,
              color: darkColor,
              height: 1.2)),
      const SizedBox(height: 6),
      Container(width: 60,
          height: 4,
          decoration: BoxDecoration(gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue]),
              borderRadius: BorderRadius.circular(2))),
    ]);
  }

  Widget _buildModernDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: lightGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.08))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.stars_rounded, color: secondaryBlue, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(
            'قم بإنشاء حساب للاستفادة من العروض الحصرية ومتابعة طلباتك',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontSize: 14, color: mediumGray, height: 1.5))),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        _buildStepCircle(0, 'المعلومات الشخصية'),
        Expanded(child: Container(height: 2,
            color: _currentStep >= 1 ? primaryBlue : Colors.grey.shade300)),
        _buildStepCircle(1, 'العنوان'),
        Expanded(child: Container(height: 2,
            color: _currentStep >= 2 ? primaryBlue : Colors.grey.shade300)),
        _buildStepCircle(2, 'كلمة المرور'),
        Expanded(child: Container(height: 2,
            color: _currentStep >= 3 ? primaryBlue : Colors.grey.shade300)),
        _buildStepCircle(3, 'رمز الدعوة'),
      ]),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle,
            color: isActive ? primaryBlue : Colors.grey.shade200,
            border: isCurrent ? Border.all(color: primaryBlue, width: 3) : null,
            boxShadow: isActive ? [
              BoxShadow(color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ] : null),
        child: Center(child: Text('${step + 1}', style: GoogleFonts.cairo(
            color: isActive ? Colors.white : Colors.grey.shade500,
            fontWeight: FontWeight.bold))),
      ),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.cairo(fontSize: 10,
          color: isActive ? primaryBlue : Colors.grey.shade500,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _buildModernRegisterForm() {
    final isCompany = _selectedUserType == 'company';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: primaryBlue.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
          border: Border.all(color: primaryBlue.withOpacity(0.05))),
      child: Form(
        key: _formKey,
        child: Column(children: [
          _buildModernUserTypeField(),
          const SizedBox(height: 16),

          if (isCompany) ...[
            _buildSectionTitle('معلومات المستخدم'),
            const SizedBox(height: 12),
            _buildModernNameField(),
            const SizedBox(height: 12),
            _buildModernEmailField(),
            const SizedBox(height: 12),
            _buildModernPhoneField(),
            const SizedBox(height: 12),
            _buildModernGovernorateField(),
            const SizedBox(height: 12),
            _buildModernPasswordField(),
            const SizedBox(height: 12),
            _buildModernConfirmPasswordField(),

            const SizedBox(height: 20),
            _buildSectionTitle('معلومات الشركة'),
            const SizedBox(height: 12),
            _buildTextField(
                _companyNameArController, 'اسم الشركة *', 'أدخل اسم الشركة'),
            const SizedBox(height: 12),
            _buildTextField(_companyDescriptionArController, 'وصف الشركة',
                'وصف مختصر عن الشركة', maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField(
                _companyPhoneController, 'هاتف الشركة', 'رقم هاتف الشركة'),
            const SizedBox(height: 12),
            _buildTextField(
                _companyWhatsappController, 'واتساب الشركة', 'رقم الواتساب'),
            const SizedBox(height: 12),
            _buildTextField(
                _companyCommercialRegisterController, 'السجل التجاري',
                'رقم السجل التجاري'),
            const SizedBox(height: 12),
            _buildTextField(_companyMapUrlController, 'رابط الخريطة',
                'https://maps.google.com/...'),
            const SizedBox(height: 12),
            _buildLogoPicker(),

            const SizedBox(height: 20),
            _buildReferralCodeField(),
            const SizedBox(height: 16),
            _buildTermsAndConditionsSection(),
            const SizedBox(height: 20),
            _buildCompanyRegisterButton(),
          ] else
            ...[
              if (_currentStep == 0) ...[
                _buildModernNameField(),
                const SizedBox(height: 16),
                _buildModernEmailField(),
                const SizedBox(height: 16),
                _buildModernPhoneField(),
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
                _buildReferralCodeField(),
                const SizedBox(height: 20),
                _buildTermsAndConditionsSection(),
              ],
              const SizedBox(height: 24),
              Row(children: [
                if (_currentStep > 0) ...[
                  Expanded(child: _buildBackButton()),
                  const SizedBox(width: 12)
                ],
                Expanded(flex: _currentStep > 0 ? 1 : 2,
                    child: _currentStep < 3
                        ? _buildNextButton()
                        : _buildRegisterButton()),
              ]),
            ],
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.info_rounded, color: primaryBlue, size: 16)),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.cairo(
          fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
    ]);
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint,
      {int maxLines = 1, TextEditingController? hintFromController}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
        hintText: hintFromController?.text.isNotEmpty == true
            ? hintFromController!.text
            : hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
        filled: true,
        fillColor: lightGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 14),
      ),
      validator: label.contains('*') ? (v) =>
      (v == null || v
          .trim()
          .isEmpty) ? 'هذا الحقل مطلوب' : null : null,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
            color: lightGray, borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
            items: items
                .map((i) =>
                DropdownMenuItem<String>(value: i,
                    child: Text(i, style: GoogleFonts.cairo(fontSize: 13))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _buildLogoPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('شعار الشركة (اختياري)', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickCompanyLogo,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _companyLogo != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_companyLogo!, width: double.infinity, fit: BoxFit.contain))
              : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_a_photo_rounded, size: 30, color: primaryBlue.withOpacity(0.6)),
            const SizedBox(height: 4),
            Text('انقر لاختيار الشعار', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
          ])),
        ),
      ),
    ]);
  }

  Widget _buildModernUserTypeField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedUserType,
        decoration: InputDecoration(
          labelText: 'نوع الحساب',
          labelStyle: GoogleFonts.cairo(color: mediumGray),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            child: const Icon(Icons.business_center_rounded, color: secondaryBlue, size: 20),
          ),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
        items: const [
          DropdownMenuItem(value: 'customer', child: Text('حساب عميل عادي')),
          DropdownMenuItem(value: 'company', child: Text('حساب شركة / تاجر')),
        ],
        onChanged: (value) => setState(() {
          _selectedUserType = value!;
          _currentStep = 0;
        }),
      ),
    );
  }

  Widget _buildModernNameField() =>
      TextFormField(controller: _nameController,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
              'الاسم الكامل', Icons.person_outline_rounded),
          validator: (v) =>
          (v == null || v.isEmpty)
              ? 'الرجاء إدخال الاسم الكامل'
              : (v.length < 3 ? 'الاسم يجب أن يكون 3 أحرف على الأقل' : null));

  Widget _buildModernEmailField() =>
      TextFormField(controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
              'البريد الإلكتروني', Icons.email_outlined),
          validator: (v) =>
          (v == null || v.isEmpty)
              ? 'الرجاء إدخال البريد الإلكتروني'
              : (!v.contains('@')
              ? 'البريد الإلكتروني يجب أن يحتوي على @'
              : (!Helpers.isValidEmail(v)
              ? 'الرجاء إدخال بريد إلكتروني صحيح'
              : null)));

  // ✅ حقل رقم الهاتف المعدل مع مثال توضيحي
  Widget _buildModernPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
            'رقم الهاتف',
            Icons.phone_outlined,
          ).copyWith(
            hintText: '+963933314567',
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            // ✅ إضافة helperText لتوضيح التنسيق
            helperText: null,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'الرجاء إدخال رقم الهاتف';
            }
            if (!v.startsWith('+963')) {
              return 'يجب أن يبدأ الرقم بـ +963';
            }
            // إزالة +963 للتحقق من طول الرقم
            final numberWithoutCode = v.substring(4);
            if (numberWithoutCode.length < 8) {
              return 'رقم الهاتف قصير جداً';
            }
            if (!Helpers.isValidPhone(v)) {
              return 'الرجاء إدخال رقم هاتف صحيح';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        // ✅ مثال توضيحي جميل
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primaryBlue.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: primaryBlue.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: mediumGray,
                    ),
                    children: [
                      const TextSpan(text: 'مثال: '),
                      TextSpan(
                        text: '+963933314567',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(
                        text: '\n+963 متبوعاً بالرقم بدون الصفر الأول',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernGovernorateField() =>
      DropdownButtonFormField<String>(value: _selectedGovernorate,
          decoration: _buildInputDecoration(
              'المحافظة', Icons.location_city_rounded),
          items: AppConstants.syrianGovernorates.map((gov) =>
              DropdownMenuItem(value: gov, child: Text(gov))).toList(),
          onChanged: (v) => setState(() => _selectedGovernorate = v),
          validator: (v) => v == null ? 'الرجاء اختيار المحافظة' : null);

  Widget _buildModernDistrictField() =>
      TextFormField(controller: _districtController,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
        decoration: _buildInputDecoration(
            'المنطقة (اختياري)', Icons.location_on_outlined),
      );

  Widget _buildModernAddressField() =>
      TextFormField(controller: _addressController,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
        decoration: _buildInputDecoration(
            'العنوان التفصيلي (اختياري)', Icons.home_outlined),
      );

  Widget _buildModernPasswordField() =>
      TextFormField(controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
              'كلمة المرور', Icons.lock_outline_rounded, suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons
                  .visibility_rounded, color: mediumGray),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword))),
          validator: (v) =>
          (v == null || v.isEmpty)
              ? 'الرجاء إدخال كلمة المرور'
              : (v.length < 6
              ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
              : null));

  Widget _buildModernConfirmPasswordField() =>
      TextFormField(controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
              'تأكيد كلمة المرور', Icons.lock_outline_rounded,
              suffixIcon: IconButton(icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons
                      .visibility_rounded, color: mediumGray),
                  onPressed: () =>
                      setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword))),
          validator: (v) =>
          (v == null || v.isEmpty)
              ? 'الرجاء تأكيد كلمة المرور'
              : (v != _passwordController.text
              ? 'كلمة المرور غير متطابقة'
              : null));

  Widget _buildReferralCodeField() {
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.15))),
          child: Row(children: [
            Icon(Icons.card_giftcard, color: primaryBlue, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
                'إذا كان لديك رمز دعوة، أدخله هنا للحصول على مكافأة!',
                style: GoogleFonts.cairo(fontSize: 12, color: primaryBlue)))
          ])),
      const SizedBox(height: 16),
      TextFormField(controller: _referralCodeController,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
          decoration: _buildInputDecoration(
              'رمز الدعوة (اختياري)', Icons.verified_user_rounded).copyWith(
              hintText: 'مثال: ABC12345',
              hintStyle: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.grey.shade400)),
          validator: (v) =>
          (v != null && v.isNotEmpty && v.length < 6)
              ? 'رمز الدعوة يجب أن يكون 6 أحرف على الأقل'
              : null),
    ]);
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: mediumGray),
      prefixIcon: Container(margin: const EdgeInsets.all(12),
          child: Icon(icon, color: secondaryBlue, size: 20)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildTermsAndConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.1))),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      color: _acceptedTerms ? primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _acceptedTerms ? primaryBlue : Colors.grey
                              .shade400, width: 2)),
                  child: _acceptedTerms
                      ? const Icon(
                      Icons.check_rounded, size: 14, color: Colors.white)
                      : null),
              const SizedBox(width: 10),
              Expanded(child: RichText(text: TextSpan(
                  style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                  children: [
                    const TextSpan(text: 'أوافق على '),
                    TextSpan(text: 'الشروط والأحكام', style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline)),
                    const TextSpan(text: ' و '),
                    TextSpan(text: 'سياسة الخصوصية', style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline))
                  ]))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildLinkButton(icon: Icons.description_rounded,
              label: 'الشروط والأحكام',
              onTap: _showTermsScreen),
          _buildLinkButton(icon: Icons.privacy_tip_rounded,
              label: 'سياسة الخصوصية',
              onTap: _showPrivacyScreen),
        ]),
      ]),
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

  Widget _buildNextButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) =>
          Transform.scale(
            scale: value,
            child: Container(
              height: 55,
              decoration: BoxDecoration(gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: primaryBlue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ]),
              child: ElevatedButton(
                  onPressed: () => setState(() => _currentStep++),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('التالي', style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white,
                            size: 18)
                      ])),
            ),
          ),
    );
  }

  Widget _buildBackButton() =>
      OutlinedButton(onPressed: () => setState(() => _currentStep--),
          style: OutlinedButton.styleFrom(foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              minimumSize: const Size(double.infinity, 55)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18),
                SizedBox(width: 8),
                Text('رجوع',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
              ]));

  Widget _buildRegisterButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) =>
          Transform.scale(
            scale: value,
            child: Container(
              height: 55,
              decoration: BoxDecoration(gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: primaryBlue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ]),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                child: _isLoading ? const SizedBox(width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)) : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white,
                          size: 20),
                      SizedBox(width: 10),
                      Text('إنشاء حساب', style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))
                    ]),
              ),
            ),
          ),
    );
  }

  Widget _buildCompanyRegisterButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerCompany,
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: 5),
        child: _isLoading ? const SizedBox(width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5)) : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('تقديم طلب التسجيل', style: GoogleFonts.cairo(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))
            ]),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('لديك حساب بالفعل؟',
          style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
      TextButton(onPressed: _goToLogin,
          style: TextButton.styleFrom(foregroundColor: primaryBlue),
          child: Text('تسجيل دخول', style: GoogleFonts.cairo(
              fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue))),
    ]);
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
      builder: (context, value, child) =>
          Opacity(opacity: value,
              child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)), child: child)),
      child: child,
    );
  }
}