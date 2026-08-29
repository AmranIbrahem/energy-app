// lib/screens/profile/edit_profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final ApiService apiService;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.apiService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGovernorate;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = widget.userData['name'] ?? '';
    _phoneController.text = widget.userData['phone'] ?? '';
    _selectedGovernorate = widget.userData['governorate'];
    _districtController.text = widget.userData['district'] ?? '';
    _addressController.text = widget.userData['address'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await widget.apiService.put(
        '/v1/user/profile',
        requiresAuth: true,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'governorate': _selectedGovernorate,
          'district': _districtController.text.trim(),
          'address': _addressController.text.trim(),
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(response['message'],
                          style: GoogleFonts.cairo(fontSize: 14))),
                ],
              ),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      response['message'] ?? 'حدث خطأ في تحديث البيانات',
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('حدث خطأ في الاتصال',
                    style: GoogleFonts.cairo(fontSize: 14)),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'تعديل الملف الشخصي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: Text(
                'حفظ',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryBlue.withOpacity(0.15),
                            secondaryBlue.withOpacity(0.08),
                          ],
                        ),
                        border: Border.all(color: primaryBlue, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.userData['profile_image'] != null
                            ? CachedNetworkImage(
                                imageUrl: widget.userData['profile_image'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person,
                                      size: 50, color: Colors.grey),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person,
                                      size: 50, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person,
                                    size: 50, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardWhite,
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
                        'لتغيير الصورة اذهب إلى حسابي ← صورة شخصية',
                        style:
                            GoogleFonts.cairo(fontSize: 11, color: mediumGray),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionHeader('المعلومات الشخصية'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'الاسم الكامل',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال الاسم الكامل';
                  if (value.length < 3)
                    return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'رقم الهاتف (مثال: +963933314341)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال رقم الهاتف';
                  if (!Helpers.isValidPhone(value))
                    return 'الرجاء إدخال رقم هاتف صحيح (يبدأ بـ +963)';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('العنوان'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGovernorate,
                decoration: _buildInputDecoration(
                    'المحافظة', Icons.location_city_rounded),
                dropdownColor: cardWhite,
                style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
                items: AppConstants.syrianGovernorates.map((gov) {
                  return DropdownMenuItem(
                    value: gov,
                    child: Text(gov,
                        style:
                            GoogleFonts.cairo(fontSize: 15, color: darkColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedGovernorate = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء اختيار المحافظة';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _districtController,
                label: 'المنطقة',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال المنطقة';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'العنوان التفصيلي',
                icon: Icons.home_outlined,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال العنوان';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: primaryBlue.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'حفظ التغييرات',
                          style: GoogleFonts.cairo(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.rtl,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      maxLines: maxLines,
      style: GoogleFonts.cairo(fontSize: 15, color: darkColor),
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: mediumGray, fontSize: 14),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryBlue.withOpacity(0.12),
              secondaryBlue.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: cardWhite,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
      ],
    );
  }
}
