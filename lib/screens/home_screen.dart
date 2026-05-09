import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/utils/constants.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/storage_service.dart';
import 'package:energy_store_app/screens/categories/main_categories_screen.dart';
import 'package:energy_store_app/screens/products/products_list_screen.dart';
import 'package:energy_store_app/screens/offers/offers_list_screen.dart';
import 'package:energy_store_app/screens/search_screen.dart';
import 'package:energy_store_app/screens/favorites/favorites_screen.dart';
import 'package:energy_store_app/screens/profile/profile_screen.dart';
import 'package:energy_store_app/screens/chat/chat_screen.dart';
import 'package:energy_store_app/widgets/product_card.dart';
import 'package:energy_store_app/widgets/offer_card.dart';
import 'package:energy_store_app/widgets/category_card.dart';
import 'package:energy_store_app/screens/categories/subcategories_screen.dart';
import 'package:energy_store_app/screens/auth/login_screen.dart';
import 'package:energy_store_app/widgets/cart_badge.dart';
import 'package:energy_store_app/screens/cart/cart_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'notifications/notifications_screen.dart';
import 'package:energy_store_app/widgets/chat_overlay.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _apiService;
  int _currentIndex = 0;
  int _unreadCount = 0;
  String _governorate = 'دمشق';  // ✅ متغير المحافظة
  bool _isProductsExpanded = false;
  bool _isOffersExpanded = false;

  // Data
  List<dynamic> _advertisements = [];
  List<dynamic> _mainCategories = [];
  List<dynamic> _mostViewedProducts = [];
  List<dynamic> _topRatedProducts = [];
  List<dynamic> _latestProducts = [];
  List<dynamic> _randomProducts = [];
  List<dynamic> _featuredOffers = [];
  List<dynamic> _varietyOffers = [];
  List<dynamic> _allOffers = [];
  List<dynamic> _highestPowerOffers = [];
  List<dynamic> _cheapestOffers = [];
  List<dynamic> _latestOffers = [];

  // Loading states
  bool _isLoadingAdvertisements = true;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  bool _isLoadingOffers = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    _loadGovernorate();
    _fetchHomeData();
    _fetchUnreadCount();
  }

  void _loadGovernorate() {
    final savedGov = widget.storageService.getGovernorate();
    print('🔍 Saved governorate from storage: $savedGov');  // ✅ للتصحيح

    if (savedGov != null && savedGov.isNotEmpty) {
      setState(() {
        _governorate = savedGov;
        print('📍 Governorate set to: $_governorate');
      });
    } else {
      print('⚠️ No saved governorate found, using default: $_governorate');
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationsCount();
      if (response.containsKey('data') && mounted) {
        setState(() {
          _unreadCount = response['data']['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchHomeData() async {
    await Future.wait([
      _fetchAdvertisements(),
      _fetchMainCategories(),
      // ✅ استخدم دوال العامة التي تدعم الزائر والمستخدم
      _fetchMostViewedProductsPublic(),
      _fetchTopRatedProductsPublic(),
      _fetchLatestProductsPublic(),
      _fetchRandomProductsPublic(),
      _fetchFeaturedOffers(),
      _fetchVarietyOffers(),
      _fetchAllOffers(),
      _fetchHighestPowerOffers(),
      _fetchCheapestOffers(),
      _fetchLatestOffers(),     // إضافة
    ]);
  }

  Future<void> _fetchAdvertisements() async {
    setState(() => _isLoadingAdvertisements = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/advertisements',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _advertisements = response['data'];
          _isLoadingAdvertisements = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingAdvertisements = false);
    }
  }

  Future<void> _fetchMainCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/categories/main',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _mainCategories = response['data'];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchMostViewedProducts() async {
    try {
      final response = await _apiService.get(
        '/v1/user/products/most-viewed',
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _mostViewedProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchTopRatedProducts() async {
    try {
      final response = await _apiService.get(
        '/v1/user/products/top-rated',
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _topRatedProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchLatestProducts() async {
    try {
      final response = await _apiService.get(
        '/v1/user/products/latest',
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _latestProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchRandomProducts() async {
    try {
      final response = await _apiService.get(
        '/v1/user/products/random',
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _randomProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

// ✅ 5) العروض المميزة (موجودة بالفعل)
  Future<void> _fetchFeaturedOffers() async {
    setState(() => _isLoadingOffers = true);
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers/featured'
          : '/v1/user/public/offers/featured/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        final offers = response['data']['offers'] ?? response['data'];
        setState(() {
          _featuredOffers = offers is List ? offers : [offers];
        });
      }
    } catch (e) {}
    setState(() => _isLoadingOffers = false);
  }

  // ✅ 6) العروض الأحدث
  Future<void> _fetchLatestOffers() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers/latest'
          : '/v1/user/public/offers/latest/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        final offers = response['data']['offers'] ?? response['data'];
        setState(() {
          _latestOffers = offers is List ? offers : [offers];
        });
      }
    } catch (e) {}
  }

  // ==================== المنتجات للعامة ====================

// ✅ المنتجات العشوائية
  Future<void> _fetchRandomProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/random'
          : '/v1/user/public/products/random/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _randomProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

// ✅ المنتجات الأكثر مشاهدة للعامة
  Future<void> _fetchMostViewedProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/most-viewed'
          : '/v1/user/public/products/most-viewed/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _mostViewedProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

// ✅ المنتجات الأعلى تقييماً للعامة
  Future<void> _fetchTopRatedProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/top-rated'
          : '/v1/user/public/products/top-rated/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _topRatedProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }

// ✅ أحدث المنتجات للعامة
  Future<void> _fetchLatestProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/latest'
          : '/v1/user/public/products/latest/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && response['data'].containsKey('products') && mounted) {
        setState(() {
          _latestProducts = response['data']['products'];
        });
      }
    } catch (e) {}
  }


  // ==================== العروض ====================

// ✅ 1) اظهار العروض (جميع العروض)
  Future<void> _fetchAllOffers() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers'
          : '/v1/user/public/offers/all/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        // معالجة البيانات حسب هيكل الـ API
        if (response['data'].containsKey('offers')) {
          // المستخدم المسجل
          setState(() {
            _allOffers = response['data']['offers'];
          });
        } else if (response['data']['offers'] != null) {
          // الزائر
          setState(() {
            _allOffers = response['data']['offers'];
          });
        }
      }
    } catch (e) {}
  }

// ✅ 2) العروض الأكثر سعة
  Future<void> _fetchHighestPowerOffers() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers/highest-power'
          : '/v1/user/public/offers/highest-power/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        final offers = response['data']['offers'] ?? response['data'];
        setState(() {
          _highestPowerOffers = offers is List ? offers : [offers];
        });
      }
    } catch (e) {}
  }

// ✅ 3) العروض الأرخص
  Future<void> _fetchCheapestOffers() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers/cheapest'
          : '/v1/user/public/offers/cheapest/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        final offers = response['data']['offers'] ?? response['data'];
        setState(() {
          _cheapestOffers = offers is List ? offers : [offers];
        });
      }
    } catch (e) {}
  }

