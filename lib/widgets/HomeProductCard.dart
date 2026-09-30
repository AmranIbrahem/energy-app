import 'dart:convert';

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../screens/cart/cart_screen.dart';

class HomeProductCard extends StatefulWidget {
  final dynamic product;
  final ApiService apiService;
  final AuthService? authService;

  const HomeProductCard({
    super.key,
    required this.product,
    required this.apiService,
    this.authService,
  });

  @override
  State<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends State<HomeProductCard>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  bool _isAddedToCart = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesService.isProductFavorite(widget.product['id']);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isSypPreferred {
    final storage = widget.authService?.storageService;
    if (storage == null) return false;
    try {
      return storage.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  bool get _isCompanyUser {
    if (widget.authService == null) return false;
    try {
      final storage = widget.authService!.storageService;

      final userData = storage.getUserDataMap();
      if (userData != null && userData.isNotEmpty) {
        final userType = (userData['user_type'] ??
                userData['role'] ??
                userData['type'] ??
                '')
            .toString()
            .toLowerCase();

        if (userType.isNotEmpty) {
          // debugPrint('👤 [map] user_type = $userType');
          if (userType == 'company' || userType.startsWith('company')) {
            return true;
          }
        }

        final companyId = userData['company_id'];
        if (companyId != null) {
          final cid = int.tryParse(companyId.toString()) ?? 0;
          if (cid > 0) {
            // debugPrint('👤 [map] company_id = $cid');
            return true;
          }
        }
      }

      final userDataStr = storage.getUserData();
      if (userDataStr != null && userDataStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(userDataStr);
          if (decoded is Map) {
            final userType = (decoded['user_type'] ??
                    decoded['role'] ??
                    decoded['type'] ??
                    '')
                .toString()
                .toLowerCase();

            if (userType.isNotEmpty) {
              // debugPrint('👤 [json] user_type = $userType');
              if (userType == 'company' || userType.startsWith('company')) {
                return true;
              }
            }

            final companyId = decoded['company_id'];
            if (companyId != null) {
              final cid = int.tryParse(companyId.toString()) ?? 0;
              if (cid > 0) {
                // debugPrint('👤 [json] company_id = $cid');
                return true;
              }
            }
          }
        } catch (_) {}
      }

      // debugPrint('❌ user_type غير موجود في التخزين');
      return false;
    } catch (e) {
      // debugPrint('❌ Error in _isCompanyUser: $e');
      return false;
    }
  }

  bool get _hasWholesale {
    if (!_isCompanyUser) return false;

    final hasWholesale = widget.product['has_wholesale'] == true;
    final hasWholesaleSyp = widget.product['has_wholesale_syp'] == true;

    return _isSypPreferred ? hasWholesaleSyp : hasWholesale;
  }

  double _getOriginalPrice() {
    return _isSypPreferred
        ? (double.tryParse(widget.product['price_syp']?.toString() ?? '0') ?? 0)
        : (double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0);
  }

  double _getFinalPrice() {
    return _isSypPreferred
        ? (double.tryParse(
                widget.product['final_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(widget.product['final_price']?.toString() ?? '0') ??
            0);
  }

  double _getWholesalePrice() {
    return _isSypPreferred
        ? (double.tryParse(
                widget.product['wholesale_price_syp']?.toString() ?? '0') ??
            0)
        : (double.tryParse(
                widget.product['wholesale_price']?.toString() ?? '0') ??
            0);
  }

  int _getWholesaleMinQty() {
    return int.tryParse(
            widget.product['wholesale_min_quantity']?.toString() ?? '0') ??
        0;
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

  Future<void> _toggleFavorite() async {
    setState(() => _isUpdatingFavorite = true);
    try {
      if (_isFavorite) {
        await _favoritesService.removeProduct(widget.product['id']);
        if (mounted) setState(() => _isFavorite = false);
      } else {
        final productData = {
          'id': widget.product['id'],
          'name_ar': widget.product['name_ar'],
          'name_en': widget.product['name_en'],
          'slug': widget.product['slug'],
          'price': widget.product['price'],
          'final_price': widget.product['final_price'],
          'discount_price': widget.product['discount_price'],
          'price_syp': widget.product['price_syp'],
          'final_price_syp': widget.product['final_price_syp'],
          'discount_price_syp': widget.product['discount_price_syp'],
          'main_image': widget.product['main_image'],
          'cover_image': widget.product['cover_image'],
          'discount_percentage': widget.product['discount_percentage'],
          'brand': widget.product['brand'],
          'rate': widget.product['rate'],
          'stock': widget.product['stock'],
          'governorate_product': widget.product['governorate_product'],
        };
        await _favoritesService.addProduct(productData);
        if (mounted) setState(() => _isFavorite = true);
      }
    } catch (e) {
      // debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingFavorite = false);
    }
  }

  void _addToCart() {
    final cartService = CartService.instance;

    final existingItem = cartService.items.firstWhere(
      (item) => item.id == widget.product['id'],
      orElse: () => CartItemModel(
        id: 0,
        name: '',
        slug: '',
        price: 0,
        finalPrice: 0,
        stock: 0,
      ),
    );

    final bool isExisting = existingItem.id != 0;
    final int oldQuantity = isExisting ? existingItem.quantity : 0;

    List<Map<String, dynamic>>? shippingCities;
    if (widget.product['shipping_cities'] != null) {
      shippingCities = List<Map<String, dynamic>>.from(
        (widget.product['shipping_cities'] as List).map((cityData) {
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
        }),
      );
    }

    final double cartOriginalPrice =
        _hasWholesale ? _getWholesalePrice() : _getOriginalPrice();
    final double cartFinalPrice =
        _hasWholesale ? _getWholesalePrice() : _getFinalPrice();

    final cartItem = CartItemModel(
      id: widget.product['id'],
      name: widget.product['name_ar']?.toString() ?? 'غير معروف',
      slug: widget.product['slug']?.toString() ?? '',
      price: cartOriginalPrice,
      finalPrice: cartFinalPrice,
      image: widget.product['main_image']?.toString(),
      stock: widget.product['stock'] ?? 0,
      quantity: isExisting ? oldQuantity + 1 : 1,
      discountPercentage: widget.product['discount_percentage']?.toDouble(),
      shippingCities: shippingCities,
    );

    cartService.addItem(cartItem);

    setState(() => _isAddedToCart = true);
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isExisting
                    ? 'تم تحديث الكمية: ${widget.product['name_ar']}\nالكمية: $oldQuantity → ${oldQuantity + 1}'
                    : 'تم إضافة ${widget.product['name_ar']} إلى السلة',
                style: GoogleFonts.cairo(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor:
            isExisting ? const Color(0xFF1E3A8A) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'السلة',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            ).then((_) {
              if (mounted) setState(() => _isAddedToCart = false);
            });
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isAddedToCart = false);
    });
  }

  Widget _buildPriceSection({
    required double finalPrice,
    required double originalPrice,
    required bool hasDiscount,
  }) {
    if (_hasWholesale) {
      final wholesalePrice = _getWholesalePrice();
      final wholesaleMinQty = _getWholesaleMinQty();
      final discountPct =
          (widget.product['discount_percentage'] ?? 0).toDouble();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_rounded, color: Colors.white, size: 10),
                const SizedBox(width: 3),
                Text(
                  'جملة',
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (wholesaleMinQty > 1) ...[
                  const SizedBox(width: 3),
                  Text(
                    '≥ $wholesaleMinQty',
                    style: GoogleFonts.cairo(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _fmt(wholesalePrice),
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7C3AED),
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  _fmt(finalPrice),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasDiscount && discountPct > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${discountPct.toStringAsFixed(0)}%',
                    style: GoogleFonts.cairo(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          _fmt(finalPrice),
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF059669),
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _fmt(originalPrice),
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.grey.shade400,
                decoration: TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = (widget.product['discount_percentage'] ?? 0) > 0;

    final double finalPrice = _getFinalPrice();
    final double originalPrice = _getOriginalPrice();

    final String name = widget.product['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.product['main_image']?.toString() ?? '';
    final String brand = widget.product['brand']?.toString() ?? '';
    final double rating =
        double.tryParse(widget.product['rate']?.toString() ?? '0') ?? 0;
    final String governorate =
        widget.product['governorate_product']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productSlug: widget.product['slug']?.toString() ?? '',
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isFavorite =
                  _favoritesService.isProductFavorite(widget.product['id']);
            });
          }
        });
      },
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 175,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: Container(
                      height: 135,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Hero(
                              tag: 'product_${widget.product['id']}',
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey.shade200,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(color: Colors.grey.shade200),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade100,
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${(widget.product['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (rating > 0)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (governorate.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              governorate,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: _isUpdatingFavorite
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.red),
                              )
                            : Icon(
                                _isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _isFavorite ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brand.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            brand,
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      _buildPriceSection(
                        finalPrice: finalPrice,
                        originalPrice: originalPrice,
                        hasDiscount: hasDiscount,
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _addToCart,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _isAddedToCart
                        ? const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          )
                        : (_hasWholesale
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              )),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isAddedToCart
                            ? Icons.check_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAddedToCart
                            ? 'تم ✓'
                            : (_hasWholesale ? 'أضف جملة للسلة' : 'أضف للسلة'),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
}
