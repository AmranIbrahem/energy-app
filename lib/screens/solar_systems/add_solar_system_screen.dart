// lib/screens/solar_systems/add_solar_system_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/solar_system_service.dart';

class AddSolarSystemScreen extends StatefulWidget {
  final AuthService authService;

  const AddSolarSystemScreen({
    super.key,
    required this.authService,
  });

  @override
  State<AddSolarSystemScreen> createState() => _AddSolarSystemScreenState();
}

class _AddSolarSystemScreenState extends State<AddSolarSystemScreen>
    with TickerProviderStateMixin {
  late SolarSystemService _solarSystemService;
  final _formKey = GlobalKey<FormState>();
  final String _baseUrl = 'https://nexsy.shop';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseAnimationController;
  late AnimationController _progressAnimationController;
  late AnimationController _submitAnimationController;

  double _formProgress = 0.0;
  final int _totalSections = 5;

  late String _installationDate = '';
  bool _isNew = true;
  String? _previousIssues;
  String? _notes;

  int _panelsCount = 0;
  double _panelWattage = 0;
  String? _panelBrand;
  File? _panelImage;

  String? _inverterType;
  double _inverterPower = 0;
  int _inverterCount = 1;
  String? _inverterBrand;
  File? _inverterImage;

  int _batteriesCount = 0;
  double _batteryCapacity = 0;
  String? _batteryType;
  String? _batteryBrand;
  File? _batteryImage;

  String? _detailsNotes;

  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _solarSystemService = SolarSystemService(
      baseUrl: _baseUrl,
      authService: widget.authService,
    );
    _installationDate = DateTime.now().toIso8601String().split('T').first;

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _submitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateFormProgress();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _progressAnimationController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }

  void _updateFormProgress() {
    int completedSections = 0;
    if (_installationDate.isNotEmpty) completedSections++;
    if (_panelsCount > 0 && _panelWattage > 0) completedSections++;
    if (_inverterType != null && _inverterPower > 0) completedSections++;
    if (_batteriesCount > 0 && _batteryCapacity > 0) completedSections++;
    completedSections++;

    setState(() => _formProgress = completedSections / _totalSections);
    _progressAnimationController.forward(from: 0.0);
  }

  Future<void> _pickImage(
      ImageSource source, Function(File) onImagePicked) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => onImagePicked(File(pickedFile.path)));
      _updateFormProgress();
    }
  }

  Widget _buildImagePicker(
      String title, File? imageFile, Function(File) onImagePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 10),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, double value, child) =>
              Transform.scale(scale: value, child: child),
          child: GestureDetector(
            onTap: () => _showImageSourceDialog(
                (source) => _pickImage(source, onImagePicked)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: imageFile != null
                      ? [Colors.grey.shade100, Colors.grey.shade200]
                      : [
                          primaryBlue.withOpacity(0.04),
                          secondaryBlue.withOpacity(0.08)
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: imageFile != null
                      ? Colors.grey.shade300
                      : primaryBlue.withOpacity(0.25),
                  width: 2,
                ),
                boxShadow: imageFile != null
                    ? [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: imageFile != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(imageFile, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => onImagePicked(File(''))),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text('اضغط للتغيير',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12, color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale:
                                  1.0 + (_pulseAnimationController.value * 0.1),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryBlue.withOpacity(0.15),
                                  secondaryBlue.withOpacity(0.08)
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_photo_alternate_rounded,
                                size: 35, color: primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('اضغط لاختيار صورة',
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: primaryBlue)),
                        const SizedBox(height: 4),
                        Text('PNG, JPG, JPEG',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(Function(ImageSource) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
            Text('اختر مصدر الصورة',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'الكاميرا',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(ImageSource.gallery);
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

  Widget _buildImageSourceOption({
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
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child));
        },
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _submitAnimationController.forward();

      setState(() => _isLoading = true);

      final result = await _solarSystemService.addSolarSystem(
        installationDate: _installationDate,
        isNew: _isNew,
        previousIssues: _previousIssues,
        notes: _notes,
        panelsCount: _panelsCount,
        panelWattage: _panelWattage,
        panelBrand: _panelBrand,
        panelImage: _panelImage,
        inverterType: _inverterType,
        inverterPower: _inverterPower,
        inverterCount: _inverterCount,
        inverterBrand: _inverterBrand,
        inverterImage: _inverterImage,
        batteriesCount: _batteriesCount,
        batteryCapacity: _batteryCapacity,
        batteryType: _batteryType,
        batteryBrand: _batteryBrand,
        batteryImage: _batteryImage,
        detailsNotes: _detailsNotes,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(result['message'], style: GoogleFonts.cairo())),
              ],
            ),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(20),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(result['message'], style: GoogleFonts.cairo())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                    scale: 1.0 + (_pulseAnimationController.value * 0.1),
                    child: child);
              },
              child: const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.yellow, size: 26),
            ),
            const SizedBox(width: 10),
            Text('إضافة منظومة جديدة',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildProgressBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('معلومات أساسية',
                              Icons.info_outline_rounded, Colors.blue, 0),
                          const SizedBox(height: 15),
                          _buildDatePicker(),
                          const SizedBox(height: 15),
                          _buildSwitchTile(),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'أعطال سابقة (اختياري)',
                              Icons.report_problem_outlined,
                              (value) => _previousIssues = value,
                              maxLines: 2),
                          const SizedBox(height: 15),
                          _buildTextField('ملاحظات (اختياري)',
                              Icons.notes_rounded, (value) => _notes = value,
                              maxLines: 2),
                          const SizedBox(height: 30),
                          _buildSectionHeader('الألواح الشمسية',
                              Icons.solar_power_rounded, Colors.orange, 1),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'عدد الألواح', Icons.grid_view_rounded, (value) {
                            _panelsCount = value;
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'قدرة اللوح (واط)', Icons.bolt_rounded, (value) {
                            _panelWattage = value.toDouble();
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'ماركة الألواح (اختياري)',
                              Icons.branding_watermark_outlined,
                              (value) => _panelBrand = value),
                          const SizedBox(height: 15),
                          _buildImagePicker('صورة الألواح', _panelImage,
                              (file) => setState(() => _panelImage = file)),
                          const SizedBox(height: 30),
                          _buildSectionHeader('الانفرتر', Icons.memory_rounded,
                              Colors.purple, 2),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'نوع الانفرتر', Icons.settings_rounded, (value) {
                            _inverterType = value;
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'قدرة الانفرتر (واط)', Icons.power_rounded,
                              (value) {
                            _inverterPower = value.toDouble();
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'عدد الانفرتر',
                              Icons.numbers_rounded,
                              (value) => _inverterCount = value),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'ماركة الانفرتر (اختياري)',
                              Icons.branding_watermark_outlined,
                              (value) => _inverterBrand = value),
                          const SizedBox(height: 15),
                          _buildImagePicker('صورة الانفرتر', _inverterImage,
                              (file) => setState(() => _inverterImage = file)),
                          const SizedBox(height: 30),
                          _buildSectionHeader(
                              'البطاريات',
                              Icons.battery_charging_full_rounded,
                              Colors.green,
                              3),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'عدد البطاريات', Icons.grid_view_rounded,
                              (value) {
                            _batteriesCount = value;
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildNumberField(
                              'سعة البطارية (أمبير/س)', Icons.storage_rounded,
                              (value) {
                            _batteryCapacity = value.toDouble();
                            _updateFormProgress();
                          }),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'نوع البطارية (اختياري)',
                              Icons.category_rounded,
                              (value) => _batteryType = value),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'ماركة البطارية (اختياري)',
                              Icons.branding_watermark_outlined,
                              (value) => _batteryBrand = value),
                          const SizedBox(height: 15),
                          _buildImagePicker('صورة البطاريات', _batteryImage,
                              (file) => setState(() => _batteryImage = file)),
                          const SizedBox(height: 30),
                          _buildSectionHeader('ملاحظات إضافية',
                              Icons.note_add_rounded, Colors.teal, 4),
                          const SizedBox(height: 15),
                          _buildTextField(
                              'تفاصيل إضافية (اختياري)',
                              Icons.description_rounded,
                              (value) => _detailsNotes = value,
                              maxLines: 4),
                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تقدم النموذج',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mediumGray)),
              Text('${(_formProgress * 100).toInt()}%',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimationController,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _formProgress * _progressAnimationController.value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _formProgress < 0.3
                        ? Colors.orange
                        : _formProgress < 0.6
                            ? Colors.blue
                            : primaryBlue,
                  ),
                  minHeight: 8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color color, int sectionIndex) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (sectionIndex * 200)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)), child: child),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkColor)),
                  const SizedBox(height: 2),
                  Text(_getSectionDescription(sectionIndex),
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Text('${sectionIndex + 1}',
                  style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionDescription(int index) {
    switch (index) {
      case 0:
        return 'المعلومات الأساسية للمنظومة';
      case 1:
        return 'تفاصيل الألواح الشمسية';
      case 2:
        return 'معلومات الانفرتر';
      case 3:
        return 'تفاصيل البطاريات';
      case 4:
        return 'ملاحظات إضافية';
      default:
        return '';
    }
  }

  Widget _buildTextField(String label, IconData icon, Function(String) onSaved,
      {int maxLines = 1}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) =>
          Transform.scale(scale: value, child: child),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: mediumGray, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06)
              ]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: primaryBlue, width: 2)),
          filled: true,
          fillColor: cardWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
        maxLines: maxLines,
        onSaved: (value) => onSaved(value ?? ''),
      ),
    );
  }

  Widget _buildNumberField(String label, IconData icon, Function(int) onSaved) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) =>
          Transform.scale(scale: value, child: child),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: mediumGray, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06)
              ]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: primaryBlue, width: 2)),
          filled: true,
          fillColor: cardWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
        keyboardType: TextInputType.number,
        onSaved: (value) => onSaved(int.tryParse(value ?? '0') ?? 0),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'الرجاء إدخال قيمة' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(_installationDate),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                primaryColor: primaryBlue,
                colorScheme: const ColorScheme.light(primary: primaryBlue),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() =>
              _installationDate = date.toIso8601String().split('T').first);
          _updateFormProgress();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06)
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: primaryBlue, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تاريخ التركيب',
                      style:
                          GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
                  const SizedBox(height: 4),
                  Text(_installationDate,
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkColor)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_calendar_rounded,
                  color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.blue.withOpacity(0.15),
                    Colors.blue.withOpacity(0.08)
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.new_releases_rounded,
                    color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('منظومة جديدة',
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkColor)),
                  Text('هل هذه المنظومة جديدة أم مستعملة؟',
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Switch(
            value: _isNew,
            onChanged: (value) {
              setState(() => _isNew = value);
              _updateFormProgress();
            },
            activeColor: primaryBlue,
            activeTrackColor: primaryBlue.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, double value, child) =>
          Transform.scale(scale: value, child: child),
      child: AnimatedBuilder(
        animation: _submitAnimationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient:
                  const LinearGradient(colors: [primaryBlue, secondaryBlue]),
              boxShadow: [
                BoxShadow(
                    color: primaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                          scale: 1.0 + (_pulseAnimationController.value * 0.1),
                          child: child);
                    },
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text('إضافة المنظومة',
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.2),
                  child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.15),
                  secondaryBlue.withOpacity(0.08)
                ]),
              ),
              child: const CircularProgressIndicator(
                  color: primaryBlue, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text('جاري إضافة المنظومة...',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: mediumGray)),
        ],
      ),
    );
  }
}
