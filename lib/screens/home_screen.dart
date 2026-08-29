import 'package:GeniusHouse/screens/settings_screen.dart';
import 'package:GeniusHouse/screens/system_builder/system_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/screens/categories/main_categories_screen.dart';
import 'package:GeniusHouse/screens/products/products_list_screen.dart';
import 'package:GeniusHouse/screens/offers/offers_list_screen.dart';
import 'package:GeniusHouse/screens/search_screen.dart';
import 'package:GeniusHouse/screens/favorites/favorites_screen.dart';
import 'package:GeniusHouse/screens/profile/profile_screen.dart';
import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/widgets/HomeProductCard.dart';
import 'package:GeniusHouse/widgets/HomeOfferCard.dart';
import 'package:GeniusHouse/screens/categories/subcategories_screen.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import 'package:GeniusHouse/screens/cart/cart_screen.dart';
import '../widgets/category_card.dart';
import 'comparison/comparison_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'notifications/notifications_screen.dart';
import 'package:GeniusHouse/widgets/chat_overlay.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/screens/solar_systems/solar_systems_screen.dart';
import 'package:GeniusHouse/services/text_ad_service.dart';
import 'package:GeniusHouse/widgets/text_ads_carousel.dart';
import 'package:GeniusHouse/screens/company/company_dashboard_screen.dart';
import 'package:GeniusHouse/screens/complaints/add_complaint_screen.dart';
import 'package:GeniusHouse/screens/profile/order_tracking_screen.dart';
import 'package:GeniusHouse/screens/workshop/workshop_request_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:GeniusHouse/screens/appliances/appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_maintenance_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_maintenance_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_schedule_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_schedule_screen.dart';
import 'package:GeniusHouse/screens/chat/support_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_support_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_solar_chat_screen.dart';


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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _textAds = [];
  bool _isLoadingTextAds = true;
  late ApiService _apiService;
  int _currentIndex = 0;
  int _unreadCount = 0;
  String _governorate = 'دمشق';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _quickActionsExpanded = false;
  List<String> _customQuickActions = [];
  List<String> _tempSelectedQuickActions = [];
  bool _isCustomizingQuickActions = false;
  String _greetingMessage = 'مرحباً';
  Map<String, dynamic>? _activeRequestsStats;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color successGreen = Color(0xFF10B981);  // ✅ أضف هذا
  bool _showActiveRequestsDetails = false;  // ✅ متغير جديد للطي

  late AnimationController _drawerAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _centerPulseController;
  late AnimationController _quickActionsAnimationController;

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
  List<dynamic> _ElectricalAppliances = [];
  List<dynamic> _ElectricalExtensions = [];
  List<dynamic> _Homelighting = [];

  bool _isLoadingAdvertisements = true;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  bool _isLoadingOffers = true;
  bool _isLoadingElectricalAppliances = true;
  bool _isLoadingElectricalExtensions = true;
  bool _isLoadingHomelighting = true;

  ScrollController? _scrollController;
  bool _showScrollToTop = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);

    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _centerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _quickActionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _scrollController = ScrollController();
    _scrollController!.addListener(_scrollListener);
    _loadCustomQuickActions();

    _loadGovernorate();
    _updateGreeting();
    _fetchHomeData();
    _fetchUnreadCount();
    if (widget.authService.isAuthenticated) {
      _fetchActiveRequestsStats();
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_scrollListener);
    _scrollController?.dispose();

    _drawerAnimationController.dispose();
    _pulseAnimationController.dispose();
    _centerPulseController.dispose();
    _quickActionsAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController == null) return;
    final shouldShow = _scrollController!.offset > 500;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    _scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  void _updateGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    setState(() {
      if (hour >= 5 && hour < 12) {
        _greetingMessage = 'صباح الخير';
      } else if (hour >= 12 && hour < 17) {
        _greetingMessage = 'مساء الخير';
      } else if (hour >= 17 && hour < 21) {
        _greetingMessage = 'مساء الخير';
      } else {
        _greetingMessage = 'مساء الخير';
      }
    });
  }

  void _onCenterTap() {
    setState(() => _currentIndex = 0);
  }

  void _loadGovernorate() {
    final savedGov = widget.storageService.getGovernorate();
    if (savedGov != null && savedGov.isNotEmpty) {
      setState(() => _governorate = savedGov);
    }
  }

  Widget _buildActiveRequestsStats() {
    if (_activeRequestsStats == null) return const SizedBox.shrink();

    final summary = _activeRequestsStats!['summary'] as Map<String, dynamic>? ?? {};
    final workshop = _activeRequestsStats!['workshop_requests'] as Map<String, dynamic>? ?? {};
    final store = _activeRequestsStats!['store_orders'] as Map<String, dynamic>? ?? {};
    final solar = _activeRequestsStats!['solar_system_orders'] as Map<String, dynamic>? ?? {};

    final totalActive = summary['total_active_requests'] ?? 0;
    final pending = summary['pending_requests'] ?? 0;
    final processing = summary['processing_requests'] ?? 0;

    // ✅ إذا لا توجد طلبات → لا يظهر
    if (totalActive == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ العنوان مع زر العرض
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.05)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: primaryBlue, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'طلباتك النشطة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(
                          authService: widget.authService,
                          apiService: _apiService,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض الكل',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, color: primaryBlue, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ الأرقام الرئيسية (مصغرة)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniStat(
                  icon: Icons.receipt_long_rounded,
                  value: totalActive.toString(),
                  label: 'إجمالي',
                  color: Colors.white,
                ),
                _buildMiniStat(
                  icon: Icons.hourglass_top_rounded,
                  value: pending.toString(),
                  label: 'انتظار',
                  color: Colors.amber,
                ),
                _buildMiniStat(
                  icon: Icons.autorenew_rounded,
                  value: processing.toString(),
                  label: 'معالجة',
                  color: Colors.cyan,
                ),
              ],
            ),
          ),

          // ✅ زر التفاصيل (للطي)
          GestureDetector(
            onTap: () {
              setState(() {
                _showActiveRequestsDetails = !_showActiveRequestsDetails;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showActiveRequestsDetails ? 'إخفاء التفاصيل' : 'عرض التفاصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mediumGray,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showActiveRequestsDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: mediumGray,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // ✅ التفاصيل عند الطي
          if (_showActiveRequestsDetails) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTypeItem(
                    icon: Icons.build_rounded,
                    label: 'ورشة',
                    value: (workshop['total_active'] ?? 0).toString(),
                    color: Colors.orange,
                  ),
                  _buildTypeItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'متجر',
                    value: (store['total_active'] ?? 0).toString(),
                    color: Colors.green,
                  ),
                  _buildTypeItem(
                    icon: Icons.solar_power_rounded,
                    label: 'منظومة',
                    value: (solar['total_active'] ?? 0).toString(),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
  // ✅ دالة بناء عنصر إحصائي مصغر
  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: mediumGray,
          ),
        ),
      ],
    );
  }

