// lib/screens/company/products/product_detail_screen.dart

import 'dart:convert';

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

  late ApiService _apiService;

  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _errorMessage;

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
      debugPrint('Error fetching product details: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ في تحميل المنتج';
        });
    }
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
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
          backgroundColor: cardWhite,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: darkColor),
              onPressed: () => Navigator.pop(context)),
          title: Text(_product?['name_ar'] ?? 'تفاصيل المنتج',
              style: GoogleFonts.cairo(
                  fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
          actions: [
            IconButton(
                icon: Icon(Icons.edit_rounded, color: primaryBlue),
                tooltip: 'تعديل المنتج',
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditProductScreen(
                              authService: widget.authService,
                              storageService: widget.storageService,
                              productId: widget.productId)))
                      .then((_) => _fetchProductDetails());
                }),
            IconButton(
                icon: Icon(Icons.refresh_rounded, color: primaryBlue),
                onPressed: _fetchProductDetails)
          ]),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : _buildContent(),
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

    // ✅ Shipping - الصيغة الجديدة
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
          // ✅ الصيغة القديمة - نص فقط
          shippingCitiesWithCosts.add({
            'city': cityData,
            'cost': null,
          });
        } else if (cityData is Map) {
          // ✅ الصيغة الجديدة
          shippingCitiesWithCosts.add({
            'city': cityData['city']?.toString() ?? '',
            'cost': cityData['cost']?.toString(),
          });
        }
      }
    }

    final double originalPrice =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final double discountPrice =
        double.tryParse(product['discount_price']?.toString() ?? '0') ?? 0;
    final double finalPrice =
        double.tryParse(product['final_price']?.toString() ?? '0') ??
            originalPrice;
    final int discountPercent = (product['discount_percentage'] ?? 0).round();
    final bool hasDiscount = discountPercent > 0;
    final bool hasWholesale = product['has_wholesale'] ?? false;
    final double wholesalePrice =
        double.tryParse(product['wholesale_price']?.toString() ?? '0') ?? 0;
    final int wholesaleMinQty = product['wholesale_min_quantity'] ?? 0;

    final String? mainImage = product['main_image'];
    final List<dynamic> additionalImages = product['additional_images'] ?? [];
    final List<String> allImages = [];
    if (mainImage != null) allImages.add(mainImage);
    for (var img in additionalImages) {
      allImages.add(img['image'] ?? '');
    }

    final Map<String, dynamic>? specs = product['specifications'] is Map
        ? Map<String, dynamic>.from(product['specifications'])
        : null;

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
                      const SizedBox(height: 12),
                      if (hasWholesale) ...[
                        _buildWholesaleCard(
                            wholesalePrice, wholesaleMinQty, originalPrice),
                        const SizedBox(height: 12)
                      ],
                      // ✅ قسم الشحن مع الأسعار
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
                      if (specs != null && specs.isNotEmpty) ...[
                        _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
                        const SizedBox(height: 8),
                        _buildSpecificationsTable(specs),
                        const SizedBox(height: 20)
                      ],
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

  // ✅ كارد الشحن مع الأسعار
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // ✅ عرض سعر الشحن
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

  Widget _buildSpecificationsTable(Map<String, dynamic> specs) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: specs.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(entry.key, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: mediumGray))),
                Expanded(flex: 3, child: Text(entry.value?.toString() ?? '-', style: GoogleFonts.cairo(fontSize: 13, color: darkColor), textAlign: TextAlign.end)),
              ],
            ),
          );
        }).toList(),
      ),
    );
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