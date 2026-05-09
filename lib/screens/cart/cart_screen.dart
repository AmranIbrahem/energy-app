import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:energy_store_app/services/cart_service.dart';
import 'package:energy_store_app/models/cart_item_model.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/products/product_details_screen.dart';
import 'package:lottie/lottie.dart';
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

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final CartService _cartService = CartService.instance;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ استخدام TickerProviderStateMixin
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCartData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    await _cartService.loadCart();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _refreshCartData();
    _showSnackBar('تم تحديث السلة', Colors.green);
  }

  void _updateQuantity(CartItemModel item, int newQuantity) {
    if (newQuantity > item.stock) {
      _showSnackBar('الكمية المتاحة: ${item.stock} فقط', Colors.orange);
      return;
    }
    _cartService.updateQuantity(item.id, newQuantity, itemType: item.itemType);
    setState(() {});
  }

  void _removeItem(CartItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف ${item.isOffer ? 'العرض' : 'المنتج'}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${item.name} من السلة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.removeItem(item.id, itemType: item.itemType);
              Navigator.pop(context);
              setState(() {});
              _showSnackBar('تم حذف ${item.isOffer ? 'العرض' : 'المنتج'} من السلة', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تفريغ السلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تفريغ السلة بالكامل؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              _cartService.clearCart();
              Navigator.pop(context);
              setState(() {});
              _showSnackBar('تم تفريغ السلة بنجاح', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تفريغ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productSlug: item.slug,
          apiService: widget.apiService!,
          authService: widget.authService,
        ),
      ),
    ).then((_) {
      _refreshCartData();
    });
  }

  void _checkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          items: _cartService.items,
          totalPrice: _cartService.totalPrice,
          authService: widget.authService,
        ),
      ),
    ).then((_) {
      _refreshCartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'سلة المشتريات',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_cartService.items.isNotEmpty)
            FadeInAnimation(
              delay: 0,
              child: TextButton.icon(
                onPressed: _clearCart,
                icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 20),
                label: Text(
                  'تفريغ الكل',
                  style: GoogleFonts.cairo(color: Colors.red, fontSize: 14),
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
        color: const Color(0xFF10B981),
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _cartService.items.length,
                itemBuilder: (context, index) {
                  final item = _cartService.items[index];
                  return FadeInAnimation(
                    delay: index * 0.05,
                    child: _buildCartItemCard(item),
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    final bool hasDiscount = (item.discountPercentage ?? 0) > 0;
    final bool isOffer = item.isOffer;

    return GestureDetector(
      onTap: () => _navigateToProductDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isOffer
              ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج/العرض - جهة اليسار
            SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.image != null && item.image!.isNotEmpty
                          ? Image.network(
                        item.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            isOffer ? Icons.local_offer : Icons.shopping_bag,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          isOffer ? Icons.local_offer : Icons.shopping_bag,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${item.discountPercentage?.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isOffer)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'عرض',
                            style: GoogleFonts.cairo(
                              fontSize: 8,
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
            // المحتوى - جهة اليمين
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج/العرض
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // معلومات إضافية للعرض
                    if (isOffer && item.totalWattage != null && item.totalWattage! > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, size: 10, color: Colors.orange.shade600),
                            const SizedBox(width: 2),
                            Text(
                              '${item.totalWattage} واط',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.battery_std, size: 10, color: Colors.blue.shade600),
                            const SizedBox(width: 2),
                            Text(
                              '${item.totalCapacity ?? 0} واط/س',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // السعر والخصم
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            Helpers.formatPrice(item.price),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        Text(
                          Helpers.formatPrice(item.finalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // المخزون المحدود
                    if (item.stock <= 5 && item.stock < 999999)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'المتبقي ${item.stock} ${item.isOffer ? 'عرض' : 'قطعة'} فقط',
                          style: GoogleFonts.cairo(
                            fontSize: 8,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // أزرار الكمية والسعر الإجمالي
                    Row(
                      children: [
                        // أزرار الكمية
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: item.quantity > 1
                                    ? () => _updateQuantity(item, item.quantity - 1)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: item.quantity > 1 ? Colors.black87 : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _updateQuantity(item, item.quantity + 1),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: const Icon(Icons.add, size: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // السعر الإجمالي
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الإجمالي',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              Helpers.formatPrice(item.totalPrice),
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        // زر الحذف
                        InkWell(
                          onTap: () => _removeItem(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'المجموع الفرعي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatPrice(_cartService.totalPrice),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'رسوم التوصيل',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'سيتم حسابها لاحقاً',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Row(
                  children: [
                    Text(
                      'الإجمالي',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatPrice(_cartService.totalPrice),
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, size: 22),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.formatPrice(_cartService.totalPrice),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - kToolbarHeight - 56,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/animations/empty_cart.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'سلة مشترياتك فارغة',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ابدأ بإضافة بعض المنتجات الرائعة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                // ✅ تم إزالة زر "مواصلة التسوق"
              ],
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
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
}

class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final double delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (delay * 100).toInt()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}