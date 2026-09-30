// lib/screens/company/products/product_detail_screen.dart

import 'dart:convert';

import 'package:GeniusHouse/screens/company/products/add_home_appliance_screen.dart';
import 'package:GeniusHouse/screens/company/products/edit_product_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ProductDetailScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color wholesaleGreenColor = Color(0xFF16A34A);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color sypAmber = Color(0xFFD97706);
  static const Color parallelPurple =
      Color(0xFF7C3AED); // ✅ لون الربط على التوازي

  late ApiService _apiService;

  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isAnalyzing = false;
  Map<String, dynamic>? _ownerAnalysis;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiService
          .get('/v1/company/products/${widget.productId}', requiresAuth: true);
      if (response['data'] != null &&
          response['data']['product'] != null &&
          mounted) {
        setState(() {
          _product = response['data']['product'];
          _isLoading = false;
        });
      } else {
        if (mounted)
          setState(() {
            _isLoading = false;
            _errorMessage = response['message'] ?? 'فشل تحميل المنتج';
          });
      }
    } catch (e) {
      // debugPrint('Error fetching product details: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ في تحميل المنتج';
        });
    }
  }

  Future<void> _analyzeProductForOwner() async {
    setState(() => _isAnalyzing = true);
    try {
      final response = await _apiService.get(
        '/v1/company/analyzeProduct/${widget.productId}',
        requiresAuth: true,
      );
      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _ownerAnalysis = response['data'] as Map<String, dynamic>;
            _isAnalyzing = false;
          });
          _showOwnerAnalysisDialog();
        } else {
          setState(() => _isAnalyzing = false);
          _showSnackBar(response['message'] ?? 'فشل تحليل المنتج', dangerRed);
        }
      }
    } catch (e) {
      // debugPrint('Error analyzing product: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showSnackBar('حدث خطأ في تحليل المنتج', dangerRed);
      }
    }
  }

  void _showOwnerAnalysisDialog() {
    if (_ownerAnalysis == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        primaryBlue.withOpacity(0.15),
                        secondaryBlue.withOpacity(0.08)
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تحليل المنتج',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildOwnerAnalysisContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerAnalysisContent() {
    if (_ownerAnalysis == null) return const SizedBox.shrink();

    final currentScore = _ownerAnalysis!['current_score'] ?? 0;
    final potentialScore = _ownerAnalysis!['potential_score'] ?? 0;
    final scoreImprovement = _ownerAnalysis!['score_improvement'] ?? 0;
    final missingSpecs = _ownerAnalysis!['missing_specs'] as List? ?? [];
    final missingCount = _ownerAnalysis!['missing_count'] ?? 0;
    final isComplete = _ownerAnalysis!['is_complete'] ?? false;
    final suggestions = _ownerAnalysis!['suggestions'] as List? ?? [];
    final summary = _ownerAnalysis!['summary'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isComplete
                  ? [
                      Colors.green.withOpacity(0.1),
                      Colors.teal.withOpacity(0.05)
                    ]
                  : [
                      warningOrange.withOpacity(0.1),
                      warningOrange.withOpacity(0.05)
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComplete
                  ? Colors.green.withOpacity(0.3)
                  : warningOrange.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 48,
                color: isComplete ? Colors.green : warningOrange,
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildScoreCard(
                      label: 'الدرجة الحالية',
                      score: currentScore,
                      color: (currentScore as num) >= 70
                          ? Colors.green
                          : warningOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScoreCard(
                      label: 'الدرجة المتوقعة',
                      score: potentialScore,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if ((scoreImprovement as num) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🚀 يمكنك زيادة $scoreImprovement نقطة!',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (missingSpecs.isNotEmpty) ...[
          Text(
            '⚠️ البيانات الناقصة ($missingCount):',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: dangerRed,
            ),
          ),
          const SizedBox(height: 10),
          ...missingSpecs.map((spec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dangerRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dangerRed.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          color: dangerRed, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec['label']?.toString() ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            spec['message']?.toString() ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${spec['points']} نقطة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        if (suggestions.isNotEmpty) ...[
          Text(
            '💡 نصائح للتحسين:',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: infoBlue,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestions.map((suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: infoBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: infoBlue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: infoBlue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: darkColor,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildScoreCard({
    required String label,
    required dynamic score,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
          ),
          const SizedBox(height: 8),
          Text(
            '$score/100',
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score as num) / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
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
                  color == successGreen
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: Colors.white,
                  size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(message, style: GoogleFonts.cairo(fontSize: 14)))
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2)));
  }

  void _openImageGallery(int initialIndex) {
    List<String> images = [];
    if (_product?['main_image'] != null) images.add(_product!['main_image']);
    if (_product?['additional_images'] != null)
      for (var img in _product!['additional_images'])
        images.add(img['image'] ?? '');
    if (images.isEmpty) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context))),
                body: PhotoViewGallery.builder(
                    itemCount: images.length,
                    pageController: PageController(initialPage: initialIndex),
                    builder: (context, index) => PhotoViewGalleryPageOptions(
                        imageProvider:
                            CachedNetworkImageProvider(images[index]),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 3),
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black)))));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: _buildAppBar(),
        body: _isLoading
            ? _buildLoading()
            : _errorMessage != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _product?['name_ar'] ?? 'تفاصيل المنتج',
        style: GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: _isAnalyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
          tooltip: 'تحليل المنتج',
          onPressed: _isAnalyzing ? null : _analyzeProductForOwner,
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          tooltip: 'تعديل المنتج',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProductScreen(
                  authService: widget.authService,
                  storageService: widget.storageService,
                  productId: widget.productId,
                ),
              ),
            ).then((_) => _fetchProductDetails());
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchProductDetails,
        ),
      ],
      flexibleSpace: ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: primaryBlue));

  Widget _buildError() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: dangerRed.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.error_outline_rounded,
              size: 64, color: dangerRed.withOpacity(0.6))),
      const SizedBox(height: 20),
      Text(_errorMessage!,
          style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
          onPressed: _fetchProductDetails,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue, foregroundColor: Colors.white))
    ]));
  }

  Widget _buildContent() {
    final product = _product!;
    final String name = product['name_ar'] ?? '';
    final String? brand = product['brand'];
    final String? model = product['model'];
    final String? warranty = product['warranty'];
    final String? description = product['description_ar'];
    final String unit = product['unit'] ?? '';
    final int stock = product['stock'] ?? 0;
    final bool isActive = product['is_active'] ?? false;
    final bool isApproved = product['is_approved'] ?? false;
    final double rate =
        double.tryParse(product['rate']?.toString() ?? '0') ?? 0;
    final int views = product['views'] ?? 0;

    final bool hasShipping = product['has_shipping'] ?? false;
    List<Map<String, dynamic>> shippingCitiesWithCosts = [];
    if (product['shipping_cities'] != null) {
      List<dynamic> citiesData = [];
      if (product['shipping_cities'] is List) {
        citiesData = product['shipping_cities'] as List;
      } else if (product['shipping_cities'] is String) {
        try {
          citiesData = jsonDecode(product['shipping_cities']) as List;
        } catch (_) {
          citiesData = [];
        }
      }
      for (var cityData in citiesData) {
        if (cityData is String) {
          shippingCitiesWithCosts.add({'city': cityData, 'cost': null});
        } else if (cityData is Map) {
          shippingCitiesWithCosts.add({
            'city': cityData['city']?.toString() ?? '',
            'cost': cityData['cost']?.toString(),
          });
        }
      }
    }

    final double originalPrice =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final double finalPrice =
        double.tryParse(product['final_price']?.toString() ?? '0') ??
            originalPrice;
    final int discountPercent = (product['discount_percentage'] ?? 0).round();
    final bool hasDiscount = discountPercent > 0;
    final bool hasWholesale = product['has_wholesale'] ?? false;
    final double wholesalePrice =
        double.tryParse(product['wholesale_price']?.toString() ?? '0') ?? 0;
    final int wholesaleMinQty = product['wholesale_min_quantity'] ?? 0;

    final double originalPriceSyp =
        double.tryParse(product['price_syp']?.toString() ?? '0') ?? 0;
    final double finalPriceSyp =
        double.tryParse(product['final_price_syp']?.toString() ?? '0') ??
            originalPriceSyp;
    final double wholesalePriceSyp =
        double.tryParse(product['wholesale_price_syp']?.toString() ?? '0') ?? 0;
    final bool hasSypPrice = originalPriceSyp > 0;
    final bool hasSypDiscount =
        finalPriceSyp > 0 && finalPriceSyp < originalPriceSyp;
    final bool hasSypWholesale = wholesalePriceSyp > 0;
    final int sypDiscountPercent = hasSypDiscount && originalPriceSyp > 0
        ? (((originalPriceSyp - finalPriceSyp) / originalPriceSyp) * 100)
            .round()
        : 0;

    final String? mainImage = product['main_image'];
    final List<dynamic> additionalImages = product['additional_images'] ?? [];
    final List<String> allImages = [];
    if (mainImage != null) allImages.add(mainImage);
    for (var img in additionalImages) {
      allImages.add(img['image'] ?? '');
    }

    // ✅ استخراج بيانات الربط على التوازي
    final parallelData = _extractParallelInfo(product);

    return RefreshIndicator(
      onRefresh: _fetchProductDetails,
      color: primaryBlue,
      child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildImageGallery(allImages),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderBadges(isActive, isApproved, stock, rate,
                          views, discountPercent),
                      const SizedBox(height: 16),
                      Text(name,
                          style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                              height: 1.3)),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.qr_code_rounded, 'SKU', product['sku'] ?? '-'),
                      const SizedBox(height: 4),
                      if (brand != null || model != null) ...[
                        Row(children: [
                          if (brand != null) _buildBadge(brand, primaryBlue),
                          if (brand != null && model != null)
                            const SizedBox(width: 8),
                          if (model != null) _buildBadge(model, secondaryBlue)
                        ]),
                        const SizedBox(height: 12)
                      ],
                      _buildPriceCard(originalPrice, finalPrice, hasDiscount,
                          discountPercent),

                      // ✅ بطاقة الربط على التوازي (جديدة)
                      if (parallelData['hasInfo'] == true) ...[
                        const SizedBox(height: 12),
                        _buildParallelSupportCard(parallelData),
                      ],

                      if (hasSypPrice) ...[
                        const SizedBox(height: 12),
                        _buildSypPriceCard(originalPriceSyp, finalPriceSyp,
                            hasSypDiscount, sypDiscountPercent),
                      ],
                      const SizedBox(height: 12),
                      if (hasWholesale) ...[
                        _buildWholesaleCard(
                            wholesalePrice, wholesaleMinQty, originalPrice),
                        const SizedBox(height: 12)
                      ],
                      if (hasSypWholesale && wholesaleMinQty > 0) ...[
                        _buildSypWholesaleCard(wholesalePriceSyp,
                            wholesaleMinQty, originalPriceSyp),
                        const SizedBox(height: 12)
                      ],
                      if (hasShipping) ...[
                        _buildShippingCard(shippingCitiesWithCosts),
                        const SizedBox(height: 12)
                      ],
                      _buildInfoGrid(stock, unit, warranty),
                      const SizedBox(height: 20),
                      if (description != null && description.isNotEmpty) ...[
                        _buildSectionTitle('الوصف', Icons.description_rounded),
                        const SizedBox(height: 8),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: _cardDecoration(),
                            child: Text(description,
                                style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    height: 1.7,
                                    color: mediumGray))),
                        const SizedBox(height: 20)
                      ],
                      _buildOrganizedSpecificationsSection(),
                      if (additionalImages.isNotEmpty) ...[
                        _buildSectionTitle(
                            'الصور الإضافية', Icons.image_rounded),
                        const SizedBox(height: 8),
                        _buildAdditionalImagesGrid(additionalImages),
                        const SizedBox(height: 20)
                      ],
                      _buildDatesSection(product),
                      const SizedBox(height: 20),
                    ])),
          ])),
    );
  }

  // ============================================================
  // ✅ استخراج معلومات الربط على التوازي من المنتج
  // ============================================================
  Map<String, dynamic> _extractParallelInfo(Map<String, dynamic> product) {
    final specs = _getSpecificationsList(product);
    final specsMap = {for (var s in specs) s['key']!: s['value']!};

    final parallelValue = specsMap['يدعم الربط على التوازي'] ?? '';
    final supportsParallel =
        parallelValue == 'نعم' || parallelValue.toLowerCase() == 'yes';

    int maxCount = 0;
    final maxCountStr = specsMap['أقصى عدد عواكس على التوازي'] ??
        specsMap['أقصى عدد بطاريات على التوازي'] ??
        '';
    if (maxCountStr.isNotEmpty) {
      maxCount = int.tryParse(maxCountStr) ?? 0;
    }

    // نوع المنتج
    final productType = product['product_type']?.toString() ?? '';
    final isBattery = productType == 'battery';
    final isInverter = productType == 'inverter';

    return {
      'hasInfo': (isBattery || isInverter) && parallelValue.isNotEmpty,
      'supportsParallel': supportsParallel,
      'maxCount': maxCount,
      'isBattery': isBattery,
      'isInverter': isInverter,
    };
  }

  // ============================================================
  // ✅ بطاقة الربط على التوازي (جديدة)
  // ============================================================
  Widget _buildParallelSupportCard(Map<String, dynamic> parallelData) {
    final supportsParallel = parallelData['supportsParallel'] == true;
    final maxCount = parallelData['maxCount'] as int;
    final isBattery = parallelData['isBattery'] == true;
    final isInverter = parallelData['isInverter'] == true;

    final deviceName = isBattery ? 'بطاريات' : 'عواكس';
    final unitName = isBattery ? 'بطارية' : 'عاكس';

    final color = supportsParallel ? parallelPurple : Colors.grey.shade600;
    final icon = supportsParallel ? Icons.link_rounded : Icons.link_off_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: supportsParallel
              ? [
                  parallelPurple.withOpacity(0.08),
                  parallelPurple.withOpacity(0.03),
                ]
              : [
                  Colors.grey.withOpacity(0.05),
                  Colors.grey.withOpacity(0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: supportsParallel
              ? parallelPurple.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: supportsParallel
                        ? [const Color(0xFF8B5CF6), parallelPurple]
                        : [Colors.grey.shade500, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'الربط على التوازي',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: supportsParallel
                      ? parallelPurple.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      supportsParallel
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      supportsParallel ? 'مدعوم' : 'غير مدعوم',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (supportsParallel) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: parallelPurple.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: parallelPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_rounded,
                        color: parallelPurple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أقصى عدد $deviceName للتجميع',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: mediumGray,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (maxCount > 0)
                          Text(
                            '$maxCount $unitName',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: parallelPurple,
                            ),
                          )
                        else
                          Text(
                            'غير محدد',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: parallelPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: parallelPurple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isBattery
                          ? 'يُسمح بالتجميع فقط للبطاريات 48 فولت بسعة 300 أمبير ساعي أو أكثر لكل بطارية، ومن نفس الموديل.'
                          : 'يجب أن تكون جميع العواكس المجمّعة من نفس الموديل، وأن تدعم الربط على التوازي، وضمن الحد الأقصى المحدد أعلاه.',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: parallelPurple,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذا المنتج لا يدعم الربط على التوازي. يجب استخدامه منفرداً.',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ✅ بطاقة سعر الليرة السورية
  // ============================================================
  Widget _buildSypPriceCard(double originalPriceSyp, double finalPriceSyp,
      bool hasDiscount, int discountPercent) {
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              sypAmber.withOpacity(0.08),
              sypAmber.withOpacity(0.03)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sypAmber.withOpacity(0.25), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Text('السعر بالليرة السورية',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: sypAmber)),
            const Spacer(),
            if (hasDiscount)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(15)),
                  child: Text('-$discountPercent%',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)))
          ]),
          const SizedBox(height: 12),
          if (hasDiscount) ...[
            Text(Helpers.formatNumber(originalPriceSyp.round()),
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough)),
            const SizedBox(height: 2)
          ],
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Helpers.formatNumber(finalPriceSyp.round()),
                style: GoogleFonts.cairo(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: sypAmber)),
            const SizedBox(width: 6),
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('ل.س',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: sypAmber)))
          ]),
          if (hasDiscount)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        'وفر ${Helpers.formatNumber((originalPriceSyp - finalPriceSyp).round())} ل.س',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: sypAmber))))
        ]));
  }

  // ============================================================
  // ✅ بطاقة جملة الليرة السورية
  // ============================================================
  Widget _buildSypWholesaleCard(
      double wholesalePriceSyp, int minQty, double originalPriceSyp) {
    final double saveAmountSyp = originalPriceSyp - wholesalePriceSyp;
    final int savePercentSyp = originalPriceSyp > 0
        ? ((saveAmountSyp / originalPriceSyp) * 100).round()
        : 0;

    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              wholesaleGreenColor.withOpacity(0.08),
              wholesaleGreenColor.withOpacity(0.04)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: wholesaleGreenColor.withOpacity(0.25), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warehouse_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Text('سعر الجملة (ل.س)',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: wholesaleGreenColor)),
            const Spacer(),
            if (savePercentSyp > 0)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                      borderRadius: BorderRadius.circular(15)),
                  child: Text('وفر $savePercentSyp%',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)))
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Helpers.formatNumber(wholesalePriceSyp.round()),
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: wholesaleGreenColor)),
            const SizedBox(width: 6),
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' ل.س / للوحدة',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: wholesaleGreenColor.withOpacity(0.7))))
          ]),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.shopping_basket_rounded,
                    color: wholesaleGreenColor, size: 18),
                const SizedBox(width: 8),
                Text('الحد الأدنى للطلب: ',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: const Color(0xFF166534))),
                Text('$minQty قطعة',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: wholesaleGreenColor)),
                const Spacer(),
                if (saveAmountSyp > 0)
                  Text('وفر ${Helpers.formatNumber(saveAmountSyp.round())} ل.س',
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: wholesaleGreenColor))
              ]))
        ]));
  }

  // ============================================================
  // ✅ قسم المواصفات المنظم حسب النوع
  // ============================================================

  Widget _buildOrganizedSpecificationsSection() {
    final product = _product!;
    final productType = product['product_type']?.toString();

    final allFields = <ProductSpecField>[];
    if (productType != null) {
      allFields.addAll(ProductSpecsDefinitions.specsByType[productType] ?? []);
      if (ProductSpecsDefinitions.homeApplianceTypes.contains(productType)) {
        allFields.addAll(_getHomeSpecFields(productType));
      }
    }

    final allSpecs = _getSpecificationsList(product);
    final Map<String, String> specsMap = {
      for (var s in allSpecs) s['key']!: s['value']!
    };

    // ✅ استبعاد حقول الربط على التوازي (لأنها ظهرت في البطاقة المخصصة)
    final parallelKeys = {
      'يدعم الربط على التوازي',
      'أقصى عدد عواكس على التوازي',
      'أقصى عدد بطاريات على التوازي',
    };

    final knownFields = <ProductSpecField>[];
    for (var field in allFields) {
      if (parallelKeys.contains(field.key)) continue;
      if (specsMap.containsKey(field.key) &&
          (specsMap[field.key] ?? '').trim().isNotEmpty) {
        knownFields.add(field);
      }
    }

    final knownKeys = knownFields.map((f) => f.key).toSet();
    final additionalSpecs = <Map<String, String>>[];
    for (var spec in allSpecs) {
      if (parallelKeys.contains(spec['key'])) continue;
      if (!knownKeys.contains(spec['key']) &&
          (spec['value'] ?? '').isNotEmpty) {
        additionalSpecs.add(spec);
      }
    }

    if (knownFields.isEmpty && additionalSpecs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
        const SizedBox(height: 8),
        if (knownFields.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.04),
                secondaryBlue.withOpacity(0.02),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              children: knownFields.asMap().entries.map((entry) {
                final isLast = entry.key == knownFields.length - 1;
                return _buildTypedSpecRow(
                  field: entry.value,
                  value: specsMap[entry.value.key]!,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (additionalSpecs.isNotEmpty) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle_outline_rounded,
                  color: warningOrange, size: 16),
            ),
            const SizedBox(width: 8),
            Text('مواصفات إضافية',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
          ]),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: additionalSpecs.asMap().entries.map((entry) {
                final isLast = entry.key == additionalSpecs.length - 1;
                return _buildAdditionalSpecRow(
                  spec: entry.value,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildTypedSpecRow({
    required ProductSpecField field,
    required String value,
    required bool isLast,
  }) {
    final iconData = _getIconForField(field);
    final isParallelField = field.key.contains('التوازي');
    final iconColor = isParallelField ? parallelPurple : primaryBlue;
    final iconBgColor = isParallelField
        ? parallelPurple.withOpacity(0.08)
        : primaryBlue.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              field.label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mediumGray,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: isParallelField ? parallelPurple : darkColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSpecRow({
    required Map<String, String> spec,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.label_outline_rounded,
              size: 16, color: mediumGray.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              spec['key'] ?? '',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: mediumGray,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              spec['value'] ?? '',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: darkColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ أيقونة مناسبة حسب نوع الحقل (محدَّثة لدعم حقول التوازي)
  // ============================================================
  IconData _getIconForField(ProductSpecField field) {
    // ✅ أيقونات حقول الربط على التوازي
    if (field.key.contains('الربط على التوازي')) {
      return Icons.link_rounded;
    }
    if (field.key.contains('أقصى عدد عواكس على التوازي')) {
      return Icons.hub_rounded;
    }
    if (field.key.contains('أقصى عدد بطاريات على التوازي')) {
      return Icons.battery_saver_rounded;
    }
    if (field.key.contains('الربط') || field.key.contains('التوازي')) {
      return Icons.link_rounded;
    }

    switch (field.inputType) {
      case 'dropdown':
        return Icons.arrow_drop_down_circle_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'number_with_unit':
        if (field.unitOptions?.contains('واط') == true) {
          return Icons.bolt_rounded;
        }
        if (field.unitOptions?.contains('فولت') == true) {
          return Icons.electrical_services_rounded;
        }
        if (field.unitOptions?.contains('أمبير') == true) {
          return Icons.electric_meter_rounded;
        }
        if (field.unitOptions?.contains('كيلوواط ساعي') == true) {
          return Icons.battery_charging_full_rounded;
        }
        if (field.unitOptions?.contains('لتر') == true) {
          return Icons.water_drop_rounded;
        }
        if (field.unitOptions?.contains('كيلوغرام') == true) {
          return Icons.scale_rounded;
        }
        if (field.unitOptions?.contains('متر') == true) {
          return Icons.straighten_rounded;
        }
        if (field.unitOptions?.contains('درجة') == true) {
          return Icons.rotate_right_rounded;
        }
        if (field.unitOptions?.contains('كلفن') == true) {
          return Icons.thermostat_rounded;
        }
        if (field.unitOptions?.contains('لومن') == true) {
          return Icons.light_mode_rounded;
        }
        if (field.unitOptions?.contains('%') == true) {
          return Icons.percent_rounded;
        }
        return Icons.straighten_rounded;
      case 'dimensions':
        return Icons.aspect_ratio_rounded;
      case 'text':
      default:
        if (field.key.contains('الماركة'))
          return Icons.branding_watermark_rounded;
        if (field.key.contains('نوع')) return Icons.category_rounded;
        if (field.key.contains('الاستخدام')) {
          return Icons.home_work_rounded;
        }
        if (field.key.contains('لون')) return Icons.palette_rounded;
        return Icons.info_outline_rounded;
    }
  }

  List<ProductSpecField> _getHomeSpecFields(String productType) {
    final result = <ProductSpecField>[];

    for (var f in HomeApplianceData.commonFields) {
      result.add(ProductSpecField(
        key: f.labelAr,
        label: f.labelAr,
        inputType: _mapHomeInputType(f.inputType),
        options: f.options,
        unitOptions: f.unitOptions,
        defaultUnit:
            f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null,
      ));
    }

    final special = HomeApplianceData.specialFields[productType] ?? [];
    for (var f in special) {
      result.add(ProductSpecField(
        key: f.labelAr,
        label: f.labelAr,
        inputType: _mapHomeInputType(f.inputType),
        options: f.options,
        unitOptions: f.unitOptions,
        defaultUnit:
            f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null,
      ));
    }
    return result;
  }

  String _mapHomeInputType(String homeType) {
    switch (homeType) {
      case 'single_select':
        return 'dropdown';
      case 'multi_select':
        return 'text';
      case 'boolean':
        return 'text';
      case 'number_with_unit':
        return 'number_with_unit';
      case 'number':
        return 'number';
      case 'text':
        return 'text';
      case 'dimensions':
        return 'dimensions';
      default:
        return 'text';
    }
  }

  // ============================================================
  // دوال مساعدة
  // ============================================================

  Widget _buildShippingCard(List<Map<String, dynamic>> citiesWithCosts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [infoBlue.withOpacity(0.06), infoBlue.withOpacity(0.03)]),
        borderRadius: BorderRadius.circular(18),
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
                    color: infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_shipping_rounded,
                    color: infoBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'الشحن متاح',
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold, color: infoBlue),
              ),
            ],
          ),
          if (citiesWithCosts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'مدن الشحن والأسعار:',
              style: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
            ),
            const SizedBox(height: 10),
            ...citiesWithCosts.map((cityData) {
              final city = cityData['city']?.toString() ?? '';
              final cost = cityData['cost']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: infoBlue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: dangerRed, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        city,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: darkColor,
                        ),
                      ),
                    ),
                    if (cost == null || cost.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'يحدد لاحقاً',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: warningOrange,
                          ),
                        ),
                      )
                    else if (double.tryParse(cost) == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'شحن مجاني',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: successGreen,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${Helpers.formatPrice(double.tryParse(cost) ?? 0)}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]);

  Widget _buildSectionTitle(String title, IconData icon) => Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06)
                ]),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: primaryBlue)),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 17, fontWeight: FontWeight.bold, color: darkColor))
      ]);

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty)
      return Container(
          height: 300,
          color: lightGray,
          child: const Center(
              child: Icon(Icons.image_not_supported_rounded,
                  size: 60, color: Colors.grey)));
    return GestureDetector(
        onTap: () => _openImageGallery(0),
        child: Container(
            height: 350,
            decoration: BoxDecoration(
                color: lightGray,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Stack(children: [
              PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) => Hero(
                      tag: 'product_image_$index',
                      child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: primaryBlue)),
                          errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_rounded,
                                  size: 50, color: Colors.grey))))),
              Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.zoom_in_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('${images.length} صور',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.white))
                      ])))
            ])));
  }

  Widget _buildHeaderBadges(bool isActive, bool isApproved, int stock,
      double rate, int views, int discountPercent) {
    // ✅ شارة الربط على التوازي (إن وُجد)
    final parallelData = _extractParallelInfo(_product!);
    final showParallelBadge = parallelData['hasInfo'] == true &&
        parallelData['supportsParallel'] == true;

    return Wrap(spacing: 8, runSpacing: 8, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: isActive
                  ? successGreen.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isActive
                      ? successGreen.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle_rounded,
                size: 8, color: isActive ? successGreen : Colors.grey),
            const SizedBox(width: 6),
            Text(isActive ? 'نشط' : 'غير نشط',
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? successGreen : mediumGray))
          ])),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: isApproved
                  ? successGreen.withOpacity(0.1)
                  : warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isApproved
                      ? successGreen.withOpacity(0.3)
                      : warningOrange.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                isApproved
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                size: 14,
                color: isApproved ? successGreen : warningOrange),
            const SizedBox(width: 6),
            Text(isApproved ? 'تمت الموافقة' : 'قيد المراجعة',
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isApproved ? successGreen : warningOrange))
          ])),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: stock > 0
                  ? successGreen.withOpacity(0.1)
                  : dangerRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: stock > 0
                      ? successGreen.withOpacity(0.3)
                      : dangerRed.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(stock > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 14, color: stock > 0 ? successGreen : dangerRed),
            const SizedBox(width: 6),
            Text(stock > 0 ? '$stock قطعة' : 'غير متوفر',
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: stock > 0 ? successGreen : dangerRed))
          ])),
      // ✅ شارة الربط على التوازي
      if (showParallelBadge)
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  parallelPurple.withOpacity(0.15),
                  parallelPurple.withOpacity(0.08),
                ]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: parallelPurple.withOpacity(0.35))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.link_rounded, size: 14, color: parallelPurple),
              const SizedBox(width: 4),
              Text('يدعم الربط',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: parallelPurple))
            ])),
      if (rate > 0)
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: 14, color: warningOrange),
              const SizedBox(width: 4),
              Text(rate.toStringAsFixed(1),
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: warningOrange))
            ])),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.visibility_rounded,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(Helpers.formatNumber(views),
                style: GoogleFonts.cairo(fontSize: 11, color: mediumGray))
          ])),
      if (discountPercent > 0)
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dangerRed.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.discount_rounded, size: 14, color: dangerRed),
              const SizedBox(width: 4),
              Text('-$discountPercent%',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: dangerRed))
            ])),
    ]);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) =>
      Row(children: [
        Icon(icon, size: 16, color: mediumGray),
        const SizedBox(width: 6),
        Text('$label: ',
            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkColor))
      ]);

  Widget _buildBadge(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text,
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)));

  Widget _buildPriceCard(double originalPrice, double finalPrice,
          bool hasDiscount, int discountPercent) =>
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.06),
                secondaryBlue.withOpacity(0.03)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryBlue.withOpacity(0.1))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('السعر',
                style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
            const SizedBox(height: 6),
            if (hasDiscount) ...[
              Text(Helpers.formatPrice(originalPrice),
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 2)
            ],
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Helpers.formatPrice(finalPrice),
                  style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
              const SizedBox(width: 6),
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('',
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: mediumGray))),
              if (hasDiscount) ...[
                const SizedBox(width: 10),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        'وفر ${Helpers.formatPrice(originalPrice - finalPrice)}',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: dangerRed)))
              ]
            ]),
          ]));

  Widget _buildWholesaleCard(
      double wholesalePrice, int minQty, double originalPrice) {
    final double saveAmount = originalPrice - wholesalePrice;
    final int savePercent =
        originalPrice > 0 ? ((saveAmount / originalPrice) * 100).round() : 0;
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              wholesaleGreenColor.withOpacity(0.08),
              wholesaleGreenColor.withOpacity(0.04)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: wholesaleGreenColor.withOpacity(0.25), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warehouse_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Text('سعر الجملة',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: wholesaleGreenColor)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                    borderRadius: BorderRadius.circular(15)),
                child: Text('وفر $savePercent%',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)))
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Helpers.formatPrice(wholesalePrice),
                style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: wholesaleGreenColor)),
            const SizedBox(width: 6),
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' / للوحدة',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: wholesaleGreenColor.withOpacity(0.7))))
          ]),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.shopping_basket_rounded,
                    color: wholesaleGreenColor, size: 18),
                const SizedBox(width: 8),
                Text('الحد الأدنى للطلب: ',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: const Color(0xFF166534))),
                Text('$minQty قطعة',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: wholesaleGreenColor)),
                const Spacer(),
                Text('وفر ${Helpers.formatPrice(saveAmount)}',
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: wholesaleGreenColor))
              ]))
        ]));
  }

  Widget _buildInfoGrid(int stock, String unit, String? warranty) =>
      Row(children: [
        Expanded(
            child: _buildInfoCard(Icons.straighten_rounded, 'الوحدة',
                _getUnitLabel(unit), primaryBlue)),
        const SizedBox(width: 10),
        if (warranty != null)
          Expanded(
              child: _buildInfoCard(
                  Icons.shield_rounded, 'الضمان', warranty, successGreen))
      ]);

  Widget _buildInfoCard(
          IconData icon, String label, String value, Color color) =>
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkColor))
          ]));

  String _getUnitLabel(String unit) {
    switch (unit) {
      case 'piece':
        return 'قطعة';
      case 'kg':
        return 'كيلوغرام';
      case 'liter':
        return 'لتر';
      case 'box':
        return 'صندوق';
      case 'set':
        return 'مجموعة';
      default:
        return unit;
    }
  }

  List<Map<String, String>> _getSpecificationsList(
      Map<String, dynamic> product) {
    final rawSpecs = product['specifications'];
    if (rawSpecs == null) return [];

    List<dynamic> specsData = [];

    if (rawSpecs is List) {
      specsData = rawSpecs;
    } else if (rawSpecs is Map) {
      rawSpecs.forEach((key, value) {
        specsData
            .add({'key': key.toString(), 'value': value?.toString() ?? ''});
      });
    } else if (rawSpecs is String) {
      try {
        final decoded = jsonDecode(rawSpecs);
        if (decoded is List) {
          specsData = decoded;
        } else if (decoded is Map) {
          decoded.forEach((key, value) {
            specsData
                .add({'key': key.toString(), 'value': value?.toString() ?? ''});
          });
        }
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
        .where((spec) => spec['key']!.isNotEmpty && spec['value']!.isNotEmpty)
        .toList();
  }

  Widget _buildAdditionalImagesGrid(List<dynamic> images) => SizedBox(
      height: 100,
      child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) => GestureDetector(
              onTap: () => _openImageGallery(index + 1),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                      imageUrl: images[index]['image'] ?? '',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: lightGray),
                      errorWidget: (_, __, ___) => Container(
                          color: lightGray,
                          child: const Icon(Icons.broken_image_rounded,
                              color: Colors.grey)))))));

  Widget _buildDatesSection(Map<String, dynamic> product) {
    final String? createdAt = product['created_at'];
    final String? updatedAt = product['updated_at'];
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(children: [
          Expanded(
              child: _buildDateItem(
                  Icons.calendar_today_rounded, 'تاريخ الإضافة', createdAt)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildDateItem(
                  Icons.edit_calendar_rounded, 'آخر تحديث', updatedAt))
        ]));
  }

  Widget _buildDateItem(IconData icon, String label, String? dateStr) {
    String formattedDate = '-';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate =
            '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = dateStr;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: mediumGray),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray))
      ]),
      const SizedBox(height: 4),
      Text(formattedDate,
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor))
    ]);
  }
}

// ✅ كلاس المنحنى السفلي للـ AppBar
class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height);
    path.lineTo(size.width - 20, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
