// lib/screens/profile/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/order_api_service.dart';
import 'rate_items_screen.dart';
import '../../services/storage_service.dart';

class OrdersScreen extends StatefulWidget {
  final ApiService? apiService;
  final AuthService? authService;

  const OrdersScreen({
    super.key,
    this.apiService,
    this.authService,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _selectedTab = 'all';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  final Map<String, String> _paymentMethodLabels = {
    'cash': 'الدفع عند الاستلام',
    'card': 'بطاقة ائتمان',
    'bank_transfer': 'تحويل بنكي',
    'wallet': 'المحفظة الإلكترونية',
  };

  final Map<String, IconData> _paymentMethodIcons = {
    'cash': Icons.money_rounded,
    'card': Icons.credit_card_rounded,
    'bank_transfer': Icons.account_balance_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;

  late OrderApiService _orderApiService;

  final String _baseUrl = 'https://nexsy.shop';

  @override
  void initState() {
    super.initState();
    _initApiService();
    _tabController = TabController(length: 4, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
    _slideAnimationController.forward();

    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  IconData _getPaymentMethodIcon(String method) {
    return _paymentMethodIcons[method] ?? Icons.payment_rounded;
  }

  void _navigateToRateItems(int invoiceId, String invoiceNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateItemsScreen(
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          apiService: widget.apiService,
          authService: widget.authService,
        ),
      ),
    ).then((_) {
      _refreshOrders();
    });
  }

  void _initApiService() {
    final authService = widget.authService ??
        AuthService(storageService: StorageService()..init());
    _orderApiService = OrderApiService(
      baseUrl: _baseUrl,
      authService: authService,
    );
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _orderApiService.getUserOrders(
        status: _selectedTab == 'all' ? null : _selectedTab,
      );

      if (result['success']) {
        final ordersData = result['data'];
        final ordersList = ordersData['orders'] as List? ?? [];

        setState(() {
          _orders =
              ordersList.map((order) => _convertApiOrderToMap(order)).toList();
          _isLoading = false;
          _isRefreshing = false;
        });

        _animationController.forward(from: 0.0);
        _slideAnimationController.forward(from: 0.0);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'حدث خطأ في تحميل الطلبات';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال بالخادم';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Map<String, dynamic> _convertApiOrderToMap(Map<String, dynamic> apiOrder) {
    return {
      'id': apiOrder['id'],
      'order_number': apiOrder['number'],
      'created_at': apiOrder['created_at'],
      'total_price': apiOrder['total'],
      'subtotal': apiOrder['subtotal'] ?? apiOrder['total'],
      'discount': apiOrder['discount'] ?? '0',
      'shipping_fee': apiOrder['shipping_fee'] ?? '0',
      'tax': apiOrder['tax'] ?? '0',
      'status': apiOrder['status'],
      'payment_method': apiOrder['payment_method'] ?? 'cash',
      'shipping_address': apiOrder['shipping_address'] ?? '',
      'user_notes': apiOrder['user_notes'],
      'admin_notes': apiOrder['admin_notes'],
      'items': apiOrder['items'] ?? [],
    };
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadOrders();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedTab == 'all') return _orders;
    return _orders.where((order) => order['status'] == _selectedTab).toList();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المعالجة';
      case 'processing':
        return 'جاري التجهيز';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'refunded':
        return 'مسترد';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'processing':
        return Icons.engineering_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'refunded':
        return Icons.currency_exchange_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_rounded,
                    color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text('إلغاء الطلب',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: darkColor)),
            ],
          ),
          content: Text('هل أنت متأكد من إلغاء هذا الطلب؟',
              style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('تراجع',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, color: mediumGray)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تأكيد الإلغاء',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _orderApiService.cancelOrder(orderId);
      if (result['success']) {
        await _loadOrders();
        _showSnackBar('تم إلغاء الطلب بنجاح', primaryBlue);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
            result['message'] ?? 'حدث خطأ في إلغاء الطلب', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
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
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
        elevation: 5,
      ));
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final paymentMethod = order['payment_method'] ?? 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade300]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child),
                          );
                        },
                        child: _buildOrderDetailHeader(order),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailCard('معلومات الطلب',
                          Icons.info_outline_rounded, Colors.blue, [
                        _buildDetailRow(
                            'رقم الطلب',
                            order['order_number'] ?? '#${order['id']}',
                            Icons.receipt_rounded),
                        _buildDetailRow(
                          'تاريخ الطلب',
                          order['created_at'] != null
                              ? DateTime.parse(order['created_at'])
                                  .toString()
                                  .split(' ')[0]
                              : 'غير محدد',
                          Icons.calendar_today_rounded,
                        ),
                        _buildDetailRow(
                          'حالة الطلب',
                          _getStatusText(order['status'] ?? 'pending'),
                          Icons.flag_rounded,
                          color: _getStatusColor(order['status'] ?? 'pending'),
                        ),
                        _buildDetailRow(
                          'طريقة الدفع',
                          _paymentMethodLabels[paymentMethod] ?? paymentMethod,
                          _getPaymentMethodIcon(paymentMethod),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      if (order['shipping_address'] != null &&
                          order['shipping_address'].isNotEmpty)
                        _buildDetailCard('عنوان التوصيل',
                            Icons.location_on_rounded, Colors.orange, [
                          Text(order['shipping_address'],
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: darkColor, height: 1.5)),
                        ]),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'المنتجات',
                        Icons.shopping_basket_rounded,
                        primaryBlue,
                        (order['items'] as List? ?? [])
                            .map((item) => _buildOrderItem(item))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard('ملخص الفاتورة',
                          Icons.receipt_long_rounded, Colors.purple, [
                        _buildDetailRow(
                            'المجموع الفرعي',
                            Helpers.formatPrice(
                                Helpers.parsePrice(order['subtotal'] ?? '0')),
                            Icons.calculate_rounded),
                        if (Helpers.parsePrice(order['discount'] ?? '0') > 0)
                          _buildDetailRow(
                              'الخصم',
                              '- ${Helpers.formatPrice(Helpers.parsePrice(order['discount'] ?? '0'))}',
                              Icons.discount_rounded,
                              color: Colors.red),
                        _buildDetailRow(
                            'الشحن',
                            Helpers.formatPrice(Helpers.parsePrice(
                                order['shipping_fee'] ?? '0')),
                            Icons.local_shipping_rounded),
                        _buildDetailRow(
                            'الضريبة',
                            Helpers.formatPrice(
                                Helpers.parsePrice(order['tax'] ?? '0')),
                            Icons.receipt_rounded),
                        const Divider(height: 16),
                        _buildDetailRow(
                            'الإجمالي',
                            Helpers.formatPrice(Helpers.parsePrice(
                                order['total_price'] ?? '0')),
                            Icons.monetization_on_rounded,
                            isBold: true,
                            color: primaryBlue),
                      ]),
                      if (order['user_notes'] != null &&
                          order['user_notes'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(
                            'ملاحظاتك', Icons.note_rounded, Colors.teal, [
                          Text(order['user_notes'],
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: darkColor, height: 1.5)),
                        ]),
                      ],
                      if (order['admin_notes'] != null &&
                          order['admin_notes'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard('ملاحظات الإدارة',
                            Icons.admin_panel_settings_rounded, Colors.indigo, [
                          Text(order['admin_notes'],
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: darkColor, height: 1.5)),
                        ]),
                      ],
                      const SizedBox(height: 30),
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

  Widget _buildOrderDetailHeader(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status).withOpacity(0.15),
            _getStatusColor(status).withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.1),
                  child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(status).withOpacity(0.2),
                    _getStatusColor(status).withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_getStatusIcon(status),
                  size: 30, color: _getStatusColor(status)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['order_number'] ?? '#${order['id']}',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
                const SizedBox(height: 4),
                Text(_getStatusText(status),
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Text(
              Helpers.formatPrice(
                  Helpers.parsePrice(order['total_price'] ?? '0')),
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(15),
              child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? color, bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBold ? primaryBlue.withOpacity(0.04) : lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isBold ? primaryBlue.withOpacity(0.15) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  isBold ? primaryBlue.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(icon, size: 16, color: isBold ? primaryBlue : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(fontSize: 13, color: mediumGray))),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isBold ? primaryBlue : darkColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final productName = item['name'] ?? item['product_name'] ?? 'منتج';
    final productImage = item['image'] ?? '';
    final quantity = item['quantity'] ?? 1;
    final price = Helpers.parsePrice(item['unit_price'] ?? '0');
    final totalPrice = Helpers.parsePrice(item['total_price'] ?? '0');
    final itemType = item['type'] ?? 'product';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'order_item_${item['id']}',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: productImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: productImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: primaryBlue, strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            itemType == 'offer'
                                ? Icons.local_offer_rounded
                                : Icons.image_not_supported_rounded,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          itemType == 'offer'
                              ? Icons.local_offer_rounded
                              : Icons.shopping_bag_rounded,
                          size: 28,
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
                      child: Text(productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkColor)),
                    ),
                    if (itemType == 'offer')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('عرض',
                            style: GoogleFonts.cairo(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('الكمية: $quantity × ${Helpers.formatPrice(price)}',
                    style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Helpers.formatPrice(totalPrice),
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final orderId = order['id'];
    final orderNumber =
        order['order_number'] ?? '#ORD${orderId.toString().padLeft(6, '0')}';
    final orderDate = order['created_at'] != null
        ? DateTime.parse(order['created_at'])
        : DateTime.now();
    final totalPrice = Helpers.parsePrice(order['total_price'] ?? '0');
    final status = order['status'] ?? 'pending';
    final items = order['items'] as List? ?? [];
    final paymentMethod = order['payment_method'] ?? 'cash';

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: _getStatusColor(status).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 5))
          ],
          border: Border.all(
              color: _getStatusColor(status).withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(status).withOpacity(0.08),
                      _getStatusColor(status).withOpacity(0.03)
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(status).withOpacity(0.2),
                            _getStatusColor(status).withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_getStatusIcon(status),
                          size: 22, color: _getStatusColor(status)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orderNumber,
                              style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor)),
                          const SizedBox(height: 3),
                          Text(
                              '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: mediumGray)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(status).withOpacity(0.15),
                            _getStatusColor(status).withOpacity(0.08)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.3)),
                      ),
                      child: Text(_getStatusText(status),
                          style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(status))),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ...items.take(2).map((item) => _buildOrderItem(item)),
                      if (items.length > 2)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                              color: lightGray,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('+ ${items.length - 2} منتجات أخرى',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: mediumGray,
                                  fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.grey.shade50, Colors.grey.shade100]),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(_getPaymentMethodIcon(paymentMethod),
                              size: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            _paymentMethodLabels[paymentMethod] ??
                                paymentMethod,
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: mediumGray)),
                        const Spacer(),
                        Text('الإجمالي:',
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: mediumGray)),
                        const SizedBox(width: 8),
                        Text(Helpers.formatPrice(totalPrice),
                            style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (status == 'pending') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showOrderDetails(order),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: primaryBlue, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('تفاصيل الطلب',
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _cancelOrder(orderId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('إلغاء الطلب',
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (status == 'completed') ...[
                      OutlinedButton(
                        onPressed: () => _showOrderDetails(order),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: Text('تفاصيل الطلب',
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue)),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToRateItems(orderId, orderNumber),
                          icon: const Icon(Icons.star_rate_rounded, size: 20),
                          label: Text('تقييم الطلب',
                              style: GoogleFonts.cairo(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.amber.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                    if (status != 'pending' && status != 'completed') ...[
                      OutlinedButton(
                        onPressed: () => _showOrderDetails(order),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: Text('تفاصيل الطلب',
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    scale: 1.0 + (_pulseAnimationController.value * 0.1),
                    child: child);
              },
              child: const Icon(Icons.shopping_bag_rounded,
                  color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 10),
            Text('طلباتي',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF0F0F0)]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: primaryBlue,
              unselectedLabelColor: Colors.white70,
              labelStyle:
                  GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: [
                _buildTab('الكل', 0),
                _buildTab('قيد المعالجة', 1),
                _buildTab('مكتمل', 2),
                _buildTab('ملغي', 3),
              ],
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      _selectedTab = 'all';
                      break;
                    case 1:
                      _selectedTab = 'pending';
                      break;
                    case 2:
                      _selectedTab = 'completed';
                      break;
                    case 3:
                      _selectedTab = 'cancelled';
                      break;
                  }
                  _loadOrders();
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshOrders,
                      color: primaryBlue,
                      backgroundColor: cardWhite,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(_filteredOrders[index], index),
                      ),
                    ),
    );
  }

  Widget _buildTab(String text, int index) {
    return Tab(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(text)));
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 220,
          decoration: BoxDecoration(
              color: cardWhite, borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardWhite,
                boxShadow: [
                  BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 60, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, double value, child) {
          return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) {
                return Transform.scale(
                    scale: 1.0 + (_pulseAnimationController.value * 0.1),
                    child: child);
              },
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cardWhite,
                  boxShadow: [
                    BoxShadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Icon(Icons.receipt_long_rounded,
                    size: 70, color: primaryBlue.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 20),
            Text('لا توجد طلبات',
                style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkColor)),
            const SizedBox(height: 10),
            Text('لم تقم بطلب أي منتج حتى الآن',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, color: mediumGray)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text('مواصلة التسوق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
