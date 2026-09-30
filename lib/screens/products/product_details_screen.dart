import 'dart:convert';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/comparison_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productSlug;
  final ApiService apiService;
  final AuthService? authService;

  const ProductDetailsScreen({
    super.key,
    required this.productSlug,
    required this.apiService,
    this.authService,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _SpecStyle {
  final IconData icon;
  final Color color;

  const _SpecStyle(this.icon, this.color);
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;

  Map<String, dynamic>? _product;
  List<dynamic> _similarProducts = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  String? _errorMessage;
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
  static const Color wholesaleGreen = Color(0xFF16A34A);
  static const Color wholesaleLight = Color(0xFF22C55E);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color warningOrange = Color(0xFFF59E0B);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _heartAnimationController;
  late AnimationController _cartAnimationController;

  int _quantity = 1;
  bool _isAddingToCart = false;
  int _currentImageIndex = 0;

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
        ? (double.tryParse(_product?['price_syp']?.toString() ?? '0') ?? 0)
        : (double.tryParse(_product?['price']?.toString() ?? '0') ?? 0);
  }

  double _getFinalPrice() {
    return _isSypPreferred
        ? (double.tryParse(_product?['final_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(_product?['final_price']?.toString() ?? '0') ?? 0);
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

    _fetchProductDetails();
    _checkIfInComparison();
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

  Color _getRatingColor(String text) {
    final match = RegExp(r'(\d+\.?\d*)/(\d+)').firstMatch(text);
    if (match != null) {
      final score = double.parse(match.group(1)!);
      final maxScore = double.parse(match.group(2)!);
      final percentage = score / maxScore;
      if (percentage >= 0.8) return successGreen;
      if (percentage >= 0.6) return Colors.orange;
      return Colors.red;
    }
    return mediumGray;
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

  Future<void> _askAIAboutProduct() async {
    final productId = _product?['id'];
    if (productId == null) return;

    setState(() => _isAnalyzing = true);
    _showAnalyzingDialog();

    try {
      final endpoint = '/v1/user/public/ai/products/$productId/analyze';
      final response =
          await widget.apiService.get(endpoint, requiresAuth: false);

      if (mounted) Navigator.pop(context);

      if (response['success'] == true && mounted) {
        _showAIAnalysisDialog(response['data']);
      } else {
        _showSnackBar(
            response['message'] ?? 'عذراً، لم نتمكن من تحليل المنتج حالياً',
            Colors.red);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
                'الرجاء الانتظار قليلاً\nنحن نحلل المنتج الآن',
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
    final productName = analysisData['product_name']?.toString() ?? '';
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
                  offset: const Offset(0, -10)),
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
                      colors: [Colors.grey.shade400, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              _buildAnalysisHeader(productName, analyzedAt),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEngineScoreCards(engineResult),
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

  void _discussProductWithAI() {
    if (_product == null) return;

    final StringBuffer message = StringBuffer();
    message.writeln('🛍️ **مناقشة منتج**');
    message.writeln('');
    message.writeln('📦 **اسم المنتج:** ${_product!['name_ar'] ?? ''}');

    if (_product!['brand'] != null) {
      message.writeln('🏷️ **الماركة:** ${_product!['brand']}');
    }
    if (_product!['model'] != null) {
      message.writeln('🔧 **الموديل:** ${_product!['model']}');
    }

    message.writeln('');
    message.writeln('💰 **السعر:** ${_fmt(_getEffectivePrice())}');

    if ((_product!['discount_percentage'] ?? 0) > 0) {
      message.writeln('🏷️ **الخصم:** ${_product!['discount_percentage']}%');
    }

    if (_product!['warranty'] != null) {
      message.writeln('🛡️ **الضمان:** ${_product!['warranty']}');
    }

    message.writeln('');
    message.writeln('📋 **المواصفات:**');

    final specs = _product!['specifications'] as List? ?? [];
    for (var spec in specs) {
      final key = spec['key']?.toString() ?? '';
      final value = spec['value']?.toString() ?? '';
      message.writeln('  • $key: $value');
    }

    if (_product!['description_ar'] != null &&
        _product!['description_ar'].isNotEmpty) {
      message.writeln('');
      message.writeln('📝 **الوصف:**');
      message.writeln(_product!['description_ar'].toString().substring(
            0,
            _product!['description_ar'].toString().length > 300
                ? 300
                : _product!['description_ar'].toString().length,
          ));
      if (_product!['description_ar'].toString().length > 300) {
        message.writeln('...');
      }
    }

    message.writeln('');
    message
        .writeln('أريد مناقشة هذا المنتج ومعرفة المزيد من التفاصيل والتوصيات.');

    final storageService =
        widget.authService?.storageService ?? StorageService();
    final token = storageService.getToken();
    final isGuest = token == null || token.isEmpty;

    if (isGuest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuestChatScreen(
            apiService: widget.apiService,
            storageService: storageService,
            initialMessage: message.toString(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            authService: widget.authService!,
            apiService: widget.apiService,
            initialMessage: message.toString(),
          ),
        ),
      );
    }
  }

  Widget _buildAnalysisHeader(String productName, String analyzedAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, secondaryBlue],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تحليل نيكس',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        productName,
                        textDirection: _getTextDirection(productName),
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.white70),
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
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(analyzedAt),
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineScoreCards(Map<String, dynamic> engineResult) {
    final totalScore = engineResult['total_score']?.toString() ?? '0';
    final technicalQuality =
        engineResult['technical_quality']?.toString() ?? '0';
    final warrantyScore = engineResult['warranty_score']?.toString() ?? '0';
    final valueScore = engineResult['value_score']?.toString() ?? '0';
    final confidence = engineResult['confidence']?.toString() ?? '0';
    final confidenceLevel =
        engineResult['confidence_level']?.toString() ?? 'low';

    final confidenceColor = confidenceLevel == 'high'
        ? successGreen
        : confidenceLevel == 'medium'
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
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                title: 'الدرجة النهائية',
                score: totalScore,
                maxScore: '100',
                color: primaryBlue,
                icon: Icons.emoji_events_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScoreCard(
                title: 'الجودة الفنية',
                score: technicalQuality,
                maxScore: '55',
                color: infoBlue,
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
                title: 'القيمة',
                score: valueScore,
                maxScore: '15',
                color: warningOrange,
                icon: Icons.savings_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: confidenceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: confidenceColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded, color: confidenceColor, size: 20),
              const SizedBox(width: 10),
              Text('الثقة:',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mediumGray)),
              const SizedBox(width: 6),
              Text('$confidence%',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: confidenceColor)),
              const Spacer(),
              Text(
                confidenceLevel == 'high'
                    ? 'عالية'
                    : confidenceLevel == 'medium'
                        ? 'متوسطة'
                        : 'منخفضة',
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: confidenceColor),
              ),
            ],
          ),
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
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
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

  Widget _buildAnalysisSection(
      {required String title, required String content}) {
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
        titleLower.contains('how to') ||
        titleLower.contains('usage')) {
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
              offset: const Offset(0, 3))
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
                    borderRadius: BorderRadius.circular(10)),
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
                      color: darkColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.length > 1)
            ...items.asMap().entries.map((entry) {
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
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFormattedText(entry.value)),
                  ],
                ),
              );
            })
          else
            _buildFormattedText(content),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final isRating = RegExp(r'\d+\.?\d*/\d+').hasMatch(text.trim());
    if (text.contains('**')) {
      final List<InlineSpan> spans = [];
      final parts = text.split('**');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isEmpty) continue;
        final cleanPart = parts[i].trim();
        final isPartRating = RegExp(r'\d+\.?\d*/\d+').hasMatch(cleanPart);
        spans.add(WidgetSpan(
          child: Text(
            parts[i],
            textDirection: _getTextDirection(parts[i]),
            style: GoogleFonts.cairo(
              fontWeight: i % 2 == 1
                  ? FontWeight.bold
                  : (isPartRating ? FontWeight.w600 : FontWeight.normal),
              fontSize: 14,
              height: 1.6,
              color: i % 2 == 1
                  ? darkColor
                  : (isPartRating ? _getRatingColor(cleanPart) : mediumGray),
            ),
          ),
        ));
      }
      return RichText(
        textAlign: _getTextAlign(text),
        textDirection: _getTextDirection(text),
        text: TextSpan(children: spans),
      );
    }
    return Text(
      text,
      textAlign: _getTextAlign(text),
      textDirection: _getTextDirection(text),
      style: GoogleFonts.cairo(
        fontSize: 14,
        height: 1.6,
        color: isRating ? _getRatingColor(text.trim()) : mediumGray,
        fontWeight: isRating ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Map<String, String> _parseAnalysisSections(String analysis) {
    final Map<String, String> sections = {};
    final lines = analysis.split('\n');
    String currentTitle = 'تقييم عام';
    StringBuffer currentContent = StringBuffer();

    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      final headerMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(trimmedLine);
      if (headerMatch != null) {
        if (currentContent.isNotEmpty)
          sections[currentTitle] = currentContent.toString().trim();
        currentTitle = headerMatch.group(1)!.replaceAll(':', '').trim();
        currentContent = StringBuffer();
        final remainingText =
            trimmedLine.replaceFirst(headerMatch.group(0)!, '').trim();
        if (remainingText.isNotEmpty) currentContent.writeln(remainingText);
      } else {
        currentContent.writeln(trimmedLine);
      }
    }
    if (currentContent.isNotEmpty)
      sections[currentTitle] = currentContent.toString().trim();
    if (sections.isEmpty) sections['تحليل المنتج'] = analysis;
    return sections;
  }

  List<String> _parseListItems(String content) {
    final mixedNumberedRegex = RegExp(r'[\d\u0660-\u0669]+\.\s+');
    if (mixedNumberedRegex.hasMatch(content)) {
      final parts = content
          .split(mixedNumberedRegex)
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.length > 1) return parts;
    }
    final bulletRegex = RegExp(r'[-•*◉○‣⁃◦◘◙◆◇▪▫]\s+');
    if (bulletRegex.hasMatch(content)) {
      final parts =
          content.split(bulletRegex).where((s) => s.trim().isNotEmpty).toList();
      if (parts.length > 1) return parts;
    }
    return [content];
  }

  void _checkIfInComparison() {
    final productId = _product?['id'];
    if (productId != null) {
      setState(() => _isInComparison =
          ComparisonService.instance.isProductInComparison(productId));
    }
  }

  void _addToComparison() async {
    if (_product == null) return;
    final added = await ComparisonService.instance.addProduct(_product!);
    if (added) {
      setState(() => _isInComparison = true);
      _showSnackBar('تم إضافة المنتج للمقارنة', primaryBlue);
    } else {
      _showSnackBar('لا يمكن إضافة أكثر من 4 منتجات للمقارنة', Colors.orange);
    }
  }

  void _removeFromComparison() async {
    await ComparisonService.instance.removeProduct(_product!['id']);
    setState(() => _isInComparison = false);
    _showSnackBar('تم إزالة المنتج من المقارنة', Colors.orange);
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String endpoint;
      bool requiresAuth;
      if (widget.authService?.isAuthenticated == true) {
        endpoint = '/v1/user/products/${widget.productSlug}/show';
        requiresAuth = true;
      } else {
        final governorate =
            widget.authService?.storageService.getGovernorate() ?? 'دمشق';
        endpoint =
            '/v1/user/public/products/${widget.productSlug}/show/$governorate';
        requiresAuth = false;
      }
      final response =
          await widget.apiService.get(endpoint, requiresAuth: requiresAuth);
      if (response.containsKey('data') && mounted) {
        setState(() {
          _product = response['data']['product'];
          _similarProducts = response['data']['similar_products'] ?? [];
          _isFavorite = _favoritesService.isProductFavorite(_product?['id']);
          _isLoading = false;
          _quantity = 1;
          _quantityController.text = '1';
        });
        _fadeAnimationController.forward(from: 0.0);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل المنتج';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isUpdatingFavorite = true);
    try {
      final productId = _product!['id'];
      if (_isFavorite) {
        await _favoritesService.removeProduct(productId);
        setState(() => _isFavorite = false);
        _heartAnimationController.reverse();
        _showSnackBar('تم إزالة المنتج من المفضلة', Colors.orange);
      } else {
        final productData = {
          'id': _product!['id'],
          'name_ar': _product!['name_ar'],
          'name_en': _product!['name_en'],
          'slug': _product!['slug'],
          'price': _product!['price'],
          'final_price': _product!['final_price'],
          'discount_price': _product!['discount_price'],
          'price_syp': _product!['price_syp'],
          'final_price_syp': _product!['final_price_syp'],
          'discount_price_syp': _product!['discount_price_syp'],
          'main_image': _product!['main_image'],
          'cover_image': _product!['cover_image'],
          'discount_percentage': _product!['discount_percentage'],
          'brand': _product!['brand'],
          'rate': _product!['rate'],
          'stock': _product!['stock'],
          'governorate_product': _product!['governorate_product'],
        };
        await _favoritesService.addProduct(productData);
        setState(() => _isFavorite = true);
        _heartAnimationController.forward();
        _showSnackBar('تم إضافة المنتج إلى المفضلة', primaryBlue);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
    } finally {
      setState(() => _isUpdatingFavorite = false);
    }
  }

  double _getEffectivePrice() {
    final bool isSyp = _isSypPreferred;

    final double defaultFinalPrice = isSyp
        ? (double.tryParse(_product?['final_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(_product?['final_price']?.toString() ?? '0') ?? 0);

    final bool hasWholesale = _product?['has_wholesale'] == true;
    final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;

    final double wholesalePrice = isSyp
        ? (double.tryParse(
                _product?['wholesale_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(_product?['wholesale_price']?.toString() ?? '0') ??
            0);

    if (hasWholesale && _quantity >= wholesaleMinQty && wholesalePrice > 0) {
      return wholesalePrice;
    }
    return defaultFinalPrice;
  }

  List<Map<String, dynamic>> _getShippingCitiesWithCosts() {
    final rawCities = _product?['shipping_cities'];
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

  void _addToCart() {
    final int stock = _product?['stock'] ?? 0;
    if (_quantity > stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }

    setState(() => _isAddingToCart = true);
    _cartAnimationController.forward();

    final cartService = CartService.instance;
    final double originalPrice = _getOriginalPrice();
    final double effectivePrice = _getEffectivePrice();

    final bool hasWholesale = _product?['has_wholesale'] == true;
    final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;
    final bool isWholesaleApplied =
        hasWholesale && _quantity >= wholesaleMinQty;

    final existingItem = cartService.items.firstWhere(
      (item) => item.id == _product!['id'],
      orElse: () => CartItemModel(
          id: 0, name: '', slug: '', price: 0, finalPrice: 0, stock: 0),
    );

    final bool isExisting = existingItem.id != 0;
    final int oldQuantity = isExisting ? existingItem.quantity : 0;

    List<Map<String, dynamic>> shippingCities = _getShippingCitiesWithCosts();

    final cartItem = CartItemModel(
      id: _product!['id'],
      name: _product!['name_ar'] ?? 'غير معروف',
      slug: _product!['slug'] ?? '',
      price: originalPrice,
      finalPrice: effectivePrice,
      image: _product!['main_image']?.toString(),
      stock: stock,
      quantity: _quantity,
      discountPercentage: _product!['discount_percentage']?.toDouble(),
      shippingCities: shippingCities.isNotEmpty ? shippingCities : null,
    );

    cartService.addItem(cartItem);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _cartAnimationController.reset();
        HapticFeedback.heavyImpact();
      }
    });

    String message;
    if (isWholesaleApplied) {
      message =
          '🎉 تم تطبيق سعر الجملة!\n${_product!['name_ar']}\nالكمية: $_quantity × ${_fmt(effectivePrice)}';
    } else if (isExisting) {
      message =
          'تم تحديث الكمية: ${_product!['name_ar']}\nالكمية: $oldQuantity → ${oldQuantity + _quantity}';
    } else {
      message = 'تم إضافة $_quantity × ${_product!['name_ar']} إلى السلة';
    }

    _showSnackBar(message, isWholesaleApplied ? wholesaleGreen : primaryBlue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
                color == primaryBlue || color == wholesaleGreen
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
  }

  void _increaseQuantity() {
    final int stock = _product?['stock'] ?? 0;
    if (_quantity < stock) {
      setState(() {
        _quantity++;
        _quantityController.text = '$_quantity';
      });
      HapticFeedback.lightImpact();
      _checkWholesaleThreshold();
    } else {
      _showSnackBar('لا يمكن زيادة الكمية عن المتوفر ($stock)', Colors.orange);
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _quantityController.text = '$_quantity';
      });
      HapticFeedback.lightImpact();
      _checkWholesaleThreshold();
    }
  }

  void _setQuantity(String value) {
    if (value.isEmpty) {
      return;
    }

    final parsed = int.tryParse(value);
    final int stock = _product?['stock'] ?? 0;

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
      _checkWholesaleThreshold();
    }
  }

  void _checkWholesaleThreshold() {
    final bool hasWholesale = _product?['has_wholesale'] == true;
    final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;

    if (hasWholesale && wholesaleMinQty > 0) {
      if (_quantity == wholesaleMinQty) {
        _showSnackBar('🎉 تم تفعيل سعر الجملة!', wholesaleGreen);
      } else if (_quantity == wholesaleMinQty - 1) {
        _showSnackBar(
            'أضف قطعة واحدة إضافية للاستفادة من سعر الجملة', Colors.orange);
      }
    }
  }

  void _openImageGallery(int initialIndex) {
    List<String> images = [];
    if (_product?['main_image'] != null) images.add(_product!['main_image']);
    if (_product?['additional_images'] != null)
      images.addAll(List<String>.from(_product!['additional_images']));

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
                    borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
              ),
            ),
            body: PhotoViewGallery.builder(
              itemCount: images.length,
              pageController: PageController(initialPage: initialIndex),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
              ),
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ));
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
                        colors: [wholesaleLight, wholesaleGreen]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: wholesaleGreen.withOpacity(0.3),
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

  Widget _buildWholesaleCard() {
    final bool isSyp = _isSypPreferred;

    final double wholesalePrice = isSyp
        ? (double.tryParse(
                _product!['wholesale_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(_product!['wholesale_price']?.toString() ?? '0') ??
            0);

    final int wholesaleMinQty = _product!['wholesale_min_quantity'] ?? 0;

    final double originalPrice = _getOriginalPrice();
    final double saveAmount = originalPrice - wholesalePrice;
    final int savePercent =
        originalPrice > 0 ? ((saveAmount / originalPrice) * 100).round() : 0;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(opacity: value, child: child));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              wholesaleLight.withOpacity(0.12),
              wholesaleGreen.withOpacity(0.06)
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF86EFAC).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: wholesaleLight.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
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
                    gradient: const LinearGradient(
                        colors: [wholesaleLight, wholesaleGreen]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: wholesaleLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Icon(Icons.warehouse_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('سعر الجملة',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF166534))),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [wholesaleLight, wholesaleGreen]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: wholesaleLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('وفر $savePercent%',
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(wholesalePrice),
                    style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: wholesaleGreen)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF166534).withOpacity(0.7))),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('للوحدة',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: const Color(0xFF166534).withOpacity(0.6))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFF86EFAC).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: wholesaleLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.shopping_basket_rounded,
                        color: wholesaleGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: const Color(0xFF166534)),
                        children: [
                          const TextSpan(text: 'الحد الأدنى للطلب: '),
                          TextSpan(
                              text: '$wholesaleMinQty قطعة',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: wholesaleLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('وفر ${_fmt(saveAmount)}',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: wholesaleGreen)),
                  ),
                ],
              ),
            ),
            if (_quantity >= wholesaleMinQty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: wholesaleLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: wholesaleLight.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: wholesaleGreen, size: 18),
                      SizedBox(width: 8),
                      Text('تم تفعيل سعر الجملة تلقائياً!',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF166534))),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
                  : _buildProductContent(),
        ),
        bottomNavigationBar:
            _isLoading || _errorMessage != null ? null : _buildBottomBar(),
      ),
    );
  }

  Widget _buildProductContent() {
    final bool hasDiscount = (_product?['discount_percentage'] ?? 0) > 0;
    final double originalPrice = _getOriginalPrice();
    final double effectivePrice = _getEffectivePrice();
    final int stock = _product?['stock'] ?? 0;
    final bool inStock = stock > 0;
    final double rate =
        double.tryParse(_product?['rate']?.toString() ?? '0') ?? 0;
    final int views = _product?['views'] ?? 0;
    final double totalPrice = effectivePrice * _quantity;
    final bool hasWholesale = _product?['has_wholesale'] == true;
    final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;

    List<String> images = [];
    if (_product?['main_image'] != null) images.add(_product!['main_image']);
    if (_product?['additional_images'] != null)
      images.addAll(List<String>.from(_product!['additional_images']));

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
                    offset: const Offset(0, 3))
              ],
            ),
            child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: darkColor, size: 22),
                onPressed: () => Navigator.pop(context)),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openImageGallery(_currentImageIndex),
                  onDoubleTap: () => _openImageGallery(_currentImageIndex),
                  child: Hero(
                    tag: _product!['main_image'] ?? 'product_image',
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: primaryBlue, strokeWidth: 2))),
                        errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_rounded,
                                size: 60, color: Colors.grey)),
                      ),
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
                          Text('خصم ${_product!['discount_percentage']}%',
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
                    onTap: () => _openImageGallery(_currentImageIndex),
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: _currentImageIndex == index
                                      ? const LinearGradient(
                                          colors: [primaryBlue, secondaryBlue])
                                      : null,
                                  color: _currentImageIndex == index
                                      ? null
                                      : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _currentImageIndex == index
                                      ? [
                                          BoxShadow(
                                              color:
                                                  primaryBlue.withOpacity(0.5),
                                              blurRadius: 5)
                                        ]
                                      : null,
                                ),
                              )),
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
              position:
                  Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: _fadeAnimationController,
                          curve: Curves.easeOutCubic)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardWhite.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(
                        color: primaryBlue.withOpacity(0.06),
                        blurRadius: 25,
                        offset: const Offset(0, -10))
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
                              gradient: LinearGradient(colors: [
                                Colors.amber.shade100,
                                Colors.amber.shade200
                              ]),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(rate.toStringAsFixed(1),
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800)),
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
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(Helpers.formatNumber(views),
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _shareProduct();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.share_rounded,
                                  color: primaryBlue, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(_product?['name_ar'] ?? '',
                        style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                            height: 1.3)),
                    const SizedBox(height: 12),
                    if (_product?['brand'] != null ||
                        _product?['model'] != null ||
                        _product?['governorate_product'] != null)
                      Row(
                        children: [
                          if (_product?['brand'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  primaryBlue.withOpacity(0.1),
                                  secondaryBlue.withOpacity(0.05)
                                ]),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: primaryBlue.withOpacity(0.2)),
                              ),
                              child: Text(_product!['brand'],
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue)),
                            ),
                          ],
                          if (_product?['model'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(15)),
                              child: Text(_product!['model'],
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: Colors.grey.shade700)),
                            ),
                          ],
                          if (_product?['governorate_product'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  successGreen.withOpacity(0.1),
                                  successGreen.withOpacity(0.05)
                                ]),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: successGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: successGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _product!['governorate_product'],
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_product?['warranty'] != null)
                          _buildInfoTag(
                              icon: Icons.security_rounded,
                              label: 'ضمان ${_product!['warranty']}',
                              color: Colors.blue),
                        if (_product?['unit'] != null)
                          _buildInfoTag(
                              icon: Icons.straighten_rounded,
                              label: 'الوحدة: ${_product!['unit']}',
                              color: Colors.purple),
                        _buildInfoTag(
                            icon: inStock
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            label:
                                inStock ? 'متوفر ($stock قطعة)' : 'غير متوفر',
                            color: inStock ? successGreen : Colors.red),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildPriceCard(originalPrice, effectivePrice, hasDiscount,
                        hasWholesale, wholesaleMinQty),
                    if (hasWholesale) ...[
                      const SizedBox(height: 16),
                      _buildWholesaleCard(),
                    ],
                    const SizedBox(height: 24),
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
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الكمية:',
                              style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor)),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                primaryBlue.withOpacity(0.08),
                                secondaryBlue.withOpacity(0.04)
                              ]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: primaryBlue.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(20),
                                        bottomRight: Radius.circular(20)),
                                    onTap: _decreaseQuantity,
                                    child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(Icons.remove_rounded,
                                            size: 22, color: primaryBlue)),
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
                                        bottomLeft: Radius.circular(20)),
                                    onTap: _increaseQuantity,
                                    child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: const Icon(Icons.add_rounded,
                                            size: 22, color: primaryBlue)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('الإجمالي',
                                      style: GoogleFonts.cairo(
                                          fontSize: 12, color: mediumGray)),
                                  if (hasWholesale &&
                                      _quantity >= wholesaleMinQty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color:
                                              wholesaleLight.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text('جملة',
                                          style: GoogleFonts.cairo(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: wholesaleGreen)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(_fmt(totalPrice),
                                  style: GoogleFonts.cairo(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: hasWholesale &&
                                              _quantity >= wholesaleMinQty
                                          ? wholesaleGreen
                                          : primaryBlue)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_product?['description_ar'] != null &&
                        _product!['description_ar'].isNotEmpty) ...[
                      _buildSectionTitle('الوصف', Icons.description_rounded),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(),
                      const SizedBox(height: 24),
                    ],
                    if (_product?['specifications'] != null &&
                        (_product!['specifications'] as List).isNotEmpty) ...[
                      _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
                      const SizedBox(height: 12),
                      _buildSpecificationsCard(),
                      const SizedBox(height: 24),
                    ],
                    if (_product?['has_shipping'] == true) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('الشحن', Icons.local_shipping_rounded),
                      const SizedBox(height: 12),
                      _buildShippingCard(),
                    ],
                    if (_similarProducts.isNotEmpty) ...[
                      _buildSectionTitle(
                          'منتجات مشابهة', Icons.recommend_rounded),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _similarProducts.length,
                          itemBuilder: (context, index) {
                            final product = _similarProducts[index];
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
                                        child: child));
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ProductCard(
                                    product: product,
                                    apiService: widget.apiService,
                                    authService: widget.authService),
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

  Widget _buildPriceCard(double originalPrice, double effectivePrice,
      bool hasDiscount, bool hasWholesale, int wholesaleMinQty) {
    final double finalPrice = _getFinalPrice();
    final double discountPercent = hasDiscount && originalPrice > 0
        ? ((originalPrice - finalPrice) / originalPrice * 100)
            .clamp(0, 100)
            .toDouble()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryBlue.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('السعر',
                  style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
              const Spacer(),
              if (hasDiscount)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFEF5350), Color(0xFFE53935)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('وفّر ${_fmt(originalPrice - effectivePrice)}',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasDiscount) ...[
            Text(_fmt(originalPrice),
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 4),
          ],
          Text(_fmt(effectivePrice),
              style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue)),
          if (hasDiscount) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: discountPercent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  discountPercent >= 50
                      ? Colors.red.shade500
                      : Colors.orange.shade500,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('نسبة الخصم: ${discountPercent.round()}%',
                    style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
              ],
            ),
          ],
        ],
      ),
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
            child: Text(_product!['description_ar'],
                style: GoogleFonts.cairo(
                    fontSize: 14, height: 1.6, color: mediumGray)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard() {
    final specs = _product!['specifications'] as List;
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: specs.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final spec = specs[index];
          final key = spec['key']?.toString() ?? '';
          final value = spec['value']?.toString() ?? '';
          final style = _getSpecStyle(key);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        style.color.withOpacity(0.15),
                        style.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: style.color.withOpacity(0.15), width: 0.5),
                  ),
                  child: Icon(style.icon, size: 18, color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    key,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: mediumGray,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _SpecStyle _getSpecStyle(String key) {
    final k = key.toLowerCase().trim();
    if (k.contains('عدد المداخل الشمسية') ||
        k.contains('المداخل الشمسية') ||
        k.contains('عدد المداخل')) {
      return const _SpecStyle(Icons.solar_power_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('تصنيف استخدام') ||
        k.contains('تصنيف الاستخدام') ||
        k.contains('استخدام المحول')) {
      return const _SpecStyle(Icons.home_work_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('أمبير ساعي') ||
        k.contains('أمبير/ساعي') ||
        k.contains('ampere hour') ||
        k.contains('ampere-hour') ||
        k.contains('ah')) {
      return const _SpecStyle(
          Icons.battery_charging_full_rounded, Color(0xFF10B981));
    }
    if (k.contains('نوع المنتج') ||
        k.contains('نوع الجهاز') ||
        k.contains('نوع اللوح') ||
        k.contains('نوع العاكس') ||
        k.contains('نوع البطارية') ||
        k.contains('نوع الموديل') ||
        k.contains('نوع الموصل') ||
        k.contains('نوع التيار') ||
        k.contains('نوع المرشح') ||
        k.contains('نوع التغذية') ||
        k.contains('نوع المحرك') ||
        k.contains('نوع القهوة')) {
      return const _SpecStyle(Icons.category_rounded, Color(0xFF6366F1));
    }

    if (k.contains('ماركة') ||
        k.contains('العلامة التجارية') ||
        k.contains('brand')) {
      return const _SpecStyle(Icons.verified_rounded, Color(0xFF2563EB));
    }

    if (k.contains('موديل') || k.contains('model') || k.contains('طراز')) {
      return const _SpecStyle(Icons.qr_code_rounded, Color(0xFF4F46E5));
    }

    if (k.contains('الدارة المفتوحة') || k.contains('voc')) {
      return const _SpecStyle(Icons.electric_bolt_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('جهد التشغيل') || k.contains('vmp')) {
      return const _SpecStyle(
          Icons.electrical_services_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('جهد') || k.contains('فولت') || k.contains('volt')) {
      return const _SpecStyle(Icons.electric_bolt_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('تيار') || k.contains('أمبير') || k.contains('ampere')) {
      return const _SpecStyle(Icons.electric_meter_rounded, Color(0xFFEA580C));
    }

    if (k.contains('استطاعة') ||
        k.contains('قدرة') ||
        k.contains('طاقة') ||
        k.contains('واط') ||
        k.contains('watt') ||
        k.contains('كيلوواط')) {
      return const _SpecStyle(Icons.flash_on_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('تيار مستمر') ||
        k.contains('تيار متناوب') ||
        k.contains('ac') ||
        k.contains('dc')) {
      return const _SpecStyle(Icons.swap_horiz_rounded, Color(0xFFDC2626));
    }

    if (k.contains('الطور') || k.contains('phase')) {
      return const _SpecStyle(Icons.tune_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('تردد') || k.contains('هرتز') || k.contains('hz')) {
      return const _SpecStyle(Icons.graphic_eq_rounded, Color(0xFF06B6D4));
    }

    if (k.contains('ليثيوم') || k.contains('lithium')) {
      return const _SpecStyle(
          Icons.battery_charging_full_rounded, Color(0xFF059669));
    }

    if (k.contains('عمق التفريغ') || k.contains('تفريغ')) {
      return const _SpecStyle(Icons.trending_down_rounded, Color(0xFFDC2626));
    }

    if (k.contains('دورات') || k.contains('دورة') || k.contains('cycles')) {
      return const _SpecStyle(Icons.autorenew_rounded, Color(0xFF06B6D4));
    }

    if (k.contains('بطارية') || k.contains('battery')) {
      return const _SpecStyle(Icons.battery_std_rounded, Color(0xFF059669));
    }

    if (k.contains('سعة') || k.contains('حجم') || k.contains('capacity')) {
      return const _SpecStyle(Icons.battery_std_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('الأبعاد') ||
        k.contains('طول') ||
        k.contains('عرض') ||
        k.contains('ارتفاع') ||
        k.contains('سمك') ||
        k.contains('dimensions')) {
      return const _SpecStyle(Icons.straighten_rounded, Color(0xFF8B4513));
    }

    if (k.contains('وزن') || k.contains('weight')) {
      return const _SpecStyle(Icons.scale_rounded, Color(0xFF14B8A6));
    }

    if (k.contains('قطر') || k.contains('مروحة')) {
      return const _SpecStyle(Icons.toys_rounded, Color(0xFF0EA5E9));
    }

    if (k.contains('سرعة') || k.contains('rpm')) {
      return const _SpecStyle(Icons.speed_rounded, Color(0xFF2563EB));
    }

    if (k.contains('مساحة المقطع') || k.contains('مقطع')) {
      return const _SpecStyle(Icons.crop_square_rounded, Color(0xFF8B4513));
    }

    if (k.contains('نواقل') || k.contains('ناقل')) {
      return const _SpecStyle(Icons.cable_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('طول الرول') || k.contains('الرول')) {
      return const _SpecStyle(Icons.waves_rounded, Color(0xFF8B4513));
    }

    if (k.contains('قدرة القطع')) {
      return const _SpecStyle(Icons.content_cut_rounded, Color(0xFFDC2626));
    }

    if (k.contains('أقطاب') || k.contains('قطب')) {
      return const _SpecStyle(Icons.account_tree_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('لومن') || k.contains('شدة الإضاءة')) {
      return const _SpecStyle(Icons.light_mode_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('زاوية الإضاءة') || k.contains('زاوية')) {
      return const _SpecStyle(Icons.architecture_rounded, Color(0xFFD97706));
    }

    if (k.contains('درجة حرارة اللون') ||
        k.contains('كلفن') ||
        k.contains('kelvin')) {
      return const _SpecStyle(Icons.color_lens_rounded, Color(0xFFEC4899));
    }

    if (k.contains('لون الإضاءة') ||
        k.contains('لون') ||
        k.contains('color') ||
        k.contains('ألوان')) {
      return const _SpecStyle(Icons.palette_rounded, Color(0xFFEC4899));
    }

    if (k.contains('حرارة') || k.contains('temperature')) {
      return const _SpecStyle(Icons.thermostat_rounded, Color(0xFFDC2626));
    }

    if (k.contains('تبريد') || k.contains('تجميد') || k.contains('cooling')) {
      return const _SpecStyle(Icons.ac_unit_rounded, Color(0xFF0EA5E9));
    }

    if (k.contains('تدفئة') || k.contains('تسخين') || k.contains('heating')) {
      return const _SpecStyle(Icons.whatshot_rounded, Color(0xFFEA580C));
    }

    if (k.contains('بخار') || k.contains('steam')) {
      return const _SpecStyle(Icons.cloud_rounded, Color(0xFF94A3B8));
    }

    if (k.contains('غاز') || k.contains('gas')) {
      return const _SpecStyle(
          Icons.local_fire_department_rounded, Color(0xFFDC2626));
    }

    if (k.contains('مناخية') || k.contains('مناخ')) {
      return const _SpecStyle(Icons.wb_sunny_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('كفاءة') || k.contains('efficiency')) {
      return const _SpecStyle(Icons.speed_rounded, Color(0xFF059669));
    }

    if (k.contains('خزان') || k.contains('ماء')) {
      return const _SpecStyle(Icons.water_drop_rounded, Color(0xFF0EA5E9));
    }

    if (k.contains('تدفق') || k.contains('flow')) {
      return const _SpecStyle(Icons.water_rounded, Color(0xFF0284C7));
    }

    if (k.contains('ضغط') || k.contains('bar') || k.contains('pressure')) {
      return const _SpecStyle(Icons.compress_rounded, Color(0xFFEF4444));
    }

    if (k.contains('مرشح') || k.contains('فلتر') || k.contains('filter')) {
      return const _SpecStyle(Icons.filter_alt_rounded, Color(0xFF059669));
    }

    if (k.contains('هواء') || k.contains('airflow') || k.contains('دفع')) {
      return const _SpecStyle(Icons.air_rounded, Color(0xFF0EA5E9));
    }

    if (k.contains('شفط') || k.contains('suction')) {
      return const _SpecStyle(Icons.air_rounded, Color(0xFF3B82F6));
    }

    if (k.contains('غبار') || k.contains('dust')) {
      return const _SpecStyle(
          Icons.cleaning_services_rounded, Color(0xFF64748B));
    }

    if (k.contains('ضجيج') || k.contains('ديسيبل') || k.contains('noise')) {
      return const _SpecStyle(Icons.volume_up_rounded, Color(0xFF64748B));
    }

    if (k.contains('حماية') ||
        k.contains('أمان') ||
        k.contains('ip') ||
        k.contains('safety')) {
      return const _SpecStyle(Icons.shield_rounded, Color(0xFF10B981));
    }

    if (k.contains('وسائل')) {
      return const _SpecStyle(
          Icons.health_and_safety_rounded, Color(0xFF10B981));
    }

    if (k.contains('ضمان') || k.contains('warranty')) {
      return const _SpecStyle(Icons.verified_user_rounded, Color(0xFF2563EB));
    }

    if (k.contains('ميزات') ||
        k.contains('وظائف') ||
        k.contains('ملحقات') ||
        k.contains('features')) {
      return const _SpecStyle(Icons.auto_awesome_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('تحكم') || k.contains('control')) {
      return const _SpecStyle(Icons.settings_remote_rounded, Color(0xFF6366F1));
    }

    if (k.contains('تركيب') || k.contains('installation')) {
      return const _SpecStyle(Icons.build_rounded, Color(0xFF64748B));
    }

    if (k.contains('عدد السرعات') || k.contains('سرعات')) {
      return const _SpecStyle(Icons.speed_rounded, Color(0xFF2563EB));
    }

    if (k.contains('عدد البرامج') || k.contains('برامج')) {
      return const _SpecStyle(Icons.apps_rounded, Color(0xFF6366F1));
    }

    if (k.contains('عدد الأطقم') || k.contains('أطقم') || k.contains('طقم')) {
      return const _SpecStyle(Icons.restaurant_rounded, Color(0xFF8B5CF6));
    }

    if (k.contains('عيون')) {
      return const _SpecStyle(Icons.blur_circular_rounded, Color(0xFFEA580C));
    }

    if (k.contains('شرائح') || k.contains('شريحة')) {
      return const _SpecStyle(Icons.view_agenda_rounded, Color(0xFF8B5CF6));
    }

    if (k.contains('سلال') || k.contains('صفائح')) {
      return const _SpecStyle(Icons.grid_view_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('شاشة') ||
        k.contains('دقة') ||
        k.contains('معدل تحديث') ||
        k.contains('screen') ||
        k.contains('display')) {
      return const _SpecStyle(Icons.tv_rounded, Color(0xFF2563EB));
    }

    if (k.contains('اتصال') ||
        k.contains('لاسلكي') ||
        k.contains('بلوتوث') ||
        k.contains('wifi')) {
      return const _SpecStyle(Icons.wifi_rounded, Color(0xFF3B82F6));
    }

    if (k.contains('مداخل') ||
        k.contains('usb') ||
        k.contains('hdmi') ||
        k.contains('منافذ')) {
      return const _SpecStyle(Icons.usb_rounded, Color(0xFF64748B));
    }

    if (k.contains('سنوي') || k.contains('annual')) {
      return const _SpecStyle(Icons.calendar_today_rounded, Color(0xFF8B5CF6));
    }

    if (k.contains('مدة') || k.contains('زمن') || k.contains('timer')) {
      return const _SpecStyle(Icons.timer_rounded, Color(0xFF06B6D4));
    }

    if (k.contains('للدورة') || k.contains('per cycle')) {
      return const _SpecStyle(Icons.refresh_rounded, Color(0xFF06B6D4));
    }

    if (k.contains('حليب') || k.contains('milk')) {
      return const _SpecStyle(Icons.coffee_rounded, Color(0xFFEAB308));
    }

    if (k.contains('مطحنة') || k.contains('طحن') || k.contains('grinder')) {
      return const _SpecStyle(Icons.coffee_maker_rounded, Color(0xFF78350F));
    }

    if (k.contains('سطح الكي') || k.contains('كي')) {
      return const _SpecStyle(Icons.iron_rounded, Color(0xFF64748B));
    }

    if (k.contains('مصدر التشغيل') ||
        k.contains('مصدر التغذية') ||
        k.contains('كهرباء')) {
      return const _SpecStyle(Icons.power_rounded, Color(0xFFF59E0B));
    }

    if (k.contains('مصدر المواصفات') || k.contains('مصدر')) {
      return const _SpecStyle(Icons.source_rounded, Color(0xFF64748B));
    }

    if (k.contains('تغطية') || k.contains('مساحة')) {
      return const _SpecStyle(Icons.grid_4x4_rounded, Color(0xFF7C3AED));
    }

    if (k.contains('مصدر الغاز')) {
      return const _SpecStyle(Icons.propane_tank_rounded, Color(0xFFDC2626));
    }

    return const _SpecStyle(Icons.article_rounded, Color(0xFF64748B));
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              primaryBlue.withOpacity(0.12),
              secondaryBlue.withOpacity(0.06)
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: primaryBlue),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 19, fontWeight: FontWeight.bold, color: darkColor)),
      ],
    );
  }

  Widget _buildInfoTag(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _shareProduct() {
    final product = _product;
    if (product == null) return;
    final String name = product['name_ar'] ?? '';
    final String price = _fmt(_getEffectivePrice());
    final String url = 'https://nexsy.com/product/${product['slug']}';
    final String shareText = 'تحقق من هذا المنتج: $name\nالسعر: $price\n$url';

    _showSnackBar('تم نسخ الرابط إلى الحافظة', primaryBlue);
    Clipboard.setData(ClipboardData(text: shareText));
  }

  Widget _buildBottomBar() {
    final double effectivePrice = _getEffectivePrice();
    final int stock = _product?['stock'] ?? 0;
    final bool inStock = stock > 0;
    final double totalPrice = effectivePrice * _quantity;
    final bool hasWholesale = _product?['has_wholesale'] == true;
    final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;
    final bool isWholesaleActive = hasWholesale && _quantity >= wholesaleMinQty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, -8))
        ],
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'analyze') {
                  _askAIAboutProduct();
                } else if (value == 'compare') {
                  _isInComparison
                      ? _removeFromComparison()
                      : _addToComparison();
                } else if (value == 'discuss') {
                  _discussProductWithAI();
                }
              },
              offset: const Offset(0, -120),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: cardWhite,
              elevation: 10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primaryBlue.withOpacity(0.08),
                    secondaryBlue.withOpacity(0.04)
                  ]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryBlue.withOpacity(0.2)),
                ),
                child: const Icon(Icons.more_horiz_rounded,
                    size: 28, color: primaryBlue),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'discuss',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_rounded,
                            color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('دردشة مع الذكاء',
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: darkColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'analyze',
                  child: Row(
                    children: [
                      _isAnalyzing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: primaryBlue))
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: primaryBlue, size: 20)),
                      const SizedBox(width: 12),
                      Text(
                          _isAnalyzing
                              ? 'جاري التحليل...'
                              : 'تحليل بالذكاء الاصطناعي',
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: darkColor)),
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
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.compare_arrows_rounded,
                              color:
                                  _isInComparison ? primaryBlue : Colors.grey,
                              size: 20)),
                      const SizedBox(width: 12),
                      Text(
                          _isInComparison
                              ? 'إزالة من المقارنة'
                              : 'إضافة للمقارنة',
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: darkColor)),
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
                        : [Colors.grey.shade100, Colors.grey.shade200]),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: _isFavorite
                        ? Colors.red.withOpacity(0.3)
                        : Colors.grey.shade300),
              ),
              child: IconButton(
                onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
                icon: _isUpdatingFavorite
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.red))
                    : AnimatedBuilder(
                        animation: _heartAnimationController,
                        builder: (context, child) => Transform.scale(
                            scale:
                                1.0 + (_heartAnimationController.value * 0.3),
                            child: child),
                        child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite ? Colors.red : Colors.grey,
                            size: 26),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _cartAnimationController,
                builder: (context, child) => Transform.scale(
                    scale: 1.0 - (_cartAnimationController.value * 0.05),
                    child: child),
                child: ElevatedButton(
                  onPressed: (inStock && !_isAddingToCart) ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inStock
                        ? (isWholesaleActive ? wholesaleGreen : primaryBlue)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: inStock ? 5 : 0,
                    shadowColor: inStock
                        ? (isWholesaleActive ? wholesaleGreen : primaryBlue)
                            .withOpacity(0.5)
                        : Colors.transparent,
                  ),
                  child: _isAddingToCart
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 10),
                            Text('جاري الإضافة...',
                                style: GoogleFonts.cairo(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(inStock ? 'أضف إلى السلة' : 'غير متوفر',
                                style: GoogleFonts.cairo(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            if (inStock) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_fmt(totalPrice),
                                        style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    if (isWholesaleActive) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.warehouse_rounded,
                                          size: 14, color: Colors.white),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
          child: Container(height: 350, color: Colors.grey.shade300),
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
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      height: 30,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20)))),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20)))),
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
        builder: (context, double value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child)),
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
                  ]),
              child: Icon(Icons.error_outline_rounded,
                  size: 50, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProductDetails,
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
