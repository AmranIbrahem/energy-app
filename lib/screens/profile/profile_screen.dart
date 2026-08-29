// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/screens/profile/edit_profile_screen.dart';
import 'package:GeniusHouse/screens/profile/change_password_screen.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/screens/company/request_company_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  int _favoritesCount = 0;
  int _ordersCount = 0;
  int _selectedTab = 0;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    );

    _fetchProfile();
    _fetchStatistics();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await widget.apiService.get(
        '/v1/user/profile',
        requiresAuth: true,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _userData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              response['message'] ?? 'حدث خطأ في تحميل الملف الشخصي';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _fetchStatistics() async {
    try {
      final favoritesResponse = await widget.apiService.get(
        '/v1/user/favorites',
        requiresAuth: true,
      );
      if (favoritesResponse.containsKey('data') &&
          favoritesResponse['data'].containsKey('total')) {
        setState(() => _favoritesCount = favoritesResponse['data']['total']);
      }
    } catch (e) {}

    try {
      final ordersResponse = await widget.apiService.get(
        '/v1/user/orders',
        requiresAuth: true,
      );
      if (ordersResponse.containsKey('data') &&
          ordersResponse['data'].containsKey('total')) {
        setState(() => _ordersCount = ordersResponse['data']['total']);
      }
    } catch (e) {}
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: source, maxWidth: 500, maxHeight: 500, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final response = await widget.apiService.uploadImage(
        '/v1/user/profile/profile-image',
        File(pickedFile.path),
        requiresAuth: true,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _userData!['profile_image'] = response['data']['profile_image'];
          _isUploadingImage = false;
        });
        _showSnackBar('تم تحديث الصورة الشخصية بنجاح', primaryBlue);
      } else {
        setState(() => _isUploadingImage = false);
        _showSnackBar(
            response['message'] ?? 'حدث خطأ في رفع الصورة', Colors.red);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar('حدث خطأ في رفع الصورة', Colors.red);
    }
  }

  Future<void> _deleteProfileImage() async {
    final confirm = await _showConfirmationDialog(
        'حذف الصورة', 'هل أنت متأكد من حذف الصورة الشخصية؟');
    if (confirm != true) return;

    setState(() => _isUploadingImage = true);
    try {
      await widget.apiService
          .delete('/v1/user/profile/profile-image', requiresAuth: true);
      if (mounted) {
        setState(() {
          _userData!['profile_image'] = null;
          _isUploadingImage = false;
        });
        _showSnackBar('تم حذف الصورة الشخصية بنجاح', primaryBlue);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar('حدث خطأ في حذف الصورة', Colors.red);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تحديث الصورة الشخصية',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library_rounded,
                  label: 'المعرض',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfileImage(ImageSource.gallery);
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'الكاميرا',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _updateProfileImage(ImageSource.camera);
                  },
                ),
                if (_userData?['profile_image'] != null)
                  _buildImageOption(
                    icon: Icons.delete_rounded,
                    label: 'حذف',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteProfileImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(title,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, fontSize: 20, color: darkColor)),
          content: Text(content,
              style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, color: mediumGray)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تأكيد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
        elevation: 5,
      ));
  }

  Future<void> _logout() async {
    final confirm = await _showConfirmationDialog(
        'تسجيل خروج', 'هل أنت متأكد من تسجيل الخروج؟');
    if (confirm == true) widget.onLogout();
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isConfirming = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_rounded,
                      color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Text('حذف الحساب',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 20)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade50, Colors.red.shade100],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك نهائياً.',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.red.shade800,
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.cairo(color: darkColor),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: GoogleFonts.cairo(color: mediumGray),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_outline,
                            color: Colors.red, size: 20),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: lightGray,
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'الرجاء إدخال كلمة المرور'
                        : (v.length < 6
                            ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                            : null),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () =>
                        setStateDialog(() => isConfirming = !isConfirming),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              isConfirming ? Colors.red : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        gradient: isConfirming
                            ? LinearGradient(colors: [
                                Colors.red.shade50,
                                Colors.red.shade100
                              ])
                            : null,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isConfirming
                                    ? Colors.red
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isConfirming
                                  ? Colors.red
                                  : Colors.transparent,
                            ),
                            child: isConfirming
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'أنا متأكد من رغبتي في حذف حسابي نهائياً',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: isConfirming
                                    ? Colors.red.shade800
                                    : mediumGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600, color: mediumGray)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() && isConfirming)
                    Navigator.pop(context, true);
                  else if (!isConfirming)
                    _showSnackBar(
                        'الرجاء تأكيد رغبتك في حذف الحساب', Colors.orange);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('حذف الحساب',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      try {
        final response = await widget.apiService.delete(
          '/v1/user/profile/account',
          requiresAuth: true,
          data: {'password': passwordController.text, 'confirmation': 'yes'},
        );
        _showSnackBar(
            response['message'] ?? 'تم حذف الحساب بنجاح', primaryBlue);
        widget.onLogout();
      } catch (e) {
        _showSnackBar('حدث خطأ في حذف الحساب', Colors.red);
      }
    }
  }

  void _copyReferralCode() {
    final referralCode = _userData?['referral_code'] ?? '';
    if (referralCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: referralCode));
      _showSnackBar('تم نسخ رمز الدعوة: $referralCode', primaryBlue);
      HapticFeedback.lightImpact();
    }
  }

  void _shareReferralCode() {
    final referralCode = _userData?['referral_code'] ?? '';
    if (referralCode.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -10)),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseAnimationController.value * 0.05),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.12),
                        secondaryBlue.withOpacity(0.06)
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      size: 50, color: primaryBlue),
                ),
              ),
              const SizedBox(height: 20),
              Text('رمز الدعوة الخاص بك',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
              const SizedBox(height: 10),
              Text(
                'ادعُ أصدقائك واحصل على 5 نقاط لكل صديق يسجل باستخدام رمزك',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: mediumGray, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.08),
                      secondaryBlue.withOpacity(0.04)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border:
                      Border.all(color: primaryBlue.withOpacity(0.2), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        referralCode,
                        style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            letterSpacing: 4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('انسخ هذا الرمز وشاركه مع أصدقائك',
                        style:
                            GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        _showSnackBar(
                            'تم نسخ الرمز: $referralCode', primaryBlue);
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text('نسخ',
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: Text('إغلاق',
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: _isLoading
          ? _buildShimmerLoading()
          : (_errorMessage != null
              ? _buildErrorWidget()
              : _buildProfileContent()),
    );
  }

  Widget _buildProfileContent() {
    final hasImage = _userData?['profile_image'] != null &&
        _userData!['profile_image'].isNotEmpty;
    final userType =
        _userData?['user_type'] == 'customer' ? 'عميل عادي' : 'تاجر';
    final createdAt = _userData?['created_at'] != null
        ? DateTime.parse(_userData!['created_at']).toString().split(' ')[0]
        : '';
    final points = _userData?['points'] ?? 0;
    final referralCode = _userData?['referral_code'] ?? '';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: cardWhite,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, secondaryBlue, Color(0xFF1E3A8A)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -60,
                    right: -40,
                    child: AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimationController.value * 0.05),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -60,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03),
                      ),
                    ),
                  ),
                  ...List.generate(12, (index) {
                    return Positioned(
                      top: 20.0 + (index * 15),
                      right: 10.0 + (index % 3 * 20),
                      child: AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity:
                                0.3 + (_pulseAnimationController.value * 0.3),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFE0E7FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _isUploadingImage
                                      ? Container(
                                          color: Colors.black54,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3),
                                          ),
                                        )
                                      : (hasImage
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  _userData!['profile_image'],
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: primaryBlue,
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: Colors.white,
                                                child: Icon(Icons.person,
                                                    size: 55,
                                                    color:
                                                        Colors.grey.shade400),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.white,
                                              child: Icon(Icons.person,
                                                  size: 55,
                                                  color: Colors.grey.shade400),
                                            )),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFA726), size: 24),
                                    const SizedBox(width: 6),
                                    Text(
                                      points.toString(),
                                      style: GoogleFonts.cairo(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFA726),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'نقاطي',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: mediumGray,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade100,
                                  Colors.grey.shade200
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _copyReferralCode,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.card_giftcard_rounded,
                                            color: primaryBlue, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          referralCode,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: primaryBlue,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: primaryBlue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.copy_rounded,
                                              size: 14, color: primaryBlue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'رمز الدعوة (اضغط للنسخ)',
                                      style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: mediumGray,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
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
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 22),
                onPressed: _shareReferralCode,
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      _userData?['name'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryBlue.withOpacity(0.12),
                            secondaryBlue.withOpacity(0.06)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: primaryBlue.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_pulseAnimationController.value * 0.2),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            userType,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatCard(
                            Icons.favorite_rounded,
                            _favoritesCount.toString(),
                            'مفضلة',
                            Colors.red.shade400,
                            0),
                        const SizedBox(width: 12),
                        _buildStatCard(
                            Icons.shopping_bag_rounded,
                            _ordersCount.toString(),
                            'طلبات',
                            Colors.blue.shade400,
                            1),
                        const SizedBox(width: 12),
                        _buildStatCard(Icons.calendar_today_rounded, createdAt,
                            'تاريخ التسجيل', Colors.orange.shade400, 2),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCustomTabs(),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
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
                      child: _selectedTab == 0
                          ? _buildPersonalInfoSection()
                          : _buildSettingsSection(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'معلومات شخصية', Icons.person_outline_rounded),
          _buildTabItem(1, 'الإعدادات', Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [primaryBlue, secondaryBlue])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final items = [
      {
        'icon': Icons.email_rounded,
        'title': 'البريد الإلكتروني',
        'value': _userData?['email'] ?? '',
        'color': Colors.blue
      },
      {
        'icon': Icons.phone_rounded,
        'title': 'رقم الهاتف',
        'value': _userData?['phone'] ?? '',
        'color': Colors.green
      },
      {
        'icon': Icons.location_on_rounded,
        'title': 'المحافظة',
        'value': _userData?['governorate'] ?? '',
        'color': Colors.orange
      },
      {
        'icon': Icons.location_city_rounded,
        'title': 'المنطقة',
        'value': _userData?['district'] ?? '',
        'color': Colors.purple
      },
      {
        'icon': Icons.home_rounded,
        'title': 'العنوان',
        'value': _userData?['address'] ?? '',
        'color': Colors.teal
      },
    ];

    return Column(
      key: const ValueKey('personal_info'),
      children: List.generate(
        items.length,
        (index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)), child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildInfoCard(
              items[index]['icon'] as IconData,
              items[index]['title'] as String,
              items[index]['value'] as String,
              items[index]['color'] as Color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {

    final settingsItems = [

      if (_userData?['user_type'] == 'customer')
        {
          'icon': Icons.business_rounded,
          'title': 'طلب فتح حساب شركة / تاجر',
          'color': primaryBlue,
          'onTap': () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestCompanyScreen(
                  authService: widget.authService,
                  apiService: widget.apiService, // ✅ apiService موجود في ProfileScreen
                ),
              ),
            );
          },
        },
      {
        'icon': Icons.edit_rounded,
        'title': 'تعديل الملف الشخصي',
        'color': primaryBlue,
        'onTap': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(
                  userData: _userData!, apiService: widget.apiService),
            ),
          );
          if (result == true) _fetchProfile();
        },
      },
      {
        'icon': Icons.lock_rounded,
        'title': 'تغيير كلمة المرور',
        'color': Colors.orange,
        'onTap': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ChangePasswordScreen(apiService: widget.apiService)),
          );
          if (result == true)
            _showSnackBar('تم تغيير كلمة المرور بنجاح', primaryBlue);
        },
      },
      {
        'icon': Icons.shopping_bag_rounded,
        'title': 'طلباتي',
        'color': Colors.purple,
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrdersScreen(
                  apiService: widget.apiService,
                  authService: widget.authService),
            ),
          );
        },
      },
      {
        'icon': Icons.logout_rounded,
        'title': 'تسجيل خروج',
        'color': Colors.red.shade400,
        'onTap': _logout,
        'isDestructive': false,
      },
      {
        'icon': Icons.delete_forever_rounded,
        'title': 'حذف الحساب',
        'color': Colors.red.shade600,
        'onTap': _deleteAccount,
        'isDestructive': true,
      },
    ];

    return Column(
      key: const ValueKey('settings'),
      children: List.generate(
        settingsItems.length,
        (index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)), child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildActionButton(
              settingsItems[index]['icon'] as IconData,
              settingsItems[index]['title'] as String,
              settingsItems[index]['color'] as Color,
              settingsItems[index]['onTap'] as VoidCallback,
              isDestructive:
                  settingsItems[index]['isDestructive'] as bool? ?? false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color, int index) {
    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 600 + (index * 200)),
        curve: Curves.easeOut,
        builder: (context, double animValue, child) {
          return Opacity(
            opacity: animValue,
            child:
                Transform.scale(scale: 0.8 + (0.2 * animValue), child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardWhite, color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08)
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 12),
              Text(value,
                  style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: mediumGray,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardWhite, color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: mediumGray,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.chevron_left_rounded,
                size: 18, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String title, Color color, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isDestructive
                ? LinearGradient(
                    colors: [Colors.red.shade50, Colors.red.shade100])
                : LinearGradient(
                    colors: [cardWhite, color.withOpacity(0.03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isDestructive
                    ? Colors.red.shade200
                    : color.withOpacity(0.2),
                width: 1),
            boxShadow: [
              BoxShadow(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.08)
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? Colors.red.shade700 : darkColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 300),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(25)),
                  child: Column(
                    children: [
                      Container(
                          height: 24,
                          width: 180,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 16),
                      Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 24),
                      Row(
                        children: List.generate(
                          3,
                          (index) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              height: 90,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(25))),
                      const SizedBox(height: 20),
                      ...List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          height: 75,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.red.shade50, Colors.red.shade100]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 64, color: Colors.red.shade300),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: GoogleFonts.cairo(
                    fontSize: 16, color: mediumGray, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  shadowColor: primaryBlue.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
