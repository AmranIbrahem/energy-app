// lib/screens/lighting/lighting_room_wizard_screen.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/lighting_design_models.dart';
import 'package:GeniusHouse/screens/lighting/lighting_project_summary_screen.dart';
import 'package:GeniusHouse/screens/lighting/lighting_visualization_screen.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/lighting_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class LightingRoomWizardScreen extends StatefulWidget {
  final ApiService? apiService;
  final StorageService? storageService;
  final String? initialSessionId;

  const LightingRoomWizardScreen({
    Key? key,
    this.apiService,
    this.storageService,
    this.initialSessionId,
  }) : super(key: key);

  @override
  State<LightingRoomWizardScreen> createState() =>
      _LightingRoomWizardScreenState();
}

class _LightingRoomWizardScreenState extends State<LightingRoomWizardScreen> {
  late final ApiService _api;
  late final StorageService _storage;

  int _currentStep = 0;
  static const int _totalSteps = 5;

  LightingConfig? _config;
  bool _isLoadingConfig = true;

  String? _sessionId;
  int? _projectId;

  String? _selectedRoomTypeKey;
  String? _customRoomTypeAr;
  String? _resolvedRoomTypeKey;

  final TextEditingController _lengthCtrl = TextEditingController(text: '6');
  final TextEditingController _widthCtrl = TextEditingController(text: '4');
  final TextEditingController _heightCtrl = TextEditingController(text: '3');

  String _coveCeiling = 'unknown';
  File? _roomPhoto;
  String? _photoRef;

  LightingDesignResponse? _designResponse;
  bool _isSubmittingDesign = false;
  String? _aiExplanation;
  bool _showFullAIExplanation = false;

  LightingPlan? _selectedPlan;
  List<LightingSelectedItem> _selectedItems = [];
  List<LightingSelectedItem> _selectedDecor = [];
  LightingRecheckResponse? _recheckResponse;
  bool _isRechecking = false;
  bool _isConfirming = false;

  final Map<String, LightingProductPick> _productsById = {};

  int? _lastAttemptId;
  int? _lastRoomIdDb;
  bool _canGenerateImage = false;
  int _remainingImageAttempts = 2;

