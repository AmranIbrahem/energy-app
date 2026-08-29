// lib/screens/company/offers/offers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/screens/company/offers/add_offer_screen.dart';
import 'package:GeniusHouse/screens/company/offers/edit_offer_screen.dart';
import 'package:GeniusHouse/screens/company/offers/offer_detail_screen.dart';

class OffersListScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const OffersListScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  late ApiService _apiService;

  List<dynamic> _offers = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalOffers = 0;

  bool _isGridView = true;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedFeatured;
  String? _selectedApprovalStatus; // ✅ جديد
  String _selectedSort = 'latest';

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchStatistics();
    _fetchOffers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    try {
      final response = await _apiService.get('/v1/company/offers/statistics', requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() => _statistics = response['data']['statistics']);
      }
    } catch (e) {
      debugPrint('Error fetching offer statistics: $e');
    }
  }

  Future<void> _fetchOffers({bool refresh = false}) async {
    if (refresh) {
      setState(() { _currentPage = 1; _isLoading = true; });
    }
    try {
      final params = _buildQueryParams();
      final response = await _apiService.get('/v1/company/offers', requiresAuth: true, queryParams: params);
      if (response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _offers = data['offers'] ?? [];
          _currentPage = data['pagination']['current_page'] ?? 1;
          _lastPage = data['pagination']['last_page'] ?? 1;
          _totalOffers = data['pagination']['total'] ?? 0;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final params = _buildQueryParams(page: _currentPage + 1);
      final response = await _apiService.get('/v1/company/offers', requiresAuth: true, queryParams: params);
      if (response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _offers.addAll(data['offers'] ?? []);
          _currentPage = data['pagination']['current_page'] ?? _currentPage;
          _lastPage = data['pagination']['last_page'] ?? _lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Map<String, dynamic> _buildQueryParams({int? page}) {
    final params = <String, dynamic>{
      'page': (page ?? _currentPage).toString(),
      'per_page': '20',
    };
    if (_searchController.text.isNotEmpty) params['search'] = _searchController.text;
    if (_selectedStatus != null) params['status'] = _selectedStatus;
    if (_selectedFeatured != null) params['featured'] = _selectedFeatured;
    if (_selectedApprovalStatus != null) params['approval_status'] = _selectedApprovalStatus; // ✅ جديد
    params['sort'] = _selectedSort;
    return params;
  }

  Future<void> _toggleStatus(int id) async {
    try {
      await _apiService.post('/v1/company/offers/$id/toggle-status', requiresAuth: true, data: {});
      _fetchOffers(refresh: true); _fetchStatistics();
    } catch (e) { _showSnackBar('حدث خطأ', dangerRed); }
  }

  Future<void> _toggleFeatured(int id) async {
    try {
      await _apiService.post('/v1/company/offers/$id/toggle-featured', requiresAuth: true, data: {});
      _fetchOffers(refresh: true); _fetchStatistics();
    } catch (e) { _showSnackBar('حدث خطأ', dangerRed); }
  }

  Future<void> _deleteOffer(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف العرض "$name"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _apiService.delete('/v1/company/offers/$id', requiresAuth: true);
        _showSnackBar('تم حذف العرض بنجاح', successGreen);
        _fetchOffers(refresh: true); _fetchStatistics();
      } catch (e) { _showSnackBar('حدث خطأ', dangerRed); }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [Icon(Icons.info_rounded, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14)))]),
        backgroundColor: color, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
      ));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedFeatured = null;
      _selectedApprovalStatus = null; // ✅ جديد
      _selectedSort = 'latest';
    });
    _fetchOffers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddOfferScreen(authService: widget.authService, storageService: widget.storageService)));
          if (result == true) { _fetchOffers(refresh: true); _fetchStatistics(); }
        },
        backgroundColor: primaryBlue, icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('إضافة عرض', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        _buildSearchBar(),
        _buildFiltersRow(),
        _buildStatsRow(),
        _buildHeaderInfo(),
        Expanded(child: _buildOffersList()),
        if (_currentPage < _lastPage && !_isLoading) _buildLoadMore(),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(padding: const EdgeInsets.all(12), color: cardWhite, child: TextField(
      controller: _searchController, style: GoogleFonts.cairo(fontSize: 14),
      decoration: InputDecoration(
        hintText: '🔍 بحث عن عرض...', hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () { _searchController.clear(); _fetchOffers(refresh: true); }) : null,
        filled: true, fillColor: lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onSubmitted: (_) => _fetchOffers(refresh: true),
      onChanged: (_) => setState(() {}),
    ));
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: cardWhite,
      child: Wrap(
        spacing: 8, runSpacing: 4,
        children: [
          SizedBox(width: 120, child: _buildDropdown('الحالة', _selectedStatus, [{'key': null, 'label': 'الكل'}, {'key': 'active', 'label': 'نشط'}, {'key': 'inactive', 'label': 'غير نشط'}], (v) { _selectedStatus = v; _fetchOffers(refresh: true); })),
          SizedBox(width: 120, child: _buildDropdown('مميز', _selectedFeatured, [{'key': null, 'label': 'الكل'}, {'key': 'yes', 'label': 'مميز'}, {'key': 'no', 'label': 'غير مميز'}], (v) { _selectedFeatured = v; _fetchOffers(refresh: true); })),
          // ✅ فلتر الموافقة
          SizedBox(width: 140, child: _buildDropdown('الموافقة', _selectedApprovalStatus, [{'key': null, 'label': 'الكل'}, {'key': 'approved', 'label': 'تمت الموافقة'}, {'key': 'pending', 'label': 'قيد المراجعة'}], (v) { _selectedApprovalStatus = v; _fetchOffers(refresh: true); })),
          SizedBox(width: 130, child: _buildDropdown('ترتيب', _selectedSort, [{'key': 'latest', 'label': 'الأحدث'}, {'key': 'oldest', 'label': 'الأقدم'}, {'key': 'name_asc', 'label': 'الاسم (أ-ي)'}, {'key': 'price_asc', 'label': 'السعر (من الأقل)'}, {'key': 'price_desc', 'label': 'السعر (من الأعلى)'}, {'key': 'views_desc', 'label': 'الأكثر مشاهدة'}], (v) { _selectedSort = v ?? 'latest'; _fetchOffers(refresh: true); })),
          if (_hasActiveFilters())
            GestureDetector(onTap: _clearFilters, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.clear_all_rounded, color: dangerRed, size: 18))),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<Map<String, String?>> items, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 10, color: mediumGray)),
      const SizedBox(height: 2),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: lightGray, borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, isDense: true, style: GoogleFonts.cairo(fontSize: 12, color: darkColor), items: items.map((i) => DropdownMenuItem<String>(value: i['key'], child: Text(i['label'] ?? '', style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setState(() => onChanged(v))))),
    ]);
  }

  bool _hasActiveFilters() => _selectedStatus != null || _selectedFeatured != null || _selectedApprovalStatus != null || _selectedSort != 'latest' || _searchController.text.isNotEmpty;

  Widget _buildStatsRow() {
    final stats = _statistics ?? {};
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), color: lightGray, child: Wrap(spacing: 6, runSpacing: 4, children: [
      _buildStatChip('الكل', '${stats['total'] ?? 0}', primaryBlue),
      _buildStatChip('نشط', '${stats['active'] ?? 0}', successGreen),
      _buildStatChip('غير نشط', '${stats['inactive'] ?? 0}', Colors.grey),
      _buildStatChip('مميز', '${stats['featured'] ?? 0}', warningOrange),
      _buildStatChip('✓ موافق', '${stats['approved'] ?? 0}', successGreen), // ✅ جديد
    ]));
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('$label: $value', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: color)));
  }

  Widget _buildHeaderInfo() {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: cardWhite, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('$_totalOffers عرض', style: GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
      Row(children: [_buildViewToggle(Icons.grid_view_rounded, _isGridView, () => setState(() => _isGridView = true)), const SizedBox(width: 4), _buildViewToggle(Icons.view_list_rounded, !_isGridView, () => setState(() => _isGridView = false))]),
    ]));
  }

  Widget _buildViewToggle(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isActive ? primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 18, color: isActive ? Colors.white : mediumGray)));
  }

  Widget _buildOffersList() {
    if (_isLoading) return _buildShimmerGrid();
    if (_offers.isEmpty) return _buildEmptyState();
    return RefreshIndicator(onRefresh: () => _fetchOffers(refresh: true), color: primaryBlue, child: _isGridView ? _buildGridView() : _buildListView());
  }

  Widget _buildGridView() {
    return GridView.builder(padding: const EdgeInsets.all(12), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.72), itemCount: _offers.length, itemBuilder: (_, i) => _buildOfferCard(_offers[i]));
  }

  Widget _buildListView() {
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: _offers.length, itemBuilder: (_, i) => _buildOfferListItem(_offers[i]));
  }

  // ✅ بطاقة العرض مع شارة الموافقة
  Widget _buildOfferCard(dynamic offer) {
    final name = offer['name_ar'] ?? '';
    final price = offer['final_price'] ?? '0';
    final imageUrl = offer['cover_image'];
    final isActive = offer['is_active'] ?? false;
    final isFeatured = offer['is_featured'] ?? false;
    final isApproved = offer['is_approved'] ?? false;
    final discountPercent = (offer['discount_percentage'] ?? 0).round();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfferDetailScreen(authService: widget.authService, storageService: widget.storageService, offerId: offer['id']))),
      child: Container(
        decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Container(width: double.infinity, color: lightGray, child: imageUrl != null ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_, __, ___) => const Icon(Icons.image_rounded, color: Colors.grey)) : const Icon(Icons.image_rounded, color: Colors.grey))),
            if (discountPercent > 0) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: dangerRed, borderRadius: BorderRadius.circular(8)), child: Text('-$discountPercent%', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)))),
            // ✅ شارة الموافقة
            Positioned(top: 8, left: discountPercent > 0 ? 50 : 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isApproved ? successGreen.withOpacity(0.9) : warningOrange.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: Text(isApproved ? '✓ موافق' : '⏳ مراجعة', style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)))),
            if (isFeatured) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: warningOrange, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.star_rounded, color: Colors.white, size: 14))),
          ])),
          Expanded(flex: 5, child: Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: darkColor), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('$price \$', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(onTap: () => _toggleStatus(offer['id']), child: Container(width: 36, height: 20, decoration: BoxDecoration(color: isActive ? successGreen : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)), child: Stack(children: [AnimatedAlign(alignment: isActive ? Alignment.centerRight : Alignment.centerLeft, duration: const Duration(milliseconds: 200), child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))]))),
              GestureDetector(onTap: () => _toggleFeatured(offer['id']), child: Icon(Icons.star_rounded, size: 20, color: isFeatured ? warningOrange : Colors.grey.shade300)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildActionBtn(Icons.edit_rounded, primaryBlue, () { Navigator.push(context, MaterialPageRoute(builder: (_) => EditOfferScreen(authService: widget.authService, storageService: widget.storageService, offerId: offer['id']))).then((_) => _fetchOffers(refresh: true)); }),
              _buildActionBtn(Icons.delete_rounded, dangerRed, () => _deleteOffer(offer['id'], name)),
            ]),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildOfferListItem(dynamic offer) {
    final name = offer['name_ar'] ?? '';
    final price = offer['final_price'] ?? '0';
    final imageUrl = offer['cover_image'];
    final isActive = offer['is_active'] ?? false;
    final isFeatured = offer['is_featured'] ?? false;
    final isApproved = offer['is_approved'] ?? false;
    final productsCount = offer['products_count'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfferDetailScreen(authService: widget.authService, storageService: widget.storageService, offerId: offer['id']))),
      child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 60, height: 60, child: imageUrl != null ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover) : Container(color: lightGray, child: const Icon(Icons.image_rounded, color: Colors.grey)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
            // ✅ شارة الموافقة
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isApproved ? successGreen.withOpacity(0.1) : warningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(isApproved ? '✓ موافق' : '⏳ مراجعة', style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: isApproved ? successGreen : warningOrange))),
          ]),
          Text('$price \$ | $productsCount منتجات', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
        ])),
        Column(children: [
          GestureDetector(onTap: () => _toggleStatus(offer['id']), child: Container(width: 36, height: 20, decoration: BoxDecoration(color: isActive ? successGreen : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)), child: Stack(children: [AnimatedAlign(alignment: isActive ? Alignment.centerRight : Alignment.centerLeft, duration: const Duration(milliseconds: 200), child: Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))]))),
          const SizedBox(height: 6),
          Row(children: [_buildActionBtn(Icons.edit_rounded, primaryBlue, () { Navigator.push(context, MaterialPageRoute(builder: (_) => EditOfferScreen(authService: widget.authService, storageService: widget.storageService, offerId: offer['id']))).then((_) => _fetchOffers(refresh: true)); }), const SizedBox(width: 4), _buildActionBtn(Icons.delete_rounded, dangerRed, () => _deleteOffer(offer['id'], name))]),
        ]),
      ])),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 16, color: color)));
  }

  Widget _buildLoadMore() {
    return Container(padding: const EdgeInsets.all(16), child: ElevatedButton(onPressed: _isLoadingMore ? null : _loadMore, style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)), child: _isLoadingMore ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.download_rounded, color: Colors.white, size: 20), const SizedBox(width: 8), Text('تحميل المزيد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600))])));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_offer_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('لا توجد عروض', style: GoogleFonts.cairo(fontSize: 16, color: mediumGray))]));
  }

  Widget _buildShimmerGrid() {
    return GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(12), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.72, children: List.generate(6, (_) => Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)))));
  }
}