// lib/screens/company/products/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/screens/company/products/add_product_screen.dart';
import 'package:GeniusHouse/screens/company/products/edit_product_screen.dart';
import 'package:GeniusHouse/screens/company/products/product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const ProductsListScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  late ApiService _apiService;

  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalProducts = 0;

  bool _isGridView = true;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String? _selectedSubCategoryId;
  String? _selectedStatus;
  String? _selectedStockStatus;
  String? _selectedApprovalStatus; // ✅ جديد
  String _selectedSort = 'latest';

  List<dynamic> _subCategories = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchSubCategories();
    _fetchProducts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  // ==================== Data Fetching ====================

  Future<void> _fetchSubCategories() async {
    try {
      final response = await _apiService.get(
          '/v1/company/products/create-data', requiresAuth: true);
      if (response['data'] != null &&
          response['data']['sub_categories'] != null && mounted) {
        setState(() =>
        _subCategories = response['data']['sub_categories'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
    }
  }

  Future<void> _fetchProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      final queryParams = _buildQueryParams();
      final response = await _apiService.get(
          '/v1/company/products', requiresAuth: true, queryParams: queryParams);

      if (response['data'] != null && response['data']['products'] != null &&
          mounted) {
        final data = response['data'];
        setState(() {
          _products = data['products'] ?? [];
          _currentPage = data['pagination']['current_page'] ?? 1;
          _lastPage = data['pagination']['last_page'] ?? 1;
          _totalProducts = data['pagination']['total'] ?? 0;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;

    setState(() => _isLoadingMore = true);

    try {
      final queryParams = _buildQueryParams(page: _currentPage + 1);
      final response = await _apiService.get(
          '/v1/company/products', requiresAuth: true, queryParams: queryParams);

      if (response['data'] != null && response['data']['products'] != null &&
          mounted) {
        final data = response['data'];
        setState(() {
          _products.addAll(data['products'] ?? []);
          _currentPage = data['pagination']['current_page'] ?? _currentPage;
          _lastPage = data['pagination']['last_page'] ?? _lastPage;
          _isLoadingMore = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      debugPrint('Error loading more products: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Map<String, dynamic> _buildQueryParams({int? page}) {
    final params = <String, dynamic>{};
    params['page'] = (page ?? _currentPage).toString();
    params['per_page'] = '20';
    if (_searchController.text.isNotEmpty)
      params['search'] = _searchController.text;
    if (_selectedSubCategoryId != null)
      params['sub_category_id'] = _selectedSubCategoryId;
    if (_selectedStatus != null) params['status'] = _selectedStatus;
    if (_selectedStockStatus != null)
      params['stock_status'] = _selectedStockStatus;
    if (_selectedApprovalStatus != null) // ✅ جديد
      params['approval_status'] = _selectedApprovalStatus;
    if (_minPriceController.text.isNotEmpty)
      params['min_price'] = _minPriceController.text;
    if (_maxPriceController.text.isNotEmpty)
      params['max_price'] = _maxPriceController.text;
    params['sort'] = _selectedSort;
    return params;
  }

  // ==================== Navigation ====================

  void _navigateToAddProduct() async {
    final result = await Navigator.push(context, MaterialPageRoute(
        builder: (_) =>
            AddProductScreen(authService: widget.authService,
                storageService: widget.storageService)));
    if (result == true) _fetchProducts(refresh: true);
  }

  void _navigateToEditProduct(dynamic product) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
        EditProductScreen(authService: widget.authService,
            storageService: widget.storageService,
            productId: product['id'])));
    _fetchProducts(refresh: true);
  }

  void _navigateToProductDetail(dynamic product) {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        ProductDetailScreen(authService: widget.authService,
            storageService: widget.storageService,
            productId: product['id'])));
  }

  // ==================== Actions ====================

  Future<void> _toggleProductStatus(int productId, bool currentStatus) async {
    try {
      final response = await _apiService.post(
          '/v1/company/products/$productId/toggle-status', requiresAuth: true,
          data: {});
      if (response['data'] != null && mounted) {
        _showSnackBar(response['message'] ?? 'تم تغيير الحالة',
            response['data']?['is_active'] == true ? successGreen : Colors
                .orange);
        _fetchProducts(refresh: true);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ في تغيير الحالة', dangerRed);
    }
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Icon(Icons.warning_rounded, color: dangerRed, size: 28),
              const SizedBox(width: 10),
              Text('تأكيد الحذف', style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, fontSize: 18))
            ]),
            content: Text(
                'هل أنت متأكد من حذف المنتج "$productName"؟\nهذا الإجراء لا يمكن التراجع عنه.',
                style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: Text(
                      'إلغاء', style: GoogleFonts.cairo(color: mediumGray))),
              ElevatedButton(onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: dangerRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('نعم، احذف',
                      style: GoogleFonts.cairo(color: Colors.white))),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final response = await _apiService.delete(
            '/v1/company/products/$productId', requiresAuth: true);
        if (response['data'] != null && mounted) {
          _showSnackBar('تم حذف المنتج بنجاح', successGreen);
          _fetchProducts(refresh: true);
        }
      } catch (e) {
        _showSnackBar('حدث خطأ في حذف المنتج', dangerRed);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Row(children: [
        Icon(color == successGreen ? Icons.check_circle_rounded : Icons
            .info_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14)))
      ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2)));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedSubCategoryId = null;
      _selectedStatus = null;
      _selectedStockStatus = null;
      _selectedApprovalStatus = null; // ✅ جديد
      _selectedSort = 'latest';
    });
    _fetchProducts(refresh: true);
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAddProduct,
          backgroundColor: primaryBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('إضافة منتج', style: GoogleFonts.cairo(
              color: Colors.white, fontWeight: FontWeight.w600))),
      body: Column(children: [
        _buildSearchBar(),
        _buildFiltersSection(),
        _buildHeaderInfo(),
        Expanded(child: _buildProductsList()),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12), color: cardWhite,
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
            hintText: '🔍 بحث عن منتج (اسم، SKU، علامة تجارية)...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
            suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20), onPressed: () {
              _searchController.clear();
              _fetchProducts(refresh: true);
            }) : null,
            filled: true,
            fillColor: lightGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 16)),
        onSubmitted: (_) => _fetchProducts(refresh: true),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: cardWhite,
      child: ExpansionTile(
        title: Row(children: [
          Icon(Icons.filter_list_rounded, color: primaryBlue, size: 20),
          const SizedBox(width: 8),
          Text('الفلاتر والتصفية', style: GoogleFonts.cairo(
              fontSize: 14, fontWeight: FontWeight.w600, color: darkColor))
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasActiveFilters()) TextButton(onPressed: _clearFilters,
                  child: Text('مسح الكل', style: GoogleFonts.cairo(
                      fontSize: 12, color: dangerRed))),
              const Icon(Icons.expand_more_rounded, color: mediumGray)
            ]),
        initiallyExpanded: false,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                const SizedBox(height: 8),
                // الصف الأول
                Row(children: [
                  Expanded(child: _buildFilterDropdown(label: 'التصنيف الفرعي',
                      value: _selectedSubCategoryId,
                      items: [
                        {'key': null, 'label': 'جميع التصنيفات'},
                        ..._subCategories.map((s) =>
                        {
                          'key': s['id']?.toString(),
                          'label': s['name_ar'] ?? ''
                        })
                      ],
                      onChanged: (v) {
                        setState(() => _selectedSubCategoryId = v);
                        _fetchProducts(refresh: true);
                      })),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFilterDropdown(label: 'الحالة',
                      value: _selectedStatus,
                      items: [
                        {'key': null, 'label': 'الكل'},
                        {'key': 'active', 'label': 'نشط'},
                        {'key': 'inactive', 'label': 'غير نشط'}
                      ],
                      onChanged: (v) {
                        setState(() => _selectedStatus = v);
                        _fetchProducts(refresh: true);
                      }))
                ]),
                const SizedBox(height: 10),
                // ✅ الصف الثاني - الموافقة والكمية
                Row(children: [
                  Expanded(child: _buildFilterDropdown(label: 'الموافقة',
                      value: _selectedApprovalStatus,
                      items: [
                        {'key': null, 'label': 'الكل'},
                        {'key': 'approved', 'label': 'تمت الموافقة'},
                        {'key': 'pending', 'label': 'قيد المراجعة'}
                      ],
                      onChanged: (v) {
                        setState(() => _selectedApprovalStatus = v);
                        _fetchProducts(refresh: true);
                      })),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFilterDropdown(label: 'الكمية',
                      value: _selectedStockStatus,
                      items: [
                        {'key': null, 'label': 'الكل'},
                        {'key': 'in_stock', 'label': 'متوفر'},
                        {'key': 'out_of_stock', 'label': 'غير متوفر'}
                      ],
                      onChanged: (v) {
                        setState(() => _selectedStockStatus = v);
                        _fetchProducts(refresh: true);
                      })),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _buildFilterDropdown(label: 'الترتيب',
                      value: _selectedSort,
                      items: [
                        {'key': 'latest', 'label': 'الأحدث'},
                        {'key': 'oldest', 'label': 'الأقدم'},
                        {'key': 'price_asc', 'label': 'السعر (من الأقل)'},
                        {'key': 'price_desc', 'label': 'السعر (من الأعلى)'},
                        {'key': 'name_asc', 'label': 'الاسم (أ-ي)'},
                        {'key': 'name_desc', 'label': 'الاسم (ي-أ)'},
                        {'key': 'views_desc', 'label': 'الأكثر مشاهدة'}
                      ],
                      onChanged: (v) {
                        setState(() => _selectedSort = v ?? 'latest');
                        _fetchProducts(refresh: true);
                      }))
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.cairo(fontSize: 13),
                      decoration: InputDecoration(labelText: 'السعر من',
                          labelStyle: GoogleFonts.cairo(
                              fontSize: 11, color: mediumGray),
                          filled: true,
                          fillColor: lightGray,
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          isDense: true))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.cairo(fontSize: 13),
                      decoration: InputDecoration(labelText: 'السعر إلى',
                          labelStyle: GoogleFonts.cairo(
                              fontSize: 11, color: mediumGray),
                          filled: true,
                          fillColor: lightGray,
                          border: OutlineInputBorder(borderRadius: BorderRadius
                              .circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          isDense: true))),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: () => _fetchProducts(refresh: true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16)),
                      child: Text('تطبيق', style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.white)))
                ]),
              ]))
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<Map<String, String?>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
              items: items.map((item) =>
                  DropdownMenuItem<String>(
                    value: item['key'],
                    child: Text(item['label'] ?? '',
                        style: GoogleFonts.cairo(fontSize: 13)),
                  )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() =>
      _selectedSubCategoryId != null || _selectedStatus != null ||
          _selectedStockStatus != null || _selectedApprovalStatus != null || // ✅ جديد
          _minPriceController.text.isNotEmpty ||
          _maxPriceController.text.isNotEmpty || _selectedSort != 'latest' ||
          _searchController.text.isNotEmpty;

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: cardWhite,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'تم العثور على $_totalProducts منتج',
            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildViewToggle(Icons.grid_view_rounded, _isGridView, () {
                      setState(() => _isGridView = true);
                    }),
                    _buildViewToggle(Icons.view_list_rounded, !_isGridView, () {
                      setState(() => _isGridView = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 20, color: isActive ? Colors.white : mediumGray),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) return _buildShimmerGrid();
    if (_products.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      onRefresh: () => _fetchProducts(refresh: true),
      color: primaryBlue,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72),
      itemCount: _products.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryBlue)));
        }
        return _buildProductCard(_products[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryBlue)));
        }
        return _buildProductListItem(_products[index]);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final String name = product['name_ar'] ?? '';
    final String sku = product['sku'] ?? '';
    final String price = product['final_price'] ?? '0';
    final String? originalPrice = (product['discount_percentage'] ?? 0) > 0 ? product['price'] : null;
    final int stock = product['stock'] ?? 0;
    final bool isActive = product['is_active'] ?? false;
    final bool isApproved = product['is_approved'] ?? false; // ✅ جديد
    final String? imageUrl = product['main_image'];
    final int discountPercent = (product['discount_percentage'] ?? 0).round();

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      color: lightGray,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey)),
                      )
                          : const Center(child: Icon(Icons.image_rounded, size: 40, color: Colors.grey)),
                    ),
                  ),
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: dangerRed, borderRadius: BorderRadius.circular(8)),
                        child: Text('-$discountPercent%', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  // ✅ شارة الموافقة
                  Positioned(
                    top: 8,
                    left: discountPercent > 0 ? 50 : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isApproved ? successGreen.withOpacity(0.9) : warningColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isApproved ? '✓ موافق' : '⏳ مراجعة',
                        style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: stock > 0 ? successGreen.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stock > 0 ? '$stock قطعة' : 'غير متوفر',
                        style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: darkColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('SKU: $sku', style: GoogleFonts.cairo(fontSize: 9, color: mediumGray)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (originalPrice != null)
                                Text(originalPrice, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                              Text('$price \$', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleProductStatus(product['id'], isActive),
                          child: Container(
                            width: 36,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isActive ? successGreen : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(Icons.edit_rounded, primaryBlue, () => _navigateToEditProduct(product)),
                        _buildActionButton(Icons.delete_rounded, dangerRed, () => _deleteProduct(product['id'], name)),
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

  Widget _buildProductListItem(dynamic product) {
    final String name = product['name_ar'] ?? '';
    final String sku = product['sku'] ?? '';
    final String price = product['final_price'] ?? '0';
    final int stock = product['stock'] ?? 0;
    final bool isActive = product['is_active'] ?? false;
    final bool isApproved = product['is_approved'] ?? false; // ✅ جديد
    final String? imageUrl = product['main_image'];

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cardWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 60,
                    height: 60,
                    child: imageUrl != null ? CachedNetworkImage(
                        imageUrl: imageUrl, fit: BoxFit.cover) : Container(
                        color: lightGray,
                        child: const Icon(
                            Icons.image_rounded, color: Colors.grey)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(name, style: GoogleFonts.cairo(fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                    // ✅ شارة الموافقة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isApproved ? successGreen.withOpacity(0.1) : warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isApproved ? '✓ موافق' : '⏳ مراجعة',
                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? successGreen : warningColor,
                        ),
                      ),
                    ),
                  ]),
                  Text('SKU: $sku | $price \$ | $stock قطعة',
                      style: GoogleFonts.cairo(fontSize: 11, color: mediumGray))
                ])),
            Column(children: [
              GestureDetector(
                  onTap: () => _toggleProductStatus(product['id'], isActive),
                  child: Container(width: 36,
                      height: 20,
                      decoration: BoxDecoration(
                          color: isActive ? successGreen : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)),
                      child: Stack(children: [
                        AnimatedAlign(alignment: isActive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                            duration: const Duration(milliseconds: 200),
                            child: Container(width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)))
                      ]))),
              const SizedBox(height: 8),
              Row(children: [
                _buildActionButton(Icons.edit_rounded, primaryBlue, () =>
                    _navigateToEditProduct(product)),
                const SizedBox(width: 4),
                _buildActionButton(Icons.delete_rounded, dangerRed, () =>
                    _deleteProduct(product['id'], name))
              ])
            ]),
          ])),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.inventory_2_rounded, size: 64,
                  color: primaryBlue.withOpacity(0.4))),
          const SizedBox(height: 20),
          Text('لا توجد منتجات', style: GoogleFonts.cairo(
              fontSize: 20, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 8),
          Text('لم يتم العثور على منتجات مطابقة',
              style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            TextButton.icon(onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded, color: primaryBlue),
                label: Text('مسح الفلاتر',
                    style: GoogleFonts.cairo(color: primaryBlue)))
          ]
        ]));
  }

  Widget _buildShimmerGrid() =>
      GridView.count(crossAxisCount: 2,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
          children: List.generate(6, (index) =>
              Container(decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16)))));
}