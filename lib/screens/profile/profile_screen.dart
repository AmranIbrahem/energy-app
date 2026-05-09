// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/profile/edit_profile_screen.dart';
import 'package:energy_store_app/screens/profile/change_password_screen.dart';

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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  int _favoritesCount = 0;
  int _ordersCount = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _fetchProfile();
    _fetchStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل الملف الشخصي';
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
      if (favoritesResponse.containsKey('data') && favoritesResponse['data'].containsKey('total')) {
        setState(() => _favoritesCount = favoritesResponse['data']['total']);
      }
      // يمكن إضافة جلب عدد الطلبات عند توفر الـ API
    } catch (e) {}
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 500, maxHeight: 500, imageQuality: 80);
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
        _showSnackBar('تم تحديث الصورة الشخصية بنجاح', Colors.green);
      } else {
        setState(() => _isUploadingImage = false);
        _showSnackBar(response['message'] ?? 'حدث خطأ في رفع الصورة', Colors.red);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar('حدث خطأ في رفع الصورة', Colors.red);
    }
  }

  Future<void> _deleteProfileImage() async {
    final confirm = await _showConfirmationDialog('حذف الصورة', 'هل أنت متأكد من حذف الصورة الشخصية؟');
    if (confirm != true) return;

    setState(() => _isUploadingImage = true);
    try {
      await widget.apiService.delete('/v1/user/profile/profile-image', requiresAuth: true);
      if (mounted) {
        setState(() {
          _userData!['profile_image'] = null;
          _isUploadingImage = false;
        });
        _showSnackBar('تم حذف الصورة الشخصية بنجاح', Colors.green);
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showSnackBar('حدث خطأ في حذف الصورة', Colors.red);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          _buildBottomSheetTile(Icons.photo_library, 'اختيار من المعرض', () {
            Navigator.pop(context);
            _updateProfileImage(ImageSource.gallery);
          }),
          _buildBottomSheetTile(Icons.camera_alt, 'التقاط صورة', () {
            Navigator.pop(context);
            _updateProfileImage(ImageSource.camera);
          }),
          if (_userData?['profile_image'] != null)
            _buildBottomSheetTile(Icons.delete, 'حذف الصورة', () {
              Navigator.pop(context);
              _deleteProfileImage();
            }, isDestructive: true),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _buildBottomSheetTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : const Color(0xFF4CAF50)),
      title: Text(title, style: GoogleFonts.cairo(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('تأكيد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _logout() async {
    final confirm = await _showConfirmationDialog('تسجيل خروج', 'هل أنت متأكد من تسجيل الخروج؟');
    if (confirm == true) widget.onLogout();
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isConfirming = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('حذف الحساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك نهائياً.',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.red.shade700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: GoogleFonts.cairo(),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'الرجاء إدخال كلمة المرور' : (v.length < 6 ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Checkbox(value: isConfirming, onChanged: (value) => setStateDialog(() => isConfirming = value ?? false), activeColor: Colors.red),
                Expanded(child: Text('أنا متأكد من رغبتي في حذف حسابي نهائياً', style: GoogleFonts.cairo(fontSize: 12))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && isConfirming) Navigator.pop(context, true);
                else if (!isConfirming) _showSnackBar('الرجاء تأكيد رغبتك في حذف الحساب', Colors.orange);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('حذف الحساب', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final response = await widget.apiService.delete('/v1/user/profile/account', requiresAuth: true, data: {'password': passwordController.text, 'confirmation': 'yes'});
        _showSnackBar(response['message'] ?? 'تم حذف الحساب بنجاح', Colors.green);
        widget.onLogout();
      } catch (e) {
        _showSnackBar('حدث خطأ في حذف الحساب', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading ? _buildShimmerLoading() : (_errorMessage != null ? _buildErrorWidget() : _buildProfileContent()),
    );
  }

  Widget _buildProfileContent() {
    final hasImage = _userData?['profile_image'] != null && _userData!['profile_image'].isNotEmpty;
    final userType = _userData?['user_type'] == 'customer' ? 'عميل عادي' : 'تاجر';
    final createdAt = _userData?['created_at'] != null ? DateTime.parse(_userData!['created_at']).toString().split(' ')[0] : '';

    return CustomScrollView(
      slivers: [
        // Header with gradient and avatar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF4CAF50),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF4CAF50), const Color(0xFF1B5E20)]),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Stack(alignment: Alignment.bottomRight, children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)]),
                            child: ClipOval(
                              child: _isUploadingImage
                                  ? Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.white)))
                                  : (hasImage
                                  ? CachedNetworkImage(imageUrl: _userData!['profile_image'], fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey.shade200))
                                  : Container(color: Colors.white, child: Icon(Icons.person, size: 60, color: Colors.grey.shade400))),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 22, color: Color(0xFF4CAF50)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          leading: IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 10),
                Text(_userData?['name'] ?? '', style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
                  child: Text(userType, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF4CAF50))),
                ),
                const SizedBox(height: 24),
                // Statistics Row
                Row(children: [
                  _buildStatCard(Icons.favorite, _favoritesCount.toString(), 'مفضلة', Colors.red),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.shopping_bag, _ordersCount.toString(), 'طلبات', Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.calendar_today, createdAt, 'تاريخ التسجيل', Colors.orange),
                ]),
                const SizedBox(height: 24),
                // Info Cards
                _buildInfoCard(Icons.email_outlined, 'البريد الإلكتروني', _userData?['email'] ?? ''),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.phone_outlined, 'رقم الهاتف', _userData?['phone'] ?? ''),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.location_on_outlined, 'المحافظة', _userData?['governorate'] ?? ''),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.location_city_outlined, 'المنطقة', _userData?['district'] ?? ''),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.home_outlined, 'العنوان', _userData?['address'] ?? ''),
                const SizedBox(height: 24),
                // Action Buttons
                _buildActionButton(Icons.edit_outlined, 'تعديل الملف الشخصي', const Color(0xFF4CAF50), () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData!, apiService: widget.apiService)));
                  if (result == true) _fetchProfile();
                }),
                const SizedBox(height: 12),
                _buildActionButton(Icons.lock_outline, 'تغيير كلمة المرور', Colors.orange, () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen(apiService: widget.apiService)));
                  if (result == true) _showSnackBar('تم تغيير كلمة المرور بنجاح', Colors.green);
                }),
                const SizedBox(height: 12),
                _buildActionButton(
                  Icons.shopping_bag_outlined,
                  'طلباتي',
                  Colors.purple,
                      () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersScreen(
                          apiService: widget.apiService,
                          authService: widget.authService,
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchStatistics(); // تحديث الإحصائيات إذا لزم الأمر
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(Icons.logout, 'تسجيل خروج', Colors.red, _logout),
                const SizedBox(height: 12),
                _buildActionButton(Icons.delete_forever, 'حذف الحساب', Colors.red.shade700, _deleteAccount, isDestructive: true),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 22, color: const Color(0xFF4CAF50))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
        ])),
      ]),
    );
  }

  Widget _buildActionButton(IconData icon, String title, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDestructive ? Border.all(color: Colors.red.shade100) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red.shade700 : Colors.black87))),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(children: [
      const SizedBox(height: 220),
      Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [
          Container(height: 20, width: 150, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Container(height: 40, width: double.infinity, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Container(height: 40, width: double.infinity, color: Colors.grey.shade300),
        ])),
      ),
    ]);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _fetchProfile, icon: const Icon(Icons.refresh), label: Text('إعادة المحاولة', style: GoogleFonts.cairo()), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      ]),
    );
  }
}