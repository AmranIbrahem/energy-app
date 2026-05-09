// lib/screens/profile/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/products/product_details_screen.dart';
import 'package:energy_store_app/screens/offers/offer_details_screen.dart';

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

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _selectedTab = 'all';

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ بيانات تجريبية (Mock Data) - يمكن استبدالها لاحقاً عند ربط API
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 1,
      'order_number': 'ORD000001',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'total_price': '1250.00',
      'status': 'pending',
      'payment_method': 'cash',
      'shipping_address': 'دمشق، المزة، شارع الرئيسي، بناء 10',
      'items': [
        {
          'product_name': 'لوح شمسي 450 واط',
          'main_image': 'https://example.com/solar1.jpg',
          'quantity': 2,
          'price': '450.00',
          'slug': 'solar-panel-450w'
        },
        {
          'product_name': 'انفرتر 5 كيلو واط',
          'main_image': 'https://example.com/inverter.jpg',
          'quantity': 1,
          'price': '350.00',
          'slug': 'inverter-5kw'
        }
      ]
    },
    {
      'id': 2,
      'order_number': 'ORD000002',
      'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'total_price': '3200.00',
      'status': 'completed',
      'payment_method': 'bank',
      'shipping_address': 'حلب، شارع النيل، بناء 5',
      'items': [
        {
          'product_name': 'بطارية ليثيوم 5 كيلو واط',
          'main_image': 'https://example.com/battery.jpg',
          'quantity': 2,
          'price': '1600.00',
          'slug': 'lithium-battery-5kw'
        }
      ]
    },
    {
      'id': 3,
      'order_number': 'ORD000003',
      'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'total_price': '850.00',
      'status': 'cancelled',
      'payment_method': 'cash',
      'shipping_address': 'حمص، شارع الحضارة، بناء 3',
      'items': [
        {
          'product_name': 'منظم شحن 40 أمبير',
          'main_image': 'https://example.com/charge-controller.jpg',
          'quantity': 1,
          'price': '850.00',
          'slug': 'charge-controller-40a'
        }
      ]
    },
    {
      'id': 4,
      'order_number': 'ORD000004',
      'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      'total_price': '2100.00',
      'status': 'shipped',
      'payment_method': 'cash',
      'shipping_address': 'اللاذقية، كورنيش البحر، بناء 20',
      'items': [
        {
          'product_name': 'نظام طاقة شمسية كامل 3 كيلو',
          'main_image': 'https://example.com/complete-system.jpg',
          'quantity': 1,
          'price': '2100.00',
          'slug': 'complete-solar-system-3kw'
        }
      ]
    },
    {
      'id': 5,
      'order_number': 'ORD000005',
      'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'total_price': '950.00',
      'status': 'processing',
      'payment_method': 'bank',
      'shipping_address': 'طرطوس، شارع الثورة، بناء 8',
      'items': [
        {
          'product_name': 'مروحة تبريد للألواح الشمسية',
          'main_image': 'https://example.com/fan.jpg',
          'quantity': 3,
          'price': '105.00',
          'slug': 'solar-fan'
        },
        {
          'product_name': 'أسلاك توصيل شمسية 10م',
          'main_image': 'https://example.com/wires.jpg',
          'quantity': 5,
          'price': '25.00',
          'slug': 'solar-wires'
        }
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();

    // ✅ عرض البيانات التجريبية (محاكاة تحميل)
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ دالة تحميل البيانات التجريبية (محاكاة API)
  Future<void> _loadMockData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _orders = List<Map<String, dynamic>>.from(_mockOrders);
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadMockData();
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
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
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
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'processing':
        return Icons.engineering;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.verified;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إلغاء الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من إلغاء هذا الطلب؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تأكيد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // محاكاة إلغاء الطلب
      setState(() {
        final index = _orders.indexWhere((order) => order['id'] == orderId);
        if (index != -1) {
          _orders[index]['status'] = 'cancelled';
        }
      });
      _showSnackBar('تم إلغاء الطلب بنجاح', Colors.green);
    }
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

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('تفاصيل الطلب', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('رقم الطلب', order['order_number'] ?? '#${order['id']}'),
                    _buildDetailRow('تاريخ الطلب', order['created_at'] != null
                        ? DateTime.parse(order['created_at']).toString().split(' ')[0]
                        : 'غير محدد'),
                    _buildDetailRow('حالة الطلب', _getStatusText(order['status'] ?? 'pending'),
                        color: _getStatusColor(order['status'] ?? 'pending')),
                    _buildDetailRow('طريقة الدفع', order['payment_method'] == 'cash' ? 'الدفع عند الاستلام' : 'تحويل بنكي'),
                    if (order['shipping_address'] != null && order['shipping_address'].isNotEmpty)
                      _buildDetailRow('عنوان التوصيل', order['shipping_address'], isMultiline: true),
                    const Divider(height: 24),
                    Text('المنتجات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    ...(order['items'] as List? ?? []).map((item) => _buildOrderItem(item)),
                    const Divider(height: 24),
                    _buildDetailRow('المجموع', Helpers.formatPrice(
                        double.tryParse(order['total_price']?.toString() ?? '0') ?? 0),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: isBold ? 16 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final productName = item['product_name'] ?? item['name_ar'] ?? 'منتج';
    final productImage = item['main_image'] ?? item['product_image'] ?? '';
    final quantity = item['quantity'] ?? 1;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final productSlug = item['slug'] ?? item['product_slug'] ?? '';

    return GestureDetector(
      onTap: () {
        if (productSlug.isNotEmpty && widget.apiService != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(
                productSlug: productSlug,
                apiService: widget.apiService!,
                authService: widget.authService,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: productImage.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: productImage,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 50, height: 50, color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 24),
                ),
              )
                  : Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade200,
                child: const Icon(Icons.shopping_bag, size: 24, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('الكمية: $quantity × ${Helpers.formatPrice(price)}',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text(Helpers.formatPrice(price * quantity),
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'];
    final orderNumber = order['order_number'] ?? '#ORD${orderId.toString().padLeft(6, '0')}';
    final orderDate = order['created_at'] != null ? DateTime.parse(order['created_at']) : DateTime.now();
    final totalPrice = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0;
    final status = order['status'] ?? 'pending';
    final items = order['items'] as List? ?? [];
    final paymentMethod = order['payment_method'] ?? 'cash';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getStatusIcon(status), size: 20, color: _getStatusColor(status)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderNumber, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text('${orderDate.day}/${orderDate.month}/${orderDate.year}',
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_getStatusText(status),
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500, color: _getStatusColor(status))),
                  ),
                ],
              ),
            ),
            // Order Items
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...items.take(2).map((item) => _buildOrderItem(item)),
                    if (items.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('و ${items.length - 2} منتجات أخرى',
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              ),
            // Order Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(paymentMethod == 'cash' ? 'الدفع عند الاستلام' : 'تحويل بنكي',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text('الإجمالي:', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 6),
                      Text(Helpers.formatPrice(totalPrice),
                          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4CAF50))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showOrderDetails(order),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF4CAF50)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('تفاصيل الطلب',
                              style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF4CAF50))),
                        ),
                      ),
                      if (status == 'pending') const SizedBox(width: 12),
                      if (status == 'pending')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _cancelOrder(orderId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('إلغاء الطلب', style: GoogleFonts.cairo(fontSize: 13, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('طلباتي', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'قيد المعالجة'),
            Tab(text: 'مكتمل'),
            Tab(text: 'ملغي'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0: _selectedTab = 'all'; break;
                case 1: _selectedTab = 'pending'; break;
                case 2: _selectedTab = 'completed'; break;
                case 3: _selectedTab = 'cancelled'; break;
              }
            });
          },
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
        color: const Color(0xFF4CAF50),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredOrders.length,
          itemBuilder: (context, index) => _buildOrderCard(_filteredOrders[index]),
        ),
      ),
    );
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
          height: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/error_animation.json',
            width: 200,
            height: 200,
            repeat: true,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMockData,
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_orders.json',
            width: 200,
            height: 200,
            repeat: true,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'لم تقم بطلب أي منتج حتى الآن',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text('مواصلة التسوق', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}