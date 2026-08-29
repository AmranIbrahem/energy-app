// lib/screens/company/commissions/company_commission_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/api_service.dart';

class CompanyCommissionScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const CompanyCommissionScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<CompanyCommissionScreen> createState() => _CompanyCommissionScreenState();
}

class _CompanyCommissionScreenState extends State<CompanyCommissionScreen> {
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
  Map<String, dynamic>? _commissionData;
  List<dynamic> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchCommissionData();
  }

  Future<void> _fetchCommissionData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/v1/company/commissions',
        requiresAuth: true,
      );

      if (response['data'] != null && mounted) {
        setState(() {
          _commissionData = response['data']['commission_data'];
        });
      }

      // جلب سجل العمولات
      final listResponse = await _apiService.get(
        '/v1/company/commissions/list',
        requiresAuth: true,
      );

      if (listResponse['data'] != null && mounted) {
        setState(() {
          _commissions = listResponse['data']['commissions'] ?? [];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return warningOrange;
      case 'partially_paid':
        return primaryBlue;
      case 'paid':
        return successGreen;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'معلق';
      case 'partially_paid':
        return 'مدفوع جزئياً';
      case 'paid':
        return 'مدفوع بالكامل';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryBlue))
        : RefreshIndicator(
      onRefresh: _fetchCommissionData,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة نسبة العمولة
            _buildPercentageCard(),
            const SizedBox(height: 16),
            // بطاقات الإحصائيات
            _buildStatsGrid(),
            const SizedBox(height: 20),
            // تنبيه
            _buildInfoAlert(),
            const SizedBox(height: 20),
            // سجل العمولات
            Text(
              'سجل العمولات',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 10),
            ..._commissions.map((commission) => _buildCommissionCard(commission)),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCard() {
    final percentage = (_commissionData?['commission_percentage'] ?? 0).toString();
    final totalRemaining = (_commissionData?['total_remaining'] ?? 0).toString();
    final totalPaid = (_commissionData?['total_paid'] ?? 0).toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: Color(0xFF92400E),
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '% ${double.tryParse(percentage)?.toStringAsFixed(2) ?? '0.00'}',
            style: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF92400E),
            ),
          ),
          Text(
            'نسبة عمولة المنصة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${double.tryParse(totalPaid)?.toStringAsFixed(2) ?? '0.00'} \$',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'المدفوع',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.4),
              ),
              Column(
                children: [
                  Text(
                    '${double.tryParse(totalRemaining)?.toStringAsFixed(2) ?? '0.00'} \$',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'المتبقي',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _commissionData;
    if (stats == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('عدد الطلبيات', '${stats['total_orders'] ?? 0}', Icons.receipt_long_rounded, primaryBlue),
        _buildStatCard('عمولات معلقة', '${stats['pending_count'] ?? 0}', Icons.pending_actions_rounded, warningOrange),
        _buildStatCard('عمولات مدفوعة', '${stats['paid_count'] ?? 0}', Icons.check_circle_rounded, successGreen),
        _buildStatCard('إجمالي العمولة', '${double.tryParse((stats['total_commissions'] ?? 0).toString())?.toStringAsFixed(2) ?? '0.00'} \$', Icons.calculate_rounded, dangerRed),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: primaryBlue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'نسبة العمولة تحددها إدارة المنصة وتطبق على جميع الطلبات التي يتم إرسالها لشركتك.',
              style: GoogleFonts.cairo(fontSize: 12, color: mediumGray, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionCard(dynamic commission) {
    final statusColor = _getStatusColor(commission['status']);
    final statusText = _getStatusText(commission['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                commission['order_number'] ?? '-',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: darkColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الطلبية', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              Text('${commission['total_amount']} \$', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: darkColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نسبة العمولة', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              Text('% ${commission['commission_percentage']}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: warningOrange)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('قيمة العمولة', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              Text('${commission['commission_amount']} \$', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: warningOrange)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المدفوع', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              Text('${commission['paid_amount']} \$', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: successGreen)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المتبقي', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              Text('${commission['remaining_amount']} \$', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: dangerRed)),
            ],
          ),
        ],
      ),
    );
  }
}