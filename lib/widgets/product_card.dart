import 'dart:convert';

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends StatefulWidget {
  final dynamic product;
  final ApiService apiService;
  final AuthService? authService;

  const ProductCard({
    super.key,
    required this.product,
    required this.apiService,
    this.authService,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final FavoritesService _favoritesService = FavoritesService.instance;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesService.isProductFavorite(widget.product['id']);
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
    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeProduct(widget.product['id']);
        setState(() {
          _isFavorite = false;
        });
        _showSnackBar('تم إزالة المنتج من المفضلة', Colors.orange);
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
        setState(() {
          _isFavorite = true;
        });
        _showSnackBar('تم إضافة المنتج إلى المفضلة', Colors.green);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
      // debugPrint('Error toggling favorite: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  void _addToCart() {
    final cartService = CartService.instance;

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
      discountPercentage:
          _hasWholesale ? 0 : widget.product['discount_percentage']?.toDouble(),
      shippingCities: shippingCities,
    );

    cartService.addItem(cartItem);
    _showSnackBar(
      _hasWholesale
          ? 'تم إضافة المنتج بسعر الجملة 🏢'
          : 'تم إضافة المنتج إلى السلة',
      Colors.green,
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
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
          setState(() {
            _isFavorite =
                _favoritesService.isProductFavorite(widget.product['id']);
          });
        });
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 130,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 130,
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.image_not_supported, size: 40),
                          ),
                        )
                      : Container(
                          height: 130,
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(widget.product['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_hasWholesale)
                  Positioned(
                    top: 8,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_rounded,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            'جملة',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_getWholesaleMinQty() > 1) ...[
                            const SizedBox(width: 2),
                            Text(
                              '≥ ${_getWholesaleMinQty()}',
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
                  ),
                if (governorate.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
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
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: _isUpdatingFavorite
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _addToCart,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _hasWholesale
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (brand.isNotEmpty)
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (_hasWholesale) ...[
                    Text(
                      _fmt(_getWholesalePrice()),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _fmt(finalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${(widget.product['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
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
                  ] else ...[
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            _fmt(originalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _fmt(finalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
