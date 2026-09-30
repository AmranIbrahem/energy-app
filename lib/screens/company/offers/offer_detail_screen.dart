// lib/screens/company/offers/offer_detail_screen.dart

import 'dart:convert';

import 'package:GeniusHouse/screens/company/offers/edit_offer_screen.dart';
import 'package:GeniusHouse/screens/company/products/product_detail_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class OfferDetailScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int offerId;

  const OfferDetailScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.offerId,
  });

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color sypAmber = Color(0xFFD97706);

  late ApiService _apiService;
  Map<String, dynamic>? _offer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchOffer();
  }

  Future<void> _fetchOffer() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/v1/company/offers/${widget.offerId}',
        requiresAuth: true,
      );
      if (response['data'] != null && mounted) {
        setState(() {
          _offer = response['data']['offer'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openGallery(int initialIndex) {
    List<String> images = [];
    if (_offer?['cover_image'] != null) images.add(_offer!['cover_image']);
    if (_offer?['additional_images'] != null) {
      for (var img in _offer!['additional_images']) {
        images.add(img['image'] ?? '');
      }
    }
    if (images.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (ctx, i) => PhotoViewGalleryPageOptions(
              imageProvider: CachedNetworkImageProvider(images[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlue))
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
        _offer?['name_ar'] ?? 'تفاصيل العرض',
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.edit_rounded, color: Colors.white),
          tooltip: 'تعديل العرض',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditOfferScreen(
                  authService: widget.authService,
                  storageService: widget.storageService,
                  offerId: widget.offerId,
                ),
              ),
            ).then((_) => _fetchOffer());
          },
        ),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchOffer,
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

  Widget _buildContent() {
    final offer = _offer!;
    final name = offer['name_ar'] ?? '';
    final description = offer['description_ar'];
    final price = offer['final_price'] ?? '0';
    final originalPrice =
        (offer['discount_percentage'] ?? 0) > 0 ? offer['price'] : null;
    final discountPercent = (offer['discount_percentage'] ?? 0).round();
    final isActive = offer['is_active'] ?? false;
    final isFeatured = offer['is_featured'] ?? false;
    final isApproved = offer['is_approved'] ?? false;
    final installationPrice = offer['installation_price'];
    final wattage = offer['total_wattage'];
    final capacity = offer['total_capacity'];
    final views = offer['views'] ?? 0;
    final coverImage = offer['cover_image'];
    final additionalImages = offer['additional_images'] ?? [];
    final products = offer['products'] ?? [];
    final components = offer['components'] as List?;
    final specifications = offer['specifications'] as List?;

    final hasShipping = offer['has_shipping'] ?? false;
    final shippingCitiesWithCosts = _getShippingCitiesWithCosts();

    final double originalPriceSyp =
        double.tryParse(offer['price_syp']?.toString() ?? '0') ?? 0;
    final double finalPriceSyp =
        double.tryParse(offer['final_price_syp']?.toString() ?? '0') ??
            originalPriceSyp;
    final double installationPriceSyp =
        double.tryParse(offer['installation_price_syp']?.toString() ?? '0') ??
            0;
    final bool hasSypPrice = originalPriceSyp > 0;
    final bool hasSypDiscount =
        finalPriceSyp > 0 && finalPriceSyp < originalPriceSyp;
    final bool hasInstallationSyp = installationPriceSyp > 0;
    final int sypDiscountPercent = hasSypDiscount && originalPriceSyp > 0
        ? (((originalPriceSyp - finalPriceSyp) / originalPriceSyp) * 100)
            .round()
        : 0;

    return RefreshIndicator(
      onRefresh: _fetchOffer,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openGallery(0),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: coverImage,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_rounded,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.image_rounded,
                        size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _buildBadge(isActive ? 'نشط' : 'غير نشط',
                        isActive ? successGreen : Colors.grey),
                    _buildBadge(isApproved ? 'تمت الموافقة' : 'قيد المراجعة',
                        isApproved ? successGreen : warningOrange),
                    if (isFeatured) _buildBadge('مميز', warningOrange),
                    _buildBadge('${products.length} منتجات', primaryBlue),
                    _buildBadge('$views مشاهدة', mediumGray),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.06),
                          primaryBlue.withOpacity(0.03)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: primaryBlue.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر',
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: mediumGray)),
                        if (originalPrice != null)
                          Text(
                            originalPrice,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$price \$',
                                style: GoogleFonts.cairo(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue)),
                            if (discountPercent > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: dangerRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-$discountPercent%',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: dangerRed,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (installationPrice != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.build_rounded,
                                  size: 14, color: mediumGray),
                              const SizedBox(width: 6),
                              Text(
                                'سعر التركيب: $installationPrice \$',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: mediumGray),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasSypPrice) ...[
                    const SizedBox(height: 12),
                    _buildSypPriceCard(
                      originalPriceSyp,
                      finalPriceSyp,
                      hasSypDiscount,
                      sypDiscountPercent,
                      hasInstallationSyp ? installationPriceSyp : null,
                    ),
                  ],
                  if (wattage != null || capacity != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (wattage != null)
                          Expanded(
                              child: _buildInfoCard(Icons.bolt_rounded,
                                  'الواطية', '$wattage واط', warningOrange)),
                        if (wattage != null && capacity != null)
                          const SizedBox(width: 10),
                        if (capacity != null)
                          Expanded(
                              child: _buildInfoCard(
                                  Icons.battery_charging_full_rounded,
                                  'السعة',
                                  '$capacity واط/ساعة',
                                  const Color(0xFF06B6D4))),
                      ],
                    ),
                  ],
                  if (hasShipping) ...[
                    const SizedBox(height: 12),
                    _buildShippingCard(shippingCitiesWithCosts),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('الوصف', Icons.description_rounded),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts.cairo(
                            fontSize: 14, height: 1.7, color: mediumGray),
                      ),
                    ),
                  ],
                  if (components != null && components.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('المكونات', Icons.settings_rounded),
                    const SizedBox(height: 8),
                    ...components.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c['key'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Text(
                                c['value'] ?? '',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: primaryBlue),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (specifications != null && specifications.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
                    const SizedBox(height: 8),
                    ...specifications.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s['key'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Text(
                                s['value'] ?? '',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: primaryBlue),
                              ),
                            ],
                          ),
                        )),
                  ],
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        'المنتجات المشمولة', Icons.inventory_2_rounded),
                    const SizedBox(height: 8),
                    ...products.map((p) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  authService: widget.authService,
                                  storageService: widget.storageService,
                                  productId: p['id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['name_ar'] ?? p['name'] ?? '',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: darkColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: primaryBlue.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                      if (p['sku'] != null)
                                        Text(
                                          'SKU: ${p['sku']}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: mediumGray,
                                          ),
                                        ),
                                      if (p['price'] != null)
                                        Text(
                                          'السعر: ${p['price']} \$',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: successGreen,
                                          ),
                                        ),
                                      if (p['price_syp'] != null &&
                                          (double.tryParse(p['price_syp']
                                                          ?.toString() ??
                                                      '0') ??
                                                  0) >
                                              0)
                                        Text(
                                          'السعر بالليرة: ${Helpers.formatNumber((double.tryParse(p['final_price_syp']?.toString() ?? p['price_syp']?.toString() ?? '0') ?? 0).round())} ل.س',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            color: sypAmber,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${p['quantity']} قطعة',
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
                        )),
                  ],
                  if (additionalImages.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        'الصور الإضافية (اختياري)', Icons.image_rounded),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: additionalImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _openGallery(i + 1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: additionalImages[i]['image'] ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: lightGray,
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: lightGray,
                                child: const Icon(Icons.broken_image_rounded,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSypPriceCard(
    double originalPriceSyp,
    double finalPriceSyp,
    bool hasDiscount,
    int discountPercent,
    double? installationPriceSyp,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sypAmber.withOpacity(0.08),
            sypAmber.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sypAmber.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: sypAmber.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'السعر بالليرة السورية',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: sypAmber,
                ),
              ),
              const Spacer(),
              if (hasDiscount)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '-$discountPercent%',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDiscount) ...[
            Text(
              '${Helpers.formatNumber(originalPriceSyp.round())} ل.س',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey.shade500,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatNumber(finalPriceSyp.round()),
                style: GoogleFonts.cairo(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: sypAmber,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ل.س',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: sypAmber,
                  ),
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'وفر ${Helpers.formatNumber((originalPriceSyp - finalPriceSyp).round())} ل.س',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sypAmber,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (installationPriceSyp != null && installationPriceSyp > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.build_rounded, size: 14, color: sypAmber),
                const SizedBox(width: 6),
                Text(
                  'سعر التركيب: ${Helpers.formatNumber(installationPriceSyp.round())} ل.س',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: sypAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingCard(List<Map<String, dynamic>> citiesWithCosts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [infoBlue.withOpacity(0.06), infoBlue.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: infoBlue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: infoBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: infoBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'الشحن متاح',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: infoBlue,
                ),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: infoBlue.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                            horizontal: 10, vertical: 4),
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
                            horizontal: 10, vertical: 4),
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

  Widget _buildSectionTitle(String title, IconData icon) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.12),
                  primaryBlue.withOpacity(0.06)
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primaryBlue),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
        ],
      );

  Widget _buildBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _buildInfoCard(
          IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
          ],
        ),
      );
}

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
