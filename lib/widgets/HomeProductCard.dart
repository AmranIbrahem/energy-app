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
          'slug': widget.product['slug'],
          'price': widget.product['price'],
          'final_price': widget.product['final_price'],
          'main_image': widget.product['main_image'],
          'discount_percentage': widget.product['discount_percentage'],
          'brand': widget.product['brand'],
          'rate': widget.product['rate'],
        };
        await _favoritesService.addProduct(productData);
        if (mounted) setState(() => _isFavorite = true);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingFavorite = false);
    }
  }

  void _addToCart() {
    final cartService = CartService.instance;

    final cartItem = CartItemModel(
      id: widget.product['id'],
      name: widget.product['name_ar']?.toString() ?? 'غير معروف',
      slug: widget.product['slug']?.toString() ?? '',
      price: double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0,
      finalPrice:
      double.tryParse(widget.product['final_price']?.toString() ?? '0') ?? 0,
      image: widget.product['main_image']?.toString(),
      stock: widget.product['stock'] ?? 0,
      discountPercentage: widget.product['discount_percentage']?.toDouble(),
    );

    cartService.addItem(cartItem);

    setState(() => _isAddedToCart = true);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تمت الإضافة إلى السلة', style: GoogleFonts.cairo(fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isAddedToCart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = (widget.product['discount_percentage'] ?? 0) > 0;
    final double finalPrice =
        double.tryParse(widget.product['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice =
        double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0;
    final String name =
        widget.product['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.product['main_image']?.toString() ?? '';
    final String brand = widget.product['brand']?.toString() ?? '';
    final double rating =
        double.tryParse(widget.product['rate']?.toString() ?? '0') ?? 0;

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
              // 📸 صورة المنتج
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
                          errorWidget: (context, url, error) =>
                              Container(
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

                  // شارة الخصم
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

                  // التقييم
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

                  // زر المفضلة
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
                          color:
                          _isFavorite ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ المحتوى المرن (يتمدد ليملأ المساحة)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العلامة التجارية
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

                      // اسم المنتج (يأخذ المساحة المتبقية)
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

                      // السعر (ثابت في الأسفل قبل الزر)
                      Row(
                        children: [
                          Text(
                            Helpers.formatPrice(finalPrice),
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
                                Helpers.formatPrice(originalPrice),
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
                      ),
                    ],
                  ),
                ),
              ),

              // 🛒 زر "أضف للسلة" - ثابت دائماً في الأسفل
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
                        : const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
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
                        _isAddedToCart ? 'تم ✓' : 'أضف للسلة',
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