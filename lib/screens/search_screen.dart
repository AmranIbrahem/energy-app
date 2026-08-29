// lib/screens/search/search_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/widgets/product_card.dart';

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

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  double _minRate = 0;

  // ✅ متغيرات فلترة المحافظة
  List<String> _selectedGovernorates = [];
  final List<String> _syrianGovernorates = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'حماة', 'درعا',
    'السويداء', 'القنيطرة', 'دير الزور', 'الرقة', 'الحسكة', 'إدلب'
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

  // ✅ متغيرات التعرف على الكلام
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false;
  bool _isProcessingAudio = false;
  bool _isSpeechAvailable = false;
  bool _isInitializingSpeech = false;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;
  String? _lastRecognizedText;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

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

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initSpeechToText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _recordingTimer?.cancel();
    _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  // ==================== ✅ التعرف على الكلام ====================

  // ✅ تهيئة خدمة التعرف على الكلام
  Future<void> _initSpeechToText() async {
    if (_isInitializingSpeech) return;
    _isInitializingSpeech = true;

    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (mounted) {
        setState(() {});
        if (!_isSpeechAvailable) {
          debugPrint('⚠️ Speech recognition not available on this device');
        } else {
          debugPrint('✅ Speech recognition initialized successfully');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing speech: $e');
      if (mounted) {
        setState(() => _isSpeechAvailable = false);
      }
    } finally {
      _isInitializingSpeech = false;
    }
  }

  // ✅ معالجة حالة التسجيل
  void _onSpeechStatus(String status) {
    debugPrint('🎤 Speech status: $status');

    if (!mounted) return;

    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isRecording = false;
        _isProcessingAudio = false;
      });
      _recordingTimer?.cancel();
    } else if (status == 'listening') {
      setState(() => _isRecording = true);
    }
  }

  // ✅ معالجة الأخطاء