  bool get _isSypPreferred {
    try {
      return _storage.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    return '${buffer.toString()}.$decimalPart';
  }

  String _fmt(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') {
      return '${_formatNumber(amount)} SYP';
    }
    return '\$${_formatNumber(amount)}';
  }

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? StorageService();
    _api = widget.apiService ?? ApiService(storageService: _storage);
    _sessionId = widget.initialSessionId;
    _loadConfig();
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool get _isLoggedIn {
    final token = _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      final res = await _api.lightingDesignConfig(requiresAuth: _isLoggedIn);
      if (res['success'] == true && res['data'] != null) {
        final cfg =
            LightingConfig.fromJson(Map<String, dynamic>.from(res['data']));
        setState(() {
          _config = cfg;
          _isLoadingConfig = false;
        });
      } else {
        setState(() => _isLoadingConfig = false);
        _showErrorDialog(res['message']?.toString() ?? 'فشل تحميل الإعدادات');
      }
    } catch (e) {
      setState(() => _isLoadingConfig = false);
      _showErrorDialog('خطأ في تحميل الإعدادات: $e');
    }
  }

  Future<void> _ensureSession() async {
    if (_sessionId != null && _sessionId!.isNotEmpty) return;
    try {
      final res = await _api.lightingDesignStart(requiresAuth: _isLoggedIn);
      if (res['success'] == true && res['data'] != null) {
        setState(() => _sessionId = res['data']['session_id']?.toString());
      }
    } catch (_) {}
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        if (_selectedRoomTypeKey == null) return false;
        if (_selectedRoomTypeKey == 'other') {
          return _customRoomTypeAr != null &&
              _customRoomTypeAr!.isNotEmpty &&
              _resolvedRoomTypeKey != null &&
              _resolvedRoomTypeKey != 'other';
        }
        return true;
      case 1:
        final l = double.tryParse(_lengthCtrl.text.trim());
        final w = double.tryParse(_widthCtrl.text.trim());
        final h = double.tryParse(_heightCtrl.text.trim());
        return l != null &&
            l > 0.5 &&
            w != null &&
            w > 0.5 &&
            h != null &&
            h > 1.8;
      case 2:
        return true;
      case 3:
        return false;
      case 4:
        return _selectedPlan != null && _selectedItems.isNotEmpty;
      default:
        return false;
    }
  }

  void _goNext() async {
    if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      await _submitDesign();
    } else if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitDesign() async {
    await _ensureSession();
    setState(() {
      _isSubmittingDesign = true;
      _designResponse = null;
      _aiExplanation = null;
      _showFullAIExplanation = false;
    });

    try {
      final roomInput = _buildRoomInput();
      final res = await _api.lightingDesign(
        room: roomInput.toJson(),
        sessionId: _sessionId,
        projectId: _projectId,
        withAi: true,
        isSyp: _isSypPreferred,
        requiresAuth: _isLoggedIn,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final engine = data['engine_result'];
        final returnedProjectId =
            int.tryParse((data['project_id'] ?? 0).toString()) ?? 0;

        setState(() {
          _designResponse = LightingDesignResponse.fromJson(
              Map<String, dynamic>.from(engine));
          _aiExplanation = data['ai_explanation']?.toString();
          _isSubmittingDesign = false;
          if (returnedProjectId > 0) _projectId = returnedProjectId;
        });
      } else {
        setState(() => _isSubmittingDesign = false);
        _showErrorDialog(res['message']?.toString() ?? 'فشل التصميم');
        setState(() => _currentStep = 2);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingDesign = false);
      _showErrorDialog('خطأ في التصميم: $e');
      setState(() => _currentStep = 2);
    }
  }

  LightingRoomInput _buildRoomInput() {
    return LightingRoomInput(
      roomId: 'room-${DateTime.now().millisecondsSinceEpoch}',
      roomTypeKey: _selectedRoomTypeKey ?? 'living_room',
      customRoomTypeAr: _customRoomTypeAr,
      resolvedRoomTypeKey: _resolvedRoomTypeKey,
      lengthM: double.tryParse(_lengthCtrl.text.trim()) ?? 6,
      widthM: double.tryParse(_widthCtrl.text.trim()) ?? 4,
      heightM: double.tryParse(_heightCtrl.text.trim()) ?? 3,
      coveCeiling: _coveCeiling,
      photoRef: _photoRef,
      attemptNo: 1,
      preferredLightColor: 'auto',
    );
  }

  Future<void> _pickRoomPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _roomPhoto = File(picked.path));

      await _ensureSession();
      if (_sessionId == null) {
        _showSnackBar('فشل بدء الجلسة');
        return;
      }

      final res = await _api.lightingUploadRoomPhoto(
        sessionId: _sessionId!,
        photo: _roomPhoto!,
        requiresAuth: _isLoggedIn,
      );
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _photoRef = res['data']['photo_ref']?.toString();
        });
        _showSnackBar('تم رفع الصورة ✅', isSuccess: true);
      } else {
        _showSnackBar(res['message']?.toString() ?? 'فشل رفع الصورة');
      }
    } catch (e) {
      _showSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  void _removePhoto() {
    setState(() {
      _roomPhoto = null;
      _photoRef = null;
    });
  }

  Future<void> _recheckDesign() async {
    if (_selectedItems.isEmpty && _selectedDecor.isEmpty) return;
    setState(() => _isRechecking = true);
    try {
      final room = _buildRoomInput().toJson();
      final items = [
        ..._selectedItems.map((e) => e.toJson()),
        ..._selectedDecor.map((e) => e.toJson()),
      ];
      final res = await _api.lightingRecheck(
        room: room,
        items: items,
        isSyp: _isSypPreferred,
        requiresAuth: _isLoggedIn,
      );
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _recheckResponse = LightingRecheckResponse.fromJson(
              Map<String, dynamic>.from(res['data']));
          _isRechecking = false;
        });
      } else {
        setState(() => _isRechecking = false);
        _showSnackBar(res['message']?.toString() ?? 'فشل إعادة الفحص');
      }
    } catch (e) {
      setState(() => _isRechecking = false);
      _showSnackBar('خطأ في إعادة الفحص: $e');
    }
  }

  Future<void> _confirmAttempt() async {
    if (_selectedPlan == null || _sessionId == null) return;
    setState(() => _isConfirming = true);
    try {
      final room = _buildRoomInput().toJson();
      final items = [
        ..._selectedItems.map((e) => e.toJson()),
        ..._selectedDecor.map((e) => e.toJson()),
      ];
      final res = await _api.lightingConfirmAttempt(
        sessionId: _sessionId!,
        projectId: _projectId,
        room: room,
        planKey: _selectedPlan!.key,
        items: items,
        distribution: _selectedPlan!.distribution.toJson(),
        equipmentAmount: _computedTotal,
        equipmentCurrency: 'USD',
        estimatedLux: _selectedPlan!.estimatedLux,
        totalPowerW: _computedTotalPower,
        imageRef: _photoRef,
        isSyp: _isSypPreferred,
        requiresAuth: _isLoggedIn,
      );
      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'] ?? {};
        final roomIdDb =
            int.tryParse((data['room_id_db'] ?? 0).toString()) ?? 0;
        final projectId =
            int.tryParse((data['project_id'] ?? 0).toString()) ?? 0;
        final attemptNo =
            int.tryParse((data['attempt_no'] ?? 1).toString()) ?? 1;

        final attemptId =
            int.tryParse((data['attempt_id'] ?? 0).toString()) ?? 0;
        final canGenerate = data['can_generate_image'] == true;
        final remaining =
            int.tryParse((data['remaining_image_attempts'] ?? 2).toString()) ??
                2;

        setState(() {
          _isConfirming = false;
          _lastAttemptId = attemptId;
          _lastRoomIdDb = roomIdDb;
          _projectId = projectId;
          _canGenerateImage = canGenerate;
          _remainingImageAttempts = remaining;
        });

        _showSuccessDialog(
          roomIdDb: roomIdDb,
          projectId: projectId,
          attemptNo: attemptNo,
        );
      } else {
        setState(() => _isConfirming = false);
        _showErrorDialog(res['message']?.toString() ?? 'فشل الاعتماد');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      _showErrorDialog('خطأ في الاعتماد: $e');
    }
  }

  double get _computedTotal {
    double total = 0;
    for (final item in _selectedItems) {
      final prod = _productsById[item.productId];
      if (prod != null) total += prod.unitPrice.amount * item.quantity;
    }
    for (final item in _selectedDecor) {
      final prod = _productsById[item.productId];
      if (prod != null) total += prod.unitPrice.amount * item.quantity;
    }
    return total;
  }

  double get _computedTotalPower {
    double total = 0;
    for (final item in _selectedItems) {
      final prod = _productsById[item.productId];
      if (prod != null) total += (prod.wattsPerUnit ?? 0) * item.quantity;
    }
    for (final item in _selectedDecor) {
      final prod = _productsById[item.productId];
      if (prod != null) total += (prod.wattsPerUnit ?? 0) * item.quantity;
    }
    return total;
  }

  void _showSuccessDialog({
    required int roomIdDb,
    required int projectId,
    required int attemptNo,
  }) {
    final canVisualize = _photoRef != null &&
        _selectedPlan != null &&
        _canGenerateImage &&
        _remainingImageAttempts > 0 &&
        _lastAttemptId != null &&
        _lastRoomIdDb != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 56),
            ),
            const SizedBox(height: 16),
            Text(
              'تم اعتماد الخطة ✅',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ماذا تريد أن تفعل الآن؟',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              if (canVisualize) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Future.microtask(() => _openVisualization());
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      'توليد صورة الغرفة',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'محاولات متبقية: $_remainingImageAttempts من 2',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Future.microtask(() => _openProjectSummary(projectId));
                  },
                  icon: const Icon(Icons.summarize_rounded, size: 18),
                  label: Text(
                    'عرض ملخص المشروع',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.pop(context, {
                      'room_id_db': roomIdDb,
                      'project_id': projectId,
                      'attempt_no': attemptNo,
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'إضافة غرفة أخرى',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side:
                        const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openVisualization() {
    if (_selectedPlan == null || _photoRef == null) return;
    if (_lastAttemptId == null || _lastRoomIdDb == null) {
      _showSnackBar('لم يتم اعتماد الخطة بعد');
      return;
    }
    if (_projectId == null || _projectId == 0) {
      _showSnackBar('تعذّر تحديد المشروع — أعد اعتماد الخطة');
      return;
    }

    final room = _buildRoomInput();
    final allItems = <LightingSelectedItem>[
      ..._selectedItems,
      ..._selectedDecor,
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LightingVisualizationScreen(
          apiService: _api,
          room: room,
          confirmedItems: allItems,
          distribution: _selectedPlan!.distribution,
          localImagePath: _roomPhoto?.path,
          sessionId: _sessionId,
          projectId: _projectId,
          roomIdDb: _lastRoomIdDb,
          attemptId: _lastAttemptId,
          isLoggedIn: _isLoggedIn,
        ),
      ),
    ).then((result) {
      if (result is Map && result['remaining_attempts'] is int) {
        setState(() {
          _remainingImageAttempts = result['remaining_attempts'] as int;
          _canGenerateImage = _remainingImageAttempts > 0;
        });
      }
    });
  }

  void _openProjectSummary(int projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LightingProjectSummaryScreen(
          apiService: _api,
          storageService: _storage,
          projectId: projectId,
          sessionId: _sessionId,
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontSize: 14)),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            Text('حدث خطأ',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.red.shade800, height: 1.6)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('حسناً',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFF1E3A8A), size: 28),
          const SizedBox(width: 10),
          Text('كيفية الاستخدام',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpItem('1. نوع المكان', 'اختر نوع الغرفة أو المكان'),
              _HelpItem('2. الأبعاد', 'أدخل طول وعرض وارتفاع الغرفة'),
              _HelpItem(
                  '3. الجبس والصورة', 'حدد وجود الجبس وارفع صورة اختيارية'),
              _HelpItem(
                  '4. الاقتراحات', 'اختر من 3 خطط (اقتصادي/متوازن/أعلى أداء)'),
              _HelpItem('5. الاعتماد', 'عدّل الكميات ثم اعتمد الخطة'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('فهمت', style: GoogleFonts.cairo())),
        ],
      ),
    );
  }

  void _openOtherRoomDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _OtherRoomDialog(profiles: _config?.knownRoomTypes ?? []),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedRoomTypeKey = 'other';
        _customRoomTypeAr = result['custom'];
        _resolvedRoomTypeKey = result['resolved'];
      });
    }
  }

  void _selectPlan(LightingPlan plan) {
    setState(() {
      _selectedPlan = plan;
      _selectedItems = plan.products
          .map((p) => LightingSelectedItem(
                productId: p.productId,
                quantity: p.quantity,
                role: p.role,
              ))
          .toList();
      _selectedDecor = [];
      _recheckResponse = null;

      _productsById.clear();
      for (final p in plan.products) {
        _productsById[p.productId] = p;
      }
      for (final p in plan.decorativeSuggestions) {
        _productsById[p.productId] = p;
      }

      _currentStep = 4;
    });
  }

  IconData _roomTypeIcon(String key) {
    switch (key) {
      case 'living_room':
        return Icons.weekend_rounded;
      case 'bedroom':
        return Icons.bed_rounded;
      case 'children_room':
        return Icons.child_care_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bathroom':
        return Icons.bathtub_rounded;
      case 'corridor':
        return Icons.meeting_room_rounded;
      case 'office':
        return Icons.work_rounded;
      case 'shop':
        return Icons.storefront_rounded;
      case 'showroom':
        return Icons.store_rounded;
      case 'warehouse':
        return Icons.warehouse_rounded;
      case 'workshop':
        return Icons.build_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _roomTypeColor(String key) {
    switch (key) {
      case 'living_room':
      case 'bedroom':
      case 'children_room':
        return const Color(0xFF8B5CF6);
      case 'kitchen':
      case 'bathroom':
        return const Color(0xFF3B82F6);
      case 'office':
      case 'shop':
      case 'showroom':
        return const Color(0xFF10B981);
      case 'warehouse':
      case 'workshop':
        return const Color(0xFFF59E0B);
      case 'restaurant':
      case 'cafe':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Color(0xFFF3F4F6),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
          return false;
        }
        return true;
      },
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: Column(
            children: [
              _buildAppBarWithCurve(),
              _buildStepperHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarWithCurve() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      'تصميم إنارة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 24),
                    onPressed: _showHelpDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final labels = ['النوع', 'الأبعاد', 'الجبس', 'النتائج', 'الاعتماد'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          final isClickable = index < _currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: isClickable
                  ? () {
                      setState(() => _currentStep = index);
                    }
                  : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isDone
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : (isDone
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.grey.shade300),
                          border: isActive
                              ? Border.all(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.4),
                                  width: 3)
                              : null,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.35),
                                      blurRadius: 8)
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : Text('${index + 1}',
                                  style: GoogleFonts.cairo(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  )),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
                      color: isActive
                          ? const Color(0xFF1E3A8A)
                          : (isClickable
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade500),
                      decoration: isClickable && !isActive
                          ? TextDecoration.underline
                          : null,
                      decorationColor: const Color(0xFF3B82F6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep == 3) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text('السابق',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              foregroundColor: const Color(0xFF1E3A8A),
            ),
          ),
        ),
      );
    }

    String text = 'التالي';
    if (_currentStep == 2) text = 'صمّم';
    if (_currentStep == 4) text = 'اعتماد الخطة';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep < 4)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('السابق', style: GoogleFonts.cairo(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ),
          if (_currentStep > 0 && _currentStep < 4) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canProceed()
                  ? (_currentStep == 4 ? _confirmAttempt : _goNext)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: (_isSubmittingDesign || _isConfirming)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(text,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0RoomType();
      case 1:
        return _buildStep1Dimensions();
      case 2:
        return _buildStep2CoveAndPhoto();
      case 3:
        return _buildStep3Results();
      case 4:
        return _buildStep4Details();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0RoomType() {
    final profiles = _config?.knownRoomTypes ?? [];
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.meeting_room_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نوع المكان',
                        style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A))),
                    Text('اختر نوع الغرفة أو المكان',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...profiles.map((p) => _buildRoomTypeOption(p)),
          const SizedBox(height: 12),
          _buildOtherRoomOption(),
        ],
      ),
    );
  }

  Widget _buildRoomTypeOption(LightingRoomProfile profile) {
    final isSelected = _selectedRoomTypeKey == profile.key;
    final color = _roomTypeColor(profile.key);
    final icon = _roomTypeIcon(profile.key);

    return GestureDetector(
      onTap: () => setState(() {
        _selectedRoomTypeKey = profile.key;
        _customRoomTypeAr = null;
        _resolvedRoomTypeKey = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [color, color.withOpacity(0.75)]
                      : [color.withOpacity(0.12), color.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.titleAr,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: 12, color: color.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        '${profile.targetLux.toStringAsFixed(0)} لوكس',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _lightColorAr(profile.defaultLightColor),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _lightColorAr(String key) {
    switch (key) {
      case 'warm':
        return 'دافئ';
      case 'natural':
        return 'طبيعي';
      case 'white':
        return 'أبيض';
      default:
        return 'تلقائي';
    }
  }

  Widget _buildOtherRoomOption() {
    final isSelected = _selectedRoomTypeKey == 'other';
    return GestureDetector(
      onTap: _openOtherRoomDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          const Color(0xFFF59E0B),
                          const Color(0xFFF59E0B).withOpacity(0.75),
                        ]
                      : [
                          const Color(0xFFF59E0B).withOpacity(0.12),
                          const Color(0xFFF59E0B).withOpacity(0.06),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.add_home_work_rounded,
                color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'غير ذلك',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (isSelected && _customRoomTypeAr != null)
                    Text(
                      '${_customRoomTypeAr!} → ${_profileTitleAr(_resolvedRoomTypeKey ?? '')}',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade600),
                    )
                  else
                    Text(
                      'اكتب اسم المكان وسيصنفه Nex',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _profileTitleAr(String key) {
    try {
      return _config?.roomTypes.firstWhere((r) => r.key == key).titleAr ?? key;
    } catch (_) {
      return key;
    }
  }

  Widget _buildStep1Dimensions() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.straighten_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أبعاد الغرفة',
                        style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A))),
                    Text('أدخل الأبعاد بالمتر',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDimField('الطول', _lengthCtrl, Icons.straighten_rounded),
          const SizedBox(height: 14),
          _buildDimField('العرض', _widthCtrl, Icons.swap_horiz_rounded),
          const SizedBox(height: 14),
          _buildDimField('الارتفاع', _heightCtrl, Icons.height_rounded),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('المساحة: ${_areaText()} م²',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _areaText() {
    final l = double.tryParse(_lengthCtrl.text.trim()) ?? 0;
    final w = double.tryParse(_widthCtrl.text.trim()) ?? 0;
    return (l * w).toStringAsFixed(1);
  }

  Widget _buildDimField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: '$label (متر)',
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildStep2CoveAndPhoto() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.architecture_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الجبس والصورة',
                        style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A))),
                    Text('هل يوجد جبس أو مكان للإنارة المخفية؟',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCoveOption('yes', 'نعم، يوجد جبس', Icons.check_circle_rounded),
          const SizedBox(height: 8),
          _buildCoveOption('no', 'لا يوجد', Icons.cancel_rounded),
          const SizedBox(height: 8),
          _buildCoveOption('unknown', 'لا أعرف', Icons.help_outline_rounded),
          const SizedBox(height: 28),
          Text('صورة الغرفة (اختياري)',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Text('تُستخدم لاحقاً لتوليد معاينة بصرية',
              style:
                  GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          _roomPhoto != null ? _buildPhotoPreview() : _buildPhotoPicker(),
        ],
      ),
    );
  }

  Widget _buildCoveOption(String value, String label, IconData icon) {
    final selected = _coveCeiling == value;
    return GestureDetector(
      onTap: () => setState(() => _coveCeiling = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF3B82F6) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade800,
                  )),
            ),
            if (selected)
              const Icon(Icons.radio_button_checked_rounded,
                  color: Color(0xFF3B82F6), size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: Color(0xFFBDBDBD), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return GestureDetector(
      onTap: _pickRoomPhoto,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_photo_alternate_rounded,
                color: Color(0xFF3B82F6), size: 48),
            const SizedBox(height: 8),
            Text('اختر صورة من المعرض',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(_roomPhoto!,
              height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_photoRef == null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('جارٍ الرفع...',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.orange.shade800)),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('✅ تم الرفع',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: const Color(0xFF10B981))),
                ),
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _removePhoto,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 18),
              label: Text('حذف',
                  style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Results() {
    if (_isSubmittingDesign || _designResponse == null) {
      return Center(
        key: const ValueKey('step3-loading'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              const SizedBox(height: 24),
              Text('جاري حساب الإنارة...',
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 12),
              Text('يقوم Nex بتحليل الغرفة واختيار المنتجات المناسبة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    final d = _designResponse!;
    return ListView(
      key: const ValueKey('step3-results'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusBanner(d.status),
        const SizedBox(height: 12),
        _buildSummaryCard(d),
        const SizedBox(height: 16),
        if (_aiExplanation != null && _aiExplanation!.isNotEmpty) ...[
          _buildExpandableAIExplanation(),
          const SizedBox(height: 16),
        ],
        Text('الخطط المتاحة',
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A))),
        const SizedBox(height: 12),
        ...d.plans.map(_buildPlanCard),
        const SizedBox(height: 8),
        if (d.assumptions.isNotEmpty) ...[
          _buildAssumptions(d.assumptions),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildStatusBanner(String status) {
    final color = status == 'complete'
        ? const Color(0xFF10B981)
        : (status == 'needs_review' ? const Color(0xFFF59E0B) : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'complete'
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(status.statusDesignAr,
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LightingDesignResponse d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1E3A8A).withOpacity(0.1),
          const Color(0xFF3B82F6).withOpacity(0.05),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('📊 ملخص الغرفة',
              style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _summaryItem('المساحة', '${d.areaM2.toStringAsFixed(1)} م²'),
            _summaryItem('المستهدف', '${d.targetLux.toStringAsFixed(0)} لوكس'),
            _summaryItem('اللومن المطلوب',
                '${d.requiredPrimaryLumens.toStringAsFixed(0)}'),
          ]),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style:
                GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _buildExpandableAIExplanation() {
    final fullText = _aiExplanation!;
    final isExpanded = _showFullAIExplanation;
    final previewText =
        fullText.length > 100 ? '${fullText.substring(0, 100)}...' : fullText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text('✨ تحليل ذكي',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.purple.shade700)),
          ]),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isExpanded ? fullText : previewText,
              style: GoogleFonts.cairo(
                  fontSize: 13, height: 1.7, color: Colors.grey.shade800),
            ),
          ),
          if (fullText.length > 100) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => _showFullAIExplanation = !_showFullAIExplanation),
                icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.purple),
                label: Text(
                  isExpanded ? 'إخفاء التفاصيل' : 'عرض التفاصيل الكاملة',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(LightingPlan plan) {
    final amount = plan.equipmentTotal.amount;
    final currency = plan.equipmentTotal.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              plan.recommended ? const Color(0xFF10B981) : Colors.grey.shade300,
          width: plan.recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: plan.recommended
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                plan.recommended ? Icons.star_rounded : Icons.lightbulb_rounded,
                color: plan.recommended
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E3A8A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(plan.titleAr,
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
            ),
            if (plan.recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('⭐ موصى به',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981))),
              ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _planSpec(
                'الإنارة', '${plan.estimatedLux.toStringAsFixed(0)} لوكس'),
            _planSpec('الاستطاعة', '${plan.totalPowerW.toStringAsFixed(0)} W'),
            _planSpec('اللون', plan.suggestedLightColor.lightColorAr),
          ]),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          ...plan.products.map((p) => _buildProductRow(p)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مجموع المنتجات:',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey.shade700)),
                Text(_fmt(amount, currency: currency),
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _selectPlan(plan),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text('اختر هذه الخطة',
                  style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planSpec(String label, String value) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
      const SizedBox(height: 2),
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A))),
    ]);
  }

  Widget _buildProductRow(LightingProductPick p) {
    final imageUrl = p.image ?? '';
    final hasDiscount = (p.discountPercentage ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        if (p.slug != null && p.slug!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailsScreen(productSlug: p.slug!, apiService: _api),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                            width: 55, height: 55, color: Colors.grey.shade300),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    )
                  : Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(p.titleAr,
                            style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_left_rounded,
                        size: 16, color: Colors.grey),
                  ]),
                  if (p.brand != null && p.brand!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                        '${p.brand}${p.model != null && p.model!.isNotEmpty ? " - ${p.model}" : ""}',
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (hasDiscount) ...[
                      Text(_fmt(p.price ?? 0, currency: p.currency),
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                        '${_fmt(p.finalPrice ?? p.unitPrice.amount, currency: p.currency)} × ${p.quantity}',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssumptions(List<LightingAssumption> assumptions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.fact_check_rounded,
                color: Color(0xFF3B82F6), size: 20),
            const SizedBox(width: 8),
            Text('📋 الافتراضات',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF1E3A8A))),
          ]),
          const SizedBox(height: 8),
          ...assumptions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${a.messageAr}',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.5)),
              )),
        ],
      ),
    );
  }

  Widget _buildStep4Details() {
    if (_selectedPlan == null) {
      return const Center(child: Text('لم يتم اختيار خطة'));
    }
    final plan = _selectedPlan!;

    return ListView(
      key: const ValueKey('step4-details'),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text('خطة ${plan.titleAr}',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A))),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('المنتجات الأساسية',
            style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A))),
        const SizedBox(height: 8),
        ..._selectedItems
            .asMap()
            .entries
            .map((e) => _buildEditableItem(e.key, e.value, 'primary')),
        const SizedBox(height: 16),
        if (plan.decorativeSuggestions.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF8B5CF6), size: 18),
              const SizedBox(width: 6),
              Text('الديكور الضوئي (اختياري)',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: 8),
          ...plan.decorativeSuggestions.map(_buildDecorOption),
          if (_selectedDecor.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('الديكور المختار',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B5CF6))),
            const SizedBox(height: 6),
            ..._selectedDecor
                .asMap()
                .entries
                .map((e) => _buildEditableItem(e.key, e.value, 'decorative')),
          ],
          const SizedBox(height: 16),
        ],
        if (_recheckResponse != null) ...[
          _buildRecheckResult(_recheckResponse!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isRechecking ? null : _recheckDesign,
            icon: _isRechecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text('إعادة فحص الكفاية',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.payments_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('المجموع:',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
              Text(
                  _fmt(_computedTotal,
                      currency: _isSypPreferred ? 'SYP' : 'USD'),
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableItem(int index, LightingSelectedItem item, String role) {
    final prod = _productsById[item.productId];
    final unitPrice = prod?.unitPrice.amount ?? 0;
    final lineTotal = unitPrice * item.quantity;
    final imageUrl = prod?.image ?? '';
    final currency = prod?.currency ?? 'USD';

    final isDecor = role == 'decorative';
    final productSlug = prod?.slug ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDecor
                ? const Color(0xFF8B5CF6).withOpacity(0.3)
                : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (productSlug.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                        productSlug: productSlug,
                        apiService: _api,
                      ),
                    ),
                  );
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported,
                                  size: 18),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.image_not_supported, size: 18),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              prod?.titleAr ?? 'منتج #${item.productId}',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              size: 16, color: Colors.grey),
                        ]),
                        if (prod?.brand != null && prod!.brand!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(prod.brand!,
                              style: GoogleFonts.cairo(
                                  fontSize: 10, color: Colors.grey.shade500)),
                        ],
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(_fmt(unitPrice, currency: currency),
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDecor
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF1E3A8A))),
                          const SizedBox(width: 6),
                          Text('× ${item.quantity}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 6),
                          Text('= ${_fmt(lineTotal, currency: currency)}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981))),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 16),
                onPressed: () {
                  setState(() {
                    final list = isDecor ? _selectedDecor : _selectedItems;
                    if (item.quantity > 1) {
                      list[index] = item.copyWith(quantity: item.quantity - 1);
                    } else {
                      list.removeAt(index);
                    }
                    _recheckResponse = null;
                  });
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                color:
                    isDecor ? const Color(0xFF8B5CF6) : const Color(0xFF1E3A8A),
              ),
              Text('${item.quantity}',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 16),
                onPressed: () {
                  setState(() {
                    final list = isDecor ? _selectedDecor : _selectedItems;
                    list[index] = item.copyWith(quantity: item.quantity + 1);
                    _recheckResponse = null;
                  });
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                color:
                    isDecor ? const Color(0xFF8B5CF6) : const Color(0xFF1E3A8A),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorOption(LightingProductPick decor) {
    final isSelected =
        _selectedDecor.any((d) => d.productId == decor.productId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDecor.removeWhere((d) => d.productId == decor.productId);
          } else {
            _selectedDecor.add(LightingSelectedItem(
              productId: decor.productId,
              quantity: decor.quantity,
              role: 'decorative',
            ));
          }
          _recheckResponse = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (decor.image ?? '').isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: decor.image!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 44, height: 44, color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 18),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 18),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(decor.titleAr,
                      style: GoogleFonts.cairo(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${_fmt(decor.unitPrice.amount, currency: decor.currency)} × ${decor.quantity}',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B5CF6))),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color:
                  isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecheckResult(LightingRecheckResponse r) {
    final color = r.isAdequate
        ? const Color(0xFF10B981)
        : (r.isLow ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              r.isAdequate
                  ? Icons.check_circle_rounded
                  : (r.isLow
                      ? Icons.warning_amber_rounded
                      : Icons.info_rounded),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(r.adequacy.adequacyAr,
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ]),
          const SizedBox(height: 6),
          Text(r.messageAr,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: Colors.grey.shade800, height: 1.5)),
          const SizedBox(height: 6),
          Text('اللوكس المتوقع: ${r.estimatedLux.toStringAsFixed(0)}',
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _OtherRoomDialog extends StatefulWidget {
  final List<LightingRoomProfile> profiles;

  const _OtherRoomDialog({required this.profiles});

  @override
  State<_OtherRoomDialog> createState() => _OtherRoomDialogState();
}

class _OtherRoomDialogState extends State<_OtherRoomDialog> {
  final _customCtrl = TextEditingController();
  String? _resolved;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('نوع مكان مخصص',
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customCtrl,
              decoration: InputDecoration(
                labelText: 'اسم المكان',
                labelStyle: GoogleFonts.cairo(),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text('التصنيف الأقرب:',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A))),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _resolved,
                  hint: Text('اختر التصنيف',
                      style: GoogleFonts.cairo(fontSize: 14)),
                  items: widget.profiles
                      .map((p) => DropdownMenuItem(
                            value: p.key,
                            child: Text(p.titleAr,
                                style: GoogleFonts.cairo(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _resolved = v),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _customCtrl.text.trim();
            if (name.isEmpty || _resolved == null) return;
            Navigator.pop(context, {'custom': name, 'resolved': _resolved!});
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          child: Text('تأكيد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String description;

  const _HelpItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF3B82F6), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E3A8A))),
                Text(description,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
