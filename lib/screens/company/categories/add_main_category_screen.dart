// lib/screens/company/categories/add_main_category_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddMainCategoryScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AddMainCategoryScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AddMainCategoryScreen> createState() => _AddMainCategoryScreenState();
}

class _AddMainCategoryScreenState extends State<AddMainCategoryScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color cardWhite = Color(0xFFFFFFFF);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late ApiService _apiService;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final firstChar = trimmed.characters.first;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
    return TextDirection.ltr;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showSnackBar('فشل اختيار الصورة', Colors.red);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_selectedImage != null) {
        final response = await _uploadCategoryWithImage();
        if (mounted) {
          if (response['error'] != true) {
            _showSnackBar(
              response['message'] ??
                  'تم إضافة التصنيف بنجاح. في انتظار موافقة الإدارة.',
              Colors.green,
            );
            Navigator.pop(context, true);
          } else {
            _showSnackBar(
                response['message'] ?? 'فشل إضافة التصنيف', Colors.red);
          }
        }
      } else {
        final response = await _apiService.post(
          '/v1/company/categories/main/store',
          requiresAuth: true,
          data: {
            'name_ar': _nameController.text.trim(),
            if (_descriptionController.text.trim().isNotEmpty)
              'description': _descriptionController.text.trim(),
          },
        );
        if (mounted) {
          if (response['error'] != true) {
            _showSnackBar(
              response['message'] ??
                  'تم إضافة التصنيف بنجاح. في انتظار موافقة الإدارة.',
              Colors.green,
            );
            Navigator.pop(context, true);
          } else {
            _showSnackBar(
                response['message'] ?? 'فشل إضافة التصنيف', Colors.red);
          }
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('فشل إضافة التصنيف: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _uploadCategoryWithImage() async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/company/categories/main/store'),
      );
      final headers = <String, String>{'Accept': 'application/json'};
      if (widget.authService.token != null) {
        headers['Authorization'] = 'Bearer ${widget.authService.token}';
      }
      request.headers.addAll(headers);
      request.fields['name_ar'] = _nameController.text.trim();
      if (_descriptionController.text.trim().isNotEmpty) {
        request.fields['description'] = _descriptionController.text.trim();
      }
      request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final response = http.Response(responseBody, streamedResponse.statusCode);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'error': true, 'message': 'خطأ في معالجة الرد من الخادم'};
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'error': true,
            'message': error['message'] ?? 'حدث خطأ في الخادم',
            'errors': error['errors'] ?? null,
          };
        } catch (e) {
          return {'error': true, 'message': 'حدث خطأ غير متوقع'};
        }
      }
    } catch (e) {
      return {'error': true, 'message': 'خطأ في رفع الصورة: $e'};
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          textDirection: _getTextDirection(message),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تنبيه هام',
                                style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue)),
                            const SizedBox(height: 4),
                            Text(
                              'التصنيفات المضافة تحتاج إلى موافقة الإدارة قبل ظهورها للعملاء.',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: mediumGray),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('اسم التصنيف *',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textDirection: _getTextDirection(_nameController.text),
                  textAlign: TextAlign.start,
                  style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'أدخل اسم التصنيف بالعربية',
                    hintStyle:
                        GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                    filled: true,
                    fillColor: cardWhite,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primaryBlue, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    prefixIcon:
                        const Icon(Icons.folder_rounded, color: primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'الرجاء إدخال اسم التصنيف';
                    if (value.trim().length < 2)
                      return 'اسم التصنيف يجب أن يكون حرفين على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('وصف التصنيف',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  textDirection: _getTextDirection(_descriptionController.text),
                  textAlign: TextAlign.start,
                  maxLines: 4,
                  style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'أدخل وصفاً للتصنيف (اختياري)...',
                    hintStyle:
                        GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                    filled: true,
                    fillColor: cardWhite,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: primaryBlue, width: 2)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                Text('صورة التصنيف',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkColor)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_selectedImage!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_rounded,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('اضغط لاختيار صورة',
                                  style: GoogleFonts.cairo(
                                      fontSize: 14, color: mediumGray)),
                              const SizedBox(height: 4),
                              Text('JPG, PNG, GIF (الحد الأقصى 2 ميجابايت)',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: primaryBlue.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: primaryBlue.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text('إضافة التصنيف',
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'إضافة قسم جديد',
        style: GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height);
    path.lineTo(size.width - 20, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
