// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/order_api_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double totalPrice;
  final AuthService? authService;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalPrice,
    this.authService,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isLoading = false;
  double _discount = 0;
  double _shippingCost = 0;
  double _tax = 0;
  double _taxRate = 0;
  String _selectedPaymentMethod = 'cash';
  bool _showCouponField = false;
  bool _isCouponValid = false;
  String? _appliedCouponCode;
  String? _couponMessage;


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _submitAnimationController;

  late OrderApiService _orderApiService;
  final String _baseUrl = 'https://aa-dev.online/energy';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'cash',
      'label': 'الدفع عند الاستلام',
      'icon': Icons.money_rounded,
      'desc': 'ادفع نقداً عند استلام الطلب',
      'color': Colors.green,
    },
    {
      'value': 'bank_transfer',
      'label': 'تحويل بنكي',
      'icon': Icons.account_balance_rounded,
      'desc': 'حوالة مصرفية',
      'color': Colors.blue,
    },
    {
      'value': 'card',
      'label': 'بطاقة ائتمان',
      'icon': Icons.credit_card_rounded,
      'desc': 'فيزا / ماستركارد',
      'color': Colors.purple,
    },
    {
      'value': 'wallet',
      'label': 'المحفظة الإلكترونية',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'دفع عبر المحفظة',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _submitAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initApiService();
    _loadUserData();

  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }

  void _initApiService() {
    AuthService authService;
    if (widget.authService != null) {
      authService = widget.authService!;
    } else {
      final storageService = StorageService();
      authService = AuthService(storageService: storageService);
    }
    _orderApiService = OrderApiService(
      baseUrl: _baseUrl,
      authService: authService,
    );
  }

  Future<void> _loadUserData() async {
    try {
      AuthService authService;
      if (widget.authService != null) {
        authService = widget.authService!;
      } else {
        final storageService = StorageService();
        await storageService.init();
        authService = AuthService(storageService: storageService);
        await authService.refreshAuthState();
      }

      if (authService.isAuthenticated == true) {
        final userData = await authService.getUserData();
        if (userData != null && mounted) {
          final fullName = (userData['name'] ?? '').toString().split(' ');
          setState(() {
            if (fullName.isNotEmpty) {
              _firstNameController.text = fullName[0];
              if (fullName.length > 1) {
                _lastNameController.text = fullName.sublist(1).join(' ');
              }
            }
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
          });
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }




  Future<void> _applyCoupon() async {
    final coupon = _couponController.text.trim();
    if (coupon.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await _orderApiService.validateCoupon(coupon, _subtotal);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          final data = result['data'];
          _discount = double.parse(data['discount_value'].toString());
          _isCouponValid = true;
          _appliedCouponCode = coupon;
          _couponMessage = data['discount_text'];
          _showSnackBar(
            'تم تطبيق ${data['discount_text']} بنجاح!',
            primaryBlue,
          );
        } else {
          _discount = 0;
          _isCouponValid = false;
          _appliedCouponCode = null;
          _couponMessage = null;
          _showSnackBar(result['message'], Colors.red);
        }
      });
    }
  }

  void _removeCoupon() {
    HapticFeedback.lightImpact();
    setState(() {
      _couponController.clear();
      _discount = 0;
      _isCouponValid = false;
      _appliedCouponCode = null;
      _couponMessage = null;
      _showCouponField = false;
    });
  }

  double get _subtotal => widget.totalPrice;
  double get _discountAmount => _discount;
  double get _shippingAmount => _shippingCost;
  double get _taxAmount => _tax;
  double get _grandTotal => _subtotal - _discountAmount + _shippingAmount + _taxAmount;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى تعبئة جميع الحقول المطلوبة', Colors.orange);
      return;
    }

    final authService = widget.authService ?? AuthService(storageService: StorageService()..init());
    await authService.refreshAuthState();

    if (!authService.isAuthenticated) {
      _showSnackBar('يرجى تسجيل الدخول أولاً', Colors.orange);
      return;
    }

    HapticFeedback.heavyImpact();
    _submitAnimationController.forward();

    setState(() => _isLoading = true);

    final result = await _orderApiService.createOrder(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      items: widget.items,
      couponCode: _isCouponValid ? _appliedCouponCode : null,
      userNotes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      _submitAnimationController.reset();

      if (result['success']) {
        final orderData = result['data'];
        if (orderData['invoice'] != null) {
          final invoice = orderData['invoice'];
          if (invoice['total'] is String) {
            invoice['total'] = (invoice['total'] as String).replaceAll(',', '');
          }
          if (invoice['subtotal'] is String) {
            invoice['subtotal'] = (invoice['subtotal'] as String).replaceAll(',', '');
          }
          if (invoice['shipping_fee'] is String) {
            invoice['shipping_fee'] = (invoice['shipping_fee'] as String).replaceAll(',', '');
          }
          if (invoice['tax'] is String) {
            invoice['tax'] = (invoice['tax'] as String).replaceAll(',', '');
          }
          if (invoice['discount'] is String) {
            invoice['discount'] = (invoice['discount'] as String).replaceAll(',', '');
          }
        }
        await CartService.instance.clearCart();
        _showOrderConfirmation(orderData);
      } else {
        _showSnackBar(result['message'], Colors.red);
      }
    }
  }

  void _showOrderConfirmation(Map<String, dynamic> orderData) {
    final invoice = orderData['invoice'];
    if (!mounted) return;

    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        String cleanPrice = price.replaceAll(',', '').replaceAll(' ', '').trim();
        return double.tryParse(cleanPrice) ?? 0.0;
      }
      return 0.0;
    }

    final total = parsePrice(invoice['total']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Column(
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.15),
                        secondaryBlue.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 50, color: primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم استلام طلبك بنجاح!',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'شكراً لتسوقك معنا',
                style: GoogleFonts.cairo(fontSize: 16, color: darkColor),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.08),
                      secondaryBlue.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'رقم الطلب: ${invoice['invoice_number']}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إجمالي الطلب: ${Helpers.formatPrice(total)}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'سيتم التواصل معك خلال 24 ساعة لتأكيد الطلب',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: mediumGray,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final storageService = StorageService();
                  final authService = widget.authService ?? AuthService(storageService: storageService);


                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        authService: authService,
                        storageService: storageService,),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  shadowColor: primaryBlue.withOpacity(0.5),
                ),
                child: Text(
                  'العودة إلى الرئيسية',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
              color == primaryBlue ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
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
              child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'تأكيد الطلب',
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
      ),
      body: _isLoading
          ? _buildLoadingOverlay()
          : Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildOrderSummary()),
            SliverToBoxAdapter(child: _buildShippingInfo()),
            SliverToBoxAdapter(child: _buildPaymentMethods()),
            SliverToBoxAdapter(child: _buildAdditionalNotes()),
            SliverToBoxAdapter(child: _buildPriceDetails()),
            SliverToBoxAdapter(child: _buildSubmitButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return FadeTransition(
      opacity: _fadeAnimationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fadeAnimationController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.12),
                          secondaryBlue.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.shopping_basket_rounded, size: 22, color: primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ملخص الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.08),
                          secondaryBlue.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${widget.items.length} منتجات',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length > 3 ? 3 : widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _buildOrderItem(item, index);
                },
              ),
              if (widget.items.length > 3) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'و ${widget.items.length - 3} منتجات أخرى',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'checkout_item_${item.id}_${item.itemType}',
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.image != null && item.image!.isNotEmpty
                      ? Image.network(
                    item.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        item.isOffer ? Icons.local_offer_rounded : Icons.shopping_bag_rounded,
                        size: 25,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      item.isOffer ? Icons.local_offer_rounded : Icons.shopping_bag_rounded,
                      size: 25,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: darkColor,
                          ),
                        ),
                      ),
                      if (item.isOffer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'عرض',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الكمية: ${item.quantity} × ${Helpers.formatPrice(item.finalPrice)}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.15),
                      Colors.blue.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.local_shipping_rounded, size: 22, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(color: darkColor),
                  decoration: _buildInputDecoration('الاسم الأول', Icons.person_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(color: darkColor),
                  decoration: _buildInputDecoration('الاسم الأخير', Icons.person_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(color: darkColor),
            decoration: _buildInputDecoration('رقم الهاتف', Icons.phone_rounded),
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: GoogleFonts.cairo(color: darkColor),
            decoration: _buildInputDecoration('عنوان التوصيل', Icons.home_rounded),
            validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.15),
                      Colors.purple.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.payment_rounded, size: 22, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Text(
                'وسيلة الدفع',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method['value'];
            final color = method['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedPaymentMethod = method['value']);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                            )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            method['icon'],
                            size: 24,
                            color: isSelected ? color : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['label'],
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? darkColor : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method['desc'],
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: isSelected ? color : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdditionalNotes() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.15),
                      Colors.orange.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.note_add_rounded, size: 22, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Text(
                'ملاحظات إضافية',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            style: GoogleFonts.cairo(color: darkColor),
            decoration: _buildInputDecoration('أضف ملاحظات (اختياري)', Icons.edit_note_rounded),
          ),
          const SizedBox(height: 16),
          if (!_showCouponField && _discount == 0)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _showCouponField = true);
              },
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.12),
                      secondaryBlue.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.discount_rounded, size: 16, color: primaryBlue),
              ),
              label: Text(
                'لديك رمز خصم؟ اضغط هنا',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: primaryBlue),
            ),
          if (_showCouponField || _discount > 0)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isCouponValid ? primaryBlue.withOpacity(0.5) : Colors.grey.shade300,
                  width: _isCouponValid ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
                color: _isCouponValid ? primaryBlue.withOpacity(0.03) : Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textDirection: TextDirection.ltr,
                      enabled: _discount == 0,
                      style: GoogleFonts.cairo(color: darkColor),
                      decoration: InputDecoration(
                        hintText: 'رمز القسيمة',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  if (_discount > 0)
                    IconButton(
                      onPressed: _removeCoupon,
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      ),
                    ),
                  if (_discount == 0)
                    Container(
                      margin: const EdgeInsets.all(6),
                      child: ElevatedButton(
                        onPressed: _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('تطبيق', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          if (_couponMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.06),
                      secondaryBlue.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      '✓ $_couponMessage',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
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

  Widget _buildPriceDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.12),
                      secondaryBlue.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 22, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل السعر',
                style: GoogleFonts.cairo(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPriceRow(
            'المجموع الفرعي',
            Helpers.formatPrice(_subtotal),
            Icons.calculate_rounded,
          ),
          if (_discountAmount > 0)
            _buildPriceRow(
              'الخصم',
              '- ${Helpers.formatPrice(_discountAmount)}',
              Icons.discount_rounded,
              isDiscount: true,
            ),

          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشحن',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: mediumGray,
                        ),
                      ),
                      Text(
                        'سيتم احتسابها لاحقاً حسب موقعك',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'مجاني',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          _buildPriceRow(
            'الضريبة',
            '0 ${_taxRate == 0 ? '(غير محسوبة)' : ''}',
            Icons.receipt_rounded,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 2,
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
          _buildPriceRow(
            'الإجمالي',
            Helpers.formatPrice(_grandTotal),
            Icons.monetization_on_rounded,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label,
      String value,
      IconData icon, {
        bool isTotal = false,
        bool isDiscount = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTotal ? primaryBlue.withOpacity(0.04) : lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTotal ? primaryBlue.withOpacity(0.15) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isTotal
                  ? primaryBlue.withOpacity(0.1)
                  : (isDiscount ? Colors.red.withOpacity(0.1) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isTotal
                  ? primaryBlue
                  : (isDiscount ? Colors.red : Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : mediumGray,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? primaryBlue : (isDiscount ? Colors.red : darkColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _submitAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_submitAnimationController.value * 0.03),
            child: child,
          );
        },
        child: ElevatedButton(
          onPressed: _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
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
                child: const Icon(Icons.check_circle_rounded, size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                'تأكيد الطلب',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  Helpers.formatPrice(_grandTotal),
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        Opacity(
          opacity: 0.4,
          child: Container(color: Colors.black),
        ),
        Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseAnimationController.value * 0.2),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primaryBlue.withOpacity(0.15),
                            secondaryBlue.withOpacity(0.08),
                          ],
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        color: primaryBlue,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'جاري تأكيد الطلب...',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى الانتظار قليلاً',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(
        color: mediumGray,
        fontSize: 14,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryBlue.withOpacity(0.12),
              secondaryBlue.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}