// ✅ دالة بناء عنصر نوع
  Widget _buildTypeItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
          ),
        ),
      ],
    );
  }

// مكان: بعد _loadGovernorate أو قبل _fetchTextAds
  Future<void> _fetchActiveRequestsStats() async {
    if (!widget.authService.isAuthenticated) return;

    try {
      final response = await _apiService.get(
        '/v1/user/dashboard/active-requests-stats',
        requiresAuth: true,
      );

      if (response['success'] == true && mounted) {
        setState(() {
          _activeRequestsStats = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching active requests stats: $e');
    }
  }


  // ✅ جلب الأيقونات المخصصة من التخزين
  Future<void> _loadCustomQuickActions() async {
    final savedActions = widget.storageService.getCustomQuickActions();
    final isExpanded = widget.storageService.isQuickActionsExpanded();

    if (savedActions.isEmpty) {
      // ✅ إذا لم يخصص المستخدم من قبل → استخدام الأيقونات الافتراضية
      _customQuickActions = _getDefaultQuickActions();
    } else {
      _customQuickActions = savedActions;
    }

    if (mounted) {
      setState(() {
        _quickActionsExpanded = isExpanded;
        _tempSelectedQuickActions = List.from(_customQuickActions);
      });
    }
  }

  // ✅ الحصول على الأيقونات الافتراضية (5 أيقونات)
  List<String> _getDefaultQuickActions() {
    final List<String> defaults = ['comparisons', 'maintenance', 'system_builder', 'workshop', 'order_tracking'];
    if (!widget.authService.isAuthenticated) {
      defaults.remove('order_tracking');
    }
    return defaults;
  }
  // ✅ حفظ الأيقونات المخصصة في التخزين
  Future<void> _saveCustomQuickActions() async {
    await widget.storageService.saveCustomQuickActions(_customQuickActions);
    await widget.storageService.saveQuickActionsExpanded(_quickActionsExpanded);
  }

  // ✅ تبديل حالة "إظهار الكل/إخفاء"
  void _toggleQuickActionsExpanded() {
    setState(() {
      _quickActionsExpanded = !_quickActionsExpanded;
    });
    _saveCustomQuickActions();
  }

  // ✅ عرض نافذة التخصيص
  void _showQuickActionsCustomization() {
    setState(() {
      _isCustomizingQuickActions = true;
      _tempSelectedQuickActions = List.from(_customQuickActions);
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionsCustomizationSheet(),
    );
  }

  // ✅ نافذة التخصيص (Bottom Sheet)
  Widget _buildQuickActionsCustomizationSheet() {
    final allActions = _getAllQuickActions();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ مؤشر السحب
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.05)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تخصيص الإجراءات السريعة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      Text(
                        'اختر الأيقونات التي تريد ظهورها',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ قائمة الأيقونات
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allActions.length,
                itemBuilder: (context, index) {
                  final action = allActions[index];
                  final isSelected = _tempSelectedQuickActions.contains(action['id'] as String);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _tempSelectedQuickActions.remove(action['id'] as String);
                        } else {
                          _tempSelectedQuickActions.add(action['id'] as String);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [primaryBlue.withOpacity(0.08), secondaryBlue.withOpacity(0.04)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        )
                            : null,
                        color: isSelected ? null : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? primaryBlue.withOpacity(0.3) : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (action['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              action['label'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? Icons.check_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ✅ أزرار الحفظ والإلغاء
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _isCustomizingQuickActions = false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _customQuickActions = List.from(_tempSelectedQuickActions);
                        _isCustomizingQuickActions = false;
                      });
                      _saveCustomQuickActions();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'حفظ التخصيص',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ✅ الحصول على كل الإجراءات المتاحة
  List<Map<String, dynamic>> _getAllQuickActions() {
    final bool isGuest = !widget.authService.isAuthenticated;

    final List<Map<String, dynamic>> allActions = [
      {
        'id': 'comparisons',
        'icon': Icons.compare_arrows_rounded,
        'label': 'المقارنات',
        'color': const Color(0xFF6366F1),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonScreen(
                apiService: _apiService,
                authService: widget.authService,
              ),
            ),
          );
        },
      },
      {
        'id': 'maintenance',
        'icon': Icons.build_rounded,
        'label': 'صيانة',
        'color': const Color(0xFFF59E0B),
        'onTap': () {
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
      },
      {
        'id': 'system_builder',
        'icon': Icons.design_services_rounded,
        'label': 'تصميم منظومة',
        'color': const Color(0xFF3B82F6),
        'onTap': _navigateToSystemBuilder,
      },
      {
        'id': 'workshop',
        'icon': Icons.handyman_rounded,
        'label': 'طلب ورشة',
        'color': const Color(0xFFEF4444),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkshopRequestScreen(
                authService: widget.authService,
                apiService: _apiService,
              ),
            ),
          );
        },
      },
      if (!isGuest)
        {
          'id': 'order_tracking',
          'icon': Icons.local_shipping_rounded,
          'label': 'تتبع طلباتي',
          'color': const Color(0xFF10B981),
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderTrackingScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          },
        },
      {
        'id': 'compatibility_check',
        'icon': Icons.check_circle_outline_rounded,
        'label': 'فحص توافق المكونات',
        'color': const Color(0xFF06B6D4),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestApplianceCompatibilityScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplianceCompatibilityScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
      {
        'id': 'smart_maintenance',
        'icon': Icons.electrical_services_rounded,
        'label': 'الصيانة الذكية',
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestApplianceMaintenanceScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplianceMaintenanceScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
      {
        'id': 'savings_calculator',
        'icon': Icons.calculate_rounded,
        'label': 'حاسبة توفير الإنفرتر',
        'color': const Color(0xFF10B981),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestApplianceSavingsScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplianceSavingsScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
      {
        'id': 'appliance_schedule',
        'icon': Icons.schedule_rounded,
        'label': 'جدولة تشغيل الأجهزة',
        'color': const Color(0xFFF59E0B),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestApplianceScheduleScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplianceScheduleScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
      {
        'id': 'solar_support',
        'icon': Icons.support_agent_rounded,
        'label': 'دعم بشري للطاقة',
        'color': const Color(0xFF6366F1),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestSupportSolarChatScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SupportSolarChatScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
      {
        'id': 'solar_qa',
        'icon': Icons.help_outline_rounded,
        'label': 'أسئلة واستفسارات',
        'color': const Color(0xFFEF4444),
        'onTap': () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestSolarChatScreen(
                  apiService: _apiService,
                  storageService: widget.storageService,
                  initialGovernorate: widget.storageService.getGuestGovernorate(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SolarChatScreen(
                  authService: widget.authService,
                  apiService: _apiService,
                ),
              ),
            );
          }
        },
      },
    ];

    return allActions;
  }

  Future<void> _fetchTextAds() async {
    setState(() => _isLoadingTextAds = true);
    try {
      final TextAdService textAdService = TextAdService(
        baseUrl: AppConstants.baseUrl,
        authService: widget.authService,
      );
      final ads = await textAdService.getActiveTextAds();
      if (mounted) {
        setState(() {
          _textAds = ads;
          _isLoadingTextAds = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTextAds = false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadNotificationsCount();
      if (response.containsKey('data') && mounted) {
        setState(() => _unreadCount = response['data']['unread_count'] ?? 0);
      }
    } catch (e) {}
  }

  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoadingProducts = true;
      _isLoadingOffers = true;
      _isLoadingTextAds = true;
    });

    await Future.wait([
      _fetchTextAds(),
      _fetchAdvertisements(),
      _fetchMainCategories(),
      _fetchElectricalAppliances(),
      _fetchElectricalExtensions(),
      _fetchHomelighting(),
    ]);

    if (mounted) {
      setState(() {
        _isInitialLoad = false;
        _isLoadingTextAds = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    await Future.wait([
      _fetchMostViewedProductsPublic(),
      _fetchTopRatedProductsPublic(),
      _fetchLatestProductsPublic(),
      _fetchRandomProductsPublic(),
      _fetchFeaturedOffers(),
      _fetchVarietyOffers(),
      _fetchAllOffers(),
      _fetchHighestPowerOffers(),
      _fetchCheapestOffers(),
      _fetchLatestOffers(),
    ]);

    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
        _isLoadingOffers = false;
      });
      _quickActionsAnimationController.forward(from: 0);
    }
  }

  Future<void> _fetchAdvertisements() async {
    setState(() => _isLoadingAdvertisements = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/advertisements',
        requiresAuth: false,
      );

      if (response.containsKey('data') && mounted) {
        final data = response['data'];

        List<dynamic> advertisements = [];

        // ✅ التحقق من البنية الصحيحة للبيانات
        if (data is Map && data.containsKey('advertisements')) {
          // البيانات في شكل {advertisements: [...], total: 3}
          advertisements = List<dynamic>.from(data['advertisements'] ?? []);
        } else if (data is List) {
          // البيانات مباشرة في شكل قائمة
          advertisements = data;
        }

        setState(() {
          _advertisements = advertisements;
          _isLoadingAdvertisements = false;
        });

        debugPrint('✅ Advertisements loaded: ${_advertisements.length}');
      } else {
        if (mounted) {
          setState(() => _isLoadingAdvertisements = false);
          _advertisements = [];
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching advertisements: $e');
      if (mounted) {
        setState(() {
          _isLoadingAdvertisements = false;
          _advertisements = [];
        });
      }
    }
  }

  Future<void> _fetchMainCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/categories/main/random',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _mainCategories = response['data'];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchElectricalAppliances() async {
    setState(() => _isLoadingElectricalAppliances = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/categories/main/7/subcategories',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _ElectricalAppliances = response['data'];
          _isLoadingElectricalAppliances = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingElectricalAppliances = false);
    }
  }

  Future<void> _fetchElectricalExtensions() async {
    setState(() => _isLoadingElectricalExtensions = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/categories/main/9/subcategories',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _ElectricalExtensions = response['data'];
          _isLoadingElectricalExtensions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingElectricalExtensions = false);
    }
  }

  Future<void> _fetchHomelighting() async {
    setState(() => _isLoadingHomelighting = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/categories/main/10/subcategories',
        requiresAuth: false,
      );
      if (response.containsKey('data') && mounted) {
        setState(() {
          _Homelighting = response['data'];
          _isLoadingHomelighting = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHomelighting = false);
    }
  }

  Future<void> _fetchFeaturedOffers() async {
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
        setState(() => _featuredOffers = offers is List ? offers : [offers]);
      }
    } catch (e) {}
  }

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
        setState(() => _latestOffers = offers is List ? offers : [offers]);
      }
    } catch (e) {}
  }

  Future<void> _fetchRandomProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/random'
          : '/v1/user/public/products/random/$_governorate';
      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && mounted) {
        if (response['data'].containsKey('products')) {
          setState(() => _randomProducts = response['data']['products']);
        } else if (response['data'] is List) {
          setState(() => _randomProducts = response['data']);
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchMostViewedProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/most-viewed'
          : '/v1/user/public/products/most-viewed/$_governorate';
      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && mounted) {
        if (response['data'].containsKey('products')) {
          setState(() => _mostViewedProducts = response['data']['products']);
        } else if (response['data'] is List) {
          setState(() => _mostViewedProducts = response['data']);
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchTopRatedProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/top-rated'
          : '/v1/user/public/products/top-rated/$_governorate';
      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && mounted) {
        if (response['data'].containsKey('products')) {
          setState(() => _topRatedProducts = response['data']['products']);
        } else if (response['data'] is List) {
          setState(() => _topRatedProducts = response['data']);
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchLatestProductsPublic() async {
    try {
      final endpoint = widget.authService.isAuthenticated
          ? '/v1/user/products/latest'
          : '/v1/user/public/products/latest/$_governorate';
      final response = await _apiService.get(
        endpoint,
        requiresAuth: widget.authService.isAuthenticated,
      );
      if (response.containsKey('data') && mounted) {
        if (response['data'].containsKey('products')) {
          setState(() => _latestProducts = response['data']['products']);
        } else if (response['data'] is List) {
          setState(() => _latestProducts = response['data']);
        }
      }
    } catch (e) {}
  }

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
        if (response['data'].containsKey('offers')) {
          setState(() => _allOffers = response['data']['offers']);
        } else if (response['data'] is List) {
          setState(() => _allOffers = response['data']);
        }
      }
    } catch (e) {}
  }

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
        setState(
            () => _highestPowerOffers = offers is List ? offers : [offers]);
      }
    } catch (e) {}
  }

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
        setState(() => _cheapestOffers = offers is List ? offers : [offers]);
      }
    } catch (e) {}
  }

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
        setState(() => _varietyOffers = offers is List ? offers : [offers]);
      }
    } catch (e) {}
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج',
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: darkColor)),
        content: Text('هل أنت متأكد من تسجيل الخروج؟',
            style: GoogleFonts.cairo(color: mediumGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تسجيل خروج',
                style: GoogleFonts.cairo(color: Colors.white)),
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
      if (mounted) {
        setState(() {});
        _fetchHomeData();
      }
    });
  }

  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'الرجاء تسجيل الدخول للوصول إلى هذه الميزة',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
    _navigateToLogin();
  }

  String _getUserName() =>
      !widget.authService.isAuthenticated ? 'زائر' : 'مستخدم';

  void _navigateToSystemBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SystemBuilderScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = !widget.authService.isAuthenticated;
    return ChatOverlay(
      authService: widget.authService,
      isGuest: isGuest,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeBody(),
            MainCategoriesScreen(
              apiService: _apiService,
              authService: widget.authService,
              storageService: widget.storageService,
            ),
            FavoritesScreen(
                authService: widget.authService, apiService: _apiService),
            OffersListScreen(
                title: 'جميع العروض',
                offers: null,
                apiService: _apiService,
                authService: widget.authService),
            CartScreen(
              apiService: _apiService,
              authService: widget.authService,
            ),
            isGuest
                ? _buildLockedScreen(
                    'حسابي', 'يجب تسجيل الدخول لعرض معلومات حسابك')
                : ProfileScreen(
                    authService: widget.authService,
                    apiService: _apiService,
                    onLogout: _logout,
                  ),
          ],
        ),
        bottomNavigationBar: _buildCenterHubNavBar(),
      ),
    );
  }

  Widget _buildHomeBody() {
    return Stack(
      children: [
        RefreshIndicator(
          color: primaryBlue,
          backgroundColor: Colors.white,
          onRefresh: _fetchHomeData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildGreetingWidget()),
              if (widget.authService.isAuthenticated && _activeRequestsStats != null)
                SliverToBoxAdapter(child: _buildActiveRequestsStats()),
              if (!_isInitialLoad) ...[
                if (!_isLoadingTextAds && _textAds.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextAdsCarousel(
                          ads: _textAds, interval: const Duration(seconds: 4)),
                    ),
                  ),
                if (!_isLoadingAdvertisements && _advertisements.isNotEmpty)
                  SliverToBoxAdapter(child: _buildAdvertisementsCarousel()),
                SliverToBoxAdapter(child: _buildSocialProofBar()),
                SliverToBoxAdapter(child: _buildQuickActionsBar()),
              ],
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: 'الأقسام الرئيسية',
                  icon: Icons.grid_view_rounded,
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainCategoriesScreen(
                        apiService: _apiService,
                        authService: widget.authService,
                        storageService: widget.storageService,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoadingCategories)
                SliverToBoxAdapter(child: _buildShimmerCategories())
              else if (_mainCategories.isNotEmpty)
                SliverToBoxAdapter(child: _buildMainCategories()),
              if (_isLoadingElectricalAppliances)
                SliverToBoxAdapter(child: _buildShimmerSubCategories())
              else if (_ElectricalAppliances.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'أجهزة كهربائية',
                    icon: Icons.kitchen_rounded,
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoriesScreen(
                          category: {
                            'id': 7,
                            'name_ar': 'أجهزة كهربائية',
                            'slug': 'aghz-khrbayy',
                            'description': 'جميع أجهزة كهربائية الحديثة',
                          },
                          apiService: _apiService,
                          authService: widget.authService,
                          storageService: widget.storageService,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child:
                      _buildSubCategoriesHorizontalList(_ElectricalAppliances),
                ),
              ],
              if (_isLoadingElectricalExtensions)
                SliverToBoxAdapter(child: _buildShimmerSubCategories())
              else if (_ElectricalExtensions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'تمديدات كهربائية',
                    icon: Icons.electrical_services,
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoriesScreen(
                          category: {
                            'id': 9,
                            'name_ar': 'تمديدات كهربائية',
                            'slug': 'tmdydat-khrbayy',
                            'description': 'جميع تمديدات الكهربائية الحديثة',
                          },
                          apiService: _apiService,
                          authService: widget.authService,
                          storageService: widget.storageService,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child:
                      _buildSubCategoriesHorizontalList(_ElectricalExtensions),
                ),
              ],
              if (_isLoadingHomelighting)
                SliverToBoxAdapter(child: _buildShimmerSubCategories())
              else if (_Homelighting.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'إنارة منزلية',
                    icon: Icons.lightbulb_rounded,
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoriesScreen(
                          category: {
                            'id': 10,
                            'name_ar': 'إنارة منزلية',
                            'slug': 'anar-mnzly',
                            'description':
                                'جميع حلول الإضاءة الداخلية والخارجية للمنزل والمكتب، من المصابيح الموفرة للطاقة إلى الثريات الفاخرة، مع تشكيلة واسعة من الأضواء الذكية والمزودة بحساسات.',
                          },
                          apiService: _apiService,
                          authService: widget.authService,
                          storageService: widget.storageService,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSubCategoriesHorizontalList(_Homelighting),
                ),
              ],
              if (!_isInitialLoad) ...[
                if (_mostViewedProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'المنتجات الأكثر مشاهدة',
                      icon: Icons.trending_up,
                      onSeeAll: () => Navigator.push(
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
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_mostViewedProducts)),
                ],
                if (_topRatedProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'منتجات مميزة',
                      icon: Icons.star_rounded,
                      onSeeAll: () => Navigator.push(
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
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_topRatedProducts)),
                ],
                if (_featuredOffers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'عروض مميزة',
                      icon: Icons.local_fire_department,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffersListScreen(
                            title: 'عروض مميزة',
                            offers: _featuredOffers,
                            apiService: _apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_featuredOffers)),
                ],
                if (_latestProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'أحدث المنتجات',
                      icon: Icons.new_releases,
                      onSeeAll: () => Navigator.push(
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
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_latestProducts)),
                ],
                if (_highestPowerOffers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'أقوى العروض',
                      icon: Icons.bolt,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffersListScreen(
                            title: 'العروض الأكثر سعة',
                            offers: _highestPowerOffers,
                            apiService: _apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_highestPowerOffers)),
                ],
                if (_randomProducts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'اقتراحات لك',
                      icon: Icons.auto_awesome,
                      onSeeAll: () => Navigator.push(
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
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildProductsHorizontalList(_randomProducts)),
                ],
                if (_cheapestOffers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'أفضل الأسعار',
                      icon: Icons.savings,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffersListScreen(
                            title: 'العروض الأرخص',
                            offers: _cheapestOffers,
                            apiService: _apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_cheapestOffers)),
                ],
                if (_latestOffers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: 'أحدث العروض',
                      icon: Icons.new_releases_outlined,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OffersListScreen(
                            title: 'أحدث العروض',
                            offers: _latestOffers,
                            apiService: _apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _buildOffersHorizontalList(_latestOffers)),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 130)),
            ],
          ),
        ),
        if (_showScrollToTop)
          Positioned(
            bottom: 20,
            left: 20,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _scrollToTop,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: primaryBlue,
      elevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      expandedHeight: 125,
      collapsedHeight: 56,
      leading: Builder(
        builder: (context) => Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_pulseAnimationController.value * 0.1),
              child: const Icon(Icons.bolt, color: Colors.yellow, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'NEX',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.notifications_outlined,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(
                authService: widget.authService,
                apiService: _apiService,
              ),
            ),
          ),
          badge: _unreadCount > 0 ? _unreadCount.toString() : null,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchScreen(
                          authService: widget.authService,
                          apiService: _apiService,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: Colors.white.withOpacity(0.8), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ابحث عن ألواح شمسية، بطاريات، انفرترات...',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mic_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  'صوتي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingWidget() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: accentBlue.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E3A8A),
                      const Color(0xFF2563EB),
                      const Color(0xFF3B82F6).withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -30,
                right: -25,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1.5),
                  ),
                ),
              ),
              Positioned(
                bottom: -35,
                left: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        final scale =
                            1.0 + (_pulseAnimationController.value * 0.12);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getGreetingIcon(),
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_greetingMessage، ${_getUserName()}',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWelcomeSubtitle(),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 17) return '☀️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }

  String _getWelcomeSubtitle() {
    if (widget.authService.isAuthenticated) {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        return 'نتمنى لك صباحاً جميلاً مليئاً بالإنجازات';
      } else if (hour >= 12 && hour < 17) {
        return 'استمتع بتصفح أحدث منتجاتنا وعروضنا المميزة';
      } else if (hour >= 17 && hour < 21) {
        return 'تصفح عروض المساء الحصرية قبل انتهائها';
      } else {
        return 'مساء الخير، اكتشف جديدنا واستعد للغد';
      }
    }
    return 'سجل دخولك الآن للاستفادة من جميع الميزات';
  }

  Widget _buildSocialProofBar() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF059669).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'موثوق من قبل آلاف العملاء',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialStat(
                  icon: Icons.people_rounded,
                  value: '+15,000',
                  label: 'عميل سعيد',
                  color: const Color(0xFF6366F1),
                ),
                _buildSocialStat(
                  icon: Icons.shopping_bag_rounded,
                  value: '+25,000',
                  label: 'منتج مباع',
                  color: const Color(0xFFF59E0B),
                ),
                _buildSocialStat(
                  icon: Icons.star_rounded,
                  value: '4.8',
                  label: 'تقييم العملاء',
                  color: const Color(0xFF10B981),
                ),
                _buildSocialStat(
                  icon: Icons.support_agent_rounded,
                  value: '24/7',
                  label: 'دعم فني',
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: mediumGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildQuickActionsBar() {
    final bool isGuest = !widget.authService.isAuthenticated;
    final List<Map<String, dynamic>> allActions = _getAllQuickActions();
    final List<Map<String, dynamic>> visibleActions = allActions
        .where((action) => _customQuickActions.contains(action['id'] as String))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ عنوان القسم مع زر إظهار الكل
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'إجراءات سريعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const Spacer(),
                // ✅ زر "إظهار الكل" أو "إخفاء"
                GestureDetector(
                  onTap: _toggleQuickActionsExpanded,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _quickActionsExpanded
                          ? primaryBlue.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _quickActionsExpanded
                            ? primaryBlue.withOpacity(0.3)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _quickActionsExpanded ? 'إخفاء' : 'إظهار الكل',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _quickActionsExpanded ? primaryBlue : mediumGray,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _quickActionsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _quickActionsExpanded ? primaryBlue : mediumGray,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ الأيقونات المرئية - قابلة للتحريك أفقياً
          if (visibleActions.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: visibleActions.length,
                itemBuilder: (context, index) {
                  final action = visibleActions[index];
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.7 + (0.3 * value),
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: action['onTap'] as VoidCallback,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: (action['color'] as Color).withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (action['color'] as Color).withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                action['icon'] as IconData,
                                color: action['color'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 70,
                              child: Text(
                                action['label'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: darkColor,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ✅ عند "إظهار الكل" → عرض كل الأيقونات مع إمكانية الاختيار
          if (_quickActionsExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'اختر الإجراءات التي تريد ظهورها:',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mediumGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: allActions.length,
                      itemBuilder: (context, index) {
                        final action = allActions[index];
                        final isSelected = _customQuickActions.contains(action['id'] as String);
                        return GestureDetector(
                          onTap: () => _toggleActionSelection(action['id'] as String),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (action['color'] as Color).withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? (action['color'] as Color).withOpacity(0.2)
                                          : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    action['icon'] as IconData,
                                    color: isSelected
                                        ? action['color'] as Color
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    action['label'] as String,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? darkColor : Colors.grey.shade500,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // ✅ علامة الاختيار
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? successGreen : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check_rounded : Icons.add_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _toggleActionSelection(String actionId) {
    setState(() {
      if (_customQuickActions.contains(actionId)) {
        _customQuickActions.remove(actionId);
      } else {
        _customQuickActions.add(actionId);
      }
    });
    _saveCustomQuickActions();
  }

  Widget _buildMainCategories() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _mainCategories.length,
        itemBuilder: (context, index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: child,
            ),
          ),
          child: CategoryCard(
            category: _mainCategories[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubCategoriesScreen(
                  category: _mainCategories[index],
                  apiService: _apiService,
                  authService: widget.authService,
                  storageService: widget.storageService,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Stack(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badge,
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
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final bool isGuest = !widget.authService.isAuthenticated;
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, Colors.white, Colors.white],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, double value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_nex_icon.jpg',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_rounded,
                                  size: 50, color: primaryBlue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _getUserName(),
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.authService.isAuthenticated ? 'عميل مسجل' : 'زائر',
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 15),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, double value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToLogin,
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: Text('تسجيل الدخول',
                            style: GoogleFonts.cairo(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        title: 'الرئيسية',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 0);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.grid_view_rounded,
                        title: 'التصنيفات',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 1);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.design_services_rounded,
                        title: 'تصميم منظومة',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToSystemBuilder();
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.favorite_rounded,
                        title: 'المفضلة',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 2);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.discount_rounded,
                        title: 'العروض',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 3);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.shopping_cart_rounded,
                        title: 'السلة',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 4);
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.person_rounded,
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
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Divider(),
                      ),
                      _buildDrawerItem(
                        icon: Icons.smart_toy_rounded,
                        title: 'المساعد الذكي',
                        onTap: () {
                          Navigator.pop(context);
                          _openChatScreen();
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.solar_power_rounded,
                        title: 'منظوماتي',
                        onTap: () {
                          Navigator.pop(context);
                          if (isGuest) {
                            _showLoginRequired();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SolarSystemsScreen(
                                  authService: widget.authService,
                                  apiService: _apiService,
                                ),
                              ),
                            );
                          }
                        },
                        requiresAuth: true,
                        isGuest: isGuest,
                      ),
                      _buildDrawerItem(
                        icon: Icons.build_rounded,
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
                        icon: Icons.compare_arrows_rounded,
                        title: 'المقارنات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComparisonScreen(
                                apiService: _apiService,
                                authService: widget.authService,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings_rounded,
                        title: 'الإعدادات',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      if (_isCompanyOwner())
                        _buildDrawerItem(
                          icon: Icons.dashboard_rounded,
                          title: 'لوحة تحكم الشركة',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompanyDashboardScreen(
                                  authService: widget.authService,
                                  storageService: widget.storageService,
                                ),
                              ),
                            );
                          },
                        ),
                      _buildDrawerItem(
                        icon: Icons.feedback_rounded,
                        title: 'تقديم شكوى',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddComplaintScreen(
                                authService: widget.authService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'تسجيل خروج',
                        onTap: () {
                          Navigator.pop(context);
                          if (!isGuest) _logout();
                        },
                        isDestructive: true,
                        requiresAuth: true,
                        isGuest: isGuest,
                      ),
                    ],
                  ),
                ),
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
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 22),
          ),
          title: Text(title,
              style: GoogleFonts.cairo(color: Colors.grey.shade400)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text('تسجيل دخول',
                style: GoogleFonts.cairo(
                    fontSize: 10, color: Colors.orange.shade700)),
          ),
          onTap: _navigateToLogin,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isDestructive
                ? LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade300])
                : LinearGradient(colors: [
                    primaryBlue.withOpacity(0.2),
                    secondaryBlue.withOpacity(0.1)
                  ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isDestructive ? Colors.white : primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            color: isDestructive ? Colors.red.shade400 : darkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildCenterHubNavBar() {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 75,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSideNavItem(
                    icon: Icons.design_services_rounded,
                    label: 'تصميم منظومة',
                    index: -1,
                    onTapOverride: _navigateToSystemBuilder,
                  ),
                  _buildSideNavItem(
                    icon: Icons.discount_rounded,
                    label: 'العروض',
                    index: 3,
                  ),
                  _buildSideNavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'التصنيفات',
                    index: 1,
                  ),
                  const SizedBox(width: 45),
                  _buildSideNavItem(
                    icon: Icons.favorite_rounded,
                    label: 'المفضلة',
                    index: 2,
                  ),
                  _buildSideNavItem(
                    icon: Icons.shopping_cart_rounded,
                    label: 'السلة',
                    index: 4,
                  ),
                  _buildSideNavItem(
                    icon: Icons.person_rounded,
                    label: 'حسابي',
                    index: 5,
                    requiresAuth: true,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: MediaQuery.of(context).size.width * 0.415,
            child: GestureDetector(
              onTap: _onCenterTap,
              child: AnimatedBuilder(
                animation: _centerPulseController,
                builder: (context, child) {
                  final pulseScale =
                      1.0 + (_centerPulseController.value * 0.05);
                  return Transform.scale(scale: pulseScale, child: child);
                },
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: accentBlue.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent
                            ],
                            radius: 0.8,
                          ),
                        ),
                      ),
                      const Icon(Icons.home_rounded,
                          color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: MediaQuery.of(context).size.width * 0.42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('الرئيسية',
                  style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTapOverride,
    bool requiresAuth = false,
  }) {
    final isSelected = _currentIndex == index && index >= 0;
    final isGuest = !widget.authService.isAuthenticated;

    return GestureDetector(
      onTap: () {
        if (onTapOverride != null) {
          onTapOverride();
        } else if (requiresAuth && isGuest) {
          _showLoginRequired();
        } else if (index >= 0) {
          setState(() => _currentIndex = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isSelected ? 9 : 7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.grey.shade600 : Colors.grey.shade400,
                size: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.cairo(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ],
        ),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.lock_rounded,
                  size: 60, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 30),
            Text(
              title,
              style: GoogleFonts.cairo(
                  fontSize: 26, fontWeight: FontWeight.bold, color: darkColor),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 16, color: mediumGray, height: 1.5),
            ),
            const SizedBox(height: 35),
            ElevatedButton.icon(
              onPressed: _navigateToLogin,
              icon: const Icon(Icons.login_rounded),
              label: Text('تسجيل الدخول',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

// في نفس ملف HomeScreen - أضف هذه الدوال والمتغيرات

// ==================== تعديل _buildAdvertisementsCarousel ====================

  Widget _buildAdvertisementsCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: _advertisements.map((ad) {
        return GestureDetector(
          onTap: () => _showAdvertisementFullScreen(ad),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ad['image_path'] ?? ad['image_url'] ?? '',
                    fit: BoxFit.cover,
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // ✅ مؤشر الضغط للتكبير
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

// ==================== دالة عرض الإعلان في شاشة كاملة ====================

  void _showAdvertisementFullScreen(dynamic ad) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // ✅ الصورة في الخلفية
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: CachedNetworkImage(
                    imageUrl: ad['image_path'] ?? ad['image_url'] ?? '',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade800,
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ زر الإغلاق X في الأعلى
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // ✅ الأزرار في الأسفل
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // ✅ زر الرابط (إذا وجد)
                    if (ad['has_link'] == true && ad['link_url'] != null)
                      _buildAdvertisementActionButton(
                        icon: Icons.link_rounded,
                        label: 'الذهاب إلى الرابط',
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pop(context);
                          _openUrl(ad['link_url']);
                        },
                      ),

                    const SizedBox(height: 10),

                    // ✅ زر الاتصال (إذا وجد)
                    if (ad['has_phone'] == true && ad['phone'] != null)
                      _buildAdvertisementActionButton(
                        icon: Icons.phone_rounded,
                        label: 'اتصال: ${ad['phone']}',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pop(context);
                          _makePhoneCall(ad['phone_url'] ?? ad['phone']);
                        },
                      ),

                    const SizedBox(height: 10),

                    // ✅ زر الواتساب (إذا وجد)
                    if (ad['has_whatsapp'] == true && ad['whatsapp'] != null)
                      _buildAdvertisementActionButton(
                        icon: Icons.chat_rounded,
                        label: 'محادثة واتساب',
                        color: const Color(0xFF25D366),
                        onTap: () {
                          Navigator.pop(context);
                          _openWhatsapp(ad['whatsapp_link'] ?? ad['whatsapp']);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// ==================== دالة بناء زر الإجراء ====================

  Widget _buildAdvertisementActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ==================== دوال فتح الروابط ====================

  void _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      _showSnackBarMessage('تعذر فتح الرابط');
    }
  }

  void _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;

    try {
      final uri = Uri.parse(phone.startsWith('tel:') ? phone : 'tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      _showSnackBarMessage('تعذر إجراء المكالمة');
    }
  }

  void _openWhatsapp(String? whatsapp) async {
    if (whatsapp == null || whatsapp.isEmpty) return;

    try {
      final uri = Uri.parse(whatsapp.startsWith('http') ? whatsapp : 'https://wa.me/$whatsapp');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
      _showSnackBarMessage('تعذر فتح الواتساب');
    }
  }

  void _showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
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
        textDirection: TextDirection.ltr,
        children: [
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'عرض الكل',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: primaryBlue,
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: primaryBlue),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsHorizontalList(List<dynamic> products) {
    return SizedBox(
      height: 285,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: products.length > 10 ? 10 : products.length,
        itemBuilder: (context, index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: HomeProductCard(
              product: products[index],
              apiService: _apiService,
              authService: widget.authService,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersHorizontalList(List<dynamic> offers) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: offers.length > 10 ? 10 : offers.length,
        itemBuilder: (context, index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          ),
          child: Container(
            width: 290,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: HomeOfferCard(
              offer: offers[index],
              apiService: _apiService,
              authService: widget.authService,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCategories() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 110,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoriesHorizontalList(List<dynamic> subCategories) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: subCategories.length > 10 ? 10 : subCategories.length,
        itemBuilder: (context, index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) => Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildSubCategoryCard(subCategories[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(dynamic subCategory) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsListScreen(
              title: subCategory['name_ar'] ?? 'المنتجات',
              products: null,
              subcategorySlug: subCategory['slug'],
              isSubCategory: true,
              apiService: _apiService,
              authService: widget.authService,
              storageService: widget.storageService,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: subCategory['image'] ?? '',
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.kitchen_rounded, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.kitchen_rounded,
                    color: Colors.grey.shade400,
                    size: 35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subCategory['name_ar'] ?? 'تصنيف',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subCategory['number_products'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${subCategory['number_products']} منتج',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: mediumGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSubCategories() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  void _openChatScreen() {
    final bool isGuest = !widget.authService.isAuthenticated;
    final savedGovernorate = widget.storageService.getGuestGovernorate();
    if (isGuest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuestChatScreen(
            apiService: _apiService,
            storageService: widget.storageService,
            initialGovernorate: savedGovernorate,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            authService: widget.authService,
            apiService: _apiService,
          ),
        ),
      );
    }
  }
  bool _isCompanyOwner() {
    if (!widget.authService.isAuthenticated) return false;

    try {
      final userData = widget.storageService.getUserDataMap();
      if (userData != null && userData['user_type'] == 'company_owner') {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking company owner: $e');
    }

    return false;
  }
}
