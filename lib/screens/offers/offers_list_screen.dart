import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/constants.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/widgets/offer_card.dart';

class OffersListScreen extends StatefulWidget {
  final String title;
  final List<dynamic>? offers;
  final String? type;
  final ApiService apiService;
  final AuthService? authService;

  const OffersListScreen({
    super.key,
    required this.title,
    this.offers,
    this.type,
    required this.apiService,
    this.authService,
  });

  @override
  State<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;

  final List<Map<String, dynamic>> _filterTypes = [
    {'key': 'all', 'name': 'الكل', 'icon': Icons.apps_rounded},
    {'key': 'cheapest', 'name': 'الأرخص', 'icon': Icons.attach_money_rounded},
    {'key': 'highest-power', 'name': 'الأقوى', 'icon': Icons.bolt_rounded},
    {'key': 'variety', 'name': 'متنوعة', 'icon': Icons.category_rounded},
    {'key': 'featured', 'name': 'مميزة', 'icon': Icons.star_rounded},
    {'key': 'latest', 'name': 'الأحدث', 'icon': Icons.fiber_new_rounded},
  ];

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.offers != null) {
      _offers = List.from(widget.offers!);
      _isLoading = false;
    } else {
      _fetchOffers();
    }
  }

  Future<void> _fetchOffers({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _offers = [];
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final String endpoint;

      if (widget.authService?.isAuthenticated == true) {
        if (widget.type != null && widget.type!.isNotEmpty) {
          endpoint = '/v1/user/offers/${widget.type}';
        } else if (_selectedFilter != 'all') {
          endpoint = '/v1/user/offers/$_selectedFilter';
        } else {
          endpoint = '/v1/user/offers';
        }
      } else {
        final governorate = widget.authService != null
            ? await widget.authService!.storageService.getGovernorate()
            : 'دمشق';

        if (widget.type != null && widget.type!.isNotEmpty) {
          endpoint = '/v1/user/public/offers/${widget.type}/$governorate';
        } else if (_selectedFilter != 'all') {
          endpoint = '/v1/user/public/offers/$_selectedFilter/$governorate';
        } else {
          endpoint = '/v1/user/public/offers/all/$governorate';
        }
      }

      final response = await widget.apiService.get(
        '$endpoint?page=$_currentPage&per_page=${AppConstants.defaultPageSize}',
        requiresAuth: widget.authService?.isAuthenticated ?? false,
      );

      if (response.containsKey('data') && mounted) {
        List<dynamic> newOffers = [];

        if (response['data'].containsKey('offers')) {
          newOffers = response['data']['offers'];
        } else if (response['data'] is List) {
          newOffers = response['data'];
        }

        final pagination = response['data']['pagination'] ??
            (response.containsKey('pagination') ? response['pagination'] : null);

        if (loadMore) {
          setState(() {
            _offers.addAll(newOffers);
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _offers = newOffers;
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
            _hasMore = newOffers.length >= AppConstants.defaultPageSize;
            if (_hasMore) _currentPage++;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل العروض';
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

  void _changeFilter(String filterKey) {
    if (_selectedFilter == filterKey) return;
    setState(() => _selectedFilter = filterKey);
    _fetchOffers();
  }

  void _toggleViewMode() => setState(() => _isGridView = !_isGridView);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A1A1A)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _toggleViewMode,
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                size: 20,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.offers == null) _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _errorMessage != null
                ? _buildErrorWidget()
                : _offers.isEmpty
                ? _buildEmptyWidget()
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  // ✅ فلترات مبسطة ومصغرة - الحل النهائي لمشكلة التجاوز
  Widget _buildFilterChips() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final filter = _filterTypes[index];
          final isSelected = _selectedFilter == filter['key'];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _changeFilter(filter['key']),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter['icon'],
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter['name'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
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
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: const Color(0xFFE0E0E0),
        highlightColor: const Color(0xFFF5F5F5),
        child: Container(
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchOffers,
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer_outlined, size: 60, color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد عروض حالياً',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4A4A4A)),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة عروض جديدة قريباً',
            style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF9E9E9E)),
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
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _offers.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _offers.length) return _buildLoadingMoreIndicator();
        return Container(
          constraints: const BoxConstraints(
            minHeight: 260,
            maxHeight: 300,
          ),
          child: OfferCard(
            offer: _offers[index],
            apiService: widget.apiService,
            authService: widget.authService,
            isListView: false, // ✅ شبكي
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _offers.length) return _buildLoadingMoreIndicator();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 125,
          child: OfferCard(
            offer: _offers[index],
            apiService: widget.apiService,
            authService: widget.authService,
            isListView: true, // ✅ قائمة
          ),
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(
          color: Color(0xFF4CAF50),
          strokeWidth: 3,
        )
            : const SizedBox.shrink(),
      ),
    );
  }
}