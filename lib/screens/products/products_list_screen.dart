// lib/screens/products/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/widgets/product_card.dart';

class ProductsListScreen extends StatefulWidget {
  final String title;
  final List<dynamic>? products;
  final String? categorySlug;
  final String? subcategorySlug;
  final ApiService apiService;
  final AuthService? authService;
  final StorageService? storageService;
  final bool isSubCategory;

  const ProductsListScreen({
    super.key,
    required this.title,
    this.products,
    this.categorySlug,
    this.subcategorySlug,
    required this.apiService,
    this.authService,
    this.storageService,
    this.isSubCategory = false,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with TickerProviderStateMixin {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;
  String _searchQuery = '';
  String _governorate = 'دمشق';

  final TextEditingController _searchController = TextEditingController();

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;

  
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  String _selectedSort = 'الأحدث';

  final List<Map<String, dynamic>> _sortOptions = [
    {
      'value': 'created_at',
      'label': 'الأحدث',
      'order': 'desc',
      'icon': Icons.schedule_rounded
    },
    {
      'value': 'price',
      'label': 'الأقل سعراً',
      'order': 'asc',
      'icon': Icons.trending_up_rounded
    },
    {
      'value': 'price',
      'label': 'الأعلى سعراً',
      'order': 'desc',
      'icon': Icons.trending_down_rounded
    },
    {
      'value': 'rate',
      'label': 'الأعلى تقييماً',
      'order': 'desc',
      'icon': Icons.star_rounded
    },
    {
      'value': 'views',
      'label': 'الأكثر مشاهدة',
      'order': 'desc',
      'icon': Icons.visibility_rounded
    },
  ];

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

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadGovernorate();

    if (widget.products != null) {
      _products = List.from(widget.products!);
      _isLoading = false;
    } else {
      _fetchProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void _loadGovernorate() {
    try {
      final savedGov = StorageService().getGovernorate();
      if (savedGov != null && savedGov.isNotEmpty) {
        _governorate = savedGov;
        return;
      }
    } catch (e) {
      print('❌ Error getting governorate: $e');
    }

    if (widget.storageService != null) {
      final savedGov = widget.storageService!.getGovernorate();
      if (savedGov != null && savedGov.isNotEmpty) {
        _governorate = savedGov;
        return;
      }
    }
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

      if (widget.isSubCategory && widget.subcategorySlug != null) {
        if (widget.authService?.isAuthenticated == true) {
          endpoint = '/v1/user/products/sub-category/${widget.subcategorySlug}';
          requiresAuth = true;
        } else {
          endpoint = '/v1/user/public/products/sub-category/${widget.subcategorySlug}/$_governorate';
          requiresAuth = false;
        }
      } else if (widget.categorySlug != null && widget.categorySlug!.isNotEmpty) {
        if (widget.authService?.isAuthenticated == true) {
          endpoint = '/v1/user/products/category/${widget.categorySlug}';
          requiresAuth = true;
        } else {
          endpoint = '/v1/user/public/products/category/${widget.categorySlug}/$_governorate';
          requiresAuth = false;
        }
      } else {
        if (widget.authService?.isAuthenticated == true) {
          endpoint = '/v1/user/products/search';
          requiresAuth = true;
        } else {
          endpoint = '/v1/user/public/products/$_governorate/search';
          requiresAuth = false;
        }
      }

      final Map<String, dynamic> params = {
        'page': _currentPage,
        'per_page': AppConstants.defaultPageSize,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
      };

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
          _fadeAnimationController.forward(from: 0.0);
          _scaleAnimationController.forward(from: 0.0);
        }

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
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSort = sortLabel;
      _sortBy = sortBy;
      _sortOrder = sortOrder;
    });
    _fetchProducts();
  }

  void _search() {
    HapticFeedback.lightImpact();
    _fetchProducts();
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
                  scale: 1.0 + (_pulseAnimationController.value * 0.15),
                  child: child,
                );
              },
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.title,
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
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  key: ValueKey(_isGridView),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _isGridView = !_isGridView);
              },
              tooltip: _isGridView ? 'عرض القائمة' : 'عرض الشبكة',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: BoxDecoration(
              color: cardWhite,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchQuery = value,
                    onSubmitted: (_) => _search(),
                    style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.15),
                              secondaryBlue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: primaryBlue,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? Container(
                        margin: const EdgeInsets.all(6),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _search();
                          },
                        ),
                      )
                          : null,
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _sortOptions.length,
                    itemBuilder: (context, index) {
                      final option = _sortOptions[index];
                      final isSelected = _selectedSort == option['label'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: () => _applySort(
                              option['label'],
                              option['value'],
                              option['order'],
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                  colors: [primaryBlue, secondaryBlue],
                                )
                                    : LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option['icon'],
                                    size: 14,
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    option['label'],
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _fetchProducts(loadMore: true);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return _buildLoadingMoreIndicator();
          }
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 500 + (index * 80)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: ProductCard(
              product: _products[index],
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _fetchProducts(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return _buildLoadingMoreIndicator();
          }
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 80)),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ProductCard(
                product: _products[index],
                apiService: widget.apiService,
                authService: widget.authService,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _isLoadingMore
            ? Column(
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
                width: 50,
                height: 50,
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
            const SizedBox(height: 12),
            Text(
              'جاري تحميل المزيد...',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: mediumGray,
              ),
            ),
          ],
        )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
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
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
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
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Column(
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
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 70,
                  color: primaryBlue.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد منتجات',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد منتجات في هذا القسم حالياً',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}