// lib/screens/company/request_company_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RequestCompanyScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const RequestCompanyScreen({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  State<RequestCompanyScreen> createState() => _RequestCompanyScreenState();
}

class _RequestCompanyScreenState extends State<RequestCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameArController = TextEditingController();
  final _companyDescriptionArController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyWhatsappController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyCommercialRegisterController = TextEditingController();
  final _companyMapUrlController = TextEditingController();
  final _companyDistrictController = TextEditingController();

  String? _companyGovernorate;
  File? _companyLogo;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  static const Color primaryBlue = Color(0xFF1E3A8A);

  @override
  void dispose() {
    _companyNameArController.dispose();
    _companyDescriptionArController.dispose();
    _companyPhoneController.dispose();
    _companyWhatsappController.dispose();
    _companyAddressController.dispose();
    _companyCommercialRegisterController.dispose();
    _companyMapUrlController.dispose();
    _companyDistrictController.dispose();
    super.dispose();
  }

  Future<void> _pickCompanyLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) setState(() => _companyLogo = File(image.path));
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/user/company-request'),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';

      request.fields['company_name_ar'] = _companyNameArController.text.trim();
      request.fields['company_description_ar'] =
          _companyDescriptionArController.text.trim();
      request.fields['company_phone'] = _companyPhoneController.text.trim();
      request.fields['company_whatsapp'] =
          _companyWhatsappController.text.trim();
      request.fields['company_address'] = _companyAddressController.text.trim();
      request.fields['company_governorate'] = _companyGovernorate ?? '';
      request.fields['company_district'] =
          _companyDistrictController.text.trim();
      request.fields['company_commercial_register'] =
          _companyCommercialRegisterController.text.trim();
      request.fields['company_map_url'] = _companyMapUrlController.text.trim();

      if (_companyLogo != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'company_logo', _companyLogo!.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (mounted) {
        setState(() => _isLoading = false);
        if (data['success'] == true || data['data'] != null) {
          _showSuccess(data['message'] ?? 'تم تقديم الطلب بنجاح');
        } else {
          _showError(data['message'] ?? 'فشل تقديم الطلب');
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
          Text('تم تقديم الطلب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ]),
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context)),
        title: Text('طلب فتح حساب شركة',
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.business_rounded,
                      color: primaryBlue, size: 40)),
            ),
            const SizedBox(height: 16),
            Text('معلومات الشركة',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(
                _companyNameArController, 'اسم الشركة *', 'أدخل اسم الشركة'),
            const SizedBox(height: 14),
            _buildTextField(
                _companyDescriptionArController, 'وصف الشركة', 'وصف مختصر',
                maxLines: 2),
            const SizedBox(height: 14),
            _buildTextField(
                _companyPhoneController, 'هاتف الشركة', 'رقم الهاتف'),
            const SizedBox(height: 14),
            _buildTextField(
                _companyWhatsappController, 'واتساب الشركة', 'رقم الواتساب'),
            const SizedBox(height: 14),
            _buildTextField(
                _companyAddressController, 'عنوان الشركة', 'العنوان التفصيلي'),
            const SizedBox(height: 14),
            _buildDropdown(
                'المحافظة',
                _companyGovernorate,
                AppConstants.syrianGovernorates,
                (v) => setState(() => _companyGovernorate = v)),
            const SizedBox(height: 14),
            _buildTextField(_companyDistrictController, 'المنطقة', 'المنطقة'),
            const SizedBox(height: 14),
            _buildTextField(_companyCommercialRegisterController,
                'السجل التجاري', 'رقم السجل'),
            const SizedBox(height: 14),
            _buildTextField(_companyMapUrlController, 'رابط الخريطة',
                'https://maps.google.com/...'),
            const SizedBox(height: 14),
            _buildLogoPicker(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.send_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text('تقديم الطلب',
                                style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ]),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 14),
      decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none)),
      validator: label.contains('*')
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map((i) => DropdownMenuItem<String>(
                value: i,
                child: Text(i, style: GoogleFonts.cairo(fontSize: 14))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('شعار الشركة (اختياري)',
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickCompanyLogo,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300)),
          child: _companyLogo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_companyLogo!, fit: BoxFit.contain))
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 30, color: primaryBlue.withOpacity(0.6)),
                      const SizedBox(height: 4),
                      Text('انقر لاختيار الشعار',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: const Color(0xFF4B5563))),
                    ])),
        ),
      ),
    ]);
  }
}
