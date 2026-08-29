// lib/screens/maintenance/maintenance_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';

class MaintenanceScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;
  final StorageService storageService;

  const MaintenanceScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.storageService,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _imageFile;
  String _supportType = 'team';
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

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
    _loadUserInfo();
    _fetchRequests();
  }

  void _loadUserInfo() {
    if (widget.authService.isAuthenticated) {
      final userData = widget.storageService.getUserDataMap();
      if (userData != null) {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _emailController.text = userData['email'] ?? '';
      }
    }
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);

    try {
      final response = await widget.apiService.fetchMaintenanceRequests();
      if (response.containsKey('data')) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response['data']);
        });
      }
    } catch (e) {
      print('Error fetching requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحميل الطلبات السابقة',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
  }

  Future<void> _submitRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء كتابة المشكلة التي تواجهها',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await widget.apiService.sendMaintenanceRequest(
        message: _messageController.text.trim(),
        type: _supportType,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        image: _imageFile,
      );

      if (response.containsKey('success') && response['success'] == true) {
        if (_supportType == 'ai' && response.containsKey('ai_solution')) {
          final aiSolution = response['ai_solution'] as String?;
          if (aiSolution != null && aiSolution.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _showAiSolutionDialog(aiSolution);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          response['message'] ?? 'تم إرسال طلب الصيانة بنجاح',
                          style: GoogleFonts.cairo())),
                ]),
                backgroundColor: primaryBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        response['message'] ?? 'تم إرسال طلب الصيانة بنجاح',
                        style: GoogleFonts.cairo())),
              ]),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        _messageController.clear();
        setState(() => _imageFile = null);
        await _fetchRequests();
      } else {
        throw Exception(response['message'] ?? 'حدث خطأ في إرسال الطلب');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text('حدث خطأ: ${e.toString()}',
                    style: GoogleFonts.cairo())),
          ]),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAiSolutionDialog(String solution) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.psychology_rounded,
                          size: 24, color: primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('حل المشكلة',
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text('تم الحل بواسطة الذكاء الاصطناعي',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: mediumGray)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.withOpacity(0.06),
                              Colors.purple.withOpacity(0.03)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(solution,
                            style: GoogleFonts.cairo(
                                fontSize: 14, height: 1.6, color: darkColor)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.06),
                              secondaryBlue.withOpacity(0.03)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: primaryBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'إذا لم يتم حل مشكلتك، يرجى التواصل مع فريق الدعم',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: primaryBlue)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('إغلاق',
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: mediumGray)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('مشكلة جديدة',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: primaryBlue),
              ),
              title: Text('التقاط صورة',
                  style: GoogleFonts.cairo(fontSize: 15, color: darkColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.photo_library_rounded, color: primaryBlue),
              ),
              title: Text('اختيار من المعرض',
                  style: GoogleFonts.cairo(fontSize: 15, color: darkColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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
        title: Text('طلب صيانة',
            style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoForm(),
                        const SizedBox(height: 16),
                        _buildMessageForm(),
                        const SizedBox(height: 16),
                        _buildImageSection(),
                        const SizedBox(height: 16),
                        _buildSupportTypeSelector(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 24),
                        _buildPreviousRequestsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('معلومات التواصل (اختياري)',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
              controller: _nameController,
              label: 'الاسم',
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              icon: Icons.phone_outlined,
              isLtr: true,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              icon: Icons.email_outlined,
              isLtr: true,
              keyboardType: TextInputType.emailAddress),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isLtr = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: mediumGray, fontSize: 13),
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: lightGray,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMessageForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded,
                    color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('تفاصيل المشكلة',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
            decoration: InputDecoration(
              hintText: 'اكتب مشكلتك بالتفصيل...',
              hintStyle:
                  GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: lightGray,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_rounded,
                    color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('صورة توضيحية',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
              const SizedBox(width: 8),
              Text('(اختياري)',
                  style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
            ],
          ),
          const SizedBox(height: 12),
          if (_imageFile == null)
            InkWell(
              onTap: _showImagePickerOptions,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: primaryBlue.withOpacity(0.2), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.03),
                    secondaryBlue.withOpacity(0.02)
                  ]),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          primaryBlue.withOpacity(0.1),
                          secondaryBlue.withOpacity(0.05)
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_photo_alternate_rounded,
                          size: 35, color: primaryBlue),
                    ),
                    const SizedBox(height: 8),
                    Text('انقر لإضافة صورة',
                        style: GoogleFonts.cairo(color: mediumGray)),
                  ],
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_imageFile!,
                      height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSupportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.12),
                    secondaryBlue.withOpacity(0.06)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded,
                    color: primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text('إرسال إلى',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSupportOption(
                  title: 'فريق الدعم',
                  icon: Icons.support_agent_rounded,
                  isSelected: _supportType == 'team',
                  onTap: () => setState(() => _supportType = 'team'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSupportOption(
                  title: 'الذكاء الاصطناعي',
                  icon: Icons.psychology_rounded,
                  isSelected: _supportType == 'ai',
                  onTap: () => setState(() => _supportType = 'ai'),
                ),
              ),
            ],
          ),
          if (_supportType == 'ai')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.purple.withOpacity(0.06),
                    Colors.purple.withOpacity(0.03)
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'سيتم حل مشكلتك تلقائياً بواسطة الذكاء الاصطناعي فور إرسالها',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: Colors.purple)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [
                  primaryBlue.withOpacity(0.08),
                  secondaryBlue.withOpacity(0.04)
                ])
              : null,
          color: isSelected ? null : lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? primaryBlue.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [
                        primaryBlue.withOpacity(0.15),
                        secondaryBlue.withOpacity(0.08)
                      ])
                    : null,
                color: isSelected ? null : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? primaryBlue : Colors.grey.shade600,
                  size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryBlue : mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          shadowColor: primaryBlue.withOpacity(0.4),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text('إرسال الطلب',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildPreviousRequestsSection() {
    if (_requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded,
                  color: primaryBlue, size: 18),
            ),
            const SizedBox(width: 10),
            Text('طلباتك السابقة',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            final request = _requests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: primaryBlue.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: request['type'] == 'ai'
                              ? LinearGradient(colors: [
                                  Colors.purple.withOpacity(0.08),
                                  Colors.purple.withOpacity(0.04)
                                ])
                              : LinearGradient(colors: [
                                  primaryBlue.withOpacity(0.08),
                                  secondaryBlue.withOpacity(0.04)
                                ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                request['type'] == 'ai'
                                    ? Icons.psychology_rounded
                                    : Icons.support_agent_rounded,
                                size: 14,
                                color: request['type'] == 'ai'
                                    ? Colors.purple
                                    : primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              request['type'] == 'ai'
                                  ? 'ذكاء اصطناعي'
                                  : 'فريق الدعم',
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: request['type'] == 'ai'
                                      ? Colors.purple
                                      : primaryBlue),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: request['status'] == 'resolved'
                              ? Colors.green.withOpacity(0.08)
                              : Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          request['status'] == 'resolved'
                              ? 'تم الحل'
                              : 'قيد المعالجة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: request['status'] == 'resolved'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request['message'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 13, color: darkColor)),
                  if (request['ai_response'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.purple.withOpacity(0.05),
                          Colors.purple.withOpacity(0.02)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology_rounded,
                              size: 16, color: Colors.purple),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(request['ai_response'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: Colors.purple)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
