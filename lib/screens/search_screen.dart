import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/widgets/product_card.dart';

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

  
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  double _minRate = 0;

  
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

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'created_at', 'label': 'الأحدث', 'icon': Icons.fiber_new_rounded},
    {'value': 'rate', 'label': 'الأعلى تقييماً', 'icon': Icons.star_rounded},
    {'value': 'views', 'label': 'الأكثر مشاهدة', 'icon': Icons.visibility_rounded},
    {'value': 'price', 'label': 'السعر', 'icon': Icons.attach_money_rounded},
  ];

  final List<Map<String, dynamic>> _rateOptions = [
    {'value': 0, 'label': 'الكل', 'icon': Icons.star_border_rounded},
    {'value': 4, 'label': '4 نجوم فما فوق', 'icon': Icons.star_rounded},
    {'value': 3, 'label': '3 نجوم فما فوق', 'icon': Icons.star_half_rounded},
    {'value': 2, 'label': 'نجمتان فما فوق', 'icon': Icons.star_outline_rounded},
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
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  Future<void> _search({bool loadMore = false}) async {
    if (!loadMore && _searchQuery.trim().isEmpty) {
      return;
    }

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
      _saveRecentSearch(_searchQuery);
    }

    try {
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
        endpoint = '/v1/user/products/search';
      } else {
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
    setState(() => _showFilters = false);
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
    setState(() => _isGridView = !_isGridView);
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
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: GoogleFonts.cairo(fontSize: 15, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              hintStyle: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
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
              setState(() => _searchQuery = value);
              _search();
            },
          ),
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
              icon: Icon(
                _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8, left: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleViewMode,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFiltersPanel(),
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
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.attach_money_rounded, size: 18, color: primaryBlue),
              ),
              const SizedBox(width: 10),
              Text(
                'نطاق السعر',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                  decoration: InputDecoration(
                    hintText: 'الحد الأدنى',
                    hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.arrow_downward_rounded, size: 16, color: mediumGray),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: lightGray,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) => _minPrice = double.tryParse(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                  decoration: InputDecoration(
                    hintText: 'الحد الأعلى',
                    hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.arrow_upward_rounded, size: 16, color: mediumGray),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: lightGray,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) => _maxPrice = double.tryParse(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sort_rounded, size: 18, color: primaryBlue),
              ),
              const SizedBox(width: 10),
              Text(
                'ترتيب حسب',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _sortBy == option['value'];
              return FilterChip(
                label: Text(option['label'], style: GoogleFonts.cairo(fontSize: 13, color: isSelected ? primaryBlue : mediumGray)),
                selected: isSelected,
                onSelected: (_) => setState(() => _sortBy = option['value']),
                avatar: Icon(option['icon'], size: 16, color: isSelected ? primaryBlue : Colors.grey),
                backgroundColor: lightGray,
                selectedColor: primaryBlue.withOpacity(0.1),
                checkmarkColor: primaryBlue,
                side: BorderSide(color: isSelected ? primaryBlue.withOpacity(0.3) : Colors.grey.shade300),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'desc', label: Text('تنازلي')),
                    ButtonSegment(value: 'asc', label: Text('تصاعدي')),
                  ],
                  selected: {_sortOrder},
                  onSelectionChanged: (Set<String> selection) => setState(() => _sortOrder = selection.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: primaryBlue.withOpacity(0.12),
                    selectedForegroundColor: primaryBlue,
                    textStyle: GoogleFonts.cairo(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.withOpacity(0.15), Colors.amber.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Text(
                'الحد الأدنى للتقييم',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _rateOptions.map((option) {
              final isSelected = _minRate == option['value'];
              return FilterChip(
                label: Text(option['label'], style: GoogleFonts.cairo(fontSize: 13, color: isSelected ? Colors.amber.shade800 : mediumGray)),
                selected: isSelected,
                onSelected: (_) => setState(() => _minRate = option['value']),
                avatar: Icon(option['icon'], size: 16, color: isSelected ? Colors.amber : Colors.grey),
                backgroundColor: lightGray,
                selectedColor: Colors.amber.withOpacity(0.15),
                checkmarkColor: Colors.amber,
                side: BorderSide(color: isSelected ? Colors.amber.withOpacity(0.3) : Colors.grey.shade300),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('إعادة تعيين', style: GoogleFonts.cairo(color: mediumGray, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shadowColor: primaryBlue.withOpacity(0.3),
                  ),
                  child: Text('تطبيق', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialWidget() {
    return _recentSearches.isEmpty
        ? Center(
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
                BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: Icon(Icons.search_rounded, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text('ابحث عن منتج', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w500, color: darkColor)),
          const SizedBox(height: 8),
          Text('اكتب اسم المنتج الذي تبحث عنه', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
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
              Text('عمليات بحث حديثة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text('مسح الكل', style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _recentSearches.map((search) {
              return Chip(
                label: Text(search, style: GoogleFonts.cairo(fontSize: 13, color: darkColor)),
                onDeleted: () => setState(() => _recentSearches.remove(search)),
                deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                backgroundColor: cardWhite,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(20)),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardWhite,
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.red.shade300),
          ),
          const SizedBox(height: 20),
          Text(_errorMessage!, style: GoogleFonts.cairo(fontSize: 16, color: mediumGray)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardWhite,
              boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text('لا توجد نتائج', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w500, color: darkColor)),
          const SizedBox(height: 8),
          Text('جرب البحث بكلمة مختلفة', style: GoogleFonts.cairo(fontSize: 14, color: mediumGray)),
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
            ? const CircularProgressIndicator(color: primaryBlue)
            : const SizedBox.shrink(),
      ),
    );
  }
}