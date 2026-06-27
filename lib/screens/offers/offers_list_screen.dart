// lib/screens/offers/offers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/widgets/offer_card.dart';

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

class _OffersListScreenState extends State<OffersListScreen>
    with TickerProviderStateMixin {
  List<dynamic> _offers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  bool _isGridView = true;


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;

  final List<Map<String, dynamic>> _filterTypes = [
    {
      'key': 'all',
      'name': 'الكل',
      'icon': Icons.apps_rounded,
      'color': primaryBlue
    },
    {
      'key': 'cheapest',
      'name': 'الأرخص',
      'icon': Icons.savings_rounded,
      'color': Colors.orange
    },
    {
      'key': 'highest-power',
      'name': 'الأقوى',
      'icon': Icons.bolt_rounded,
      'color': Colors.amber
    },
    {
      'key': 'variety',
      'name': 'متنوعة',
      'icon': Icons.category_rounded,
      'color': Colors.purple
    },
    {
      'key': 'featured',
      'name': 'مميزة',
      'icon': Icons.star_rounded,
      'color': Colors.amber.shade700
    },
    {
      'key': 'latest',
      'name': 'الأحدث',
      'icon': Icons.fiber_new_rounded,
      'color': Colors.teal
    },
  ];

  String _selectedFilter = 'all';

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

    if (widget.offers != null) {
      _offers = List.from(widget.offers!);
      _isLoading = false;
    } else {
      _fetchOffers();
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
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
          _fadeAnimationController.forward(from: 0.0);
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
    HapticFeedback.lightImpact();
    setState(() => _selectedFilter = filterKey);
    _fetchOffers();
  }

  void _toggleViewMode() {
    HapticFeedback.lightImpact();
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
              child: const Icon(Icons.local_offer_rounded, color: Colors.yellow, size: 24),
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
              onPressed: _toggleViewMode,
              tooltip: _isGridView ? 'عرض القائمة' : 'عرض الشبكة',
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

  Widget _buildFilterChips() {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final filter = _filterTypes[index];
          final isSelected = _selectedFilter == filter['key'];
          final color = filter['color'] as Color;

          return TweenAnimationBuilder(
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _changeFilter(filter['key']),
                  borderRadius: BorderRadius.circular(25),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                      )
                          : LinearGradient(
                        colors: [cardWhite, Colors.grey.shade50],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                          : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter['name'],
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
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
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
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
              onPressed: _fetchOffers,
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
                width: 120,
                height: 120,
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
                  Icons.local_offer_rounded,
                  size: 60,
                  color: primaryBlue.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد عروض حالياً',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إضافة عروض جديدة قريباً',
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

  Widget _buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
            !_isLoadingMore &&
            _hasMore) {
          _fetchOffers(loadMore: true);
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
        ),
        itemCount: _offers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _offers.length) {
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
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 260,
                maxHeight: 310,
              ),
              child: OfferCard(
                offer: _offers[index],
                apiService: widget.apiService,
                authService: widget.authService,
                isListView: false,
              ),
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
          _fetchOffers(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _offers.length) {
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
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 130,
              child: OfferCard(
                offer: _offers[index],
                apiService: widget.apiService,
                authService: widget.authService,
                isListView: true,
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
}