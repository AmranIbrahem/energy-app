// lib/screens/company/company_dashboard_screen.dart

import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:GeniusHouse/screens/company/categories/main_categories_screen.dart';
import 'package:GeniusHouse/screens/company/offers/offers_list_screen.dart';
import 'package:GeniusHouse/screens/company/products/products_list_screen.dart';
import 'package:GeniusHouse/screens/company/supplier_orders/supplier_orders_list_screen.dart';
import 'package:GeniusHouse/screens/home_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/screens/company/commissions/company_commission_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const CompanyDashboardScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  int _currentIndex = 0;
  Map<String, dynamic>? _advancedStats;
  List<Map<String, dynamic>> _productsByMainCategory = [];
  List<Map<String, dynamic>> _productsBySubCategory = [];
  bool _isLoadingStats = true;
  bool _isLoadingAdvanced = true;
  String? _companyName;
  int _touchedIndex = -1;

  late ApiService _apiService;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final token = widget.authService.token;
    debugPrint('═══════════════════════════════════');
    debugPrint('🔑 CompanyDashboard - Token: ${token != null ? token.substring(0, token.length > 30 ? 30 : token.length) + '...' : 'NULL'}');
    debugPrint('🔑 isAuthenticated: ${widget.authService.isAuthenticated}');
    debugPrint('═══════════════════════════════════');

    _apiService = ApiService(storageService: widget.storageService);

    if (token != null && token.isNotEmpty) {
      _apiService.setToken(token);
      debugPrint('✅ Token set in ApiService');
    } else {
      debugPrint('❌ No token available!');
    }

    _loadCompanyInfo();
    _fetchDashboardStats();
  }

  void _loadCompanyInfo() async {
    try {
      final userData = await widget.authService.getUserData();
      debugPrint('👤 User Data: ${jsonEncode(userData)}');

      if (userData != null && mounted) {
        setState(() {
          _companyName = userData['name'] ?? userData['name_ar'] ?? 'شركتي';
        });
      } else {
        final name = widget.storageService.getUserName();
        debugPrint('👤 User Name from Storage: $name');
        if (name != null && mounted) {
          setState(() {
            _companyName = name;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoadingStats = true);
    setState(() => _isLoadingAdvanced = true);

    try {
      final response = await _apiService.get(
        '/v1/company/dashboard/stats',
        requiresAuth: true,
      );

      debugPrint('📊 Dashboard Stats Response: ${jsonEncode(response)}');

      if (response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _advancedStats = data['statistics'];
          _productsByMainCategory = List<Map<String, dynamic>>.from(data['chart_data']['products_by_main_category'] ?? []);
          _productsBySubCategory = List<Map<String, dynamic>>.from(data['chart_data']['products_by_sub_category'] ?? []);
          _isLoadingStats = false;
          _isLoadingAdvanced = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
            _isLoadingAdvanced = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching dashboard stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingAdvanced = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
                color == successGreen
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  void _navigateToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تسجيل الخروج',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content:
        Text('هل أنت متأكد من تسجيل الخروج؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تسجيل الخروج',
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              authService: widget.authService,
              storageService: widget.storageService,
            ),
          ),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: darkColor),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.cairo(
              fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryBlue),
            onPressed: () {
              if (_currentIndex == 0) {
                _fetchDashboardStats();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildProductsPlaceholder();
      case 2:
        return _buildCategoriesPlaceholder();
      case 4:
        return OffersListScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        );
      case 5:
        return _buildSupplierOrdersPlaceholder();
      case 6: // ✅ عمولة المنصة
        return CompanyCommissionScreen(
          authService: widget.authService,
          storageService: widget.storageService,
        );
      default:
        return _buildDashboardContent();
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'المنتجات';
      case 2:
        return 'التصنيفات';
      case 4:
        return 'العروض';
      case 5:
        return 'طلبات التوريد';
      case 6: // ✅
        return 'عمولة المنصة';
      default:
        return 'لوحة التحكم';
    }
  }

  // ==================== Drawer ====================

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: cardWhite,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, secondaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.store_rounded,
                          color: Colors.white, size: 35),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _companyName ?? 'شركتي',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لوحة تحكم الشركة',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'الداشبورد',
                      index: 0),
                  _buildDrawerItem(
                      icon: Icons.inventory_2_rounded,
                      title: 'المنتجات',
                      index: 1),
                  _buildDrawerItem(
                    icon: Icons.category_rounded,
                    title: 'التصنيفات',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_offer_rounded,
                    title: 'العروض',
                    index: 4,
                  ),
                  _buildDrawerItem(
                    icon: Icons.local_shipping_rounded,
                    title: 'طلبات التوريد',
                    index: 5,
                  ),
                  _buildDrawerItem(
                    icon: Icons.percent_rounded,
                    title: 'عمولة المنصة',
                    index: 6,
                  ),
                  const Divider(height: 30, thickness: 1),
                  _buildDrawerItem(
                      icon: Icons.shopping_bag_rounded,
                      title: 'تصفح التطبيق',
                      index: -1,
                      onTap: _navigateToApp),
                  _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'تسجيل الخروج',
                      index: -1,
                      color: dangerRed,
                      onTap: _logout),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text('NEX v1.0',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: Colors.grey.shade400)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index && index >= 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryBlue.withOpacity(0.15)
                : (color ?? darkColor).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: isSelected ? primaryBlue : (color ?? mediumGray),
              size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryBlue : (color ?? darkColor),
            )),
        trailing: isSelected
            ? Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
                color: primaryBlue, borderRadius: BorderRadius.circular(4)))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.pop(context);
          if (onTap != null) {
            onTap();
          } else if (index >= 0) {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }

  // ==================== Dashboard Content ====================

  Widget _buildDashboardContent() {
    final stats = _advancedStats;

    return RefreshIndicator(
      onRefresh: _fetchDashboardStats,
      color: primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // === بطاقات الإحصائيات السريعة ===
            if (stats != null) ...[
              Text('لوحة الإحصائيات المتقدمة',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  _buildAdvancedStatCard(
                      Icons.category_rounded, 'تصنيفات رئيسية',
                      '${stats['main_categories_count'] ?? 0}',
                      '+${stats['main_categories_count'] ?? 0} هذا الشهر',
                      primaryBlue, [primaryBlue, secondaryBlue]),
                  _buildAdvancedStatCard(
                      Icons.layers_rounded, 'تصنيفات فرعية',
                      '${stats['sub_categories_count'] ?? 0}',
                      '+${stats['sub_categories_count'] ?? 0} هذا الشهر',
                      const Color(0xFF4facfe), [const Color(0xFF4facfe), const Color(0xFF00f2fe)]),
                  _buildAdvancedStatCard(
                      Icons.inventory_2_rounded, 'منتجاتك',
                      '${stats['total_products'] ?? 0}',
                      '${stats['active_products'] ?? 0} نشط',
                      successGreen, [successGreen, const Color(0xFF34D399)]),
                  _buildAdvancedStatCard(
                      Icons.local_offer_rounded, 'العروض',
                      '${stats['total_offers'] ?? 0}',
                      '${stats['active_offers'] ?? 0} نشط',
                      warningOrange, [warningOrange, const Color(0xFFFBBF24)]),
                  _buildAdvancedStatCard(
                      Icons.local_shipping_rounded, 'طلبات التوريد',
                      '${stats['total_supplier_orders'] ?? 0}',
                      '${stats['pending_supplier_orders'] ?? 0} قيد الانتظار',
                      dangerRed, [dangerRed, const Color(0xFFF87171)]),
                ],
              ),

              const SizedBox(height: 24),

              // === الرسوم البيانية ===
              if (!_isLoadingAdvanced) ...[
                if (_productsByMainCategory.isNotEmpty) ...[
                  _buildChartCard(
                    title: 'منتجاتك حسب التصنيف الرئيسي',
                    icon: Icons.bar_chart_rounded,
                    color: primaryBlue,
                    child: Column(
                      children: _productsByMainCategory.asMap().entries.map((e) {
                        final maxVal = _productsByMainCategory
                            .map((x) => (x['count'] as int).toDouble())
                            .reduce(max);
                        final val = (e.value['count'] as int).toDouble();
                        final ratio = maxVal > 0 ? val / maxVal : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              // اسم التصنيف
                              SizedBox(
                                width: 100,
                                child: Text(
                                  e.value['name'] ?? '',
                                  style: GoogleFonts.cairo(fontSize: 10, color: darkColor, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // الشريط الأفقي
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: ratio.clamp(0.02, 1.0),
                                      child: Container(
                                        height: 22,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            _getChartColor(e.key),
                                            _getChartColor(e.key).withOpacity(0.7),
                                          ]),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          '${e.value['count']}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

// Doughnut Chart - توزيع حسب التصنيف الفرعي مع Legend
                if (_productsBySubCategory.isNotEmpty) ...[
                  _buildChartCard(
                    title: 'توزيع منتجاتك حسب التصنيف الفرعي',
                    icon: Icons.donut_large_rounded,
                    color: successGreen,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sections: _productsBySubCategory.asMap().entries.map((e) {
                                final isTouched = e.key == _touchedIndex;
                                final radius = isTouched ? 90.0 : 75.0;
                                return PieChartSectionData(
                                  color: _getChartColor(e.key),
                                  value: (e.value['count'] as int).toDouble(),
                                  title: isTouched ? '${e.value['name']}\n(${e.value['count']})' : '${e.value['count']}',
                                  radius: radius,
                                  titleStyle: GoogleFonts.cairo(
                                    fontSize: isTouched ? 11 : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  titlePositionPercentageOffset: 0.55,
                                );
                              }).toList(),
                              centerSpaceRadius: 30,
                              sectionsSpace: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ✅ Legend - أسماء الأقسام مع الألوان
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _productsBySubCategory.asMap().entries.map((e) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _touchedIndex = _touchedIndex == e.key ? -1 : e.key;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _touchedIndex == e.key
                                      ? _getChartColor(e.key).withOpacity(0.15)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _touchedIndex == e.key
                                        ? _getChartColor(e.key)
                                        : Colors.grey.shade200,
                                    width: _touchedIndex == e.key ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getChartColor(e.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${e.value['name']} (${e.value['count']})',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: _touchedIndex == e.key ? FontWeight.bold : FontWeight.w500,
                                        color: darkColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],              ],
            ] else if (_isLoadingAdvanced) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator(color: primaryBlue)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [primaryBlue, secondaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.waving_hand_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك،',
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8))),
                    Text(_companyName ?? 'مدير الشركة',
                        style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
              'هذه لوحة التحكم الخاصة بك. يمكنك إدارة منتجاتك وعرض الإحصائيات من هنا.',
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.5)),
        ],
      ),
    );
  }

  // بطاقة إحصائية متقدمة
  Widget _buildAdvancedStatCard(IconData icon, String title, String value, String trend, Color color, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: darkColor)),
            Text(title, style: GoogleFonts.cairo(fontSize: 10, color: mediumGray)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(trend, style: GoogleFonts.cairo(fontSize: 9, color: successGreen)),
          ),
        ],
      ),
    );
  }

  // بطاقة رسم بياني
  Widget _buildChartCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  // ألوان متنوعة للرسوم البيانية
  Color _getChartColor(int index) {
    const colors = [
      Color(0xFF667eea), Color(0xFF4facfe), Color(0xFF84fab0), Color(0xFFf093fb),
      Color(0xFFfa709a), Color(0xFFa855f7), Color(0xFF06b6d4), Color(0xFFf59e0b),
      Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFEF4444), Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
  }

  Widget _buildProductsPlaceholder() {
    return ProductsListScreen(
        authService: widget.authService, storageService: widget.storageService);
  }

  Widget _buildCategoriesPlaceholder() {
    return MainCategoriesScreen(
      authService: widget.authService,
      storageService: widget.storageService,
    );
  }

  Widget _buildSupplierOrdersPlaceholder() {
    return SupplierOrdersListScreen(
      authService: widget.authService,
      storageService: widget.storageService,
    );
  }
}