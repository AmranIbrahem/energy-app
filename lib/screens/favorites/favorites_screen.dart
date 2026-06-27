// lib/screens/favorites/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/screens/offers/offer_details_screen.dart';
import 'package:GeniusHouse/widgets/product_card.dart';
import 'package:GeniusHouse/widgets/offer_card.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class FavoritesScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService? authService;

  const FavoritesScreen({
    super.key,
    required this.apiService,
    this.authService,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final FavoritesService _favoritesService = FavoritesService.instance;

  List<Map<String, dynamic>> _favoriteProducts = [];
  List<Map<String, dynamic>> _favoriteOffers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedSection = 'all';


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _animationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addObserver(this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFavoritesData();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    await _favoritesService.loadFavorites();

    setState(() {
      _favoriteProducts = List.from(_favoritesService.favoriteProducts);
      _favoriteOffers = List.from(_favoritesService.favoriteOffers);
      _isLoading = false;
      _isRefreshing = false;
    });

    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _refreshFavoritesData() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);

    await _favoritesService.loadFavorites();

    if (mounted) {
      setState(() {
        _favoriteProducts = List.from(_favoritesService.favoriteProducts);
        _favoriteOffers = List.from(_favoritesService.favoriteOffers);
        _isRefreshing = false;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _onRefresh() async {
    await _refreshFavoritesData();
    _showSnackBar('تم تحديث المفضلة', primaryBlue);
  }

  void _refreshFavorites() {
    setState(() {
      _favoriteProducts = List.from(_favoritesService.favoriteProducts);
      _favoriteOffers = List.from(_favoritesService.favoriteOffers);
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _removeProduct(int productId) async {
    HapticFeedback.mediumImpact();
    await _favoritesService.removeProduct(productId);
    _refreshFavorites();
    _showSnackBar('تم حذف المنتج من المفضلة', Colors.orange);
  }

  void _removeOffer(int offerId) async {
    HapticFeedback.mediumImpact();
    await _favoritesService.removeOffer(offerId);
    _refreshFavorites();
    _showSnackBar('تم حذف العرض من المفضلة', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
  }

  void _navigateToProduct(dynamic product) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProductDetailsScreen(
          productSlug: product['slug'],
          apiService: widget.apiService,
          authService: widget.authService,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) => _refreshFavoritesData());
  }

  void _navigateToOffer(dynamic offer) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => OfferDetailsScreen(
          offerSlug: offer['slug'],
          apiService: widget.apiService,
          authService: widget.authService,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) => _refreshFavoritesData());
  }

  @override
  Widget build(BuildContext context) {
    final bool showProducts = _selectedSection == 'all' || _selectedSection == 'products';
    final bool showOffers = _selectedSection == 'all' || _selectedSection == 'offers';

    final bool hasProducts = _favoriteProducts.isNotEmpty;
    final bool hasOffers = _favoriteOffers.isNotEmpty;
    final bool isEmpty = !_isLoading && !hasProducts && !hasOffers;

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
              child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'المفضلة',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 22),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardWhite,
              elevation: 10,
              onSelected: (value) {
                HapticFeedback.lightImpact();
                setState(() => _selectedSection = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _selectedSection == 'all'
                              ? primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: _selectedSection == 'all' ? primaryBlue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('الكل', style: GoogleFonts.cairo(fontSize: 14, color: darkColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'products',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _selectedSection == 'products'
                              ? primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          size: 18,
                          color: _selectedSection == 'products' ? primaryBlue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('المنتجات فقط', style: GoogleFonts.cairo(fontSize: 14, color: darkColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'offers',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _selectedSection == 'offers'
                              ? primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_offer_rounded,
                          size: 18,
                          color: _selectedSection == 'offers' ? primaryBlue : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('العروض فقط', style: GoogleFonts.cairo(fontSize: 14, color: darkColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryBlue,
        backgroundColor: cardWhite,
        child: isEmpty
            ? _buildEmptyState()
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            SliverToBoxAdapter(
              child: _buildStatsBanner(),
            ),


            if (showProducts && hasProducts) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'المنتجات المفضلة',
                  icon: Icons.shopping_bag_rounded,
                  count: _favoriteProducts.length,
                  color: primaryBlue,
                ),
              ),
              _buildProductsGrid(),
            ],


            if (showProducts && showOffers && hasProducts && hasOffers)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        primaryBlue.withOpacity(0.3),
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),
              ),


            if (showOffers && hasOffers) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'العروض المفضلة',
                  icon: Icons.local_offer_rounded,
                  count: _favoriteOffers.length,
                  color: Colors.orange,
                ),
              ),
              _buildOffersGrid(),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final totalFavorites = _favoriteProducts.length + _favoriteOffers.length;
    if (totalFavorites == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.08),
            secondaryBlue.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: primaryBlue.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.15),
                    secondaryBlue.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: primaryBlue,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي المفضلة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: mediumGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalFavorites عنصر',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.shopping_bag_rounded,
                count: _favoriteProducts.length,
                label: 'منتج',
                color: primaryBlue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.local_offer_rounded,
                count: _favoriteOffers.length,
                label: 'عرض',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              '${Helpers.formatNumber(count)} عنصر',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = _favoriteProducts[index];
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
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProduct(product),
                    child: ProductCard(
                      product: product,
                      apiService: widget.apiService,
                      authService: widget.authService,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _removeProduct(product['id']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _favoriteProducts.length,
        ),
      ),
    );
  }

  Widget _buildOffersGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final offer = _favoriteOffers[index];
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
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToOffer(offer),
                    child: OfferCard(
                      offer: offer,
                      apiService: widget.apiService,
                      authService: widget.authService,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _removeOffer(offer['id']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _favoriteOffers.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Center(
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
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 70,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'لا توجد مفضلات',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'المنتجات والعروض التي تضيفها إلى المفضلة\nستظهر هنا',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: mediumGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
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
            ),
          ),
        ],
      ),
    );
  }
}