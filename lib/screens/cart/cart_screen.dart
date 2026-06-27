// lib/screens/cart/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final ApiService? apiService;
  final AuthService? authService;

  const CartScreen({
    super.key,
    this.apiService,
    this.authService,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final CartService _cartService = CartService.instance;
  bool _isLoading = true;

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _cartAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addObserver(this);
    _loadCart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCartData();
    }
  }

  Future<void> _loadCart() async {
    await _cartService.loadCart();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCartData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _cartService.loadCart();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _refreshCartData();
    _showSnackBar('تم تحديث السلة', primaryBlue);
  }

  void _updateQuantity(CartItemModel item, int newQuantity) {
    if (newQuantity > item.stock) {
      _showSnackBar('الكمية المتاحة: ${item.stock} فقط', Colors.orange);
      return;
    }
    HapticFeedback.lightImpact();
    _cartService.updateQuantity(item.id, newQuantity, itemType: item.itemType);
    setState(() {});
  }

  void _removeItem(CartItemModel item) {
    HapticFeedback.mediumImpact();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_rounded, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'حذف ${item.isOffer ? 'العرض' : 'المنتج'}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف ${item.name} من السلة؟',
            style: GoogleFonts.cairo(fontSize: 15, color: mediumGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: mediumGray)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _cartService.removeItem(item.id, itemType: item.itemType);
                Navigator.pop(context);
                setState(() {});
                _showSnackBar('تم حذف ${item.isOffer ? 'العرض' : 'المنتج'} من السلة', Colors.orange);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('حذف', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCart() {
    HapticFeedback.heavyImpact();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'تفريغ السلة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من تفريغ السلة بالكامل؟',
            style: GoogleFonts.cairo(fontSize: 15, color: mediumGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: mediumGray)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                _cartService.clearCart();
                Navigator.pop(context);
                setState(() {});
                _showSnackBar('تم تفريغ السلة بنجاح', Colors.orange);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تفريغ', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
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

  void _navigateToProductDetails(CartItemModel item) {
    if (item.isOffer) {
      _showSnackBar('تفاصيل العرض غير متاحة حالياً', Colors.orange);
      return;
    }

    if (widget.apiService == null) {
      _showSnackBar('لا يمكن فتح تفاصيل المنتج حالياً', Colors.orange);
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProductDetailsScreen(
          productSlug: item.slug,
          apiService: widget.apiService!,
          authService: widget.authService,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) => _refreshCartData());
  }

  void _checkout() {
    if (CartService.instance.items.isEmpty) {
      _showSnackBar('السلة فارغة، أضف منتجات أولاً', Colors.orange);
      return;
    }

    HapticFeedback.heavyImpact();
    _cartAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              items: CartService.instance.items,
              totalPrice: CartService.instance.totalPrice,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          _cartAnimationController.reset();
          _refreshCartData();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.15),
                  child: child,
                );
              },
              child: const Icon(Icons.shopping_cart_rounded, color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'سلة المشتريات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_cartService.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: _clearCart,
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18),
                label: Text(
                  'تفريغ الكل',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _cartService.items.isEmpty
          ? _buildEmptyCart()
          : RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryBlue,
        backgroundColor: cardWhite,
        child: Column(
          children: [
            _buildItemsCountBanner(),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cartService.items.length,
                itemBuilder: (context, index) {
                  final item = _cartService.items[index];
                  return _buildCartItemCard(item, index);
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCountBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.08),
            secondaryBlue.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
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
            child: const Icon(Icons.shopping_basket_rounded, color: primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_cartService.items.length} ${_cartService.items.length == 1 ? 'منتج' : 'منتجات'} في السلة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اسحب للأسفل للتحديث',
                  style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              Helpers.formatPrice(_cartService.totalPrice),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item, int index) {
    final bool hasDiscount = (item.discountPercentage ?? 0) > 0;
    final bool isOffer = item.isOffer;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToProductDetails(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: isOffer
                ? Border.all(color: primaryBlue.withOpacity(0.4), width: 1.5)
                : Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: isOffer
                    ? primaryBlue.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'cart_item_${item.id}_${item.itemType}',
                  child: Container(
                    width: 110,
                    height: 130,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          item.image != null && item.image!.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: item.image!,
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
                              color: Colors.grey.shade100,
                              child: Icon(
                                isOffer ? Icons.local_offer_rounded : Icons.shopping_bag_rounded,
                                size: 35,
                                color: Colors.grey,
                              ),
                            ),
                          )
                              : Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              isOffer ? Icons.local_offer_rounded : Icons.shopping_bag_rounded,
                              size: 35,
                              color: Colors.grey,
                            ),
                          ),
                          if (hasDiscount)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '-${item.discountPercentage?.toStringAsFixed(0)}%',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (isOffer)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryBlue, secondaryBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'عرض',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isOffer && item.totalWattage != null && item.totalWattage! > 0)
                          Row(
                            children: [
                              _buildMiniInfoChip(
                                icon: Icons.bolt_rounded,
                                value: '${item.totalWattage} واط',
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              if (item.totalCapacity != null && item.totalCapacity! > 0)
                                _buildMiniInfoChip(
                                  icon: Icons.battery_charging_full_rounded,
                                  value: '${item.totalCapacity} واط/س',
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                Helpers.formatPrice(item.price),
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              Helpers.formatPrice(item.finalPrice),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (item.stock <= 5 && item.stock < 999999)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade50, Colors.orange.shade100],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'المتبقي ${item.stock} ${item.isOffer ? 'عرض' : 'قطعة'} فقط',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
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
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: item.quantity > 1
                                          ? () => _updateQuantity(item, item.quantity - 1)
                                          : null,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          size: 16,
                                          color: item.quantity > 1 ? primaryBlue : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 35,
                                    child: Center(
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _updateQuantity(item, item.quantity + 1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الإجمالي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: mediumGray,
                                  ),
                                ),
                                Text(
                                  Helpers.formatPrice(item.totalPrice),
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _removeItem(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfoChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 9, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.06),
                    secondaryBlue.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_rounded, size: 18, color: mediumGray),
                      const SizedBox(width: 8),
                      Text(
                        'المجموع الفرعي',
                        style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
                      ),
                      const Spacer(),
                      Text(
                        Helpers.formatPrice(_cartService.totalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 18, color: mediumGray),
                      const SizedBox(width: 8),
                      Text(
                        'رسوم التوصيل',
                        style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
                      ),
                      const Spacer(),
                      Text(
                        'سيتم حسابها لاحقاً',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          primaryBlue.withOpacity(0.3),
                          Colors.grey.shade200,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded, size: 20, color: primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'الإجمالي',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Helpers.formatPrice(_cartService.totalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _cartAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_cartAnimationController.value * 0.03),
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _checkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 8,
                    shadowColor: primaryBlue.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseAnimationController.value * 0.1),
                            child: child,
                          );
                        },
                        child: const Icon(Icons.shopping_cart_checkout_rounded, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إتمام الطلب',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Helpers.formatPrice(_cartService.totalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 15,
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

  Widget _buildEmptyCart() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: primaryBlue,
      backgroundColor: cardWhite,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight - 56,
          child: Center(
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
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseAnimationController.value * 0.1),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardWhite,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: primaryBlue.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'سلة مشترياتك فارغة',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ابدأ بإضافة بعض المنتجات الرائعة',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 130,
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        );
      },
    );
  }
}