// ✅ معالجة الأخطاء - النسخة الصحيحة
  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('❌ Speech error: ${error.errorMsg}');

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isProcessingAudio = false;
    });
    _recordingTimer?.cancel();

    // ✅ رسائل خطأ واضحة بالعربي - نفحص errorMsg بدلاً من errorCode
    String message;
    final errorMsg = error.errorMsg.toLowerCase();

    if (errorMsg.contains('recognizernotavailable') ||
        errorMsg.contains('recognizer_not_available') ||
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
    } else if (errorMsg.contains('permission') ||
        errorMsg.contains('permissions') ||
        errorMsg.contains('denied')) {
      message = 'صلاحية الميكروفون غير ممنوحة.\nيرجى منح الصلاحية من الإعدادات.';
    } else if (errorMsg.contains('network') ||
        errorMsg.contains('internet') ||
        errorMsg.contains('timeout') ||
        errorMsg.contains('connection')) {
      message = 'انقطع الاتصال بالإنترنت.\nخدمة التعرف على الكلام تحتاج اتصالاً بالإنترنت.';
    } else if (errorMsg.contains('timeout') ||
        errorMsg.contains('speech_timeout')) {
      message = 'انتهت مهلة الاستماع.\nاضغط على الميكروفون وحاول مرة أخرى.';
    } else if (errorMsg.contains('busy') ||
        errorMsg.contains('already')) {
      message = 'خدمة التعرف على الكلام مشغولة حالياً.\nحاول مرة أخرى بعد قليل.';
    } else {
      message = 'تعذر تحويل الصوت إلى نص.\nيرجى المحاولة مرة أخرى.\n(${error.errorMsg})';
    }

    _showSnackBar(message, dangerRed);
  }
  // ✅ طلب إذن الميكروفون
  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog();
        return false;
      } else {
        _showSnackBar('يرجى منح إذن الوصول إلى الميكروفون', warningOrange);
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  // ✅ عرض نافذة عند رفض الصلاحية نهائياً
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
          style: GoogleFonts.cairo(fontSize: 14, color: mediumGray, height: 1.6),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('فتح الإعدادات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ✅ بدء التسجيل
  Future<void> _startRecording() async {
    if (_isRecording || _isProcessingAudio) return;

    try {
      // ✅ طلب إذن الميكروفون
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) return;

      // ✅ إذا لم تكن الخدمة مهيأة، حاول التهيئة مرة أخرى
      if (!_isSpeechAvailable) {
        _showSnackBar('جاري فحص خاصية التعرف على الكلام...', warningOrange);
        await _initSpeechToText();

        if (!_isSpeechAvailable) {
          _showSnackBar(
            'عذراً، جهازك لا يدعم خاصية التعرف على الكلام.\n'
                'تأكد من تثبيت تطبيق Google وتفعيل اللغة العربية في الإعدادات.',
            dangerRed,
          );
          return;
        }
      }

      setState(() {
        _isRecording = true;
        _isProcessingAudio = false;
        _recordingProgress = 0.0;
        _lastRecognizedText = null;
      });

      _startRecordingTimer();

      // ✅ بدء الاستماع مع تحديد اللغة العربية
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        localeId: 'ar_SY', // ✅ العربية السورية
      );
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessingAudio = false;
        });
        _recordingTimer?.cancel();
        _showSnackBar('فشل بدء التسجيل الصوتي. حاول مرة أخرى.', dangerRed);
      }
    }
  }

  // ✅ معالجة نتيجة التعرف على الكلام
  void _onSpeechResult(SpeechRecognitionResult result) {
    debugPrint('🎤 Recognized: ${result.recognizedWords}');
    debugPrint('🎤 Final: ${result.finalResult}');

    if (!mounted) return;

    // ✅ تحديث النص الجزئي أثناء التحدث
    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        _lastRecognizedText = result.recognizedWords;
      });
    }

    // ✅ عند اكتمال التعرف
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      final recognizedText = result.recognizedWords.trim();

      setState(() {
        _searchController.text = recognizedText;
        _searchQuery = recognizedText;
        _isRecording = false;
        _isProcessingAudio = false;
      });

      _recordingTimer?.cancel();
      _speech.stop();

      if (recognizedText.isNotEmpty) {
        _showSnackBar('تم التعرف على: "$recognizedText"', successGreen);
        _search();
      }
    }
  }

  // ✅ إيقاف التسجيل يدوياً
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isProcessingAudio = true;
        _isRecording = false;
      });

      _recordingTimer?.cancel();
      await _speech.stop();

      // ✅ استخدام النص الأخير إذا لم تكن هناك نتيجة نهائية
      if (_lastRecognizedText != null && _lastRecognizedText!.isNotEmpty) {
        setState(() {
          _searchController.text = _lastRecognizedText!;
          _searchQuery = _lastRecognizedText!;
        });
        _search();
      } else {
        _showSnackBar('لم يتم التعرف على أي كلام. حاول مرة أخرى.', warningOrange);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isProcessingAudio = false);
        }
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessingAudio = false;
      });
    }
  }

  // ✅ إلغاء التسجيل
  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      await _speech.cancel();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessingAudio = false;
          _recordingProgress = 0.0;
          _lastRecognizedText = null;
        });
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  // ✅ مؤقت شريط التقدم
  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (mounted && _isRecording) {
            setState(() {
              _recordingProgress += 0.01;
              if (_recordingProgress >= 1.0) {
                _recordingProgress = 0.0;
              }
            });
          } else {
            timer.cancel();
          }
        });
  }

  // ✅ عرض رسالة
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

  // ==================== ✅ البحث ====================

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
    setState(() {
      _recentSearches.clear();
    });
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
    });
    _search();
  }

  void _toggleViewMode() {
    setState(() => _isGridView = !_isGridView);
  }

  // ==================== ✅ Build ====================

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
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: GoogleFonts.cairo(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: _isRecording
                  ? 'استمع... تحدث الآن'
                  : 'ابحث عن منتج...',
              hintStyle: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white70, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                  // ✅ زر التسجيل الصوتي
                  IconButton(
                    icon: _isRecording
                        ? Icon(Icons.stop_rounded,
                        color: Colors.red.shade300, size: 24)
                        : _isProcessingAudio
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.mic_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: _isRecording
                        ? _stopRecording
                        : _isProcessingAudio
                        ? null
                        : _startRecording,
                  ),
                ],
              ),
            ),
            onSubmitted: (value) {
              setState(() => _searchQuery = value);
              _search();
            },
          ),
        ),
        elevation: 0,
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
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showFilters
                    ? Icons.filter_list_off_rounded
                    : Icons.filter_list_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8, left: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleViewMode,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ مؤشر التسجيل
          if (_isRecording) _buildRecordingIndicator(),
          if (_showFilters) _buildFiltersPanel(),
          // ✅ عرض المحافظات المحددة كـ Chips
          if (_selectedGovernorates.isNotEmpty && !_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cardWhite,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedGovernorates.map((gov) {
                  return Chip(
                    label: Text(gov,
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: primaryBlue)),
                    onDeleted: () {
                      setState(() => _selectedGovernorates.remove(gov));
                      _search();
                    },
                    deleteIcon: const Icon(Icons.close_rounded,
                        size: 14, color: primaryBlue),
                    backgroundColor: primaryBlue.withOpacity(0.08),
                    side: BorderSide(color: primaryBlue.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
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
    );
  }

  // ✅ واجهة مؤشر التسجيل
  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جاري التسجيل... تحدث الآن',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ عرض النص الجزئي أثناء التحدث
                if (_lastRecognizedText != null &&
                    _lastRecognizedText!.isNotEmpty)
                  Text(
                    _lastRecognizedText!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: primaryBlue,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _recordingProgress,
                    backgroundColor: Colors.red.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: Colors.red),
            onPressed: _cancelRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ قسم فلترة المحافظة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.12),
                      const Color(0xFF7C3AED).withOpacity(0.06)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    size: 18, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 10),
              Text(
                'المحافظة',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkColor),
              ),
              const Spacer(),
              if (_selectedGovernorates.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedGovernorates.clear()),
                  child: Text('إلغاء الكل',
                      style: GoogleFonts.cairo(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _syrianGovernorates.map((governorate) {
              final isSelected = _selectedGovernorates.contains(governorate);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGovernorates.remove(governorate);
                    } else {
                      _selectedGovernorates.add(governorate);
                    }
                  });
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withOpacity(0.1)
                        : lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        governorate,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // ✅ أزرار التطبيق
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
                  onPressed: _applyFilters,
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
    );
  }

  Widget _buildInitialWidget() {
    return Center(
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
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ],
            ),
            child:
            Icon(Icons.search_rounded, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text('ابحث عن منتج',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: darkColor)),
          const SizedBox(height: 8),
          Text('اكتب اسم المنتج الذي تبحث عنه أو استخدم البحث الصوتي',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
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
                color: cardWhite, borderRadius: BorderRadius.circular(20)),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
                    offset: const Offset(0, 5))
              ],
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 50, color: Colors.red.shade300),
          ),
          const SizedBox(height: 20),
          Text(_errorMessage!,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
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
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Icon(Icons.search_off_rounded,
                size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text('لا توجد نتائج',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: darkColor)),
          const SizedBox(height: 8),
          Text('جرب البحث بكلمة مختلفة',
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return _buildLoadingMoreIndicator();
        }
        final product = _products[index];
        return ProductCard(
          product: product,
          apiService: widget.apiService,
          authService: widget.authService,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return _buildLoadingMoreIndicator();
        }
        final product = _products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProductCard(
            product: product,
            apiService: widget.apiService,
            authService: widget.authService,
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: primaryBlue)
            : const SizedBox.shrink(),
      ),
    );
  }
}