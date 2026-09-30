// lib/screens/cart/checkout_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/screens/profile/orders_screen.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/order_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PaymentMethodModel {
  final String paymentCompanyName;
  final String? paymentCompanyImageUrl;
  final String? recipientName;
  final String? city;
  final String? phone;
  final String? accountNumber;
  final String? accountImageUrl;

  PaymentMethodModel({
    required this.paymentCompanyName,
    this.paymentCompanyImageUrl,
    this.recipientName,
    this.city,
    this.phone,
    this.accountNumber,
    this.accountImageUrl,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return PaymentMethodModel(
      paymentCompanyName: json['payment_company_name']?.toString() ?? '',
      paymentCompanyImageUrl: clean(json['payment_company_image_url']),
      recipientName: clean(json['recipient_name']),
      city: clean(json['city']),
      phone: clean(json['phone']),
      accountNumber: clean(json['account_number']),
      accountImageUrl: clean(json['account_image_url']),
    );
  }

  bool get hasDetails =>
      recipientName != null ||
      city != null ||
      phone != null ||
      accountNumber != null ||
      accountImageUrl != null;

  String get id => paymentCompanyName;
}

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
  final _customCompanyController = TextEditingController();
  final _customWalletController = TextEditingController();

  bool _isLoading = false;
  double _discount = 0;
  double _tax = 0;
  double _taxRate = 0;
  String _selectedPaymentMethod = 'cash';

  List<PaymentMethodModel> _bankTransferCompanies = [];
  List<PaymentMethodModel> _walletCompanies = [];
  bool _isLoadingBankTransfers = false;
  bool _isLoadingWallets = false;

  PaymentMethodModel? _selectedBankTransferCompany;
  PaymentMethodModel? _selectedWalletCompany;

  bool _useCustomCompany = false;
  bool _useCustomWallet = false;
  bool _showCouponField = false;
  bool _isCouponValid = false;
  String? _appliedCouponCode;
  String? _couponMessage;

  bool _isPrepaid = false;
  double _prepaidPercentage = 0;
  bool _isLoadingPrepaidPercentage = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _submitAnimationController;

  late OrderApiService _orderApiService;
  final String _baseUrl = 'https://nexsy.shop';
  final CartService _cartService = CartService.instance;

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
      'value': 'wallet',
      'label': 'المحفظة الإلكترونية',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'دفع عبر المحفظة',
      'color': Colors.orange,
    },
  ];

  bool get _isSypPreferred {
    final storage = widget.authService?.storageService;
    if (storage == null) return false;
    try {
      return storage.isSypPreferred();
    } catch (_) {
      return false;
    }
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
    _fetchPrepaidPercentage();

    _fetchPaymentMethodsByType('bank_transfer');
    _fetchPaymentMethodsByType('electronic_wallet');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    _customCompanyController.dispose();
    _customWalletController.dispose();
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

  Future<void> _fetchPaymentMethodsByType(String type) async {
    setState(() {
      if (type == 'bank_transfer') {
        _isLoadingBankTransfers = true;
      } else {
        _isLoadingWallets = true;
      }
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/nex/v1/user/public/payment-methods/type/$type'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded['data'] as List?) ?? [];
        final methods =
            list.map((e) => PaymentMethodModel.fromJson(e)).toList();

        if (mounted) {
          setState(() {
            if (type == 'bank_transfer') {
              _bankTransferCompanies = methods;
            } else {
              _walletCompanies = methods;
            }
          });
        }
      } else {}
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'bank_transfer') {
            _isLoadingBankTransfers = false;
          } else {
            _isLoadingWallets = false;
          }
        });
      }
    }
  }

  Future<void> _fetchPrepaidPercentage() async {
    setState(() => _isLoadingPrepaidPercentage = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/nex/v1/user/public/setting/aldfaa_almsbk'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['value'] != null) {
          setState(() {
            _prepaidPercentage =
                double.tryParse(data['data']['value'].toString()) ?? 0;
          });
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrepaidPercentage = false);
      }
    }
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
    } catch (e) {}
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

  double get _shippingAmount => _cartService.calculatedShippingCost;

  double get _taxAmount => _tax;

  double get _prepaidDiscountAmount {
    if (!_isPrepaid || _prepaidPercentage <= 0) return 0;
    return _subtotal * (_prepaidPercentage / 100);
  }

  double get _prepaidAmount {
    if (!_isPrepaid || _prepaidPercentage <= 0) return 0;
    return _subtotal - _prepaidDiscountAmount;
  }

  double get _grandTotal {
    double total = _subtotal - _discountAmount + _shippingAmount + _taxAmount;
    if (_isPrepaid && _prepaidDiscountAmount > 0) {
      total -= _prepaidDiscountAmount;
    }
    return total > 0 ? total : 0;
  }

  List<CartItemModel> get _pendingShippingItems {
    return _cartService.items.where((item) {
      return item.isShippingPendingForCity(_cartService.userGovernorate) ||
          !item.hasShippingInfo;
    }).toList();
  }

  List<CartItemModel> get _freeShippingItems {
    return _cartService.items.where((item) {
      return item.isFreeShippingForCity(_cartService.userGovernorate);
    }).toList();
  }

  List<CartItemModel> get _itemsWithShipping {
    return _cartService.items.where((item) {
      return item.isShippingCalculatedForCity(_cartService.userGovernorate);
    }).toList();
  }

  String _getSelectedBankTransferCompanyName() {
    if (_useCustomCompany) {
      return _customCompanyController.text.trim();
    }
    return _selectedBankTransferCompany?.paymentCompanyName ?? '';
  }

  String _getSelectedWalletCompanyName() {
    if (_useCustomWallet) {
      return _customWalletController.text.trim();
    }
    return _selectedWalletCompany?.paymentCompanyName ?? '';
  }

  String _buildShippingNotes() {
    final notes = StringBuffer();

    if (_pendingShippingItems.isNotEmpty) {
      notes.writeln('⚠️ المنتجات التالية بدون رسوم شحن محددة:');
      for (final item in _pendingShippingItems) {
        notes.writeln('- ${item.name} (الكمية: ${item.quantity})');
        if (item.hasShippingInfo) {
          notes.writeln(
              '  (المدينة: ${_cartService.userGovernorate ?? "غير محددة"} - غير متوفرة في قائمة الشحن)');
        } else {
          notes.writeln('  (لا توجد بيانات شحن متاحة)');
        }
      }
      notes.writeln();
    }

    if (_freeShippingItems.isNotEmpty) {
      notes.writeln('✅ المنتجات التالية شحنها مجاني:');
      for (final item in _freeShippingItems) {
        notes.writeln('- ${item.name} (الكمية: ${item.quantity})');
      }
      notes.writeln();
    }

    if (_itemsWithShipping.isNotEmpty) {
      notes.writeln('📦 المنتجات التالية لها رسوم شحن محسوبة:');
      for (final item in _itemsWithShipping) {
        final cost = item.getShippingCostForCity(_cartService.userGovernorate);
        notes.writeln(
            '- ${item.name} (الكمية: ${item.quantity}) - الشحن: ${Helpers.formatPrice(cost ?? 0)}');
      }
      notes.writeln();
    }

    return notes.toString().trim();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ $label', primaryBlue);
  }

  Future<void> _shareImage(String url, String title) async {
    try {
      _showSnackBar('جاري تجهيز الصورة...', primaryBlue);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _showSnackBar('فشل تحميل الصورة (${response.statusCode})', Colors.red);
        return;
      }

      final tempDir = await getTemporaryDirectory();

      String ext = 'jpg';
      try {
        final rawExt = url.split('.').last.split('?').first.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(rawExt)) {
          ext = rawExt;
        }
      } catch (_) {}

      final fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: title,
      );
    } catch (e) {
      _showSnackBar('تعذّر مشاركة الصورة', Colors.red);
    }
  }

  void _showPaymentMethodDetails(PaymentMethodModel method) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: lightGray,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: method.paymentCompanyImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: method.paymentCompanyImageUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) =>
                                          _companyPlaceholder(),
                                      placeholder: (_, __) =>
                                          _companyPlaceholder(),
                                    )
                                  : _companyPlaceholder(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.paymentCompanyName,
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تفاصيل التحويل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (method.recipientName != null)
                            _buildDetailRow(
                              icon: Icons.person_rounded,
                              label: 'اسم المستلم',
                              value: method.recipientName!,
                              onCopy: () => _copyToClipboard(
                                  method.recipientName!, 'اسم المستلم'),
                            ),
                          if (method.city != null)
                            _buildDetailRow(
                              icon: Icons.location_city_rounded,
                              label: 'المدينة',
                              value: method.city!,
                              onCopy: () =>
                                  _copyToClipboard(method.city!, 'المدينة'),
                            ),
                          if (method.phone != null)
                            _buildDetailRow(
                              icon: Icons.phone_rounded,
                              label: 'رقم الهاتف',
                              value: method.phone!,
                              onCopy: () =>
                                  _copyToClipboard(method.phone!, 'رقم الهاتف'),
                            ),
                          if (method.accountNumber != null)
                            _buildDetailRow(
                              icon: Icons.credit_card_rounded,
                              label: 'رقم الحساب',
                              value: method.accountNumber!,
                              onCopy: () => _copyToClipboard(
                                  method.accountNumber!, 'رقم الحساب'),
                            ),
                          if (method.accountImageUrl != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'صورة الحساب',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: CachedNetworkImage(
                                imageUrl: method.accountImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  height: 220,
                                  color: lightGray,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 220,
                                  color: lightGray,
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _shareImage(
                                  method.accountImageUrl!,
                                  'صورة حساب ${method.paymentCompanyName}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded),
                                label: Text(
                                  'حفظ / مشاركة صورة الحساب',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                          if (method.paymentCompanyImageUrl != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _shareImage(
                                  method.paymentCompanyImageUrl!,
                                  'شعار ${method.paymentCompanyName}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBlue,
                                  side: BorderSide(
                                    color: primaryBlue.withOpacity(0.4),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: Text(
                                  'مشاركة شعار الشركة',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  if (_selectedPaymentMethod ==
                                      'bank_transfer') {
                                    _selectedBankTransferCompany = method;
                                    _useCustomCompany = false;
                                    _customCompanyController.clear();
                                  } else if (_selectedPaymentMethod ==
                                      'wallet') {
                                    _selectedWalletCompany = method;
                                    _useCustomWallet = false;
                                    _customWalletController.clear();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text(
                                'اختيار هذه الطريقة',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
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
            child: Icon(icon, size: 18, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: mediumGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'نسخ',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.copy_rounded, size: 16, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyPlaceholder() {
    return Container(
      color: lightGray,
      child: Icon(
        Icons.account_balance_rounded,
        size: 28,
        color: Colors.grey.shade400,
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى تعبئة جميع الحقول المطلوبة', Colors.orange);
      return;
    }

    if (_isPrepaid && _selectedPaymentMethod == 'cash') {
      _showSnackBar(
          'الدفع المسبق لا يتوفر مع الدفع عند الاستلام - يرجى اختيار وسيلة دفع أخرى',
          Colors.red);
      return;
    }

    if (_selectedPaymentMethod == 'bank_transfer') {
      if (_useCustomCompany) {
        if (_customCompanyController.text.trim().isEmpty) {
          _showSnackBar('يرجى إدخال اسم شركة التحويل', Colors.orange);
          return;
        }
      } else {
        if (_selectedBankTransferCompany == null) {
          _showSnackBar('يرجى اختيار شركة التحويل', Colors.orange);
          return;
        }
      }
    }

    if (_selectedPaymentMethod == 'wallet') {
      if (_useCustomWallet) {
        if (_customWalletController.text.trim().isEmpty) {
          _showSnackBar('يرجى إدخال اسم المحفظة الإلكترونية', Colors.orange);
          return;
        }
      } else {
        if (_selectedWalletCompany == null) {
          _showSnackBar('يرجى اختيار المحفظة الإلكترونية', Colors.orange);
          return;
        }
      }
    }

    final authService = widget.authService ??
        AuthService(storageService: StorageService()..init());
    await authService.refreshAuthState();

    if (!authService.isAuthenticated) {
      HapticFeedback.mediumImpact();
      _showSnackBar('يرجى تسجيل الدخول أولاً', Colors.orange);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            authService: authService,
            storageService: StorageService(),
            returnToCheckout: true,
          ),
        ),
      );

      await authService.refreshAuthState();

      if (authService.isAuthenticated == true) {
        await _loadUserData();
      }
      return;
    }
    HapticFeedback.heavyImpact();
    _submitAnimationController.forward();

    setState(() => _isLoading = true);

    String notes = _notesController.text.trim();

    final shippingNotes = _buildShippingNotes();
    if (shippingNotes.isNotEmpty) {
      if (notes.isNotEmpty) notes += '\n\n';
      notes += shippingNotes;
    }

    if (_selectedPaymentMethod == 'bank_transfer') {
      final companyName = _getSelectedBankTransferCompanyName();
      if (companyName.isNotEmpty) {
        if (notes.isNotEmpty) notes += '\n';
        notes += 'تحويل بنكي عن طريق: $companyName';
      }
    } else if (_selectedPaymentMethod == 'wallet') {
      final walletName = _getSelectedWalletCompanyName();
      if (walletName.isNotEmpty) {
        if (notes.isNotEmpty) notes += '\n';
        notes += 'محفظة إلكترونية: $walletName';
      }
    }

    if (_isPrepaid && _prepaidPercentage > 0) {
      if (notes.isNotEmpty) notes += '\n';
      notes += '✅ دفع مسبق - خصم ${_prepaidPercentage}%';
    }

    if (_cartService.calculatedShippingCost > 0) {
      if (notes.isNotEmpty) notes += '\n';
      notes +=
          '📦 إجمالي رسوم الشحن المحسوبة: ${Helpers.formatPrice(_cartService.calculatedShippingCost)}';
      notes += ' (${_cartService.calculatedShippingItemsCount} عناصر)';
    }

    if (_cartService.freeShippingItemsCount > 0) {
      if (notes.isNotEmpty) notes += '\n';
      notes += '✅ ${_cartService.freeShippingItemsCount} عناصر شحنها مجاني';
    }

    if (_cartService.pendingShippingItemsCount > 0) {
      if (notes.isNotEmpty) notes += '\n';
      notes +=
          '⚠️ ${_cartService.pendingShippingItemsCount} عناصر سيتم تحديد شحنها لاحقاً';
    }

    final result = await _orderApiService.createOrder(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      items: widget.items,
      couponCode: _isCouponValid ? _appliedCouponCode : null,
      userNotes: notes,
      isPrepaid: _isPrepaid,
      isSyp: _isSypPreferred,
      governorate: _cartService.userGovernorate,
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
            invoice['subtotal'] =
                (invoice['subtotal'] as String).replaceAll(',', '');
          }
          if (invoice['shipping_fee'] is String) {
            invoice['shipping_fee'] =
                (invoice['shipping_fee'] as String).replaceAll(',', '');
          }
          if (invoice['tax'] is String) {
            invoice['tax'] = (invoice['tax'] as String).replaceAll(',', '');
          }
          if (invoice['discount'] is String) {
            invoice['discount'] =
                (invoice['discount'] as String).replaceAll(',', '');
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
        String cleanPrice =
            price.replaceAll(',', '').replaceAll(' ', '').trim();
        return double.tryParse(cleanPrice) ?? 0.0;
      }
      return 0.0;
    }

    final bool invoiceIsSyp =
        invoice['is_syp'] == true || invoice['is_syp'] == 1;

    String fmtInvoice(double price) {
      if (invoiceIsSyp) {
        return '${_formatNumber(price)} SYP';
      }
      return '\$${_formatNumber(price)}';
    }

    final total = parsePrice(invoice['total']);
    final isPrepaid = invoice['is_prepaid'] ?? false;
    final prepaidAmount = parsePrice(invoice['prepaid_amount']);

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                  child: const Icon(Icons.check_circle_rounded,
                      size: 50, color: primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم استلام طلبك بنجاح!',
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('شكراً لتسوقك معنا',
                  style: GoogleFonts.cairo(fontSize: 16, color: darkColor)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.08),
                      secondaryBlue.withOpacity(0.04)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: primaryBlue.withOpacity(0.15), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'رقم الطلب: ${invoice['invoice_number']}',
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إجمالي الطلب: ${fmtInvoice(total)}',
                      style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue),
                    ),
                    if (isPrepaid && prepaidAmount > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🏷️ خصم الدفع المسبق: ${invoice['prepaid_discount_percentage'] ?? 0}%',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💵 المبلغ بعد الخصم: ${fmtInvoice(prepaidAmount)}',
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'سيتم التواصل معك خلال 24 ساعة لتأكيد الطلب',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final storageService = StorageService();
                      final authService = widget.authService ??
                          AuthService(storageService: storageService);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => OrdersScreen(
                            authService: authService,
                            apiService: null,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: Text(
                      'الذهاب إلى طلباتي',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: successGreen.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final storageService = StorageService();
                      final authService = widget.authService ??
                          AuthService(storageService: storageService);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            authService: authService,
                            storageService: storageService,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: primaryBlue.withOpacity(0.5),
                    ),
                    child: Text(
                      'العودة إلى الرئيسية',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
              color == primaryBlue
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEFF6FF),
                Color(0xFFF5F7FA),
              ],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          if (Navigator.canPop(context))
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                          scale: 1.0 +
                                              (_pulseAnimationController.value *
                                                  0.15),
                                          child: child);
                                    },
                                    child: const Icon(
                                        Icons.shopping_cart_checkout_rounded,
                                        color: Colors.yellow,
                                        size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'تأكيد الطلب',
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingOverlay()
                    : Form(
                        key: _formKey,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(child: _buildOrderSummary()),
                            SliverToBoxAdapter(child: _buildShippingInfo()),
                            SliverToBoxAdapter(child: _buildPrepaidSection()),
                            SliverToBoxAdapter(child: _buildPaymentMethods()),
                            if (_selectedPaymentMethod == 'bank_transfer')
                              SliverToBoxAdapter(
                                  child: _buildBankTransferCompanies()),
                            if (_selectedPaymentMethod == 'wallet')
                              SliverToBoxAdapter(
                                  child: _buildWalletCompanies()),
                            SliverToBoxAdapter(child: _buildAdditionalNotes()),
                            SliverToBoxAdapter(child: _buildPriceDetails()),
                            SliverToBoxAdapter(child: _buildSubmitButton()),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 30)),
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
            border: Border.all(color: Colors.grey.shade100, width: 1),
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
                    child: const Icon(Icons.shopping_basket_rounded,
                        size: 22, color: primaryBlue),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              if (_cartService.calculatedShippingCost > 0 ||
                  _cartService.freeShippingItemsCount > 0 ||
                  _cartService.pendingShippingItemsCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (_cartService.calculatedShippingCost > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded,
                                size: 16, color: successGreen),
                            const SizedBox(width: 8),
                            Text(
                              'رسوم الشحن المحسوبة: ${Helpers.formatPrice(_cartService.calculatedShippingCost)}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (_cartService.freeShippingItemsCount > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              '${_cartService.freeShippingItemsCount} عناصر شحنها مجاني',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (_cartService.pendingShippingItemsCount > 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '${_cartService.pendingShippingItemsCount} عناصر سيتم تحديد شحنها لاحقاً',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
    final shippingCost =
        item.getShippingCostForCity(_cartService.userGovernorate);
    final bool isFreeShipping =
        item.isFreeShippingForCity(_cartService.userGovernorate);
    final bool isPendingShipping =
        item.isShippingPendingForCity(_cartService.userGovernorate) ||
            !item.hasShippingInfo;
    final bool isCalculatedShipping =
        item.isShippingCalculatedForCity(_cartService.userGovernorate);

    final double displayFinalPrice =
        item.displayFinalPrice(isSyp: _isSypPreferred);
    final double displayTotalPrice =
        item.displayTotalPrice(isSyp: _isSypPreferred);

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
                              item.isOffer
                                  ? Icons.local_offer_rounded
                                  : Icons.shopping_bag_rounded,
                              size: 25,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            item.isOffer
                                ? Icons.local_offer_rounded
                                : Icons.shopping_bag_rounded,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
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
                    'الكمية: ${item.quantity} × ${_fmt(displayFinalPrice)}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: mediumGray,
                    ),
                  ),
                  if (isFreeShipping)
                    Text(
                      '🚚 شحن مجاني',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (isCalculatedShipping)
                    Text(
                      '🚚 شحن: ${Helpers.formatPrice(shippingCost ?? 0)}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (isPendingShipping)
                    Text(
                      '📦 سيتم تحديد الشحن لاحقاً',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmt(displayTotalPrice),
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
        border: Border.all(color: Colors.grey.shade100, width: 1),
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
                child: const Icon(Icons.local_shipping_rounded,
                    size: 22, color: Colors.blue),
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
                  decoration: _buildInputDecoration(
                      'الاسم الأول', Icons.person_rounded),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(color: darkColor),
                  decoration: _buildInputDecoration(
                      'الاسم الأخير', Icons.person_rounded),
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
            decoration:
                _buildInputDecoration('رقم الهاتف', Icons.phone_rounded),
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
            decoration:
                _buildInputDecoration('عنوان التوصيل', Icons.home_rounded),
            validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPrepaidSection() {
    if (_prepaidPercentage <= 0 && !_isLoadingPrepaidPercentage) {
      return const SizedBox.shrink();
    }

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
        border: Border.all(
          color:
              _isPrepaid ? Colors.green.withOpacity(0.4) : Colors.grey.shade200,
          width: _isPrepaid ? 2 : 1,
        ),
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
                      Colors.green.withOpacity(0.15),
                      Colors.teal.withOpacity(0.08)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.savings_rounded,
                    size: 22, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدفع المسبق',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoadingPrepaidPercentage
                          ? 'جاري تحميل نسبة الخصم...'
                          : 'احصل على خصم ${_prepaidPercentage.toStringAsFixed(0)}% عند الدفع المسبق',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isPrepaid,
                onChanged: _isLoadingPrepaidPercentage
                    ? null
                    : (value) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isPrepaid = value;
                          if (value && _selectedPaymentMethod == 'cash') {
                            _selectedPaymentMethod = 'bank_transfer';
                            _showSnackBar(
                              'تم تغيير وسيلة الدفع لأن الدفع المسبق لا يتوافق مع الدفع عند الاستلام',
                              Colors.orange,
                            );
                          }
                        });
                      },
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_isPrepaid && _prepaidPercentage > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الدفع المسبق لا يتوفر مع الدفع عند الاستلام',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.08),
                    Colors.teal.withOpacity(0.04)
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('السعر الأصلي',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: mediumGray)),
                      Text(_fmt(_subtotal),
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('نسبة الخصم',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: mediumGray)),
                      Text('${_prepaidPercentage.toStringAsFixed(2)}%',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('قيمة الخصم',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: mediumGray)),
                      Text('- ${_fmt(_prepaidDiscountAmount)}',
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('السعر بعد الخصم',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkColor)),
                      Text(_fmt(_prepaidAmount),
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        border: Border.all(color: Colors.grey.shade100, width: 1),
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
                child: const Icon(Icons.payment_rounded,
                    size: 22, color: Colors.purple),
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
          ..._paymentMethods.where((method) {
            if (_isPrepaid && method['value'] == 'cash') {
              return false;
            }
            return true;
          }).map((method) {
            final isSelected = _selectedPaymentMethod == method['value'];
            final color = method['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedPaymentMethod = method['value'] as String;
                      if (_selectedPaymentMethod != 'bank_transfer') {
                        _selectedBankTransferCompany = null;
                        _useCustomCompany = false;
                        _customCompanyController.clear();
                      }
                      if (_selectedPaymentMethod != 'wallet') {
                        _selectedWalletCompany = null;
                        _useCustomWallet = false;
                        _customWalletController.clear();
                      }
                    });
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
                        color: isSelected
                            ? color.withOpacity(0.5)
                            : Colors.grey.shade200,
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
                            method['icon'] as IconData,
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
                                method['label'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? darkColor
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                method['desc'] as String,
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
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
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
        border: Border.all(color: Colors.grey.shade100, width: 1),
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
                child: const Icon(Icons.note_add_rounded,
                    size: 22, color: Colors.orange),
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
            decoration: _buildInputDecoration(
                'أضف ملاحظات (اختياري)', Icons.edit_note_rounded),
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
                child: const Icon(Icons.discount_rounded,
                    size: 16, color: primaryBlue),
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
                  color: _isCouponValid
                      ? primaryBlue.withOpacity(0.5)
                      : Colors.grey.shade300,
                  width: _isCouponValid ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
                color: _isCouponValid
                    ? primaryBlue.withOpacity(0.03)
                    : Colors.white,
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                        child: const Icon(Icons.close_rounded,
                            color: Colors.red, size: 18),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('تطبيق',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.w600)),
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
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: primaryBlue),
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
        border: Border.all(color: Colors.grey.shade100, width: 1),
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
                child: const Icon(Icons.receipt_long_rounded,
                    size: 22, color: primaryBlue),
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
            _fmt(_subtotal),
            Icons.calculate_rounded,
          ),
          if (_discountAmount > 0)
            _buildPriceRow(
              'الخصم',
              '- ${_fmt(_discountAmount)}',
              Icons.discount_rounded,
              isDiscount: true,
            ),
          _buildPriceRow(
            'الشحن',
            _shippingAmount > 0
                ? Helpers.formatPrice(_shippingAmount)
                : _cartService.freeShippingItemsCount > 0
                    ? 'مجاني'
                    : 'سيحدد لاحقاً',
            Icons.local_shipping_rounded,
            isShipping: true,
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
            _fmt(_grandTotal),
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
    bool isShipping = false,
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
                  : (isDiscount
                      ? Colors.red.withOpacity(0.1)
                      : (isShipping
                          ? successGreen.withOpacity(0.1)
                          : Colors.grey.shade100)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isTotal
                  ? primaryBlue
                  : (isDiscount
                      ? Colors.red
                      : (isShipping ? successGreen : Colors.grey)),
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
              color:
                  isTotal ? primaryBlue : (isDiscount ? Colors.red : darkColor),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fmt(_grandTotal),
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

  Widget _buildBankTransferCompanies() {
    return _buildPaymentMethodsSection(
      title: 'اختر شركة التحويل',
      subtitle: 'يرجى اختيار شركة التحويل البنكي المناسبة',
      icon: Icons.business_rounded,
      accentColor: Colors.blue,
      isLoading: _isLoadingBankTransfers,
      methods: _bankTransferCompanies,
      selectedMethod: _useCustomCompany ? null : _selectedBankTransferCompany,
      isCustomMode: _useCustomCompany,
      customController: _customCompanyController,
      customHint: 'أدخل اسم شركة التحويل',
      customLabel: 'شركة أخرى',
      customDesc: 'أدخل اسم شركة تحويل غير موجودة في القائمة',
      onCustomToggle: () {
        HapticFeedback.lightImpact();
        setState(() {
          _useCustomCompany = !_useCustomCompany;
          if (_useCustomCompany) {
            _selectedBankTransferCompany = null;
          } else {
            _customCompanyController.clear();
          }
        });
      },
      onSelect: (method) {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedBankTransferCompany = method;
          _useCustomCompany = false;
          _customCompanyController.clear();
        });
      },
      selectedName: _getSelectedBankTransferCompanyName(),
    );
  }

  Widget _buildWalletCompanies() {
    return _buildPaymentMethodsSection(
      title: 'اختر المحفظة الإلكترونية',
      subtitle: 'يرجى اختيار المحفظة الإلكترونية المناسبة',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: Colors.orange,
      isLoading: _isLoadingWallets,
      methods: _walletCompanies,
      selectedMethod: _useCustomWallet ? null : _selectedWalletCompany,
      isCustomMode: _useCustomWallet,
      customController: _customWalletController,
      customHint: 'أدخل اسم المحفظة الإلكترونية',
      customLabel: 'محفظة أخرى',
      customDesc: 'أدخل اسم محفظة إلكترونية غير موجودة في القائمة',
      onCustomToggle: () {
        HapticFeedback.lightImpact();
        setState(() {
          _useCustomWallet = !_useCustomWallet;
          if (_useCustomWallet) {
            _selectedWalletCompany = null;
          } else {
            _customWalletController.clear();
          }
        });
      },
      onSelect: (method) {
        HapticFeedback.mediumImpact();
        setState(() {
          _selectedWalletCompany = method;
          _useCustomWallet = false;
          _customWalletController.clear();
        });
      },
      selectedName: _getSelectedWalletCompanyName(),
    );
  }

  Widget _buildPaymentMethodsSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isLoading,
    required List<PaymentMethodModel> methods,
    required PaymentMethodModel? selectedMethod,
    required bool isCustomMode,
    required TextEditingController customController,
    required String customHint,
    required String customLabel,
    required String customDesc,
    required VoidCallback onCustomToggle,
    required Function(PaymentMethodModel) onSelect,
    required String selectedName,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
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
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1.5,
          ),
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
                        accentColor.withOpacity(0.15),
                        accentColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(color: primaryBlue),
                ),
              )
            else if (methods.isEmpty && !isCustomMode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لا توجد طرق متاحة حاليًا من هذا النوع',
                        style:
                            GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                      ),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final company = methods[index];
                  final isSelected =
                      !isCustomMode && selectedMethod?.id == company.id;
                  return _buildPaymentMethodCard(
                    method: company,
                    isSelected: isSelected,
                    accentColor: accentColor,
                    onTap: () => onSelect(company),
                    onDetails: () => _showPaymentMethodDetails(company),
                  );
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Divider(color: Colors.grey, thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'أو',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: mediumGray,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(color: Colors.grey, thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCustomToggle,
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isCustomMode
                        ? LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.1),
                              accentColor.withOpacity(0.05),
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
                      color: isCustomMode
                          ? accentColor.withOpacity(0.5)
                          : Colors.grey.shade200,
                      width: isCustomMode ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCustomMode
                              ? accentColor.withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 24,
                          color:
                              isCustomMode ? accentColor : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customLabel,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isCustomMode
                                    ? darkColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customDesc,
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
                            color: isCustomMode
                                ? accentColor
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          color:
                              isCustomMode ? accentColor : Colors.transparent,
                        ),
                        child: isCustomMode
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isCustomMode) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: customController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(color: darkColor),
                decoration: InputDecoration(
                  hintText: customHint,
                  hintStyle: GoogleFonts.cairo(color: Colors.grey),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  filled: true,
                  fillColor: lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (selectedName.isNotEmpty &&
                (selectedMethod != null || isCustomMode))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.08),
                        accentColor.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 20, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تم اختيار: $selectedName',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                          ),
                        ),
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

  Widget _buildPaymentMethodCard({
    required PaymentMethodModel method,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
    required VoidCallback onDetails,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.1),
                      accentColor.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.shade50,
                      Colors.grey.shade100,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor.withOpacity(0.6)
                  : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: method.paymentCompanyImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: method.paymentCompanyImageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            color: lightGray,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => _companyPlaceholder(),
                        )
                      : _companyPlaceholder(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                method.paymentCompanyName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? darkColor : Colors.grey.shade700,
                ),
              ),
              if (method.hasDetails)
                GestureDetector(
                  onTap: onDetails,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded,
                            size: 11, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'التفاصيل',
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isSelected ? accentColor : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
