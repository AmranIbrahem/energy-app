// lib/screens/system_builder/order_history_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/system_builder/edit_system_order_screen.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/system_builder_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class OrderHistoryScreen extends StatefulWidget {
  final AuthService authService;

  const OrderHistoryScreen({
    super.key,
    required this.authService,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late SystemBuilderService _service;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _selectedTab = 'all';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);

  late TabController _tabController;
  late AnimationController _pulseAnimationController;

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

  @override
  void initState() {
    super.initState();
    _service = SystemBuilderService(authService: widget.authService);
    _tabController = TabController(length: 4, vsync: this);
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  double getPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  double getTotal(dynamic item) {
    if (item == null) return 0.0;
    final price = getPrice(item['price']);
    final quantity = item['quantity'] ?? 1;
    final total = getPrice(item['total']);
    return total > 0 ? total : (price * quantity);
  }

  String _fmtOrder(double amount, Map<String, dynamic> order) {
    final num = amount.toStringAsFixed(2);
    final isSyp = order['is_syp'] == true || order['is_syp'] == 1;
    return isSyp ? '$num SYP' : '\$$num';
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.getMyOrders();

    if (mounted) {
      setState(() {
        if (result['success']) {
          _orders = result['data'] ?? [];
        } else {
          _errorMessage = result['message'] ?? 'حدث خطأ في جلب الطلبات';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    setState(() => _isRefreshing = true);
    await _loadOrders();
  }

  List<dynamic> get _filteredOrders {
    if (_selectedTab == 'all') return _orders;
    return _orders.where((order) => order['status'] == _selectedTab).toList();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'جاري المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status ?? 'غير معروف';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'processing':
        return Icons.engineering_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.design_services_rounded;
    }
  }

  void _editOrder(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSystemOrderScreen(
          authService: widget.authService,
          order: order,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadOrders();
      }
    });
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تأكيد الإلغاء',
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: darkColor)),
          content: Text(
            'هل أنت متأكد من إلغاء هذا الطلب؟\n\n${order['order_number'] ?? ''}',
            style: GoogleFonts.cairo(color: mediumGray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('تراجع', style: GoogleFonts.cairo(color: mediumGray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('إلغاء الطلب',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final result = await _service.cancelOrder(order['id']);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          _showSnackBar('تم إلغاء الطلب بنجاح', Colors.green);
          _loadOrders();
        } else {
          _showSnackBar(result['message'] ?? 'فشل إلغاء الطلب', Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final panels = order['panels'] ?? [];
    final inverters = order['inverters'] ?? [];
    final batteries = order['batteries'] ?? [];
    final cables = order['cables'] ?? [];
    final panelBoards = order['panel_boards'] ?? [];

    final subtotal = getPrice(order['subtotal']);
    final discount = getPrice(order['discount']);
    final total = getPrice(order['total']);
    final installationPrice = getPrice(order['installation_price']);

    final isPrepaid = order['is_prepaid'] == true || order['is_prepaid'] == 1;
    final prepaidDiscountPercentage =
        getPrice(order['prepaid_discount_percentage']);
    final prepaidAmount = getPrice(order['prepaid_amount']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
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
                    color: Colors.grey.shade300,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getStatusColor(order['status'])
                                    .withOpacity(0.15),
                                _getStatusColor(order['status'])
                                    .withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(order['status'])
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status'])
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  _getStatusIcon(order['status']),
                                  size: 28,
                                  color: _getStatusColor(order['status']),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['order_number'] ??
                                          'طلب #${order['id']}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: darkColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getStatusText(order['status']),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(order['status']),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _fmtOrder(total, order),
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (order['full_name'] != null ||
                            order['phone'] != null ||
                            order['shipping_address'] != null ||
                            order['payment_method'] != null)
                          _buildDetailCard(
                            title: 'معلومات التوصيل والدفع',
                            icon: Icons.local_shipping_rounded,
                            color: Colors.blue,
                            children: [
                              if (order['full_name'] != null &&
                                  order['full_name'].isNotEmpty)
                                _buildDetailRow('الاسم الكامل',
                                    order['full_name'], Icons.person_rounded),
                              if (order['phone'] != null &&
                                  order['phone'].isNotEmpty)
                                _buildDetailRow('رقم الهاتف', order['phone'],
                                    Icons.phone_rounded),
                              if (order['shipping_address'] != null &&
                                  order['shipping_address'].isNotEmpty)
                                _buildDetailRow(
                                    'عنوان التوصيل',
                                    order['shipping_address'],
                                    Icons.home_rounded),
                              if (order['payment_method'] != null &&
                                  order['payment_method'].isNotEmpty)
                                _buildDetailRow(
                                  'وسيلة الدفع',
                                  _paymentMethodLabels[
                                          order['payment_method']] ??
                                      order['payment_method'],
                                  _paymentMethodIcons[
                                          order['payment_method']] ??
                                      Icons.payment_rounded,
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (isPrepaid)
                          _buildDetailCard(
                            title: 'الدفع المسبق',
                            icon: Icons.savings_rounded,
                            color: Colors.green,
                            children: [
                              if (prepaidDiscountPercentage > 0)
                                _buildDetailRow(
                                  'نسبة الخصم',
                                  '% ${prepaidDiscountPercentage.toStringAsFixed(2)}',
                                  Icons.percent_rounded,
                                  color: Colors.green,
                                ),
                              if (prepaidAmount > 0)
                                _buildDetailRow(
                                  'المبلغ بعد الخصم',
                                  _fmtOrder(prepaidAmount, order),
                                  Icons.monetization_on_rounded,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (panels.isNotEmpty)
                          _buildItemSection(
                              title: 'الألواح الشمسية',
                              icon: Icons.solar_power_rounded,
                              color: Colors.orange,
                              items: panels,
                              order: order),
                        if (inverters.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildItemSection(
                              title: 'الانفرتر',
                              icon: Icons.memory_rounded,
                              color: Colors.blue,
                              items: inverters,
                              order: order),
                        ],
                        if (batteries.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildItemSection(
                              title: 'البطاريات',
                              icon: Icons.battery_charging_full_rounded,
                              color: Colors.green,
                              items: batteries,
                              order: order),
                        ],
                        if (cables.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildItemSection(
                              title: 'الكابلات',
                              icon: Icons.cable_rounded,
                              color: Colors.purple,
                              items: cables,
                              order: order),
                        ],
                        if (panelBoards.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildItemSection(
                              title: 'تابلو الحماية',
                              icon: Icons.electrical_services_rounded,
                              color: Colors.teal,
                              items: panelBoards,
                              order: order),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'ملخص التكلفة',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.purple,
                          children: [
                            _buildDetailRow(
                                'المجموع الفرعي',
                                _fmtOrder(subtotal, order),
                                Icons.calculate_rounded),
                            if (discount > 0)
                              _buildDetailRow(
                                  'الخصم',
                                  '- ${_fmtOrder(discount, order)}',
                                  Icons.discount_rounded,
                                  color: Colors.red),
                            if (installationPrice > 0)
                              _buildDetailRow(
                                  'سعر التركيب',
                                  _fmtOrder(installationPrice, order),
                                  Icons.build_rounded,
                                  color: Colors.orange),
                            if (isPrepaid && prepaidAmount > 0)
                              _buildDetailRow(
                                  'المبلغ بعد الدفع المسبق',
                                  _fmtOrder(prepaidAmount, order),
                                  Icons.savings_rounded,
                                  color: Colors.green),
                            _buildDetailRow(
                                'الإجمالي النهائي',
                                _fmtOrder(total, order),
                                Icons.monetization_on_rounded,
                                isBold: true),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (order['user_notes'] != null &&
                            order['user_notes'].isNotEmpty)
                          _buildDetailCard(
                            title: 'ملاحظات المستخدم',
                            icon: Icons.comment_rounded,
                            color: Colors.teal,
                            children: [
                              Text(
                                order['user_notes'],
                                style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: darkColor,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (order['notes'] != null && order['notes'].isNotEmpty)
                          _buildDetailCard(
                            title: 'ملاحظات إضافية',
                            icon: Icons.note_rounded,
                            color: Colors.orange,
                            children: [
                              Text(
                                order['notes'],
                                style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: darkColor,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'التواريخ',
                          icon: Icons.calendar_today_rounded,
                          color: Colors.indigo,
                          children: [
                            if (order['created_at'] != null)
                              _buildDetailRow(
                                  'تاريخ الإنشاء',
                                  order['created_at'].toString().split('T')[0],
                                  Icons.event_rounded),
                            if (order['updated_at'] != null)
                              _buildDetailRow(
                                  'آخر تحديث',
                                  order['updated_at'].toString().split('T')[0],
                                  Icons.update_rounded),
                          ],
                        ),
                        const SizedBox(height: 30),
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

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? color, bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isBold ? primaryBlue.withOpacity(0.04) : lightGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isBold ? primaryBlue : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isBold ? 15 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? (isBold ? primaryBlue : darkColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> items,
    required Map<String, dynamic> order,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkColor)),
                const Spacer(),
                Text('${items.length} عنصر',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          ...items
              .map((item) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? 'غير معروف',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: darkColor),
                          ),
                        ),
                        Text(
                          '${item['quantity'] ?? 1} × ${_fmtOrder(getPrice(item['price']), order)}',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: mediumGray),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _fmtOrder(getTotal(item), order),
                            style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final panels = order['panels'] ?? [];
    final inverters = order['inverters'] ?? [];
    final batteries = order['batteries'] ?? [];
    final cables = order['cables'] ?? [];
    final panelBoards = order['panel_boards'] ?? [];

    final total = getPrice(order['total']);
    final installationPrice = getPrice(order['installation_price']);
    final discount = getPrice(order['discount']);
    final isPrepaid = order['is_prepaid'] == true || order['is_prepaid'] == 1;
    final prepaidPercentage = getPrice(order['prepaid_discount_percentage']);
    final status = order['status'] ?? 'pending';

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showOrderDetails(order),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(status).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(status).withOpacity(0.08),
                      _getStatusColor(status).withOpacity(0.03),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'solar_order_status_${order['id']}',
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getStatusIcon(status),
                            size: 22, color: _getStatusColor(status)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['order_number'] ?? 'طلب #${order['id']}',
                            style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: darkColor),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order['created_at'] != null
                                ? DateTime.parse(order['created_at'].toString())
                                    .toString()
                                    .split(' ')[0]
                                : '',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: mediumGray),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatItem(
                              icon: Icons.solar_power_rounded,
                              label: 'الألواح',
                              value: '${panels.length}',
                              color: Colors.orange),
                          _buildStatItem(
                              icon: Icons.memory_rounded,
                              label: 'الانفرتر',
                              value: '${inverters.length}',
                              color: Colors.blue),
                          _buildStatItem(
                              icon: Icons.battery_charging_full_rounded,
                              label: 'البطاريات',
                              value: '${batteries.length}',
                              color: Colors.green),
                          _buildStatItem(
                              icon: Icons.cable_rounded,
                              label: 'الكابلات',
                              value: '${cables.length}',
                              color: Colors.purple),
                          _buildStatItem(
                              icon: Icons.electrical_services_rounded,
                              label: 'التابلو',
                              value: '${panelBoards.length}',
                              color: Colors.teal),
                          _buildStatItem(
                              icon: Icons.attach_money_rounded,
                              label: 'الإجمالي',
                              value: _fmtOrder(total, order),
                              color: primaryBlue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.build_rounded,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'سعر التركيب: ${_fmtOrder(installationPrice, order)}',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.orange.shade700),
                        ),
                        const Spacer(),
                        Text(
                          'اضغط للتفاصيل',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: primaryBlue),
                        ),
                        const Icon(Icons.arrow_back_ios_rounded,
                            size: 12, color: primaryBlue),
                      ],
                    ),
                    if (isPrepaid || discount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isPrepaid && prepaidPercentage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.savings_rounded,
                                      size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'دفع مسبق - خصم ${prepaidPercentage.toStringAsFixed(0)}%',
                                    style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.discount_rounded,
                                      size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'خصم ${_fmtOrder(discount, order)}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (status == 'pending') ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editOrder(order),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: Text('تعديل الطلب',
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryBlue,
                                side: BorderSide(
                                    color: primaryBlue.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _cancelOrder(order),
                              icon: const Icon(Icons.cancel_rounded, size: 18),
                              label: Text('إلغاء الطلب',
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                    color: Colors.red.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
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
      ),
    );
  }

  Widget _buildStatItem(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label,
              style:
                  GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
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
                                                  (_pulseAnimationController
                                                          .value *
                                                      0.1),
                                              child: child);
                                        },
                                        child: const Icon(
                                            Icons.design_services_rounded,
                                            color: Colors.yellow,
                                            size: 24),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('سجل طلبات التصميم',
                                          style: GoogleFonts.cairo(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: TabBar(
                            controller: _tabController,
                            dividerColor: Colors.transparent,
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
                            labelStyle: GoogleFonts.cairo(
                                fontSize: 12, fontWeight: FontWeight.w700),
                            unselectedLabelStyle: GoogleFonts.cairo(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            tabs: [
                              _buildTab('الكل', 0),
                              _buildTab('قيد الانتظار', 1),
                              _buildTab('جاري المعالجة', 2),
                              _buildTab('مكتمل', 3),
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
                                    _selectedTab = 'processing';
                                    break;
                                  case 3:
                                    _selectedTab = 'completed';
                                    break;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildShimmerLoading()
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _filteredOrders.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshOrders,
                                color: primaryBlue,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredOrders.length,
                                  itemBuilder: (context, index) =>
                                      _buildOrderCard(
                                          _filteredOrders[index], index),
                                ),
                              ),
              ),
            ],
          ),
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
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style:
                  GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
          Icon(Icons.design_services_rounded,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('لا توجد طلبات',
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('لم تقم بإرسال أي طلب تصميم بعد',
              style:
                  GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text('العودة للتصميم', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
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
