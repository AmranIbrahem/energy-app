import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/constants.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService? authService;

  const SearchScreen({
    super.key,
    required this.apiService,
    this.authService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Search parameters
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'created_at'; // rate, price, views, created_at
  String _sortOrder = 'desc'; // asc, desc
  double _minRate = 0;

  // UI state
  List<dynamic> _products = [];
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;
  bool _showFilters = false;

  // Filter options
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'created_at', 'label': 'الأحدث', 'icon': Icons.fiber_new},
    {'value': 'rate', 'label': 'الأعلى تقييماً', 'icon': Icons.star},
    {'value': 'views', 'label': 'الأكثر مشاهدة', 'icon': Icons.visibility},
    {'value': 'price', 'label': 'السعر', 'icon': Icons.attach_money},
  ];

  final List<Map<String, dynamic>> _rateOptions = [
    {'value': 0, 'label': 'الكل', 'icon': Icons.star_border},
    {'value': 4, 'label': '4 نجوم فما فوق', 'icon': Icons.star},
    {'value': 3, 'label': '3 نجوم فما فوق', 'icon': Icons.star_half},
    {'value': 2, 'label': 'نجمتان فما فوق', 'icon': Icons.star_outline},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // Load from shared preferences
    // For now, using dummy data
    _recentSearches = [];
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    if (_recentSearches.contains(query)) {
      _recentSearches.remove(query);
    }
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
    // Save to shared preferences
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    // Clear from shared preferences
  }

  Future<void> _search({bool loadMore = false}) async {
    if (!loadMore && _searchQuery.trim().isEmpty) {
      return;
    }

    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      });
      _saveRecentSearch(_searchQuery);
    }

    try {
      // Build query parameters
      final Map<String, dynamic> params = {
        'page': _currentPage,
        'per_page': AppConstants.defaultPageSize,
        'sort_by': _sortBy,
        'sort_order': _sortOrder,
        'min_rate': _minRate,
      };

      if (_searchQuery.trim().isNotEmpty) {
        params['name'] = _searchQuery.trim();
      }
      if (_minPrice != null && _minPrice! > 0) {
        params['min_price'] = _minPrice;
      }
      if (_maxPrice != null && _maxPrice! > 0) {
        params['max_price'] = _maxPrice;
      }

      String endpoint;

      if (widget.authService?.isAuthenticated == true) {
        // Authenticated user
        endpoint = '/v1/user/products/search';
      } else {
        // Guest user
        final governorate = widget.authService != null
            ? await widget.authService!.storageService.getGovernorate()
            : 'دمشق';
        endpoint = '/v1/user/public/products/$governorate/search';
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: widget.authService?.isAuthenticated ?? false,
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

        // Check if has more pages
        if (pagination != null) {
          final currentPage = pagination['current_page'] ?? _currentPage;
          final lastPage = pagination['last_page'] ?? 1;
          setState(() {
            _hasMore = currentPage < lastPage;
            _currentPage = currentPage + 1;
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
          _errorMessage = response['message'] ?? 'حدث خطأ في البحث';
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

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
    _search();
  }

  void _resetFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _sortBy = 'created_at';
      _sortOrder = 'desc';
      _minRate = 0;
    });
    _search();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.cairo(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
                : null,
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            _search();
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Badge(
              // isVisible: _hasActiveFilters(),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),

          // Results
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _errorMessage != null
                ? _buildErrorWidget()
                : _products.isEmpty && _searchQuery.isEmpty
                ? _buildInitialWidget()
                : _products.isEmpty
                ? _buildEmptyWidget()
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Range
          Text(
            'نطاق السعر',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'الحد الأدنى',
                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                    prefixIcon: const Icon(Icons.attach_money, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    _minPrice = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'الحد الأعلى',
                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                    prefixIcon: const Icon(Icons.attach_money, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    _maxPrice = double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort By
          Text(
            'ترتيب حسب',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _sortBy == option['value'];
              return FilterChip(
                label: Text(
                  option['label'],
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _sortBy = option['value'];
                  });
                },
                avatar: Icon(
                  option['icon'],
                  size: 16,
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
                ),
                backgroundColor: Colors.grey.shade100,
                selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4CAF50),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Sort Order
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'desc', label: Text('تنازلي')),
                    ButtonSegment(value: 'asc', label: Text('تصاعدي')),
                  ],
                  selected: {_sortOrder},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _sortOrder = selection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                    selectedForegroundColor: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Minimum Rating
          Text(
            'الحد الأدنى للتقييم',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _rateOptions.map((option) {
              final isSelected = _minRate == option['value'];
              return FilterChip(
                label: Text(
                  option['label'],
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _minRate = option['value'];
                  });
                },
                avatar: Icon(
                  option['icon'],
                  size: 16,
                  color: isSelected ? Colors.amber : Colors.grey,
                ),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.amber.withOpacity(0.2),
                checkmarkColor: Colors.amber,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'إعادة تعيين',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'تطبيق',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _minPrice != null ||
        _maxPrice != null ||
        _sortBy != 'created_at' ||
        _sortOrder != 'desc' ||
        _minRate > 0;
  }

  Widget _buildInitialWidget() {
    return _recentSearches.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'ابحث عن منتج',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب اسم المنتج الذي تبحث عنه',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    )
        : Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات بحث حديثة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  'مسح الكل',
                  style: GoogleFonts.cairo(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _recentSearches.map((search) {
              return Chip(
                label: Text(
                  search,
                  style: GoogleFonts.cairo(),
                ),
                onDeleted: () {
                  setState(() {
                    _recentSearches.remove(search);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
        ],
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
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.refresh),
            label: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمة مختلفة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
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
        final product = _products[index];
        return ProductCard(
          product: product,
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
        final product = _products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProductCard(
            product: product,
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
            ? const CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        )
            : const SizedBox.shrink(),
      ),
    );
  }
}