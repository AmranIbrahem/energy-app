import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';

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
    // تحميل حالة المفضلة من الخدمة المحلية
    _isFavorite = _favoritesService.isProductFavorite(widget.product['id']);
  }

  Future<void> _toggleFavorite() async {
    // إذا لم يكن المستخدم مسجلاً، نسمح بإضافة المفضلة محلياً
    // لأن الفلاتر تعمل محلياً للجميع

    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      if (_isFavorite) {
        // إزالة من المفضلة المحلية
        await _favoritesService.removeProduct(widget.product['id']);
        setState(() {
          _isFavorite = false;
        });
        _showSnackBar('تم إزالة المنتج من المفضلة', Colors.orange);
      } else {
        // إضافة إلى المفضلة المحلية
        final productData = {
          'id': widget.product['id'],
          'name_ar': widget.product['name_ar'],
          'slug': widget.product['slug'],
          'price': widget.product['price'],
          'final_price': widget.product['final_price'],
          'main_image': widget.product['main_image'],
          'discount_percentage': widget.product['discount_percentage'],
          'brand': widget.product['brand'],
          'rate': widget.product['rate'],
        };
        await _favoritesService.addProduct(productData);
        setState(() {
          _isFavorite = true;
        });
        _showSnackBar('تم إضافة المنتج إلى المفضلة', Colors.green);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
      debugPrint('Error toggling favorite: $e');
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

    final cartItem = CartItemModel(
      id: widget.product['id'],
      name: widget.product['name_ar']?.toString() ?? 'غير معروف',
      slug: widget.product['slug']?.toString() ?? '',
      price: double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0,
      finalPrice: double.tryParse(widget.product['final_price']?.toString() ?? '0') ?? 0,
      image: widget.product['main_image']?.toString(),
      stock: widget.product['stock'] ?? 0,
      discountPercentage: widget.product['discount_percentage']?.toDouble(),
    );

    cartService.addItem(cartItem);
    _showSnackBar('تم إضافة المنتج إلى السلة', Colors.green);
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
    final double finalPrice = double.tryParse(widget.product['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice = double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0;
    final String name = widget.product['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.product['main_image']?.toString() ?? '';
    final String brand = widget.product['brand']?.toString() ?? '';

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
          // تحديث حالة المفضلة عند العودة
          setState(() {
            _isFavorite = _favoritesService.isProductFavorite(widget.product['id']);
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
            // Image Section
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
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  )
                      : Container(
                    height: 130,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
                // Discount Badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                // Favorite Button
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
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Cart Button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _addToCart,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
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
            // Content Section
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
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          Helpers.formatPrice(originalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        Helpers.formatPrice(finalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}