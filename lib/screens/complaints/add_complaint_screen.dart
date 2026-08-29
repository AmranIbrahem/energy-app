// lib/screens/complaints/add_complaint_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/constants.dart';

class AddComplaintScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AddComplaintScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);

  @override
  void initState() {
    super.initState();
    if (widget.authService.isAuthenticated) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final userData = await widget.authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/v1/user/public/complaints'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (widget.authService.token != null)
            'Authorization': 'Bearer ${widget.authService.token}',
        },
        body: jsonEncode({
          'message': _messageController.text.trim(),
          'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() => _isLoading = false);
        if (data['success'] == true) {
          _showSuccess(data['message'] ?? 'تم تقديم الشكوى بنجاح');
        } else {
          _showError(data['message'] ?? 'فشل تقديم الشكوى');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('حدث خطأ في الاتصال');
      }
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: primaryBlue, size: 28),
          const SizedBox(width: 10),
          Text('تم بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ]),
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.cairo()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: () => Navigator.pop(context)),
        title: Text('تقديم شكوى', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // أيقونة
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.feedback_rounded, color: primaryBlue, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            Text('اكتب شكواك أو اقتراحك', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('نحن هنا للاستماع إليك. سيتم مراجعة شكواك في أقرب وقت ممكن.', style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF4B5563))),
            const SizedBox(height: 20),

            // حقل الشكوى (مطلوب)
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'الشكوى *',
                hintText: 'اكتب شكواك أو اقتراحك هنا...',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء كتابة الشكوى' : (v.trim().length < 10 ? 'الشكوى يجب أن تكون 10 أحرف على الأقل' : null),
            ),
            const SizedBox(height: 16),

            // الاسم (اختياري)
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'الاسم (اختياري)',
                hintText: 'اسمك الكامل',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // الإيميل (اختياري)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني (اختياري)',
                hintText: 'example@email.com',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // الهاتف (اختياري)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                hintText: '09XXXXXXXX',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // زر الإرسال
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('إرسال الشكوى', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}