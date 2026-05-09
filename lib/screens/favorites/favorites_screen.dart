import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/favorites_service.dart';
import 'package:energy_store_app/screens/products/product_details_screen.dart';
import 'package:energy_store_app/screens/offers/offer_details_screen.dart';
import 'package:energy_store_app/widgets/product_card.dart';
import 'package:energy_store_app/widgets/offer_card.dart';

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

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final FavoritesService _favoritesService = FavoritesService.instance;

  List<Map<String, dynamic>> _favoriteProducts = [];
  List<Map<String, dynamic>> _favoriteOffers = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedSection = 'all'; // all, products, offers

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();

    WidgetsBinding.instance.addObserver(this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _isRefreshing = true;
    });

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
    _showSnackBar('تم تحديث المفضلة', Colors.green);
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
    await _favoritesService.removeProduct(productId);
    _refreshFavorites();
    _showSnackBar('تم حذف المنتج من المفضلة', Colors.green);
  }

  void _removeOffer(int offerId) async {
    await _favoritesService.removeOffer(offerId);
    _refreshFavorites();
    _showSnackBar('تم حذف العرض من المفضلة', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showProducts = _selectedSection == 'all' || _selectedSection == 'products';
    final bool showOffers = _selectedSection == 'all' || _selectedSection == 'offers';

    final bool hasProducts = _favoriteProducts.isNotEmpty;
    final bool hasOffers = _favoriteOffers.isNotEmpty;
    final bool isEmpty = !_isLoading && !hasProducts && !hasOffers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'المفضلة',
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
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list, size: 20),
              ),
              onSelected: (value) {
                setState(() {
                  _selectedSection = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.grid_view, size: 20, color: Color(0xFF4CAF50)),
                      SizedBox(width: 12),
                      Text('الكل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'products',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag, size: 20, color: Color(0xFF4CAF50)),
                      SizedBox(width: 12),
                      Text('المنتجات فقط'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'offers',
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, size: 20, color: Color(0xFF4CAF50)),
                      SizedBox(width: 12),
                      Text('العروض فقط'),
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
        color: const Color(0xFF4CAF50),
        backgroundColor: Colors.white,
        child: isEmpty
            ? _buildEmptyState()
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (showProducts && hasProducts) ...[
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(
                    title: 'المنتجات المفضلة',
                    icon: Icons.shopping_bag,
                    count: _favoriteProducts.length,
                  ),
                ),
              ),
              _buildProductsGrid(),
            ],
            if (showProducts && showOffers && hasProducts && hasOffers)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ),
            if (showOffers && hasOffers) ...[
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(
                    title: 'العروض المفضلة',
                    icon: Icons.local_offer,
                    count: _favoriteOffers.length,
                  ),
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

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              Helpers.formatNumber(count),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
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
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final product = _favoriteProducts[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(
                            productSlug: product['slug'],
                            apiService: widget.apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ).then((_) {
                        _refreshFavoritesData();
                      });
                    },
                    child: ProductCard(
                      product: product,
                      apiService: widget.apiService,
                      authService: widget.authService,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _removeProduct(product['id']),
                        icon: const Icon(Icons.favorite, color: Colors.red, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
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
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final offer = _favoriteOffers[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OfferDetailsScreen(
                            offerSlug: offer['slug'],
                            apiService: widget.apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ).then((_) {
                        _refreshFavoritesData();
                      });
                    },
                    child: OfferCard(
                      offer: offer,
                      apiService: widget.apiService,
                      authService: widget.authService,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _removeOffer(offer['id']),
                        icon: const Icon(Icons.favorite, color: Colors.red, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/empty_favorites.json',
              width: 200,
              height: 200,
              repeat: true,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مفضلات',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المنتجات والعروض التي تضيفها إلى المفضلة ستظهر هنا',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
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
      ),
    );
  }
}