// ✅ 4) العروض المتنوعة (موجودة بالفعل ولكن للتأكيد)
  Future<void> _fetchVarietyOffers() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/offers/variety'
          : '/v1/user/public/offers/variety/$_governorate';

      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );

      if (response.containsKey('data') && mounted) {
        final offers = response['data']['offers'] ?? response['data'];
        setState(() {
          _varietyOffers = offers is List ? offers : [offers];
        });
      }
    } catch (e) {}
  }

  void _logout() async {
    // عرض رسالة تأكيد
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'تسجيل خروج',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              authService: widget.authService,
              storageService: widget.storageService,
            ),
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        ),
      ),
    ).then((_) {
      // بعد العودة من شاشة تسجيل الدخول، تحديث الحالة
      if (mounted) {
        setState(() {});
        _fetchHomeData(); // إعادة تحميل البيانات للمستخدم الجديد
      }
    });
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الرجاء تسجيل الدخول للوصول إلى هذه الميزة'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _navigateToLogin();
  }

  String _getUserName() {
    if (!widget.authService.isAuthenticated) return 'زائر';
    return 'مستخدم';
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = !widget.authService.isAuthenticated;

    return ChatOverlay(
      authService: widget.authService,
      isGuest: isGuest,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            RefreshIndicator(
              onRefresh: _fetchHomeData,
              child: CustomScrollView(
                slivers: [
                  // Advertisements Carousel
                  if (!_isLoadingAdvertisements && _advertisements.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildAdvertisementsCarousel(),
                    ),
                  // Main Categories
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'الأقسام الرئيسية',
                      onSeeAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainCategoriesScreen(
                              categories: _mainCategories,
                              apiService: _apiService,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoadingCategories)
                    SliverToBoxAdapter(child: _buildShimmerCategories())
                  else if (_mainCategories.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildMainCategories(),
                    ),
                  // Featured Offers
                  if (!_isLoadingOffers && _featuredOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'عروض مميزة',
                        icon: Icons.local_offer,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'عروض مميزة',
                                offers: _featuredOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingOffers && _featuredOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_featuredOffers),
                    ),
                  // ✅ جميع العروض (All Offers)
                  if (!_isLoadingOffers && _allOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'جميع العروض',
                        icon: Icons.list_alt,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'جميع العروض',
                                offers: _allOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingOffers && _allOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_allOffers),
                    ),
                  // ✅ العروض الأكثر سعة (Highest Power Offers)
                  if (!_isLoadingOffers && _highestPowerOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'العروض الأكثر سعة',
                        icon: Icons.flash_on,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'العروض الأكثر سعة',
                                offers: _highestPowerOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingOffers && _highestPowerOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_highestPowerOffers),
                    ),
                  // ✅ العروض الأرخص (Cheapest Offers)
                  if (!_isLoadingOffers && _cheapestOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'العروض الأرخص',
                        icon: Icons.attach_money,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'العروض الأرخص',
                                offers: _cheapestOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingOffers && _cheapestOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_cheapestOffers),
                    ),
                  // ✅ أحدث العروض (Latest Offers)
                  if (!_isLoadingOffers && _latestOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'أحدث العروض',
                        icon: Icons.fiber_new,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'أحدث العروض',
                                offers: _latestOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingOffers && _latestOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_latestOffers),
                    ),
                  // ✅ المنتجات العشوائية (Random Products)
                  if (!_isLoadingProducts && _randomProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'اقتراحات لك',
                        icon: Icons.shuffle,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsListScreen(
                                title: 'اقتراحات لك',
                                products: _randomProducts,
                                apiService: _apiService,
                                authService: widget.authService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingProducts && _randomProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_randomProducts),
                    ),
                  // ✅ المنتجات الأكثر مشاهدة (Most Viewed Products)
                  if (!_isLoadingProducts && _mostViewedProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'الأكثر مشاهدة',
                        icon: Icons.visibility,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsListScreen(
                                title: 'الأكثر مشاهدة',
                                products: _mostViewedProducts,
                                apiService: _apiService,
                                authService: widget.authService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingProducts && _mostViewedProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_mostViewedProducts),
                    ),
                  // ✅ المنتجات الأعلى تقييماً (Top Rated Products)
                  if (!_isLoadingProducts && _topRatedProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'أعلى تقييماً',
                        icon: Icons.star,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsListScreen(
                                title: 'أعلى تقييماً',
                                products: _topRatedProducts,
                                apiService: _apiService,
                                authService: widget.authService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingProducts && _topRatedProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_topRatedProducts),
                    ),
                  // ✅ أحدث المنتجات (Latest Products)
                  if (!_isLoadingProducts && _latestProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'أحدث المنتجات',
                        icon: Icons.fiber_new,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsListScreen(
                                title: 'أحدث المنتجات',
                                products: _latestProducts,
                                apiService: _apiService,
                                authService: widget.authService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!_isLoadingProducts && _latestProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_latestProducts),
                    ),
                  // Variety Offers
                  if (_varietyOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: 'عروض متنوعة',
                        icon: Icons.category,
                        onSeeAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OffersListScreen(
                                title: 'عروض متنوعة',
                                offers: _varietyOffers,
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_varietyOffers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_varietyOffers),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
            // التصنيفات (Categories) - index 1
            MainCategoriesScreen(
              categories: _mainCategories,
              apiService: _apiService,
            ),
            // ✅ المفضلة (Favorites) - index 2 (متاحة للجميع - تعمل محلياً)
            FavoritesScreen(
              authService: widget.authService,
              apiService: _apiService,
            ),
            // العروض (Offers) - index 3
            OffersListScreen(
              title: 'جميع العروض',
              offers: null,
              apiService: _apiService,
              authService: widget.authService,
            ),
            const CartScreen(),
            // حسابي (Profile) - index 5
            isGuest
                ? _buildLockedScreen('حسابي', 'يجب تسجيل الدخول لعرض معلومات حسابك')
                : ProfileScreen(
              authService: widget.authService,
              apiService: _apiService,
              onLogout: _logout,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'متجر الطاقة البديلة',
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4CAF50),
        ),
      ),
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, color: Colors.black87),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    authService: widget.authService,
                    apiService: _apiService,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.black87),
          ),
        ),
        // CartBadge(
        //   child: Container(
        //     margin: const EdgeInsets.only(right: 8),
        //     decoration: BoxDecoration(
        //       color: Colors.grey.shade100,
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: IconButton(
        //       onPressed: () {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => const CartScreen(),
        //           ),
        //         );
        //       },
        //       icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
        //     ),
        //   ),
        // ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        authService: widget.authService,
                        apiService: _apiService,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none, color: Colors.black87),
              ),
              // شارة العدد غير المقروء
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }

  Widget _buildDrawer() {
    final bool isGuest = !widget.authService.isAuthenticated;
    final String userName = _getUserName();

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4CAF50),
                    const Color(0xFF1B5E20),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.authService.isAuthenticated ? 'عميل مسجل' : 'زائر',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _navigateToLogin,
                      icon: const Icon(Icons.login, size: 16),
                      label: Text(
                        'تسجيل الدخول',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Drawer Items
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'الرئيسية',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.category_outlined,
                    title: 'التصنيفات',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_border,
                    title: 'المفضلة',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),

                  // ✅ قائمة المنتجات (قابلة للطي)
                  ExpansionTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4CAF50)),
                    title: Text(
                      'المنتجات',
                      style: GoogleFonts.cairo(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      _isProductsExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() => _isProductsExpanded = expanded);
                    },
                    children: _buildProductsSubmenu(),
                  ),

                  // ✅ قائمة العروض (قابلة للطي)
                  ExpansionTile(
                    leading: const Icon(Icons.local_offer_outlined, color: Color(0xFF4CAF50)),
                    title: Text(
                      'العروض',
                      style: GoogleFonts.cairo(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      _isOffersExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() => _isOffersExpanded = expanded);
                    },
                    children: _buildOffersSubmenu(),
                  ),

                  _buildDrawerItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'المساعد الذكي',
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        _showLoginRequired();
                      } else {
                        setState(() => _currentIndex = 4);
                      }
                    },
                    requiresAuth: true,
                    isGuest: isGuest,
                  ),
                  _buildDrawerItem(
                    icon: Icons.build,
                    title: 'صيانة',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaintenanceScreen(
                            authService: widget.authService,
                            apiService: _apiService,
                            storageService: widget.storageService,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'حسابي',
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        _showLoginRequired();
                      } else {
                        setState(() => _currentIndex = 5);
                      }
                    },
                    requiresAuth: true,
                    isGuest: isGuest,
                  ),
                  const Divider(height: 1, thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'تسجيل خروج',
                    onTap: () {
                      Navigator.pop(context);
                      if (!isGuest) {
                        _logout();
                      }
                    },
                    isDestructive: true,
                    requiresAuth: true,
                    isGuest: isGuest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool requiresAuth = false,
    bool isGuest = false,
  }) {
    if (requiresAuth && isGuest) {
      return ListTile(
        leading: Icon(icon, color: Colors.grey.shade400),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: Colors.grey.shade400,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'تسجيل دخول',
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        onTap: _navigateToLogin,
      );
    }

    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red.shade400 : const Color(0xFF4CAF50)),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color: isDestructive ? Colors.red.shade400 : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'التصنيفات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'العروض',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),  // ✅ السلة بدلاً من المساعد
            activeIcon: Icon(Icons.shopping_cart),
            label: 'السلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _buildLockedScreen(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToLogin,
              icon: const Icon(Icons.login),
              label: Text(
                'تسجيل الدخول',
                style: GoogleFonts.cairo(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertisementsCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        enlargeFactor: 0.3,
      ),
      items: _advertisements.map((ad) {
        return GestureDetector(
          onTap: () {
            if (ad['link_url'] != null && ad['link_url'].isNotEmpty) {
              // TODO: Open URL in browser
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: ad['image_path'],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(color: Colors.grey.shade300),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error, size: 50),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
              child: Text(
                'عرض الكل',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainCategories() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _mainCategories.length,
        itemBuilder: (context, index) {
          final category = _mainCategories[index];
          return CategoryCard(
            category: category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubCategoriesScreen(
                    category: category,
                    apiService: _apiService,
                    authService: widget.authService,
                    storageService: widget.storageService,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsHorizontalList(List<dynamic> products) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: products.length > 10 ? 10 : products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            apiService: _apiService,
            authService: widget.authService,
          );
        },
      ),
    );
  }

  Widget _buildOffersHorizontalList(List<dynamic> offers) {
    return SizedBox(
      height: 290,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: offers.length > 10 ? 10 : offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: OfferCard(
              offer: offer,
              apiService: _apiService,
              authService: widget.authService,

            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCategories() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        },
      ),
    );
  }
  // بناء قائمة المنتجات الفرعية
  List<Widget> _buildProductsSubmenu() {
    return [
      _buildDrawerItem(
        icon: Icons.visibility,
        title: 'الأكثر مشاهدة',
        onTap: () {
          Navigator.pop(context);
          _navigateToProductsList('الأكثر مشاهدة', 'most-viewed');
        },
      ),
      _buildDrawerItem(
        icon: Icons.star,
        title: 'أعلى تقييماً',
        onTap: () {
          Navigator.pop(context);
          _navigateToProductsList('أعلى تقييماً', 'top-rated');
        },
      ),
      _buildDrawerItem(
        icon: Icons.fiber_new,
        title: 'أحدث المنتجات',
        onTap: () {
          Navigator.pop(context);
          _navigateToProductsList('أحدث المنتجات', 'latest');
        },
      ),
      _buildDrawerItem(
        icon: Icons.shuffle,
        title: 'اقتراحات لك',
        onTap: () {
          Navigator.pop(context);
          _navigateToProductsList('اقتراحات لك', 'random');
        },
      ),
    ];
  }

// بناء قائمة العروض الفرعية
  List<Widget> _buildOffersSubmenu() {
    return [
      _buildDrawerItem(
        icon: Icons.flash_on,
        title: 'الأكثر سعة',
        onTap: () {
          Navigator.pop(context);
          _navigateToOffersList('العروض الأكثر سعة', 'highest-power');
        },
      ),
      _buildDrawerItem(
        icon: Icons.attach_money,
        title: 'الأرخص',
        onTap: () {
          Navigator.pop(context);
          _navigateToOffersList('العروض الأرخص', 'cheapest');
        },
      ),
      _buildDrawerItem(
        icon: Icons.fiber_new,
        title: 'أحدث العروض',
        onTap: () {
          Navigator.pop(context);
          _navigateToOffersList('أحدث العروض', 'latest');
        },
      ),
      _buildDrawerItem(
        icon: Icons.category,
        title: 'عروض متنوعة',
        onTap: () {
          Navigator.pop(context);
          _navigateToOffersList('عروض متنوعة', 'variety');
        },
      ),
      _buildDrawerItem(
        icon: Icons.local_offer,
        title: 'عروض مميزة',
        onTap: () {
          Navigator.pop(context);
          _navigateToOffersList('عروض مميزة', 'featured');
        },
      ),
    ];
  }

// التنقل إلى شاشة المنتجات حسب النوع
  void _navigateToProductsList(String title, String type) {
    List<dynamic> products = [];

    switch (type) {
      case 'most-viewed':
        products = _mostViewedProducts;
        break;
      case 'top-rated':
        products = _topRatedProducts;
        break;
      case 'latest':
        products = _latestProducts;
        break;
      case 'random':
        products = _randomProducts;
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsListScreen(
          title: title,
          products: products,
          apiService: _apiService,
          authService: widget.authService,
          storageService: widget.storageService,

        ),
      ),
    );
  }

// التنقل إلى شاشة العروض حسب النوع
  void _navigateToOffersList(String title, String type) {
    List<dynamic> offers = [];

    switch (type) {
      case 'highest-power':
        offers = _highestPowerOffers;
        break;
      case 'cheapest':
        offers = _cheapestOffers;
        break;
      case 'latest':
        offers = _latestOffers;
        break;
      case 'variety':
        offers = _varietyOffers;
        break;
      case 'featured':
        offers = _featuredOffers;
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OffersListScreen(
          title: title,
          offers: offers,
          apiService: _apiService,
          authService: widget.authService,
        ),
      ),
    );
  }
}
