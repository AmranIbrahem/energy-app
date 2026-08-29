// lib/screens/company/supplier_orders/supplier_order_detail_screen.dart

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierOrderDetailScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int orderId;

  const SupplierOrderDetailScreen(
      {super.key,
      required this.authService,
      required this.storageService,
      required this.orderId});

  @override
  State<SupplierOrderDetailScreen> createState() =>
      _SupplierOrderDetailScreenState();
}

class _SupplierOrderDetailScreenState extends State<SupplierOrderDetailScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color goldColor = Color(0xFFB45309);

  late ApiService _apiService;
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String _selectedStatus = '';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null)
      _apiService.setToken(widget.authService.token!);
    _fetchOrder();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrder() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
          '/v1/company/supplier-orders/${widget.orderId}',
          requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() {
          _order = response['data']['order'];
          _selectedStatus = _order!['status'] ?? '';
          _notesController.text = _order!['notes'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus() async {
    try {
      final response = await _apiService.post(
        '/v1/company/supplier-orders/${widget.orderId}/update-status',
        requiresAuth: true,
        data: {'status': _selectedStatus, 'notes': _notesController.text},
      );
      if (response['data'] != null && mounted) {
        _showSnackBar('تم تحديث الحالة بنجاح', successGreen);
        _fetchOrder();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ', dangerRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return warningOrange;
      case 'confirmed':
        return primaryBlue;
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return successGreen;
      case 'cancelled':
        return dangerRed;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'تم التأكيد';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
          backgroundColor: cardWhite,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: darkColor),
              onPressed: () => Navigator.pop(context)),
          title: Text(_order?['supplier_order_number'] ?? 'تفاصيل الطلب',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkColor))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final items = order['items'] as List? ?? [];
    final statusColor = _getStatusColor(order['status']);

    // ✅ استخراج بيانات العمولة
    final percentageAlaamol =
        (order['percentage_alaamol_mn_alshrkat'] ?? 0).toDouble();
    final alaamolAmount = (order['alaamol_mn_alshrkat'] ?? 0).toDouble();
    final totalAmount = (order['total_amount'] ?? 0).toDouble();
    final netAmount = totalAmount - alaamolAmount;

    return RefreshIndicator(
      onRefresh: _fetchOrder,
      color: primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status Update Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تحديث حالة الطلب',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: [
                  DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('✅ تم التأكيد', style: GoogleFonts.cairo())),
                  DropdownMenuItem(
                      value: 'shipped',
                      child: Text('📦 تم الشحن', style: GoogleFonts.cairo())),
                  DropdownMenuItem(
                      value: 'delivered',
                      child: Text('🎯 تم التسليم', style: GoogleFonts.cairo())),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _updateStatus,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('تحديث',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
            ]),
          ),

          const SizedBox(height: 20),

          // Info Cards
          Row(children: [
            Expanded(
                child: _buildInfoCard(
                    'رقم الطلب',
                    order['supplier_order_number'] ?? '-',
                    Icons.receipt_long_rounded,
                    primaryBlue)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildInfoCard('الحالة', _getStatusText(order['status']),
                    Icons.circle_rounded, statusColor)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _buildInfoCard(
                    'الإجمالي',
                    '${totalAmount.toStringAsFixed(2)} \$',
                    Icons.attach_money_rounded,
                    successGreen)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildInfoCard(
                    'التاريخ',
                    order['created_at']?.toString().substring(0, 10) ?? '-',
                    Icons.calendar_today_rounded,
                    mediumGray)),
          ]),

          const SizedBox(height: 20),

          // ✅ عمولة المنصة Card
          if (percentageAlaamol > 0 || alaamolAmount > 0)
            _buildCommissionCard(
                percentageAlaamol, alaamolAmount, totalAmount, netAmount),

          const SizedBox(height: 20),

          // Items
          Text('المنتجات (${items.length})',
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${index + 1}. ${item['name'] ?? ''}',
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkColor)),
                      const SizedBox(height: 2),
                      Text(
                          '${item['quantity']} × ${(item['unit_price'] ?? 0).toStringAsFixed(2)} \$',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: mediumGray)),
                    ])),
                Text('${(item['total_price'] ?? 0).toStringAsFixed(2)} \$',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: successGreen)),
              ]),
            );
          }),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  // ✅ ودجت بطاقة العمولة
  Widget _buildCommissionCard(
      double percentage, double amount, double total, double net) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.percent_rounded,
                    color: goldColor, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'عمولة المنصة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // نسبة العمولة
          _buildCommissionRow(
            'نسبة العمولة',
            '% ${percentage.toStringAsFixed(2)}',
            Icons.tag_rounded,
            goldColor,
          ),
          const SizedBox(height: 10),

          // قيمة العمولة
          _buildCommissionRow(
            'قيمة العمولة',
            '${amount.toStringAsFixed(2)} \$',
            Icons.calculate_rounded,
            dangerRed,
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFDE68A)),
          const SizedBox(height: 8),

          // صافي المبلغ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.money_rounded, color: successGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'صافي المبلغ المستلم',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${net.toStringAsFixed(2)} \$',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ صف معلومات العمولة
  Widget _buildCommissionRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: goldColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.bold, color: darkColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
