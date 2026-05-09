import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/constants.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/services/storage_service.dart';
import 'package:energy_store_app/widgets/product_card.dart';

class ProductsListScreen extends StatefulWidget {
  final String title;
  final List<dynamic>? products;
  final String? categorySlug;
  final String? subcategorySlug;
  final ApiService apiService;
  final AuthService? authService;
  final StorageService? storageService;  // ✅ إضافة storageService
  final bool isSubCategory;

  const ProductsListScreen({
    super.key,
    required this.title,
    this.products,
    this.categorySlug,
    this.subcategorySlug,
    required this.apiService,
    this.authService,
    this.storageService,  // ✅ إضافة
    this.isSubCategory = false,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;
  String _searchQuery = '';
  String _governorate = 'دمشق';  // ✅ متغير المحافظة

  // خيارات الفرز
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  String _selectedSort = 'الأحدث';

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'created_at', 'label': 'الأحدث', 'order': 'desc'},
    {'value': 'price', 'label': 'السعر: من الأقل للأعلى', 'order': 'asc'},
    {'value': 'price', 'label': 'السعر: من الأعلى للأقل', 'order': 'desc'},
    {'value': 'rate', 'label': 'الأعلى تقييماً', 'order': 'desc'},
    {'value': 'views', 'label': 'الأكثر مشاهدة', 'order': 'desc'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGovernorate();

    if (widget.products != null) {
      _products = List.from(widget.products!);
      _isLoading = false;
    } else {
      _fetchProducts();
    }
  }

  void _loadGovernorate() {
    // ✅ محاولة جلب المحافظة من StorageService مباشرة (Singleton)
    try {
      final savedGov = StorageService().getGovernorate();
      if (savedGov != null && savedGov.isNotEmpty) {
        _governorate = savedGov;
        print('📍 ProductsList - Governorate from StorageService: $_governorate');
        return;
      }
    } catch (e) {
      print('❌ Error getting governorate from StorageService: $e');
    }

    // ✅ من widget.storageService
    if (widget.storageService != null) {
      final savedGov = widget.storageService!.getGovernorate();
      if (savedGov != null && savedGov.isNotEmpty) {
        _governorate = savedGov;
        print('📍 ProductsList - Governorate from widget: $_governorate');
        return;
      }
    }

    // ✅ القيمة الافتراضية
    print('⚠️ ProductsList - No saved governorate, using default: $_governorate');
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      String endpoint;
      bool requiresAuth;

      // ⭐ تحديد الـ API حسب نوع المستخدم ونوع القسم
      if (widget.isSubCategory && widget.subcategorySlug != null) {
        // جلب منتجات قسم فرعي معين
        if (widget.authService?.isAuthenticated == true) {
          // مستخدم مسجل
          endpoint = '/v1/user/products/sub-category/${widget.subcategorySlug}';
          requiresAuth = true;
          print('📡 Auth user - Subcategory endpoint: $endpoint');
        } else {
          // ✅ زائر: استخدام _governorate المخزنة
          endpoint = '/v1/user/public/products/sub-category/${widget.subcategorySlug}/$_governorate';
          requiresAuth = false;
          print('📡 Guest - Subcategory endpoint: $endpoint');
          print('📍 Using governorate: $_governorate');
        }
      }
      else if (widget.categorySlug != null && widget.categorySlug!.isNotEmpty) {
        // جلب منتجات قسم رئيسي
        if (widget.authService?.isAuthenticated == true) {
          endpoint = '/v1/user/products/category/${widget.categorySlug}';
          requiresAuth = true;
        } else {
          // ✅ زائر: استخدام _governorate المخزنة
          endpoint = '/v1/user/public/products/category/${widget.categorySlug}/$_governorate';
          requiresAuth = false;
        }
      }
      else {
        // بحث عام
        if (widget.authService?.isAuthenticated == true) {
          endpoint = '/v1/user/products/search';
          requiresAuth = true;
        } else {
          // ✅ زائر: استخدام _governorate المخزنة
          endpoint = '/v1/user/public/products/$_governorate/search';
          requiresAuth = false;
        }
      }

      // بناء معاملات البحث (للـ Pagination والفرز)
      final Map<String, dynamic> params = {
        'page': _currentPage,
        'per_page': AppConstants.defaultPageSize,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };

      // إضافة البحث النصي إذا وجد
      if (_searchQuery.isNotEmpty) {
        params['name'] = _searchQuery;
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: requiresAuth,
        queryParams: params,
      );

      if (response.containsKey('data') && mounted) {
        List<dynamic> newProducts = [];

        if (response['data'].containsKey('products')) {
          newProducts = response['data']['products'];
        } else if (response['data'] is List) {
          newProducts = response['data'];
        }

        final pagination = response['data']['pagination'];

        if (loadMore) {
          setState(() {
            _products.addAll(newProducts);
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _products = newProducts;
            _isLoading = false;
          });
        }

        // التحقق من وجود صفحات إضافية
        if (pagination != null) {
          final currentPage = pagination['current_page'] ?? _currentPage;
          final lastPage = pagination['last_page'] ?? 1;
          setState(() {
            _hasMore = currentPage < lastPage;
            if (_hasMore) _currentPage = currentPage + 1;
          });
        } else {
          setState(() {
            _hasMore = newProducts.length >= AppConstants.defaultPageSize;
            if (_hasMore) _currentPage++;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل المنتجات';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  void _applySort(String sortLabel, String sortBy, String sortOrder) {
    setState(() {
      _selectedSort = sortLabel;
      _sortBy = sortBy;
      _sortOrder = sortOrder;
    });
    _fetchProducts();
  }

  void _search() {
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) => _searchQuery = value,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    hintStyle: GoogleFonts.cairo(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        _search();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // خيارات الفرز
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: _sortOptions.map((option) {
                    final isSelected = _selectedSort == option['label'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(option['label'], style: GoogleFonts.cairo(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) => _applySort(option['label'], option['value'], option['order']),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF4CAF50),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _products.isEmpty
          ? _buildEmptyWidget()
          : _isGridView
          ? _buildGridView()
          : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return _buildLoadingMoreIndicator();
        }
        return ProductCard(
          product: _products[index],
          apiService: widget.apiService,
          authService: widget.authService,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _products.length) {
          return _buildLoadingMoreIndicator();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProductCard(
            product: _products[index],
            apiService: widget.apiService,
            authService: widget.authService,
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: Color(0xFF4CAF50))
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchProducts,
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('لا توجد منتجات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('لا توجد منتجات في هذا القسم حالياً', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}