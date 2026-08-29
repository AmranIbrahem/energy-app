// lib/screens/workshop/workshop_request_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/screens/workshop/workshop_history_screen.dart';
import 'package:GeniusHouse/screens/workshop/location_picker_screen.dart';
import 'package:intl/intl.dart';

class WorkshopRequestScreen extends StatefulWidget {
  final AuthService? authService;  // ✅ nullable
  final ApiService apiService;

  const WorkshopRequestScreen({
    super.key,
    this.authService,  // ✅ اختياري
    required this.apiService,
  });

  @override
  State<WorkshopRequestScreen> createState() => _WorkshopRequestScreenState();
}

class _WorkshopRequestScreenState extends State<WorkshopRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _problemsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customWorkshopTypeController = TextEditingController();
  final _customDateController = TextEditingController();
  final _customTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTimeOfDay;
  double? _latitude;
  double? _longitude;
  String _selectedAddress = '';

  List<dynamic> _workshops = [];
  Map<String, dynamic>? _selectedWorkshop;
  bool _isLoadingWorkshops = false;
  bool _isCustomWorkshop = false;

  List<dynamic> _workers = [];
  Map<String, dynamic>? _selectedWorker;
  bool _isLoadingWorkers = false;

  List<dynamic> _availableTimes = [];
  Map<String, dynamic>? _selectedTime;
  bool _isLoadingTimes = false;
  bool _useCustomTime = false;

  String _urgencyLevel = 'normal';
  List<File> _images = [];

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);

  // ✅ isGuest يتحقق من null
  bool get isGuest => widget.authService == null || !widget.authService!.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _loadWorkshops();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _problemsController.dispose();
    _descriptionController.dispose();
    _customWorkshopTypeController.dispose();
    _customDateController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

  IconData _getWorkshopIcon(String iconName) {
    final iconMap = {
      'tools': Icons.handyman_rounded,
      'wrench': Icons.build_rounded,
      'bolt': Icons.bolt_rounded,
      'plug': Icons.power_rounded,
      'industry': Icons.factory_rounded,
      'hammer': Icons.construction_rounded,
      'screwdriver': Icons.hardware_rounded,
      'house': Icons.home_rounded,
      'house-chimney': Icons.home_rounded,
      'solar-panel': Icons.solar_power_rounded,
      'fan': Icons.wind_power_rounded,
      'snowflake': Icons.ac_unit_rounded,
      'lightbulb': Icons.lightbulb_rounded,
      'fire': Icons.local_fire_department_rounded,
      'water': Icons.water_drop_rounded,
      'elevator': Icons.elevator_rounded,
    };
    return iconMap[iconName] ?? Icons.build_rounded;
  }

  Future<void> _loadWorkshops() async {
    setState(() => _isLoadingWorkshops = true);
    try {
      final response = await widget.apiService.get(
        '/v1/user/public/workshops',
        requiresAuth: false,
      );
      if (response['success'] == true) {
        setState(() {
          _workshops = response['data']['workshops'] ?? [];
        });
      }
    } catch (e) {
      print('❌ خطأ في جلب الورشات: $e');
    } finally {
      setState(() => _isLoadingWorkshops = false);
    }
  }

  Future<void> _loadWorkers(int workshopId) async {
    setState(() => _isLoadingWorkers = true);
    try {
      final response = await widget.apiService.get(
        '/v1/user/public/workshops/workers?workshop_id=$workshopId',
        requiresAuth: false,
      );
      if (response['success'] == true) {
        setState(() {
          _workers = response['data']['workers'] ?? [];
          _selectedWorker = null;
          _selectedTime = null;
          _availableTimes = [];
        });
      }
    } catch (e) {
      print('❌ خطأ في جلب العمال: $e');
    } finally {
      setState(() => _isLoadingWorkers = false);
    }
  }

  Future<void> _loadAvailableTimes(int workerId) async {
    setState(() => _isLoadingTimes = true);
    try {
      final response = await widget.apiService.get(
        '/v1/user/public/workers/available-times?worker_id=$workerId',
        requiresAuth: false,
      );
      if (response['success'] == true) {
        setState(() {
          _availableTimes = response['data']['available_times'] ?? [];
        });
      }
    } catch (e) {
      print('❌ خطأ في جلب الأوقات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTimes = false);
      }
    }
  }

  Future<void> _showWorkerRatings(Map<String, dynamic> worker) async {
    try {
      final response = await widget.apiService.get(
        '/v1/user/public/workers/ratings?worker_id=${worker['id']}',
        requiresAuth: false,
      );
      if (response['success'] == true) {
        _showRatingsBottomSheet(response['data']);
      }
    } catch (e) {
      print('❌ خطأ في جلب التقييمات: $e');
    }
  }

  Future<void> _showAvailableTimes(Map<String, dynamic> worker) async {
    await _loadAvailableTimes(worker['id']);
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الأوقات المتاحة',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkColor,
                                ),
                              ),
                              Text(
                                '${worker['full_name']}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoadingTimes
                        ? const Center(child: CircularProgressIndicator())
                        : _availableTimes.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy_rounded, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text('لا توجد أوقات متاحة', style: GoogleFonts.cairo(color: mediumGray)),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _useCustomTime = true);
                            },
                            child: Text('إدخال وقت يدوي', style: GoogleFonts.cairo(color: primaryBlue)),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableTimes.length,
                      itemBuilder: (context, index) {
                        final time = _availableTimes[index];
                        final isSelected = _selectedTime?['id'] == time['id'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedTime = time;
                              _useCustomTime = false;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue.withOpacity(0.1) : lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryBlue : Colors.grey.shade200,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: isSelected ? primaryBlue : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(time['day_name_ar'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: darkColor)),
                                      Text('${time['date'] ?? ''} - ${time['time_12h'] ?? ''}', style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  void _showRatingsBottomSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final worker = data['worker'];
        final ratings = data['ratings'] ?? [];
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقييمات ${worker['full_name']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: darkColor)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              Text(' ${worker['final_rating']} (${worker['total_ratings_count']} تقييم)', style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              Expanded(
                child: ratings.isEmpty
                    ? Center(child: Text('لا توجد تقييمات بعد', style: GoogleFonts.cairo(color: mediumGray)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: primaryBlue,
                                child: Text(rating['customer_name']?[0] ?? '؟', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rating['customer_name'] ?? 'عميل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12))),
                              Row(children: List.generate(5, (i) => Icon(i < rating['rating'] ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 14))),
                            ],
                          ),
                          if (rating['rating_comment'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(rating['rating_comment'], style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _selectedAddress = result['address'];
        _addressController.text = result['address'];
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _images = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _customDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTimeOfDay = picked;
        _customTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkshop == null) {
      _showSnackBar('الرجاء اختيار نوع الورشة', Colors.red);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      String workshopType;
      if (_isCustomWorkshop) {
        workshopType = _customWorkshopTypeController.text.trim();
        if (workshopType.isEmpty) {
          _showSnackBar('الرجاء كتابة نوع الورشة', Colors.red);
          setState(() => _isSubmitting = false);
          return;
        }
      } else {
        workshopType = _selectedWorkshop!['name'];
      }

      final Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _selectedAddress.isNotEmpty ? _selectedAddress : _addressController.text.trim(),
        'workshop_type': workshopType,
        'urgency_level': _urgencyLevel,
        'problems': _problemsController.text.trim().isNotEmpty ? _problemsController.text.trim() : null,
        'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      };

      if (_latitude != null && _longitude != null) {
        body['latitude'] = _latitude;
        body['longitude'] = _longitude;
      }

      if (_selectedWorker != null) {
        body['assigned_worker_id'] = _selectedWorker!['id'];
      }

      if (_useCustomTime) {
        if (_selectedDate != null && _selectedTimeOfDay != null) {
          final String datePart = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          final String timePart = _selectedTimeOfDay!.format(context);
          final DateTime combinedDateTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$datePart $timePart');
          body['booking_datetime'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(combinedDateTime);
        } else if (_customDateController.text.isNotEmpty && _customTimeController.text.isNotEmpty) {
          try {
            final String datePart = _customDateController.text.trim();
            final String timePart = _customTimeController.text.trim();
            final DateTime combinedDateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$datePart $timePart');
            body['booking_datetime'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(combinedDateTime);
          } catch (e) {
            body['booking_datetime'] = '${_customDateController.text.trim()} ${_customTimeController.text.trim()}:00';
          }
        }
      } else if (_selectedTime != null) {
        String rawDatetime = _selectedTime!['available_datetime'];
        try {
          DateTime parsedDate = DateTime.parse(rawDatetime);
          body['booking_datetime'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
        } catch (e) {
          body['booking_datetime'] = rawDatetime;
        }
      }

      print('📦 الجسم المرسل: $body');

      String endpoint;
      bool requiresAuth;
      if (isGuest) {
        endpoint = '/v1/user/public/workshop-requests';
        requiresAuth = false;
      } else {
        endpoint = '/v1/user/workshop-requests';
        requiresAuth = true;
      }

      final response = await widget.apiService.post(
        endpoint,
        data: body,
        requiresAuth: requiresAuth,
        files: _images.isNotEmpty ? _images : null,
      );

      print('📡 استجابة الإرسال: $response');

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (response['success'] == true) {
          _showSnackBar('تم إرسال طلب الورشة بنجاح 🎉', successGreen);
          _clearForm();
        } else {
          _showSnackBar(response['message'] ?? 'فشل إرسال الطلب', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar('حدث خطأ في الاتصال: $e', Colors.red);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _problemsController.clear();
    _descriptionController.clear();
    _customWorkshopTypeController.clear();
    _customDateController.clear();
    _customTimeController.clear();
    setState(() {
      _selectedWorkshop = null;
      _selectedWorker = null;
      _selectedTime = null;
      _selectedAddress = '';
      _latitude = null;
      _longitude = null;
      _urgencyLevel = 'normal';
      _images = [];
      _isCustomWorkshop = false;
      _useCustomTime = false;
      _workers = [];
      _selectedDate = null;
      _selectedTimeOfDay = null;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == successGreen ? Icons.check_circle_rounded : Icons.info_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
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
        title: Text(
          'طلب ورشة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ زر السجلات السابقة (للمسجلين فقط)
                if (!isGuest) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkshopHistoryScreen(
                                authService: widget.authService!,  // ✅ !
                                apiService: widget.apiService,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.history_rounded, color: primaryBlue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'سجل الطلبات السابقة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: mediumGray, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // ✅ معلومات العميل
                _buildSectionTitle('معلومات العميل', Icons.person_outline_rounded),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _nameController,
                  label: 'الاسم الكامل *',
                  hint: 'أدخل اسمك الكامل',
                  icon: Icons.person_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الموبايل *',
                  hint: 'مثال: 0991234567',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الموبايل مطلوب' : null,
                ),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _addressController,
                  label: 'العنوان بالتفصيل *',
                  hint: 'اكتب العنوان هنا أو اختر من الخريطة',
                  icon: Icons.location_on_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: Text(
                      'تحديد موقعي على الخريطة (اختياري)',
                      style: GoogleFonts.cairo(color: primaryBlue, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ نوع الخدمة المطلوبة
                _buildSectionTitle('نوع الخدمة المطلوبة', Icons.build_rounded),
                const SizedBox(height: 12),
                if (_isLoadingWorkshops)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _workshops.length,
                    itemBuilder: (context, index) {
                      final workshop = _workshops[index];
                      final isSelected = _selectedWorkshop?['id'] == workshop['id'];
                      final iconName = workshop['icon'] ?? 'tools';
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkshop = workshop;
                            _isCustomWorkshop = workshop['name'] == 'أخرى';
                            _selectedWorker = null;
                            _selectedTime = null;
                            _useCustomTime = false;
                            _workers = [];
                          });
                          if (workshop['name'] != 'أخرى') {
                            _loadWorkers(workshop['id']);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : cardWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? primaryBlue : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getWorkshopIcon(iconName),
                                color: isSelected ? Colors.white : primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                workshop['name'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : darkColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                if (_isCustomWorkshop) ...[
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _customWorkshopTypeController,
                    label: 'اكتب نوع الورشة',
                    hint: 'أدخل نوع الورشة المطلوبة',
                    icon: Icons.edit_rounded,
                  ),
                ],

                // ✅ العمال (اختياري)
                if (_selectedWorkshop != null && !_isCustomWorkshop) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('اختر العامل (اختياري)', Icons.person_search_rounded),
                  const SizedBox(height: 10),
                  if (_isLoadingWorkers)
                    const Center(child: CircularProgressIndicator())
                  else if (_workers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'لا يوجد عمال متاحين حالياً، يمكنك المتابعة بدون اختيار عامل',
                              style: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._workers.map((worker) => _buildWorkerCard(worker)),
                ],

                const SizedBox(height: 24),

                // ✅ تفاصيل إضافية
                _buildSectionTitle('تفاصيل إضافية', Icons.settings_rounded),
                const SizedBox(height: 12),

                Text('الوقت المختار:', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13, color: mediumGray)),
                const SizedBox(height: 8),

                if (_useCustomTime) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _customDateController,
                              label: 'التاريخ',
                              hint: 'انقر لاختيار التاريخ',
                              icon: Icons.calendar_today_rounded,
                              readOnly: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickTime,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _customTimeController,
                              label: 'الوقت',
                              hint: 'انقر لاختيار الوقت',
                              icon: Icons.access_time_rounded,
                              readOnly: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (_selectedTime != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: successGreen),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedTime!['day_name_ar']} - ${_selectedTime!['date']} - ${_selectedTime!['time_12h']}',
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_rounded, color: mediumGray),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'لم يتم اختيار وقت، يمكنك المتابعة أو إدخال وقت يدوي',
                            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!_useCustomTime) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useCustomTime = true;
                        _selectedTime = null;
                      });
                    },
                    child: Text('إدخال وقت يدوي', style: GoogleFonts.cairo(color: primaryBlue, fontSize: 12)),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _useCustomTime = false);
                    },
                    child: Text('إلغاء الوقت اليدوي', style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
                  ),
                ],

                const SizedBox(height: 16),

                Text('مستوى الاستعجال:', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13, color: mediumGray)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _urgencyLevel = 'normal'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _urgencyLevel == 'normal' ? primaryBlue.withOpacity(0.1) : cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _urgencyLevel == 'normal' ? primaryBlue : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.schedule_rounded, color: _urgencyLevel == 'normal' ? primaryBlue : mediumGray),
                              const SizedBox(height: 4),
                              Text('عادي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _urgencyLevel = 'urgent'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _urgencyLevel == 'urgent' ? Colors.red.withOpacity(0.1) : cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _urgencyLevel == 'urgent' ? Colors.red : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.priority_high_rounded, color: _urgencyLevel == 'urgent' ? Colors.red : mediumGray),
                              const SizedBox(height: 4),
                              Text('مستعجل جداً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ وصف المشكلة
                _buildSectionTitle('وصف المشكلة', Icons.report_problem_rounded),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _problemsController,
                  label: 'وصف المشكلة / الأعطال (اختياري)',
                  hint: 'اذكر المشاكل التي تواجهها بالتفصيل',
                  icon: Icons.warning_amber_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'تفاصيل إضافية (اختياري)',
                  hint: 'وصف تفصيلي للحالة',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // ✅ إرفاق الوسائط
                _buildSectionTitle('إرفاق الوسائط (اختياري)', Icons.attach_file_rounded),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt_rounded, color: primaryBlue, size: 30),
                        const SizedBox(height: 8),
                        Text(
                          _images.isEmpty ? 'اضف صورة أو فيديو للعطل' : 'تم اختيار ${_images.length} صورة',
                          style: GoogleFonts.cairo(color: mediumGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ زر الإرسال
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded),
                        const SizedBox(width: 10),
                        Text(
                          'إرسال الطلب',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: darkColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
        prefixIcon: icon != null
            ? Icon(icon, color: primaryBlue.withOpacity(0.6), size: 20)
            : null,
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final isSelected = _selectedWorker?['id'] == worker['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue.withOpacity(0.1) : cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryBlue : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryBlue,
            child: Text(
              worker['full_name']?[0] ?? '؟',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker['full_name'] ?? '',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    Text(
                      ' ${worker['rating'] ?? 0}',
                      style: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedWorker = isSelected ? null : worker;
              });
            },
            child: Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? primaryBlue : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showAvailableTimes(worker),
            icon: const Icon(Icons.schedule_rounded, color: primaryBlue),
          ),
          IconButton(
            onPressed: () => _showWorkerRatings(worker),
            icon: const Icon(Icons.star_rounded, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}