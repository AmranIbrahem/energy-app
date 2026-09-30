// lib/screens/diagnosis/diagnosis_flow_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/diagnosis_models.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/diagnosis_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../workshop/workshop_request_maintenance_screen.dart';

enum _FlowStep {
  manufacturer,
  family,
  codeEntry,
  symptomEntry,
  question,
  step,
  askResolved,
  result,
  safety,
  solved,
  noMatch,
  handoff,
}

class DiagnosisFlowScreen extends StatefulWidget {
  final ApiService apiService;
  final String mode;
  final String? prefilledFaultId;
  final String? prefilledFaultTitle;
  final String? prefilledCategory;

  const DiagnosisFlowScreen({
    super.key,
    required this.apiService,
    required this.mode,
    this.prefilledFaultId,
    this.prefilledFaultTitle,
    this.prefilledCategory,
  });

  @override
  State<DiagnosisFlowScreen> createState() => _DiagnosisFlowScreenState();
}

class _DiagnosisFlowScreenState extends State<DiagnosisFlowScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFDC2626);
  static const Color purple = Color(0xFF8B5CF6);

  static const List<Map<String, String>> _manufacturers = [
    {'id': 'deye', 'label': 'Deye', 'icon': 'D'},
    {'id': 'voltronic', 'label': 'Voltronic Axpert', 'icon': 'V'},
    {'id': 'felicity', 'label': 'Felicity', 'icon': 'F'},
    {'id': 'usfull', 'label': 'USFULL', 'icon': 'U'},
    {'id': 'invt', 'label': 'INVT', 'icon': 'I'},
  ];

  static const List<Map<String, String>> _categories = [
    {'id': 'solar', 'label': 'طاقة شمسية', 'icon': 'ش'},
    {'id': 'electricity', 'label': 'كهرباء منزلية', 'icon': 'ك'},
    {'id': 'lighting', 'label': 'إنارة', 'icon': 'إ'},
  ];

  late final DiagnosisApiService _api;

  _FlowStep _step = _FlowStep.manufacturer;
  bool _loading = false;
  String? _errorMessage;

  String? _selectedManufacturer;
  String? _selectedManufacturerLabel;
  InverterFamily? _selectedFamily;
  String? _selectedCategory;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<InverterFamily> _families = [];
  List<DiagnosticFault> _faultsForCategory = [];

  String? _sessionId;
  int _sessionDbId = 0;
  DiagnosisSessionResponse? _response;

  @override
  void initState() {
    super.initState();
    _api = DiagnosisApiService(api: widget.apiService);
    _step =
        widget.mode == 'code' ? _FlowStep.manufacturer : _FlowStep.symptomEntry;

    if (widget.prefilledFaultId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startFromPrefilledFault();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    if (_selectedManufacturer == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.listFamilies(
        manufacturer: _selectedManufacturer!,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => InverterFamily.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        setState(() {
          _families = list;
          _step = _FlowStep.family;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = 'فشل في تحميل السلاسل';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  Future<void> _startFromPrefilledFault() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.startSession(
        mode: 'symptom',
        description:
            widget.prefilledFaultTitle ?? widget.prefilledFaultId ?? '',
        category: widget.prefilledCategory,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);
      if (!parsed.success) {
        setState(() {
          _loading = false;
          _errorMessage = parsed.message ?? 'فشل في بدء الجلسة';
        });
        return;
      }

      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  String _faultIdToDescription(String faultId) {
    return faultId;
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('أدخل الرمز أولاً');
      return;
    }
    if (_selectedFamily == null) {
      _showSnack('اختر السلسلة أولاً');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.startSession(
        mode: 'code',
        manufacturer: _selectedManufacturer,
        familyId: _selectedFamily!.id,
        code: code,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);
      if (!parsed.success) {
        setState(() {
          _loading = false;
          _errorMessage = parsed.message ?? 'فشل في بدء الجلسة';
        });
        return;
      }

      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  Future<void> _submitDescription() async {
    final desc = _descriptionController.text.trim();
    if (desc.isEmpty && _selectedCategory == null) {
      _showSnack('اكتب وصفاً أو اختر القسم');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.startSession(
        mode: 'symptom',
        description: desc.isNotEmpty ? desc : null,
        category: _selectedCategory,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);
      if (!parsed.success) {
        setState(() {
          _loading = false;
          _errorMessage = parsed.message ?? 'فشل في بدء الجلسة';
        });
        return;
      }

      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  Future<void> _submitAnswer(String answer) async {
    if (_sessionId == null || _response == null) return;

    setState(() => _loading = true);

    try {
      final res = await _api.answer(
        sessionId: _sessionId!,
        questionIndex: _response!.questionIndex ?? 0,
        answer: answer,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);
      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  Future<void> _submitStep(String outcome) async {
    if (_sessionId == null || _response == null) return;

    setState(() => _loading = true);

    try {
      final res = await _api.completeStep(
        sessionId: _sessionId!,
        stepIndex: _response!.stepIndex ?? 0,
        outcome: outcome,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);
      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  Future<void> _submitOutcome(String outcome) async {
    if (_sessionId == null) return;

    setState(() => _loading = true);

    try {
      final res = await _api.recordOutcome(
        sessionId: _sessionId!,
        outcome: outcome,
      );

      if (!mounted) return;

      final parsed = DiagnosisSessionResponse.fromJson(res);

      if (outcome == 'unresolved') {
        final handoff = parsed.handoff;
        final summaryText = handoff?['summary_text']?.toString() ?? '';

        setState(() => _loading = false);

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkshopRequestMaintenanceScreen(
              apiService: widget.apiService,
              prefilledSummary: summaryText.isNotEmpty ? summaryText : null,
            ),
          ),
        );

        if (mounted && result == null) {
          Navigator.pop(context);
        }
        return;
      }

      _applyResponse(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'خطأ في الاتصال: $e';
      });
    }
  }

  void _applyResponse(DiagnosisSessionResponse parsed) {
    setState(() {
      _response = parsed;
      _loading = false;
      _errorMessage = null;

      if (parsed.sessionId != null) {
        _sessionId = parsed.sessionId;
      }
      if (parsed.sessionDbId != null && parsed.sessionDbId! > 0) {
        _sessionDbId = parsed.sessionDbId!;
      }

      if (parsed.isSafetyStop || parsed.isDanger) {
        _step = _FlowStep.safety;
      } else if (parsed.isNoMatch) {
        _step = _FlowStep.noMatch;
      } else if (parsed.isSolved) {
        _step = _FlowStep.solved;
      } else if (parsed.isHandoff) {
        _step = _FlowStep.handoff;
      } else if (parsed.askResolved || parsed.stepFinished) {
        _step = _FlowStep.askResolved;
      } else if (parsed.isStep) {
        _step = _FlowStep.step;
      } else if (parsed.isQuestion) {
        _step = _FlowStep.question;
      } else if (parsed.isResult) {
        _step = _FlowStep.result;
      } else {
        _step = _FlowStep.result;
      }
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.cairo(fontSize: 14)),
          backgroundColor: isError ? red : primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  bool get _isCodeMode => widget.mode == 'code';

  String get _stepTitle {
    switch (_step) {
      case _FlowStep.manufacturer:
        return 'شركة المحول';
      case _FlowStep.family:
        return 'سلسلة المحول';
      case _FlowStep.codeEntry:
        return 'رمز الشاشة';
      case _FlowStep.symptomEntry:
        return 'وصف المشكلة';
      case _FlowStep.question:
        return 'سؤال تشخيص';
      case _FlowStep.step:
        return 'خطوة آمنة';
      case _FlowStep.askResolved:
        return 'نتيجة التشخيص';
      case _FlowStep.result:
        return 'نتيجة التشخيص';
      case _FlowStep.safety:
        return 'تنبيه أمان';
      case _FlowStep.solved:
        return 'تم الحل';
      case _FlowStep.noMatch:
        return 'لم نتعرف على العطل';
      case _FlowStep.handoff:
        return 'تحويل لصيانة';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case _FlowStep.manufacturer:
        return 'اختر الاسم المكتوب على واجهة الجهاز';
      case _FlowStep.family:
        return _selectedManufacturerLabel ?? 'اختر السلسلة الدقيقة';
      case _FlowStep.codeEntry:
        return _selectedFamily?.label ?? '';
      case _FlowStep.symptomEntry:
        return 'اكتب وصفاً بالعربية';
      case _FlowStep.question:
        final r = _response;
        if (r?.totalQuestions != null && r?.questionIndex != null) {
          return 'السؤال ${(r!.questionIndex! + 1)} من ${r.totalQuestions}';
        }
        return '';
      case _FlowStep.step:
        final r = _response;
        if (r?.totalSteps != null && r?.stepIndex != null) {
          return 'الخطوة ${(r!.stepIndex! + 1)} من ${r.totalSteps}';
        }
        return '';
      case _FlowStep.askResolved:
        return 'انتهت الخطوات الآمنة';
      case _FlowStep.result:
        return 'نتيجة أولية';
      case _FlowStep.safety:
        return 'تم إيقاف التشخيص العادي';
      case _FlowStep.solved:
        return 'سجّلنا النتيجة';
      case _FlowStep.noMatch:
        return 'حاول وصفاً آخر';
      case _FlowStep.handoff:
        return 'ملخص جاهز للفني';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: PopScope(
        canPop:
            _step == _FlowStep.manufacturer || _step == _FlowStep.symptomEntry,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _goBack();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? _buildLoading()
                    : _errorMessage != null
                        ? _buildError()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                            child: _buildCurrentStep(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
                    onPressed: _goBack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stepTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _stepSubtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildProgressBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBadge() {
    IconData icon;
    switch (_step) {
      case _FlowStep.safety:
        icon = Icons.warning_amber_rounded;
        break;
      case _FlowStep.solved:
        icon = Icons.check_circle_rounded;
        break;
      case _FlowStep.result:
      case _FlowStep.handoff:
        icon = Icons.build_rounded;
        break;
      default:
        icon = Icons.medical_services_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 16),
          Text('جاري المعالجة...',
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline_rounded, color: red, size: 48),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _errorMessage = null),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('حاول مرة أخرى', style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _FlowStep.manufacturer:
        return _buildManufacturerStep();
      case _FlowStep.family:
        return _buildFamilyStep();
      case _FlowStep.codeEntry:
        return _buildCodeEntryStep();
      case _FlowStep.symptomEntry:
        return _buildSymptomEntryStep();
      case _FlowStep.question:
        return _buildQuestionStep();
      case _FlowStep.step:
        return _buildStepStep();
      case _FlowStep.askResolved:
        return _buildAskResolvedStep();
      case _FlowStep.result:
        return _buildResultStep();
      case _FlowStep.safety:
        return _buildSafetyStep();
      case _FlowStep.solved:
        return _buildSolvedStep();
      case _FlowStep.noMatch:
        return _buildNoMatchStep();
      case _FlowStep.handoff:
        return _buildHandoffStep();
    }
  }

  Widget _buildManufacturerStep() {
    return SingleChildScrollView(
      key: const ValueKey('manufacturer'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'اختر الشركة',
            'نفس الرقم قد يعني عطلاً مختلفاً بين شركتين',
          ),
          const SizedBox(height: 16),
          ..._manufacturers.map(_buildManufacturerCard),
        ],
      ),
    );
  }

  Widget _buildManufacturerCard(Map<String, String> m) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedManufacturer = m['id'];
          _selectedManufacturerLabel = m['label'];
        });
        _loadFamilies();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  m['icon']!,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                m['label']!,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
            Icon(Icons.arrow_back_ios_rounded,
                color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyStep() {
    if (_families.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد سلاسل مسجلة لهذه الشركة.',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('family'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'السلسلة / الموديل',
            'اختر السلسلة المكتوبة على ملصق الجهاز',
          ),
          const SizedBox(height: 16),
          ..._families.map(_buildFamilyCard),
          const SizedBox(height: 12),
          _buildHintBox(
            'ما عرفت السلسلة؟',
            'صوّر ملصق الجهاز بوضوح وأرسله مع طلب صيانة لاحقاً.',
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(InverterFamily f) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFamily = f;
        _step = _FlowStep.codeEntry;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              f.label,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            if (f.models.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                f.models.join(' • '),
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCodeEntryStep() {
    return SingleChildScrollView(
      key: const ValueKey('code-entry'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'اكتب الرمز كما يظهر',
            'مثلاً F13 أو 05 أو A-LS',
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: secondaryBlue.withOpacity(0.3), width: 2),
            ),
            child: TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: primaryBlue,
              ),
              decoration: InputDecoration(
                hintText: 'F13',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 28,
                  color: Colors.grey.shade300,
                  letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
              onSubmitted: (_) => _submitCode(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitCode,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                'اعرف معنى الرمز',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHintBox(
            'ملاحظة',
            'المطابقة تعتمد على السلسلة الدقيقة، وليس على اسم الشركة فقط.',
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomEntryStep() {
    return SingleChildScrollView(
      key: const ValueKey('symptom-entry'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'شو المشكلة؟',
            'اكتب وصفاً واضحاً بالعربية',
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              minLines: 3,
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade800),
              decoration: InputDecoration(
                hintText: 'مثلاً: المحول ما عم يشتغل نهائياً والشاشة مطفأة',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'اختر القسم (اختياري)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يساعدنا في دقة المطابقة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map(_buildCategoryChip).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitDescription,
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                'ابدأ التشخيص',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHintBox(
            'تنبيه أمان',
            'إذا يوجد دخان أو شرر أو رائحة احتراق، اكتب ذلك فوراً ولا تلمس الجهاز.',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, String> c) {
    final isSelected = _selectedCategory == c['id'];
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = isSelected ? null : c['id'];
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? secondaryBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? secondaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? secondaryBlue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  c['icon']!,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              c['label']!,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryBlue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStep() {
    final r = _response!;
    final question = r.question ?? '';
    final idx = r.questionIndex ?? 0;
    final total = r.totalQuestions ?? 3;

    return SingleChildScrollView(
      key: ValueKey('question-${r.questionIndex}'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(idx, total, secondaryBlue),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: secondaryBlue.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: secondaryBlue.withOpacity(0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: secondaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: secondaryBlue, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildAnswerButton(
            label: 'نعم',
            icon: Icons.check_rounded,
            color: green,
            onTap: () => _submitAnswer('yes'),
          ),
          const SizedBox(height: 10),
          _buildAnswerButton(
            label: 'لا',
            icon: Icons.close_rounded,
            color: red,
            onTap: () => _submitAnswer('no'),
          ),
          const SizedBox(height: 10),
          _buildAnswerButton(
            label: 'لا أعرف',
            icon: Icons.help_outline_rounded,
            color: amber,
            onTap: () => _submitAnswer('unknown'),
          ),
          const SizedBox(height: 20),
          _buildHintBox(
            'قاعدة أمان',
            'لا تفتح الجهاز ولا تغيّر إعدادات الجهد أو الحماية.',
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepStep() {
    final r = _response!;
    final step = r.stepText ?? '';
    final idx = r.stepIndex ?? 0;
    final total = r.totalSteps ?? 1;

    return SingleChildScrollView(
      key: ValueKey('step-${r.stepIndex}'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(idx, total, green),
          const SizedBox(height: 24),
          if (r.code != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: secondaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    r.manufacturerLabel ?? '',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.code!,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: green.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.08),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [green, green.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  step,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.7,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitStep('completed'),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'عملت هالخطوة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _submitStep('unable'),
              icon: const Icon(Icons.engineering_rounded, size: 20),
              label: Text(
                'ما بقدر / بدي فني',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: secondaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildHintBox(
            'قاعدة أمان',
            'لا تفتح الجهاز، لا تلمس الأسلاك، ولا تغيّر إعدادات الجهد أو الحماية.',
          ),
        ],
      ),
    );
  }

  Widget _buildAskResolvedStep() {
    return SingleChildScrollView(
      key: const ValueKey('ask-resolved'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.help_center_rounded, color: green, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'هل انحل العطل؟',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'إذا ما انحل، بنحوّل كل المعلومات للفني بدون ما تعيد الشرح.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitOutcome('resolved'),
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                'نعم، انحل',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _submitOutcome('unresolved'),
              icon: const Icon(Icons.engineering_rounded, size: 22),
              label: Text(
                'لا، ما انحل',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: secondaryBlue, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStep() {
    final r = _response!;
    final title = r.title ?? r.meaning ?? 'نتيجة التشخيص';
    final isCodeResult = r.code != null;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: amber.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.build_rounded, color: amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يحتاج فحص فني',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isCodeResult)
            _buildCodeResultCard(r)
          else
            _buildFaultResultCard(r),
          const SizedBox(height: 20),
          if (r.causes != null && r.causes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rule_rounded,
                          color: primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'الأسباب المحتملة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...r.causes!.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: secondaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                height: 1.6,
                                color: Colors.grey.shade800,
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
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لن تعيد الشرح — كل الإجابات والرمز تنتقل تلقائياً إلى طلب الصيانة.',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: green,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitOutcome('unresolved'),
              icon: const Icon(Icons.engineering_rounded, size: 20),
              label: Text(
                'إرسال طلب صيانة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: secondaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'إنهاء',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeResultCard(DiagnosisSessionResponse r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'بيانات المطابقة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('الشركة', r.manufacturerLabel ?? '-'),
          _buildInfoRow('السلسلة', r.familyLabel ?? '-'),
          _buildInfoRow('الرمز', r.code ?? '-', isCode: true),
          if (r.meaning != null && r.meaning!.isNotEmpty)
            _buildInfoRow('المعنى', r.meaning!),
        ],
      ),
    );
  }

  Widget _buildFaultResultCard(DiagnosisSessionResponse r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.title ?? 'نتيجة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          if (r.result != null && r.result!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.result!,
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.7,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
            textDirection: isCode ? TextDirection.ltr : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyStep() {
    final r = _response!;
    final actions = r.actions.isNotEmpty
        ? r.actions
        : [
            'لا تفتح الجهاز أو لوحة الكهرباء.',
            'ابتعد عن البطارية أو السلك أو الوحدة المتضررة.',
            'افصل التغذية فقط إذا كان ذلك آمناً ومن مفتاح معروف.',
            'عند وجود إصابة أو حريق اتصل بالطوارئ المختصة.',
          ];

    return SingleChildScrollView(
      key: const ValueKey('safety'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.warning_amber_rounded, color: red, size: 64),
          ),
          const SizedBox(height: 20),
          Text(
            'قد تكون الحالة خطرة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: red,
            ),
          ),
          if (r.matchedKeywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: r.matchedKeywords
                  .map(
                    (k) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        k,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...actions.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              height: 1.7,
                              color: Colors.grey.shade800,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitOutcome('unresolved'),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 22),
              label: Text(
                'اطلب فني عاجل',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: secondaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolvedStep() {
    return SingleChildScrollView(
      key: const ValueKey('solved'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle_rounded, color: green, size: 80),
          ),
          const SizedBox(height: 24),
          Text(
            'تم حل المشكلة',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'تم الحل بواسطة تشخيص نيكس',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّلنا النتيجة لتحسين جودة التشخيص',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchStep() {
    return SingleChildScrollView(
      key: const ValueKey('no-match'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: amber, size: 64),
          ),
          const SizedBox(height: 20),
          Text(
            'لم نتعرف على العطل',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _response?.message ??
                'ما قدرنا نطابق الوصف بدقة. جرّب وصفاً آخر أو اختر القسم.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _step = _FlowStep.symptomEntry;
                  _response = null;
                  _sessionId = null;
                  _errorMessage = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'إعادة الوصف',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: secondaryBlue, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoffStep() {
    final r = _response!;
    final handoff = r.handoff ?? {};
    final summary = handoff['summary_text']?.toString() ?? '';

    return SingleChildScrollView(
      key: const ValueKey('handoff'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: secondaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded,
                      color: secondaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ملخص جاهز للفني',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              summary.isNotEmpty ? summary : 'لا يوجد ملخص متاح.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.9,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ميزة اختيار الفني وطلب الصيانة قيد التطوير. عند الإطلاق، سيُفتح تلقائياً مع كل السياق.',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHintBox(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: secondaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: secondaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int current, int total, Color color) {
    final ratio = total > 0 ? (current + 1) / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'التقدم',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              '${current + 1} / $total',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  void _goBack() {
    switch (_step) {
      case _FlowStep.manufacturer:
      case _FlowStep.symptomEntry:
        Navigator.pop(context);
        break;
      case _FlowStep.family:
        setState(() {
          _step = _FlowStep.manufacturer;
          _families = [];
          _selectedManufacturer = null;
          _selectedManufacturerLabel = null;
        });
        break;
      case _FlowStep.codeEntry:
        setState(() {
          _step = _FlowStep.family;
          _selectedFamily = null;
          _codeController.clear();
        });
        break;
      case _FlowStep.question:
      case _FlowStep.step:
      case _FlowStep.askResolved:
      case _FlowStep.result:
      case _FlowStep.safety:
      case _FlowStep.noMatch:
      case _FlowStep.handoff:
      case _FlowStep.solved:
        _confirmExit();
        break;
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'إنهاء التشخيص؟',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        content: Text(
          'سيتم فقدان تقدمك الحالي في هذه الجلسة.',
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('متابعة', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'إنهاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
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
