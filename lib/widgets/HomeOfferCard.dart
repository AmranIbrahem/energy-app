import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/screens/offers/offer_details_screen.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';

class HomeOfferCard extends StatefulWidget {
  final dynamic offer;
  final ApiService apiService;
  final AuthService? authService;

  const HomeOfferCard({
    super.key,
    required this.offer,
    required this.apiService,
    this.authService,
  });

  @override
  State<HomeOfferCard> createState() => _HomeOfferCardState();
}

class _HomeOfferCardState extends State<HomeOfferCard>
    with TickerProviderStateMixin  {
  final FavoritesService _favoritesService = FavoritesService.instance;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  bool _isAddedToCart = false;
  bool _isAddingToCart = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _cartAnimationController;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoritesService.isOfferFavorite(widget.offer['id']);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isUpdatingFavorite = true);
    try {
      if (_isFavorite) {
        await _favoritesService.removeOffer(widget.offer['id']);
        if (mounted) setState(() => _isFavorite = false);
      } else {
        final offerData = {
          'id': widget.offer['id'],
          'name_ar': widget.offer['name_ar'],
          'slug': widget.offer['slug'],
          'price': widget.offer['price'],
          'final_price': widget.offer['final_price'],
          'cover_image': widget.offer['cover_image'],
          'discount_percentage': widget.offer['discount_percentage'],
          'total_wattage': widget.offer['total_wattage'],
          'total_capacity': widget.offer['total_capacity'],
          'rate': widget.offer['rate'],
        };
        await _favoritesService.addOffer(offerData);
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

    setState(() {
      _isAddingToCart = true;
      _isAddedToCart = true;
    });

    _cartAnimationController.forward();

    // استخدام CartItemModel.fromOffer لنفس منطق OfferDetailsScreen
    final cartItem = CartItemModel.fromOffer(
      widget.offer,
      quantity: 1,
    );

    cartService.addOffer(cartItem);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _cartAnimationController.reset();
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تمت إضافة العرض إلى السلة', style: GoogleFonts.cairo(fontSize: 13)),
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
    final bool hasDiscount = (widget.offer['discount_percentage'] ?? 0) > 0;
    final double finalPrice =
        double.tryParse(widget.offer['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice =
        double.tryParse(widget.offer['price']?.toString() ?? '0') ?? 0;
    final int totalWattage = widget.offer['total_wattage'] ?? 0;
    final int totalCapacity = widget.offer['total_capacity'] ?? 0;
    final String name =
        widget.offer['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.offer['cover_image']?.toString() ?? '';
    final double rating =
        double.tryParse(widget.offer['rate']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferDetailsScreen(
              offerSlug: widget.offer['slug']?.toString() ?? '',
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isFavorite =
                  _favoritesService.isOfferFavorite(widget.offer['id']);
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
              // 📸 صورة العرض
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
                        tag: 'offer_${widget.offer['id']}',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade100,
                            child: Container(color: Colors.grey.shade200),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.local_offer_rounded,
                                size: 40, color: Colors.grey.shade400),
                          ),
                        ),
                      )
                          : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.local_offer_rounded,
                            size: 40, color: Colors.grey.shade400),
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
                          '-${(widget.offer['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
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

                  // معلومات الطاقة
                  if (totalWattage > 0 || totalCapacity > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          if (totalWattage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded,
                                      color: Color(0xFFF59E0B), size: 10),
                                  const SizedBox(width: 2),
                                  Text('$totalWattage',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 9)),
                                ],
                              ),
                            ),
                          if (totalWattage > 0 && totalCapacity > 0)
                            const SizedBox(width: 4),
                          if (totalCapacity > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.battery_charging_full_rounded,
                                      color: Color(0xFF3B82F6), size: 10),
                                  const SizedBox(width: 2),
                                  Text('$totalCapacity',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 9)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // زر المفضلة
                  Positioned(
                    bottom: 8,
                    right: 8,
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

              // ✅ المحتوى المرن
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم العرض
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

                      // السعر
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
                onTap: _isAddingToCart ? null : _addToCart,
                child: AnimatedBuilder(
                  animation: _cartAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 - (_cartAnimationController.value * 0.05),
                      child: child,
                    );
                  },
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
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isAddingToCart)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Icon(
                            _isAddedToCart
                                ? Icons.check_rounded
                                : Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          _isAddingToCart
                              ? 'جاري الإضافة...'
                              : _isAddedToCart
                              ? 'تم ✓'
                              : 'أضف للسلة',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}