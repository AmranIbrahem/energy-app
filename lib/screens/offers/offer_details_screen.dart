// lib/screens/offers/offer_details_screen.dart

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/cart/cart_screen.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/widgets/offer_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/comparison_service.dart';

class OfferDetailsScreen extends StatefulWidget {
  final String offerSlug;
  final ApiService apiService;
  final AuthService? authService;

  const OfferDetailsScreen({
    super.key,
    required this.offerSlug,
    required this.apiService,
    this.authService,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;

  Map<String, dynamic>? _offer;
  List<dynamic> _similarOffers = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  bool _isAddingToCart = false;
  String? _errorMessage;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isAnalyzing = false;
  bool _isInComparison = false;

  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color warningOrange = Color(0xFFF59E0B);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _heartAnimationController;
  late AnimationController _cartAnimationController;

  bool get _isSypPreferred {
    final storage = widget.authService?.storageService;
    if (storage == null) return false;
    try {
      return storage.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  double _getOriginalPrice() {
    return _isSypPreferred
        ? (double.tryParse(_offer?['price_syp']?.toString() ?? '0') ?? 0)
        : (double.tryParse(_offer?['price']?.toString() ?? '0') ?? 0);
  }

  double _getFinalPrice() {
    return _isSypPreferred
        ? (double.tryParse(_offer?['final_price_syp']?.toString() ?? '0') ?? 0)
        : (double.tryParse(_offer?['final_price']?.toString() ?? '0') ?? 0);
  }

  double _getInstallationPrice() {
    return _isSypPreferred
        ? (double.tryParse(
                _offer?['installation_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(_offer?['installation_price']?.toString() ?? '0') ??
            0);
  }

  String _fmt(double price) {
    if (_isSypPreferred) {
      return '${_formatNumber(price)} SYP';
    }
    return '\$${_formatNumber(price)}';
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

  @override
  void initState() {
    super.initState();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fetchOfferDetails();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _heartAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  void _checkIfInComparison() {
    final offerId = _offer?['id'];
    if (offerId != null) {
      setState(() {
        _isInComparison =
            ComparisonService.instance.isOfferInComparison(offerId);
      });
    }
  }

  void _addToComparison() async {
    if (_offer == null) return;

    final added = await ComparisonService.instance.addOffer(_offer!);
    if (added) {
      setState(() => _isInComparison = true);
      _showSnackBar('تم إضافة العرض للمقارنة', primaryBlue);
    } else {
      _showSnackBar('لا يمكن إضافة أكثر من 4 عروض للمقارنة', Colors.orange);
    }
  }

  void _removeFromComparison() async {
    await ComparisonService.instance.removeOffer(_offer!['id']);
    setState(() => _isInComparison = false);
    _showSnackBar('تم إزالة العرض من المقارنة', Colors.orange);
  }

  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final firstChar = text.trim().characters.first;
    final arabicRegex = RegExp(
        r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    final englishRegex = RegExp(r'[a-zA-Z]');
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
    if (englishRegex.hasMatch(firstChar) || RegExp(r'\d').hasMatch(firstChar)) {
      return TextDirection.ltr;
    }
    return arabicRegex.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign _getTextAlign(String text) {
    if (text.isEmpty) return TextAlign.right;
    final firstChar = text.trim().characters.first;
    final arabicRegex = RegExp(
        r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    if (arabicRegex.hasMatch(firstChar)) return TextAlign.right;
    final arabicChars = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    final englishChars = RegExp(r'[a-zA-Z]').allMatches(text).length;
    return arabicChars > englishChars ? TextAlign.right : TextAlign.left;
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
      if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
      if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _fetchOfferDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String endpoint;

      if (widget.authService?.isAuthenticated == true) {
        endpoint = '/v1/user/offers/${widget.offerSlug}/show';
      } else {
        final governorate = widget.authService != null
            ? await widget.authService!.storageService.getGovernorate()
            : 'دمشق';
        endpoint =
            '/v1/user/public/offers/${widget.offerSlug}/show/$governorate';
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: widget.authService?.isAuthenticated ?? false,
      );

      if (response.containsKey('data') && mounted) {
        setState(() {
          _offer = response['data']['offer'];
          _similarOffers = response['data']['similar_offers'] ?? [];
          _isFavorite = _favoritesService.isOfferFavorite(_offer?['id']);
          _isLoading = false;
          _quantity = 1;
          _quantityController.text = '1';
        });
        _checkIfInComparison();
        _fadeAnimationController.forward(from: 0.0);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل العرض';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _askAIAboutOffer() async {
    final offerId = _offer?['id'];
    if (offerId == null) return;

    setState(() => _isAnalyzing = true);
    _showAnalyzingDialog();

    try {
      final endpoint = '/v1/user/public/ai/offers/$offerId/analyze';
      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: false,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response['success'] == true && mounted) {
        final analysisData = response['data'];
        _showAIAnalysisDialog(analysisData);
      } else {
        _showSnackBar(
          response['message'] ?? 'عذراً، لم نتمكن من تحليل العرض حالياً',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar('حدث خطأ في الاتصال بخدمة التحليل', Colors.red);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showAnalyzingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 4,
                      color: primaryBlue,
                      backgroundColor: primaryBlue.withOpacity(0.1),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: primaryBlue,
                      size: 30,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'جاري التحليل...',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الرجاء الانتظار قليلاً\nنحن نحلل العرض الآن',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: mediumGray,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIAnalysisDialog(Map<String, dynamic> analysisData) {
    final engineResult =
        analysisData['engine_result'] as Map<String, dynamic>? ?? {};
    final aiExplanation = analysisData['ai_explanation']?.toString() ?? '';
    final offerName = analysisData['offer_name']?.toString() ?? '';
    final analyzedAt = analysisData['analyzed_at']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              _buildAnalysisHeader(offerName, analyzedAt),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOfferScoreCards(engineResult),
                      const SizedBox(height: 20),
                      _buildStrengthsWeaknesses(engineResult),
                      const SizedBox(height: 20),
                      _buildRecommendationCard(engineResult),
                      const SizedBox(height: 20),
                      _buildAIExplanationSection(aiExplanation),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferScoreCards(Map<String, dynamic> engineResult) {
    final totalScore = engineResult['score_total']?.toString() ?? '0';
    final componentQuality =
        engineResult['score_component_quality']?.toString() ?? '0';
    final compatibilityScore =
        engineResult['score_compatibility']?.toString() ?? '0';
    final warrantyScore = engineResult['score_warranty']?.toString() ?? '0';
    final installationScore =
        engineResult['score_installation']?.toString() ?? '0';
    final valueScore = engineResult['score_value']?.toString() ?? '0';
    final compatibilityStatus =
        engineResult['compatibility_status']?.toString() ?? '';

    final statusColor = compatibilityStatus == 'compatible_within_nex_data'
        ? successGreen
        : compatibilityStatus == 'conditional'
            ? warningOrange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.amber.withOpacity(0.15),
                  Colors.amber.withOpacity(0.05)
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded,
                  size: 20, color: Colors.amber),
            ),
            const SizedBox(width: 10),
            Text('نتيجة المحرك',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.1),
                secondaryBlue.withOpacity(0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الدرجة النهائية',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mediumGray)),
                  Text('$totalScore / 100',
                      style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  compatibilityStatus == 'compatible_within_nex_data'
                      ? 'متوافق'
                      : compatibilityStatus == 'conditional'
                          ? 'مشروط'
                          : 'غير متوافق',
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                title: 'جودة المكونات',
                score: componentQuality,
                maxScore: '35',
                color: infoBlue,
                icon: Icons.settings_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScoreCard(
                title: 'التوافق',
                score: compatibilityScore,
                maxScore: '10',
                color: statusColor,
                icon: Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                title: 'الضمان',
                score: warrantyScore,
                maxScore: '30',
                color: successGreen,
                icon: Icons.shield_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScoreCard(
                title: 'التركيب',
                score: installationScore,
                maxScore: '10',
                color: Colors.purple,
                icon: Icons.build_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                title: 'القيمة',
                score: valueScore,
                maxScore: '15',
                color: warningOrange,
                icon: Icons.savings_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String score,
    required String maxScore,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mediumGray)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score,
                  style: GoogleFonts.cairo(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('/$maxScore',
                    style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsWeaknesses(Map<String, dynamic> engineResult) {
    final strengths = (engineResult['strengths'] as List?) ?? [];
    final weaknesses = (engineResult['weaknesses'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strengths.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: successGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text('نقاط القوة',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 10),
          ...strengths.map((strength) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: successGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, color: successGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strength.toString(),
                        textDirection: _getTextDirection(strength.toString()),
                        style:
                            GoogleFonts.cairo(fontSize: 13, color: darkColor),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (weaknesses.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: warningOrange, size: 18),
              ),
              const SizedBox(width: 10),
              Text('نقاط الضعف',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 10),
          ...weaknesses.map((weakness) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: warningOrange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.close_rounded, color: warningOrange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weakness.toString(),
                        textDirection: _getTextDirection(weakness.toString()),
                        style:
                            GoogleFonts.cairo(fontSize: 13, color: darkColor),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> engineResult) {
    final recommendation = engineResult['recommendation']?.toString() ?? '';
    final disclaimer = engineResult['disclaimer']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.08),
            secondaryBlue.withOpacity(0.04)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded,
                  color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text('التوصية',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            textDirection: _getTextDirection(recommendation),
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w600, color: primaryBlue),
          ),
          if (disclaimer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              disclaimer,
              textDirection: _getTextDirection(disclaimer),
              style: GoogleFonts.cairo(
                  fontSize: 11, color: mediumGray, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIExplanationSection(String aiExplanation) {
    if (aiExplanation.isEmpty) return const SizedBox.shrink();

    final sections = _parseAnalysisSections(aiExplanation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.purple.withOpacity(0.15),
                  Colors.purple.withOpacity(0.05)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.purple, size: 18),
            ),
            const SizedBox(width: 10),
            Text('شرح الذكاء الاصطناعي',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
          ],
        ),
        const SizedBox(height: 12),
        ...sections.entries.map((entry) {
          return _buildAnalysisSection(
              title: entry.key.trim(), content: entry.value.trim());
        }),
      ],
    );
  }

  Widget _buildAnalysisHeader(String offerName, String analyzedAt) {
    final bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(offerName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.05),
            secondaryBlue.withOpacity(0.02),
          ],
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.1),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasArabic ? 'تحليل الذكاء الاصطناعي' : 'AI Analysis',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        offerName,
                        textDirection: _getTextDirection(offerName),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: mediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (analyzedAt.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(analyzedAt),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required String content,
  }) {
    IconData sectionIcon;
    Color sectionColor;

    final titleLower = title.toLowerCase();

    if (titleLower.contains('مميزات') ||
        titleLower.contains('مزايا') ||
        titleLower.contains('advantages') ||
        titleLower.contains('pros')) {
      sectionIcon = Icons.check_circle_outline_rounded;
      sectionColor = successGreen;
    } else if (titleLower.contains('عيوب') ||
        titleLower.contains('ضعف') ||
        titleLower.contains('سلبيات') ||
        titleLower.contains('disadvantages') ||
        titleLower.contains('cons')) {
      sectionIcon = Icons.warning_amber_rounded;
      sectionColor = Colors.orange;
    } else if (titleLower.contains('نصيحة') ||
        titleLower.contains('توصية') ||
        titleLower.contains('advice') ||
        titleLower.contains('recommendation')) {
      sectionIcon = Icons.lightbulb_outline_rounded;
      sectionColor = Colors.amber.shade700;
    } else if (titleLower.contains('استفادة') ||
        titleLower.contains('كيفية') ||
        titleLower.contains('كيف') ||
        titleLower.contains('how to') ||
        titleLower.contains('usage') ||
        titleLower.contains('أخبارك')) {
      sectionIcon = Icons.tips_and_updates_rounded;
      sectionColor = Colors.blue;
    } else if (titleLower.contains('تقييم') ||
        titleLower.contains('عام') ||
        titleLower.contains('overview') ||
        titleLower.contains('general')) {
      sectionIcon = Icons.analytics_outlined;
      sectionColor = Colors.purple;
    } else if (titleLower.contains('جودة') ||
        titleLower.contains('أداء') ||
        titleLower.contains('قيمة') ||
        titleLower.contains('quality') ||
        titleLower.contains('performance') ||
        titleLower.contains('value')) {
      sectionIcon = Icons.insights_rounded;
      sectionColor = Colors.indigo;
    } else if (titleLower.contains('قارن') ||
        titleLower.contains('مقارنة') ||
        titleLower.contains('compare') ||
        titleLower.contains('سعر')) {
      sectionIcon = Icons.compare_arrows_rounded;
      sectionColor = Colors.teal;
    } else {
      sectionIcon = Icons.article_outlined;
      sectionColor = primaryBlue;
    }

    final List<String> items = _parseListItems(content);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(sectionIcon, color: sectionColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textDirection: _getTextDirection(title),
                  textAlign: _getTextAlign(title),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.length > 1)
            ...items.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final item = entry.value;
              final displayText =
                  sectionIcon == Icons.check_circle_outline_rounded ||
                          sectionIcon == Icons.warning_amber_rounded
                      ? '${itemIndex + 1}. $item'
                      : item;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: sectionColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayText,
                        textDirection: _getTextDirection(displayText),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.6,
                          color: mediumGray,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Text(
              content,
              textDirection: _getTextDirection(content),
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.6,
                color: mediumGray,
              ),
            ),
        ],
      ),
    );
  }

  Map<String, String> _parseAnalysisSections(String analysis) {
    final Map<String, String> sections = {};

    final lines = analysis.split('\n');
    String currentTitle = 'تقييم عام';
    StringBuffer currentContent = StringBuffer();
    bool hasArabicContent = false;

    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (RegExp(r'[\u0600-\u06FF]').hasMatch(trimmedLine)) {
        hasArabicContent = true;
      }

      final headerMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(trimmedLine);

      if (headerMatch != null) {
        if (currentContent.isNotEmpty) {
          sections[currentTitle] = currentContent.toString().trim();
        }

        currentTitle = headerMatch.group(1)!.replaceAll(':', '').trim();
        currentContent = StringBuffer();

        final remainingText =
            trimmedLine.replaceFirst(headerMatch.group(0)!, '').trim();
        if (remainingText.isNotEmpty) {
          currentContent.writeln(remainingText);
        }
      } else {
        currentContent.writeln(trimmedLine);
      }
    }

    if (currentContent.isNotEmpty) {
      sections[currentTitle] = currentContent.toString().trim();
    }

    if (sections.isEmpty) {
      final defaultTitle = hasArabicContent ? 'تحليل العرض' : 'Offer Analysis';
      sections[defaultTitle] = analysis;
    }

    return sections;
  }

  List<String> _parseListItems(String content) {
    final mixedNumberedRegex = RegExp(r'[\d\u0660-\u0669]+\.\s+');

    if (mixedNumberedRegex.hasMatch(content)) {
      final parts = content
          .split(mixedNumberedRegex)
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.length > 1) {
        return parts;
      }
    }

    final bulletRegex = RegExp(r'[-•*◉○‣⁃◦◘◙◆◇▪▫]\s+');
    if (bulletRegex.hasMatch(content)) {
      final parts =
          content.split(bulletRegex).where((s) => s.trim().isNotEmpty).toList();
      if (parts.length > 1) {
        return parts;
      }
    }

    final arabicBulletRegex = RegExp(r'^[\s]*[-–—•]+\s*');
    if (content
        .split('\n')
        .any((line) => arabicBulletRegex.hasMatch(line.trimLeft()))) {
      return content
          .split('\n')
          .map((line) => line.replaceFirst(arabicBulletRegex, '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [content];
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isUpdatingFavorite = true);

    try {
      final offerId = _offer!['id'];

      if (_isFavorite) {
        await _favoritesService.removeOffer(offerId);
        setState(() => _isFavorite = false);
        _heartAnimationController.reverse();
        _showSnackBar('تم إزالة العرض من المفضلة', Colors.orange);
      } else {
        final offerData = {
          'id': _offer!['id'],
          'name_ar': _offer!['name_ar'],
          'name_en': _offer!['name_en'],
          'slug': _offer!['slug'],
          'price': _offer!['price'],
          'final_price': _offer!['final_price'],
          'discount_price': _offer!['discount_price'],
          'price_syp': _offer!['price_syp'],
          'final_price_syp': _offer!['final_price_syp'],
          'discount_price_syp': _offer!['discount_price_syp'],
          'cover_image': _offer!['cover_image'],
          'main_image': _offer!['main_image'],
          'discount_percentage': _offer!['discount_percentage'],
          'total_wattage': _offer!['total_wattage'],
          'total_capacity': _offer!['total_capacity'],
          'rate': _offer!['rate'],
          'governorate_offer': _offer!['governorate_offer'],
        };
        await _favoritesService.addOffer(offerData);
        setState(() => _isFavorite = true);
        _heartAnimationController.forward();
        _showSnackBar('تم إضافة العرض إلى المفضلة', primaryBlue);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
    } finally {
      setState(() => _isUpdatingFavorite = false);
    }
  }

  void _increaseQuantity() {
    final int stock = _offer?['stock'] ?? -1;
    if (stock > 0 && _quantity >= stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }
    setState(() {
      _quantity++;
      _quantityController.text = '$_quantity';
    });
    HapticFeedback.lightImpact();
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _quantityController.text = '$_quantity';
      });
      HapticFeedback.lightImpact();
    }
  }

  void _setQuantity(String value) {
    if (value.isEmpty) {
      return;
    }

    final parsed = int.tryParse(value);
    final int stock = _offer?['stock'] ?? -1;

    if (parsed == null) return;

    if (parsed <= 0) {
      return;
    }

    if (stock > 0 && parsed > stock) {
      setState(() {
        _quantity = stock;
        _quantityController.text = '$stock';
      });
      _showSnackBar(
          'هذه الكمية غير متوفرة - الكمية المتاحة: $stock فقط', Colors.orange);
    } else {
      setState(() {
        _quantity = parsed;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _addOfferToCart() {
    final int stock = _offer?['stock'] ?? -1;

    if (stock > 0 && _quantity > stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }

    setState(() => _isAddingToCart = true);
    _cartAnimationController.forward();

    final cartService = CartService.instance;

    final existingQuantity = cartService.getItemQuantity(
      _offer!['id'],
      itemType: 'offer',
    );

    final bool isExisting = existingQuantity > 0;

    final cartItem = CartItemModel.fromOffer(
      _offer!,
      quantity: _quantity,
    );

    cartService.addOffer(cartItem);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _cartAnimationController.reset();
        HapticFeedback.heavyImpact();
      }
    });

    if (isExisting) {
      _showSnackBar(
        'تم تحديث كمية العرض: ${_offer!['name_ar']}\nالكمية الجديدة: ${existingQuantity + _quantity}',
        primaryBlue,
      );
    } else {
      _showSnackBar(
        'تم إضافة $_quantity × ${_offer!['name_ar']} إلى السلة',
        primaryBlue,
      );
    }

    _showGoToCartDialog();
  }

  void _showGoToCartDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.15),
                      secondaryBlue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: primaryBlue, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'تمت الإضافة بنجاح',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          content: Text(
            'تم إضافة العرض إلى سلة المشتريات. هل تريد الذهاب إلى السلة الآن؟',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('مواصلة التسوق',
                  style: GoogleFonts.cairo(
                      color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(
                      apiService: widget.apiService,
                      authService: widget.authService!,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _isFavorite =
                          _favoritesService.isOfferFavorite(_offer?['id']);
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('الذهاب إلى السلة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
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
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
  }

  void _openImageGallery(int initialIndex) {
    List<String> images = [];
    if (_offer?['cover_image'] != null) {
      images.add(_offer!['cover_image']);
    }
    if (_offer?['additional_images'] != null) {
      images.addAll(List<String>.from(_offer!['additional_images']));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSpecifications() {
    final specs = _offer?['specifications'];
    if (specs == null) return [];

    List<dynamic> specsData = [];
    if (specs is List) {
      specsData = specs;
    } else if (specs is String) {
      try {
        specsData = jsonDecode(specs) as List;
      } catch (_) {
        return [];
      }
    }

    return specsData
        .map((spec) {
          if (spec is Map) {
            return {
              'key': spec['key']?.toString() ?? '',
              'value': spec['value']?.toString() ?? '',
            };
          }
          return {'key': '', 'value': ''};
        })
        .where((spec) => spec['key']!.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _getShippingCitiesWithCosts() {
    final rawCities = _offer?['shipping_cities'];
    if (rawCities == null) return [];

    List<dynamic> citiesData = [];
    if (rawCities is List) {
      citiesData = rawCities;
    } else if (rawCities is String) {
      try {
        citiesData = jsonDecode(rawCities) as List;
      } catch (_) {
        return [];
      }
    }

    return citiesData.map((cityData) {
      if (cityData is String) {
        return {'city': cityData, 'cost': null};
      }
      if (cityData is Map) {
        return {
          'city': cityData['city']?.toString() ?? '',
          'cost': cityData['cost']?.toString(),
        };
      }
      return {'city': '', 'cost': null};
    }).toList();
  }

  Widget _buildShippingCard() {
    final shippingCities = _getShippingCitiesWithCosts();
    final currentGov =
        widget.authService?.storageService.getGovernorate() ?? 'دمشق';
    final bool isInCurrentGov =
        shippingCities.any((c) => c['city'] == currentGov);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [infoBlue.withOpacity(0.06), infoBlue.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: infoBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: successGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'الشحن متاح',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: successGreen,
                ),
              ),
              if (isInCurrentGov) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'متوفر في $currentGov',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (shippingCities.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'مدن الشحن والأسعار:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: mediumGray,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shippingCities.map((cityData) {
                final city = cityData['city']?.toString() ?? '';
                final cost = cityData['cost']?.toString();

                Color bgColor;
                Color borderColor;
                Color textColor;
                IconData icon;
                if (cost == null || cost.isEmpty) {
                  bgColor = Colors.grey.shade100;
                  borderColor = Colors.grey.shade300;
                  textColor = Colors.grey.shade600;
                  icon = Icons.question_mark_rounded;
                } else if (double.tryParse(cost) == 0) {
                  bgColor = const Color(0xFFD1FAE5);
                  borderColor = const Color(0xFF6EE7B7);
                  textColor = const Color(0xFF065F46);
                  icon = Icons.emoji_events_rounded;
                } else {
                  final price = double.tryParse(cost) ?? 0;
                  if (price <= 5000) {
                    bgColor = Colors.blue.shade50;
                    borderColor = Colors.blue.shade200;
                    textColor = Colors.blue.shade700;
                    icon = Icons.local_shipping_rounded;
                  } else if (price <= 15000) {
                    bgColor = Colors.orange.shade50;
                    borderColor = Colors.orange.shade200;
                    textColor = Colors.orange.shade700;
                    icon = Icons.local_shipping_rounded;
                  } else {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red.shade200;
                    textColor = Colors.red.shade700;
                    icon = Icons.local_shipping_rounded;
                  }
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: textColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        city,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (cost == null || cost.isEmpty)
                        Text(
                          'يحدد لاحقاً',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        )
                      else if (double.tryParse(cost) == 0)
                        Text(
                          'شحن مجاني',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        )
                      else
                        Text(
                          Helpers.formatPrice(double.tryParse(cost) ?? 0),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'جميع المحافظات',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
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
          child: _isLoading
              ? _buildShimmerLoading()
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildOfferContent(),
        ),
        bottomNavigationBar:
            _isLoading || _errorMessage != null ? null : _buildBottomBar(),
      ),
    );
  }

  Widget _buildOfferContent() {
    final bool hasDiscount = (_offer?['discount_percentage'] ?? 0) > 0;

    final double finalPrice = _getFinalPrice();
    final double originalPrice = _getOriginalPrice();
    final double installationPrice = _getInstallationPrice();

    final int totalWattage = _offer?['total_wattage'] ?? 0;
    final int totalCapacity = _offer?['total_capacity'] ?? 0;
    final int views = _offer?['views'] ?? 0;
    final double rate =
        double.tryParse(_offer?['rate']?.toString() ?? '0') ?? 0;
    final double totalPrice = finalPrice * _quantity;
    final String governorate = _offer?['governorate_offer']?.toString() ?? '';
    final specifications = _getSpecifications();

    List<String> images = [];
    if (_offer?['cover_image'] != null) {
      images.add(_offer!['cover_image']);
    }
    if (_offer?['additional_images'] != null) {
      images.addAll(List<String>.from(_offer!['additional_images']));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardWhite.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: darkColor, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openImageGallery(_selectedImageIndex),
                  onDoubleTap: () => _openImageGallery(_selectedImageIndex),
                  child: Hero(
                    tag: _offer!['cover_image'] ?? 'offer_image',
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _selectedImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.discount_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('خصم ${_offer!['discount_percentage']}%',
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 50,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _openImageGallery(_selectedImageIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('عرض الصور (${images.length})',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _selectedImageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _selectedImageIndex == index
                                ? const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue])
                                : null,
                            color: _selectedImageIndex == index
                                ? null
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedImageIndex == index
                                ? [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.5),
                                      blurRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimationController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fadeAnimationController,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardWhite.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (rate > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade100,
                                  Colors.amber.shade200,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  rate.toStringAsFixed(1),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                Helpers.formatNumber(views),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (governorate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7C3AED).withOpacity(0.1),
                                  const Color(0xFF7C3AED).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 16, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 4),
                                Text(
                                  governorate,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _offer?['name_ar'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (totalWattage > 0)
                          _buildInfoTag(
                            icon: Icons.bolt_rounded,
                            label: '$totalWattage واط',
                            color: Colors.orange,
                          ),
                        if (totalCapacity > 0)
                          _buildInfoTag(
                            icon: Icons.battery_charging_full_rounded,
                            label: '$totalCapacity واط/ساعة',
                            color: Colors.blue,
                          ),
                        if (installationPrice > 0)
                          _buildInfoTag(
                            icon: Icons.build_rounded,
                            label: 'تركيب: ${_fmt(installationPrice)}',
                            color: Colors.purple,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryBlue.withOpacity(0.08),
                            secondaryBlue.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السعر',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: mediumGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (hasDiscount) ...[
                            Text(
                              _fmt(originalPrice),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            _fmt(finalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_offer?['has_shipping'] == true) ...[
                      _buildShippingCard(),
                      const SizedBox(height: 24),
                    ],
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الكمية:',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryBlue.withOpacity(0.08),
                                  secondaryBlue.withOpacity(0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    onTap: _decreaseQuantity,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.remove_rounded,
                                        size: 22,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    controller: _quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    onChanged: _setQuantity,
                                    onTap: () {
                                      _quantityController.selection =
                                          TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _quantityController.text.length,
                                      );
                                    },
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    onTap: _increaseQuantity,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 22,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'الإجمالي',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: mediumGray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmt(totalPrice),
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_offer?['description_ar'] != null &&
                        _offer!['description_ar'].isNotEmpty) ...[
                      _buildSectionTitle(
                          'وصف العرض', Icons.description_rounded),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(),
                      const SizedBox(height: 24),
                    ],
                    if (specifications.isNotEmpty) ...[
                      _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
                      const SizedBox(height: 12),
                      ...specifications.map((spec) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  spec['key']!,
                                  textDirection:
                                      _getTextDirection(spec['key']!),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  spec['value']!,
                                  textDirection:
                                      _getTextDirection(spec['value']!),
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                    if (_offer?['components'] != null &&
                        (_offer!['components'] as List).isNotEmpty) ...[
                      _buildSectionTitle('المكونات', Icons.settings_rounded),
                      const SizedBox(height: 12),
                      ...(_offer!['components'] as List).map((component) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  component['key'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Text(
                                component['value'] ?? '',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                    if (_offer?['products_in_offer'] != null &&
                        (_offer!['products_in_offer'] as List).isNotEmpty) ...[
                      _buildSectionTitle(
                          'المنتجات المشمولة', Icons.inventory_2_rounded),
                      const SizedBox(height: 12),
                      ...(_offer!['products_in_offer'] as List).map((product) {
                        return _buildProductInOfferCard(product);
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                    if (_similarOffers.isNotEmpty) ...[
                      _buildSectionTitle(
                          'عروض مشابهة', Icons.recommend_rounded),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _similarOffers.length,
                          itemBuilder: (context, index) {
                            final offer = _similarOffers[index];
                            return TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration:
                                  Duration(milliseconds: 400 + (index * 100)),
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
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: OfferCard(
                                  offer: offer,
                                  apiService: widget.apiService,
                                  authService: widget.authService,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text('التفاصيل الكاملة',
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
        trailing: const Icon(Icons.expand_more_rounded, color: primaryBlue),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(_offer!['description_ar'],
                style: GoogleFonts.cairo(
                    fontSize: 14, height: 1.6, color: mediumGray)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInOfferCard(dynamic product) {
    final int quantity = product['quantity'] ?? 1;
    final String name = product['name_ar'] ?? '';
    final String imageUrl = product['main_image'] ?? '';
    final String unit = product['unit'] ?? 'piece';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productSlug: product['slug'],
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          setState(() {
            _isFavorite = _favoritesService.isOfferFavorite(_offer?['id']);
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product_in_offer_${product['id']}',
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.12),
                          secondaryBlue.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'الكمية: $quantity $unit',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.08),
                    secondaryBlue.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: primaryBlue),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final double finalPrice = _getFinalPrice();
    final double totalPrice = finalPrice * _quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'analyze') {
                  _askAIAboutOffer();
                } else if (value == 'compare') {
                  if (_isInComparison) {
                    _removeFromComparison();
                  } else {
                    _addToComparison();
                  }
                }
              },
              offset: const Offset(0, -120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardWhite,
              elevation: 10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.08),
                      secondaryBlue.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 28,
                  color: primaryBlue,
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'analyze',
                  child: Row(
                    children: [
                      _isAnalyzing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: primaryBlue,
                                size: 20,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Text(
                        _isAnalyzing
                            ? 'جاري التحليل...'
                            : 'تحليل بالذكاء الاصطناعي',
                        style:
                            GoogleFonts.cairo(fontSize: 14, color: darkColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isInComparison
                              ? primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: _isInComparison ? primaryBlue : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isInComparison
                            ? 'إزالة من المقارنة'
                            : 'إضافة للمقارنة',
                        style:
                            GoogleFonts.cairo(fontSize: 14, color: darkColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isFavorite
                      ? [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05)
                        ]
                      : [Colors.grey.shade100, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isFavorite
                      ? Colors.red.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: IconButton(
                onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
                icon: _isUpdatingFavorite
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _heartAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                1.0 + (_heartAnimationController.value * 0.3),
                            child: child,
                          );
                        },
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 26,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _cartAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 - (_cartAnimationController.value * 0.05),
                    child: child,
                  );
                },
                child: ElevatedButton(
                  onPressed: _isAddingToCart ? null : _addOfferToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 5,
                    shadowColor: primaryBlue.withOpacity(0.5),
                  ),
                  child: _isAddingToCart
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'جاري الإضافة...',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'أضف إلى السلة',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _fmt(totalPrice),
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 350,
            color: Colors.grey.shade300,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 20,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
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
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 50, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchOfferDetails,
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
}
