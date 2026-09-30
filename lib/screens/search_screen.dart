// lib/screens/search/search_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService? authService;

  const SearchScreen({
    super.key,
    required this.apiService,
    this.authService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  double _minRate = 0;
  String _selectedSortLabel = 'الأحدث';

  List<String> _selectedGovernorates = [];
  final List<String> _syrianGovernorates = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'اللاذقية',
    'طرطوس',
    'حماة',
    'درعا',
    'السويداء',
    'القنيطرة',
    'دير الزور',
    'الرقة',
    'الحسكة',
    'إدلب'
  ];

  List<dynamic> _products = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;
  bool _showFilters = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false;
  bool _isProcessingAudio = false;
  bool _isSpeechAvailable = false;
  bool _isInitializingSpeech = false;
  bool _isMicPressed = false;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;
  Timer? _micLongPressTimer;
  String? _lastRecognizedText;
  String _selectedLocaleId = 'ar-SY';
  bool _resolveLocaleAttempted = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF7C3AED);

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'created_at', 'label': 'الأحدث', 'icon': Icons.fiber_new_rounded},
    {'value': 'rate', 'label': 'الأعلى تقييماً', 'icon': Icons.star_rounded},
    {
      'value': 'views',
      'label': 'الأكثر مشاهدة',
      'icon': Icons.visibility_rounded
    },
    {'value': 'price', 'label': 'السعر', 'icon': Icons.attach_money_rounded},
  ];

  final List<Map<String, dynamic>> _rateOptions = [
    {'value': 0, 'label': 'الكل', 'icon': Icons.star_border_rounded},
    {'value': 4, 'label': '4 نجوم فما فوق', 'icon': Icons.star_rounded},
    {'value': 3, 'label': '3 نجوم فما فوق', 'icon': Icons.star_half_rounded},
    {'value': 2, 'label': 'نجمتان فما فوق', 'icon': Icons.star_outline_rounded},
  ];

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initSpeechToText();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    try {
      _speech.cancel();
      _speech.stop();
    } catch (_) {}
    _recordingTimer?.cancel();
    _micLongPressTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initSpeechToText() async {
    if (_isInitializingSpeech) return;
    _isInitializingSpeech = true;

    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (_isSpeechAvailable && !_resolveLocaleAttempted) {
        _selectedLocaleId = await _resolveBestLocale();
        _resolveLocaleAttempted = true;
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _isSpeechAvailable = false);
      }
    } finally {
      _isInitializingSpeech = false;
    }
  }

  Future<String> _resolveBestLocale() async {
    try {
      final locales = await _speech.locales();
      final available =
      locales.map((l) => l.localeId.replaceAll('_', '-')).toSet();

      const preferred = ['ar-SY', 'ar-SA', 'ar-EG', 'ar-AE', 'ar-JO', 'ar'];
      for (final loc in preferred) {
        if (available.contains(loc)) return loc.replaceAll('-', '_');
      }

      final anyArabic = available.firstWhere(
            (l) => l.startsWith('ar'),
        orElse: () => '',
      );
      if (anyArabic.isNotEmpty) return anyArabic.replaceAll('-', '_');

      return 'ar-SY';
    } catch (_) {
      return 'ar-SY';
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;

    if (status == 'done' || status == 'notListening') {
      if (_isRecording && !_isProcessingAudio && !_isMicPressed) {
        _stopRecordingAndSearch();
      }
    } else if (status == 'listening') {
      if (!_isRecording) setState(() => _isRecording = true);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isProcessingAudio = false;
      _isMicPressed = false;
    });
    _recordingTimer?.cancel();
    _micLongPressTimer?.cancel();

    final errorMsg = error.errorMsg.toLowerCase();
    String message;

    if (errorMsg.contains('recognizernotavailable') ||
        errorMsg.contains('not available') ||
        errorMsg.contains('notavailable')) {
      message = 'خاصية التعرف على الكلام غير متاحة على هذا الجهاز.\n'
          'يرجى التأكد من تثبيت تطبيق Google وتفعيل اللغة العربية.';
    } else if (errorMsg.contains('no_match') ||
        errorMsg.contains('nomatch') ||
        errorMsg.contains('no match')) {
      message = 'لم يتم التعرف على أي كلام.\nحاول التحدث بوضوح وبصوت أعلى.';
    } else if (errorMsg.contains('audio') ||
        errorMsg.contains('microphone') ||
        errorMsg.contains('mic')) {
      message = 'حدث خطأ في التقاط الصوت.\nتأكد من عمل الميكروفون.';
    } else if (errorMsg.contains('permission') || errorMsg.contains('denied')) {
      message =
      'صلاحية الميكروفون غير ممنوحة.\nيرجى منح الصلاحية من الإعدادات.';
    } else if (errorMsg.contains('network') ||
        errorMsg.contains('internet') ||
        errorMsg.contains('connection')) {
      message =
      'انقطع الاتصال بالإنترنت.\nخدمة التعرف على الكلام تحتاج اتصالاً بالإنترنت.';
    } else if (errorMsg.contains('timeout')) {
      message = 'انتهت مهلة الاستماع.\nاضغط على الميكروفون وحاول مرة أخرى.';
    } else if (errorMsg.contains('busy') || errorMsg.contains('already')) {
      message = 'خدمة التعرف على الكلام مشغولة حالياً.\nحاول مرة أخرى بعد قليل.';
    } else {
      message = 'تعذر تحويل الصوت إلى نص.\nيرجى المحاولة مرة أخرى.';
    }

    _showSnackBar(message, dangerRed);
  }

  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) return true;

      if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog();
        return false;
      }
      _showSnackBar('يرجى منح إذن الوصول إلى الميكروفون', warningOrange);
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warningOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_off_rounded,
                  color: warningOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'صلاحية الميكروفون مطلوبة',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor),
              ),
            ),
          ],
        ),
        content: Text(
          'يحتاج التطبيق إلى الوصول إلى الميكروفون لاستخدام خاصية البحث الصوتي.\n\n'
              'يمكنك تفعيل الصلاحية من إعدادات التطبيق.',
          style:
          GoogleFonts.cairo(fontSize: 14, color: mediumGray, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('فتح الإعدادات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _onMicPointerDown() {
    if (_isRecording || _isProcessingAudio) return;

    HapticFeedback.selectionClick();
    setState(() => _isMicPressed = true);

    _micLongPressTimer?.cancel();
    _micLongPressTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isMicPressed) {
        _startRecording();
      }
    });
  }

  void _onMicPointerUp() {
    _micLongPressTimer?.cancel();

    if (!_isMicPressed) return;

    setState(() => _isMicPressed = false);

    if (_isRecording) {
      _stopRecordingAndSearch();
    }
  }

  void _onMicPointerCancel() {
    _micLongPressTimer?.cancel();

    if (!_isMicPressed) return;

    setState(() => _isMicPressed = false);

    if (_isRecording) {
      _cancelRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isProcessingAudio) return;

    try {
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        setState(() => _isMicPressed = false);
        return;
      }

      if (!_isSpeechAvailable) {
        await _initSpeechToText();

        if (!_isSpeechAvailable) {
          setState(() => _isMicPressed = false);
          _showSnackBar(
            'جهازك لا يدعم التعرف على الكلام.\n'
                'تأكد من تثبيت تطبيق Google وتفعيل اللغة العربية.',
            dangerRed,
          );
          return;
        }
      }

      HapticFeedback.mediumImpact();

      setState(() {
        _isRecording = true;
        _isProcessingAudio = false;
        _recordingProgress = 0.0;
        _lastRecognizedText = null;
      });

      _startRecordingTimer();

      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: _selectedLocaleId,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessingAudio = false;
          _isMicPressed = false;
        });
        _recordingTimer?.cancel();
        _showSnackBar('فشل بدء التسجيل الصوتي. حاول مرة أخرى.', dangerRed);
      }
    }
  }

  void _onSoundLevelChange(double level) {
    if (!mounted || !_isRecording) return;
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
    setState(() => _recordingProgress = normalized);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        _lastRecognizedText = result.recognizedWords;
        if (!result.finalResult) {
          _searchController.text = result.recognizedWords;
        }
      });
    }
  }

  String _processVoiceCommand(String text) {
    var cleaned = text.trim();

    const prefixes = [
      'ابحث لي عن ',
      'ابحث عن ',
      'ابحث ',
      'دور على ',
      'دور لي على ',
      'أريد ',
      'اريد ',
      'أرغب في ',
      'ارغب في ',
      'أبحث عن ',
      'ابحثي عن ',
      'بحث عن ',
    ];

    for (final p in prefixes) {
      if (cleaned.startsWith(p)) {
        cleaned = cleaned.substring(p.length).trim();
        break;
      }
    }

    return cleaned;
  }

  Future<void> _stopRecordingAndSearch() async {
    if (!_isRecording) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isProcessingAudio = true;
      _isRecording = false;
      _isMicPressed = false;
    });

    _recordingTimer?.cancel();
    _micLongPressTimer?.cancel();

    try {
      await _speech.stop();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    final rawText = _lastRecognizedText?.trim() ?? '';

    if (rawText.isEmpty) {
      setState(() {
        _isProcessingAudio = false;
        _recordingProgress = 0.0;
      });
      _showSnackBar('لم يتم التعرف على أي كلام. حاول مرة أخرى.', warningOrange);
      return;
    }

    final processed = _processVoiceCommand(rawText);

    if (processed.isEmpty) {
      setState(() {
        _isProcessingAudio = false;
        _recordingProgress = 0.0;
      });
      _showSnackBar('لم يتم التعرف على أي كلام. حاول مرة أخرى.', warningOrange);
      return;
    }

    setState(() {
      _isProcessingAudio = false;
      _recordingProgress = 0.0;
      _searchController.text = processed;
      _searchQuery = processed;
    });

    _saveRecentSearch(processed);
    _search();
  }

  Future<void> _cancelRecording() async {
    HapticFeedback.heavyImpact();
    _recordingTimer?.cancel();
    _micLongPressTimer?.cancel();

    try {
      await _speech.cancel();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isProcessingAudio = false;
        _isMicPressed = false;
        _recordingProgress = 0.0;
        _lastRecognizedText = null;
      });
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted || !_isRecording) {
            timer.cancel();
          }
        });
  }

  void _showSnackBar(String message, [Color? color]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              color == successGreen
                  ? Icons.check_circle_rounded
                  : color == warningOrange
                  ? Icons.warning_rounded
                  : color == dangerRed
                  ? Icons.error_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.cairo(fontSize: 13, height: 1.4)),
            ),
          ],
        ),
        backgroundColor: color ?? primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
  }

  void _loadRecentSearches() {
    _recentSearches = [];
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    if (_recentSearches.contains(query)) {
      _recentSearches.remove(query);
    }
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  void _clearRecentSearches() {
    setState(() => _recentSearches.clear());
  }

  Future<void> _search({bool loadMore = false}) async {
    if (!loadMore &&
        _searchQuery.trim().isEmpty &&
        _selectedGovernorates.isEmpty) {
      return;
    }

    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      });
      if (_searchQuery.trim().isNotEmpty) {
        _saveRecentSearch(_searchQuery);
      }
    }

    try {
      final Map<String, dynamic> params = {
        'page': _currentPage,
        'per_page': AppConstants.defaultPageSize,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
        'min_rate': _minRate,
      };

      if (_searchQuery.trim().isNotEmpty) {
        params['name'] = _searchQuery.trim();
      }
      if (_minPrice != null && _minPrice! > 0) {
        params['min_price'] = _minPrice;
      }
      if (_maxPrice != null && _maxPrice! > 0) {
        params['max_price'] = _maxPrice;
      }
      if (_selectedGovernorates.isNotEmpty) {
        params['governorate'] = _selectedGovernorates.join(',');
      }

      String endpoint;
      if (widget.authService?.isAuthenticated == true) {
        endpoint = '/v1/user/products/search';
      } else {
        final governorate = widget.authService != null
            ? await widget.authService!.storageService.getGovernorate()
            : 'دمشق';
        endpoint = '/v1/user/public/products/$governorate/search';
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: widget.authService?.isAuthenticated ?? false,
        queryParams: params,
      );

      if (response.containsKey('data') && mounted) {
        List<dynamic> newProducts = [];

        if (response['data'].containsKey('products')) {
          newProducts = response['data']['products'];
        } else if (response['data'] is List) {
          newProducts = response['data'];
        }

        final pagination = response['data']['pagination'];

        if (loadMore) {
          setState(() {
            _products.addAll(newProducts);
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _products = newProducts;
            _isLoading = false;
          });
        }

        if (pagination != null) {
          final currentPage = pagination['current_page'] ?? _currentPage;
          final lastPage = pagination['last_page'] ?? 1;
          setState(() {
            _hasMore = currentPage < lastPage;
            _currentPage = currentPage + 1;
          });
        } else {
          setState(() {
            _hasMore = newProducts.length >= AppConstants.defaultPageSize;
            if (_hasMore) _currentPage++;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في البحث';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  void _applySort(String sortBy, String sortLabel) {
    HapticFeedback.lightImpact();
    setState(() {
      _sortBy = sortBy;
      if (sortBy == 'price') {
        _sortOrder = (_sortOrder == 'asc') ? 'desc' : 'asc';
      } else {
        _sortOrder = 'desc';
      }
      _selectedSortLabel = sortLabel;
    });
    _search();
  }

  void _applyFilters() {
    setState(() => _showFilters = false);
    _search();
  }

  void _resetFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _sortBy = 'created_at';
      _sortOrder = 'desc';
      _minRate = 0;
      _selectedGovernorates = [];
      _selectedSortLabel = 'الأحدث';
    });
    _search();
  }

  void _toggleViewMode() {
    setState(() => _isGridView = !_isGridView);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F7FA)],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'البحث',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
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
                                  icon: Icon(
                                    _isGridView
                                        ? Icons.view_list_rounded
                                        : Icons.grid_view_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleViewMode,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: darkColor),
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: _isRecording
                                    ? 'استمع... تحدث الآن'
                                    : 'ابحث عن منتج...',
                                hintStyle: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.search_rounded,
                                      size: 20, color: Colors.white),
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_searchController.text.isNotEmpty &&
                                        !_isRecording)
                                      IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            color: Colors.white70, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      ),
                                    _buildMicButton(),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                      color: Colors.white, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              onSubmitted: (value) {
                                setState(() => _searchQuery = value);
                                _search();
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _sortOptions.length,
                            itemBuilder: (context, index) {
                              final option = _sortOptions[index];
                              final isSelected =
                                  _selectedSortLabel == option['label'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds: 400 + (index * 50)),
                                  curve: Curves.easeOut,
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.scale(
                                        scale: 0.8 + (0.2 * value),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => _applySort(
                                        option['value'], option['label']),
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(colors: [
                                          primaryBlue,
                                          secondaryBlue
                                        ])
                                            : LinearGradient(colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.1)
                                        ]),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: primaryBlue
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(option['icon'],
                                              size: 14,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70),
                                          const SizedBox(width: 6),
                                          Text(
                                            option['label'],
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isRecording) _buildRecordingIndicator(),
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _errorMessage != null
                    ? _buildErrorWidget()
                    : _products.isEmpty &&
                    _searchQuery.isEmpty &&
                    _selectedGovernorates.isEmpty
                    ? _buildInitialWidget()
                    : _products.isEmpty
                    ? _buildEmptyWidget()
                    : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
              ),
            ],
          ),
        ),
        floatingActionButton: _showFilters
            ? null
            : FloatingActionButton.extended(
          onPressed: () => _showFiltersSheet(),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.filter_list_rounded),
          label: Text('فلترة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return Listener(
      onPointerDown: (_) => _onMicPointerDown(),
      onPointerUp: (_) => _onMicPointerUp(),
      onPointerCancel: (_) => _onMicPointerCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording
              ? Colors.red.withOpacity(0.85)
              : _isMicPressed
              ? Colors.white.withOpacity(0.45)
              : Colors.white.withOpacity(0.18),
          boxShadow: _isRecording
              ? [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),
        child: _isProcessingAudio
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(
          _isRecording
              ? Icons.mic_rounded
              : _isMicPressed
              ? Icons.mic_rounded
              : Icons.mic_none_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        purple.withOpacity(0.12),
                        purple.withOpacity(0.06)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_alt_rounded,
                      size: 20, color: purple),
                ),
                const SizedBox(width: 10),
                Text('الفلاتر',
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGovernorateFilter(),
            const SizedBox(height: 16),
            _buildPriceFilter(),
            const SizedBox(height: 16),
            _buildRateFilter(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('إعادة تعيين',
                        style: GoogleFonts.cairo(
                            color: mediumGray, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: primaryBlue.withOpacity(0.3),
                    ),
                    child: Text('تطبيق',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernorateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المحافظة',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _syrianGovernorates.map((gov) {
            final isSelected = _selectedGovernorates.contains(gov);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGovernorates.remove(gov);
                  } else {
                    _selectedGovernorates.add(gov);
                  }
                });
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? purple.withOpacity(0.1) : lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected ? purple : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? purple : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(gov,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? purple : mediumGray,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('السعر (ل.س)',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الحد الأدنى',
                  labelStyle:
                  GoogleFonts.cairo(fontSize: 12, color: mediumGray),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => _minPrice = double.tryParse(value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الحد الأعلى',
                  labelStyle:
                  GoogleFonts.cairo(fontSize: 12, color: mediumGray),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => _maxPrice = double.tryParse(value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التقييم',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _rateOptions.map((option) {
            final isSelected = _minRate == option['value'];
            return GestureDetector(
              onTap: () => setState(() => _minRate = option['value']),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                  isSelected ? warningOrange.withOpacity(0.1) : lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected ? warningOrange : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(option['icon'],
                        size: 16,
                        color: isSelected ? warningOrange : mediumGray),
                    const SizedBox(width: 6),
                    Text(option['label'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? warningOrange : mediumGray,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: Colors.red.withOpacity(0.25))),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.15),
              child: child,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.red, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('امسك للتحدث... ارفع إصبعك للبحث',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
                const SizedBox(height: 6),
                if (_lastRecognizedText != null &&
                    _lastRecognizedText!.isNotEmpty)
                  Text(_lastRecognizedText!,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: primaryBlue,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (_lastRecognizedText != null &&
                    _lastRecognizedText!.isNotEmpty)
                  const SizedBox(height: 6),
                _buildWaveform(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Colors.red),
              onPressed: _cancelRecording),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) {
          final waveFactor =
              (math.sin((i / 20) * math.pi * 2) + 1) / 2;
          final h = 4.0 + (_recordingProgress * 20 * waveFactor);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 2.5,
            height: h.clamp(4.0, 24.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.5 + (_recordingProgress * 0.5)),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _search(loadMore: true);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) return _buildLoadingMoreIndicator();
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500 + (index * 80)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child:
                Transform.scale(scale: 0.9 + (0.1 * value), child: child),
              ),
            ),
            child: ProductCard(
              product: _products[index],
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _search(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) return _buildLoadingMoreIndicator();
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 80)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProductCard(
                product: _products[index],
                apiService: widget.apiService,
                authService: widget.authService,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitialWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.05),
                    secondaryBlue.withOpacity(0.1)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.search_rounded,
                  size: 60, color: primaryBlue.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            Text('ابحث عن منتج',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
            const SizedBox(height: 8),
            Text('اضغط مطولاً على الميكروفون للتحدث',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.05),
                    secondaryBlue.withOpacity(0.1)
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                      color: primaryBlue.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 70, color: primaryBlue.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            Text('لا توجد نتائج',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
            const SizedBox(height: 8),
            Text('جرب البحث بكلمة مختلفة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardWhite,
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 50, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _search(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _isLoadingMore
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.2),
                child: child,
              ),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.15),
                      secondaryBlue.withOpacity(0.08)
                    ],
                  ),
                ),
                child: const CircularProgressIndicator(
                    color: primaryBlue, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 12),
            Text('جاري تحميل المزيد...',
                style:
                GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
          ],
        )
            : const SizedBox.shrink(),
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