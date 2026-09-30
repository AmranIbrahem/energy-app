// lib/screens/company/supplier_orders/supplier_orders_list_screen.dart

import 'package:GeniusHouse/screens/company/supplier_orders/supplier_order_detail_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierOrdersListScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const SupplierOrdersListScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<SupplierOrdersListScreen> createState() =>
      _SupplierOrdersListScreenState();
}

class _SupplierOrdersListScreenState extends State<SupplierOrdersListScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color purpleColor = Color(0xFF8B5CF6);

  late ApiService _apiService;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalOrders = 0;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _dateFrom;
  String? _dateTo;
  String _selectedSort = 'latest';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchStatistics();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    try {
      final response = await _apiService
          .get('/v1/company/supplier-orders/statistics', requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() => _statistics = response['data']['statistics']);
      }
    } catch (e) {
      // debugPrint('Error: $e');
    }
  }

  Future<void> _fetchOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }
    try {
      final params = _buildParams();
      final response = await _apiService.get('/v1/company/supplier-orders',
          requiresAuth: true, queryParams: params);
      if (response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _orders = data['orders'] ?? [];
          _currentPage = data['pagination']['current_page'] ?? 1;
          _lastPage = data['pagination']['last_page'] ?? 1;
          _totalOrders = data['pagination']['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final params = _buildParams(page: _currentPage + 1);
      final response = await _apiService.get('/v1/company/supplier-orders',
          requiresAuth: true, queryParams: params);
      if (response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _orders.addAll(data['orders'] ?? []);
          _currentPage = data['pagination']['current_page'] ?? _currentPage;
          _lastPage = data['pagination']['last_page'] ?? _lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Map<String, dynamic> _buildParams({int? page}) {
    final params = <String, dynamic>{
      'page': (page ?? _currentPage).toString(),
      'per_page': '20'
    };
    if (_searchController.text.isNotEmpty)
      params['search'] = _searchController.text;
    if (_selectedStatus != null) params['status'] = _selectedStatus;
    if (_dateFrom != null) params['date_from'] = _dateFrom;
    if (_dateTo != null) params['date_to'] = _dateTo;
    params['sort'] = _selectedSort;
    return params;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _dateFrom = null;
      _dateTo = null;
      _selectedSort = 'latest';
    });
    _fetchOrders(refresh: true);
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return warningOrange;
      case 'confirmed':
        return infoBlue;
      case 'shipped':
        return primaryBlue;
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
      case 'cancelled':
        return 'ملغي';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        body: Column(
          children: [
            _buildSearchBar(),
            _buildStatsRow(),
            _buildFiltersRow(),
            Expanded(child: _buildOrdersList()),
            if (_currentPage < _lastPage && !_isLoading) _buildLoadMore(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: cardWhite,
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: '🔍 بحث برقم الطلب...',
          prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _fetchOrders(refresh: true);
                  })
              : null,
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
        ),
        onSubmitted: (_) => _fetchOrders(refresh: true),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _statistics ?? {};
    return Container(
      padding: const EdgeInsets.all(12),
      color: lightGray,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _buildStatChip('الكل', '${stats['total'] ?? 0}', primaryBlue),
          const SizedBox(width: 6),
          _buildStatChip('معلق', '${stats['pending'] ?? 0}', warningOrange),
          const SizedBox(width: 6),
          _buildStatChip('مؤكد', '${stats['confirmed'] ?? 0}', infoBlue),
          const SizedBox(width: 6),
          _buildStatChip('مشحون', '${stats['shipped'] ?? 0}', purpleColor),
          const SizedBox(width: 6),
          _buildStatChip('مسلم', '${stats['delivered'] ?? 0}', successGreen),
        ]),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.cairo(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: cardWhite,
      child: Row(children: [
        Expanded(
          child: _buildDropdown('الحالة', _selectedStatus, [
            {'key': null, 'label': 'الكل'},
            {'key': 'pending', 'label': 'قيد الانتظار'},
            {'key': 'confirmed', 'label': 'تم التأكيد'},
            {'key': 'shipped', 'label': 'تم الشحن'},
            {'key': 'delivered', 'label': 'تم التسليم'},
            {'key': 'cancelled', 'label': 'ملغي'},
          ], (v) {
            _selectedStatus = v;
            _fetchOrders(refresh: true);
          }),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown('ترتيب', _selectedSort, [
            {'key': 'latest', 'label': 'الأحدث'},
            {'key': 'oldest', 'label': 'الأقدم'},
            {'key': 'total_desc', 'label': 'الأعلى قيمة'},
            {'key': 'total_asc', 'label': 'الأقل قيمة'},
          ], (v) {
            _selectedSort = v ?? 'latest';
            _fetchOrders(refresh: true);
          }),
        ),
        if (_hasActiveFilters())
          IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: dangerRed),
              onPressed: _clearFilters),
      ]),
    );
  }

  Widget _buildDropdown(String label, String? value,
      List<Map<String, String?>> items, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.cairo(
              fontSize: 10, color: mediumGray, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: lightGray, borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            isDense: true,
            style: GoogleFonts.cairo(fontSize: 12, color: darkColor),
            items: items
                .map((i) => DropdownMenuItem<String>(
                    value: i['key'],
                    child: Text(i['label'] ?? '',
                        style: GoogleFonts.cairo(fontSize: 12))))
                .toList(),
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
      ),
    ]);
  }

  bool _hasActiveFilters() =>
      _selectedStatus != null || _dateFrom != null || _selectedSort != 'latest';

  Widget _buildOrdersList() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    if (_orders.isEmpty)
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('لا توجد طلبات توريد',
              style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
        ],
      ));
    return RefreshIndicator(
      onRefresh: () => _fetchOrders(refresh: true),
      color: primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusColor = _getStatusColor(order['status']);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SupplierOrderDetailScreen(
                  authService: widget.authService,
                  storageService: widget.storageService,
                  orderId: order['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
              BoxShadow(
                  color: statusColor.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 8),
              Text(order['supplier_order_number'] ?? '',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
            ]),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2))),
                child: Text(_getStatusText(order['status']),
                    style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.description_rounded, size: 14, color: mediumGray),
            const SizedBox(width: 4),
            Expanded(
              child: Text(order['items_preview'] ?? '',
                  style: GoogleFonts.cairo(fontSize: 12, color: darkColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if ((order['items_count'] ?? 0) > 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+${order['items_count'] - 2}',
                    style: GoogleFonts.cairo(fontSize: 10, color: primaryBlue)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.attach_money_rounded, color: successGreen, size: 16),
              const SizedBox(width: 4),
              Text('${order['total_amount']} \$',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: successGreen)),
            ]),
            Text(
                order['created_at'] != null
                    ? order['created_at'].toString().substring(0, 10)
                    : '',
                style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildLoadMore() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoadingMore ? null : _loadMore,
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 4,
            shadowColor: primaryBlue.withOpacity(0.3)),
        child: _isLoadingMore
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('تحميل المزيد',
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height);
    path.lineTo(size.width - 20, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
