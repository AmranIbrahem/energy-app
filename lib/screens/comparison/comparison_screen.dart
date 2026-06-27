// lib/screens/comparison/comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/services/comparison_service.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';

class ComparisonScreen extends StatefulWidget {
  final ApiService? apiService;
  final AuthService? authService;

  const ComparisonScreen({
    super.key,
    this.apiService,
    this.authService,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ComparisonService _comparisonService = ComparisonService.instance;
  bool _isComparing = false;
  String? _comparisonResult;
  bool _isLoading = true;
  late AnimationController _pulseController;


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _comparisonService.loadComparisonData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _compareProducts() async {
    if (_comparisonService.productsCount < 2) {
      _showSnackBar('يجب إضافة منتجين على الأقل للمقارنة', Colors.orange);
      return;
    }

    setState(() {
      _isComparing = true;
      _comparisonResult = null;
    });

    try {
      final productIds = _comparisonService.products.map((p) => p['id']).toList();
      final response = await widget.apiService?.post(
        '/v1/user/public/ai/products/compare-multiple',
        data: {'product_ids': productIds},
        requiresAuth: false,
      );

      if (mounted) {
        if (response != null && response['success'] == true) {
          setState(() => _comparisonResult = response['data']['comparison']);
        } else {
          _showSnackBar(response?['message'] ?? 'حدث خطأ في المقارنة', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('حدث خطأ في الاتصال', Colors.red);
    } finally {
      if (mounted) setState(() => _isComparing = false);
    }
  }

  Future<void> _compareOffers() async {
    if (_comparisonService.offersCount < 2) {
      _showSnackBar('يجب إضافة عرضين على الأقل للمقارنة', Colors.orange);
      return;
    }

    setState(() {
      _isComparing = true;
      _comparisonResult = null;
    });

    try {
      final offerIds = _comparisonService.offers.map((o) => o['id']).toList();
      final response = await widget.apiService?.post(
        '/v1/user/public/ai/offers/compare-multiple',
        data: {'offer_ids': offerIds},
        requiresAuth: false,
      );

      if (mounted) {
        if (response != null && response['success'] == true) {
          setState(() => _comparisonResult = response['data']['comparison']);
        } else {
          _showSnackBar(response?['message'] ?? 'حدث خطأ في المقارنة', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('حدث خطأ في الاتصال', Colors.red);
    } finally {
      if (mounted) setState(() => _isComparing = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(color == primaryBlue ? Icons.check_circle_rounded : Icons.info_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
  }

  void _removeProduct(int productId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _comparisonService.removeProduct(productId);
      _comparisonResult = null;
    });
    _showSnackBar('تم إزالة المنتج من المقارنة', Colors.orange);
  }

  void _removeOffer(int offerId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _comparisonService.removeOffer(offerId);
      _comparisonResult = null;
    });
    _showSnackBar('تم إزالة العرض من المقارنة', Colors.orange);
  }

  void _clearAllItems() {
    final isProductsTab = _tabController.index == 0;
    final items = isProductsTab ? _comparisonService.products : _comparisonService.offers;
    if (items.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text('تأكيد الإزالة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkColor)),
        ]),
        content: Text(
          isProductsTab ? 'هل تريد إزالة جميع المنتجات من المقارنة؟' : 'هل تريد إزالة جميع العروض من المقارنة؟',
          style: GoogleFonts.cairo(color: mediumGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: mediumGray, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isProductsTab) {
                  _comparisonService.clearProducts();
                } else {
                  _comparisonService.clearOffers();
                }
                _comparisonResult = null;
              });
              Navigator.pop(context);
              _showSnackBar('تم إزالة جميع العناصر', Colors.orange);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
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
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.15),
                child: child,
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: Colors.yellow, size: 24),
            ),
            const SizedBox(width: 10),
            Text('المقارنات', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _clearAllItems,
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 22),
              tooltip: 'إزالة الكل',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryBlue, secondaryBlue]),
                borderRadius: BorderRadius.circular(18),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_bag_rounded, size: 18), SizedBox(width: 8), Text('المنتجات')
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_offer_rounded, size: 18), SizedBox(width: 8), Text('العروض')
                ])),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildComparisonTab(isProducts: true),
          _buildComparisonTab(isProducts: false),
        ],
      ),
    );
  }

  Widget _buildComparisonTab({required bool isProducts}) {
    final items = isProducts ? _comparisonService.products : _comparisonService.offers;
    final count = items.length;
    const maxItems = 4;

    if (_comparisonResult != null && !_isComparing && count >= 2) {
      return _buildComparisonResult(isProducts);
    }

    return Column(children: [
      if (count > 0) _buildHeaderBanner(isProducts, count, maxItems),
      if (count > 0)
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: count,
            itemBuilder: (context, index) => _buildComparisonCard(items[index], isProducts, index),
          ),
        )
      else
        Expanded(child: _buildEmptyState(isProducts)),
      if (count >= 2 && (_comparisonResult == null || _isComparing))
        _buildCompareButton(isProducts),
      if (_comparisonResult == null && count > 0 && count < 2)
        Expanded(child: _buildNoResultPlaceholder(isProducts, count)),
    ]);
  }

  Widget _buildHeaderBanner(bool isProducts, int count, int maxItems) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          primaryBlue.withOpacity(0.06),
          secondaryBlue.withOpacity(0.03),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryBlue.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              primaryBlue.withOpacity(0.15),
              secondaryBlue.withOpacity(0.08),
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isProducts ? Icons.shopping_bag_rounded : Icons.local_offer_rounded, color: primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('عناصر المقارنة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
          const SizedBox(height: 1),
          Text('$count من $maxItems عناصر', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
        ]),
        const Spacer(),
        if (count < maxItems)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryBlue.withOpacity(0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_circle_outline, size: 12, color: primaryBlue),
              const SizedBox(width: 4),
              Text('أضف ${maxItems - count}', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: primaryBlue)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildCompareButton(bool isProducts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ElevatedButton(
        onPressed: _isComparing ? null : (isProducts ? _compareProducts : _compareOffers),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 50),
          elevation: 3,
          shadowColor: primaryBlue.withOpacity(0.4),
        ),
        child: _isComparing
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
          const SizedBox(width: 10),
          Text('جاري المقارنة...', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ])
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.compare_arrows_rounded, size: 20),
          const SizedBox(width: 8),
          Text('قارن الآن', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _buildComparisonResult(bool isProducts) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue.withOpacity(0.06), secondaryBlue.withOpacity(0.03)],
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.15), secondaryBlue.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: primaryBlue, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('نتيجة المقارنة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
                const SizedBox(height: 1),
                Text(isProducts ? 'مقارنة المنتجات' : 'مقارنة العروض', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
              ]),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _comparisonResult = null);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 16),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: _buildFormattedComparisonResult(),
          ),
        ),
      ]),
    );
  }

  Widget _buildFormattedComparisonResult() {
    if (_comparisonResult == null) return const SizedBox.shrink();

    final lines = _comparisonResult!.split('\n');
    List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('##')) {
        final title = line.replaceAll('#', '').trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Row(children: [
            Container(width: 3, height: 18, decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor))),
          ]),
        ));
        continue;
      }

      if (line.startsWith('**') && line.endsWith('**')) {
        final title = line.replaceAll('*', '').trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 3),
          child: Row(children: [
            Icon(Icons.circle, size: 5, color: primaryBlue.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
          ]),
        ));
        continue;
      }

      if (line.startsWith('-') || line.startsWith('*')) {
        final text = line.substring(1).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 14, top: 3, bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(top: 7),
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: primaryBlue.withOpacity(0.5), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: GoogleFonts.cairo(fontSize: 12, height: 1.5, color: mediumGray))),
          ]),
        ));
        continue;
      }

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(line, style: GoogleFonts.cairo(fontSize: 12, height: 1.5, color: mediumGray)),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildNoResultPlaceholder(bool isProducts, int count) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(Icons.compare_arrows_rounded, size: 35, color: primaryBlue.withOpacity(0.4)),
        ),
        const SizedBox(height: 14),
        Text(
          count < 2 ? 'أضف عنصرين على الأقل للمقارنة' : 'اضغط زر المقارنة للبدء',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: mediumGray),
        ),
        const SizedBox(height: 4),
        Text('نتيجة المقارنة ستظهر هنا', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildEmptyState(bool isProducts) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(scale: 1.0 + (_pulseController.value * 0.08), child: child),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.06), secondaryBlue.withOpacity(0.03)]),
                shape: BoxShape.circle,
              ),
              child: Icon(isProducts ? Icons.shopping_bag_outlined : Icons.local_offer_outlined, size: 45, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isProducts ? 'لا توجد منتجات للمقارنة' : 'لا توجد عروض للمقارنة',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
          ),
          const SizedBox(height: 6),
          Text('يمكنك إضافة ما يصل إلى 4 عناصر للمقارنة', style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline_rounded, size: 14, color: primaryBlue.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text('أضف عناصر من صفحات المنتجات والعروض',
                  style: GoogleFonts.cairo(fontSize: 11, color: primaryBlue.withOpacity(0.7))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildComparisonCard(Map<String, dynamic> item, bool isProduct, int index) {
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        String cleaned = price.trim().replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleaned.isEmpty) return 0.0;
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    double parseRating(dynamic rating) {
      if (rating == null) return 0.0;
      if (rating is double) return rating;
      if (rating is int) return rating.toDouble();
      if (rating is String) {
        final cleaned = rating.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    final double originalPrice = parsePrice(item['price']);
    final double finalPrice = parsePrice(item['final_price'] ?? item['price']);
    final bool hasDiscount = originalPrice > 0 && finalPrice > 0 && originalPrice > finalPrice;
    final double rating = parseRating(item['rate']);
    final bool hasRating = rating > 0;

    String discountText = '';
    if (hasDiscount) {
      final discountPercent = ((originalPrice - finalPrice) / originalPrice * 100).round();
      discountText = 'خصم $discountPercent%';
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                child: CachedNetworkImage(
                  imageUrl: item['image'] ?? '',
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 110,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50])),
                    child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue))),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 110,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50])),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(isProduct ? Icons.shopping_bag_rounded : Icons.local_offer_rounded, size: 28, color: Colors.grey.shade400),
                      const SizedBox(height: 2),
                      Text('لا توجد صورة', style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey.shade500)),
                    ]),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => isProduct ? _removeProduct(item['id']) : _removeOffer(item['id']),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 11, color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (hasDiscount && discountText.isNotEmpty)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.local_offer_rounded, size: 8, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(discountText, style: GoogleFonts.cairo(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isProduct ? primaryBlue.withOpacity(0.9) : const Color(0xFFFF9800).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isProduct ? Icons.shopping_bag_rounded : Icons.local_offer_rounded, size: 8, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(isProduct ? 'منتج' : 'عرض', style: GoogleFonts.cairo(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(item['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: darkColor)),
                const SizedBox(height: 2),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_formatPrice(finalPrice), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
                  const SizedBox(width: 2),
                  Text(r'$', style: GoogleFonts.cairo(fontSize: 9, color: Colors.grey.shade500)),
                  const Spacer(),
                  if (hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(5)),
                      child: Text('وفر ${_formatPrice(originalPrice - finalPrice)}',
                          style: GoogleFonts.cairo(fontSize: 7, color: Colors.red.shade600, fontWeight: FontWeight.w600)),
                    ),
                ]),
                if (hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text('${_formatPrice(originalPrice)} \$',
                        style: GoogleFonts.cairo(fontSize: 9, decoration: TextDecoration.lineThrough, color: Colors.grey.shade400)),
                  ),
                const SizedBox(height: 6),
                if (isProduct && item['brand'] != null && item['brand'].toString().isNotEmpty)
                  _buildInfoRow(icon: Icons.business_rounded, label: 'العلامة', value: item['brand'].toString(), iconColor: Colors.blue.shade600),
                if (!isProduct && item['total_wattage'] != null)
                  _buildInfoRow(icon: Icons.flash_on_rounded, label: 'الطاقة', value: '${item['total_wattage']} واط', iconColor: Colors.orange.shade600),
                if (!isProduct && item['total_capacity'] != null)
                  _buildInfoRow(icon: Icons.battery_std_rounded, label: 'السعة', value: '${item['total_capacity']} واط/ساعة', iconColor: Colors.purple.shade600),
                if (hasRating)
                  _buildInfoRow(icon: Icons.star_rounded, label: 'التقييم', value: rating.toStringAsFixed(1), iconColor: Colors.amber.shade600),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => isProduct ? _removeProduct(item['id']) : _removeOffer(item['id']),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                      foregroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 26),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.delete_outline_rounded, size: 11),
                      const SizedBox(width: 3),
                      Text('إزالة', style: GoogleFonts.cairo(fontSize: 9)),
                    ]),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 10, color: iconColor),
        const SizedBox(width: 3),
        Text('$label: ', style: GoogleFonts.cairo(fontSize: 8, color: mediumGray)),
        Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: 8, color: darkColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return '0';
    if (price == price.roundToDouble()) return price.round().toString();
    return price.toStringAsFixed(2);
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(height: 50, decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(18))),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: 180,
              margin: const EdgeInsets.only(right: 10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 110, decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(18))),
                  const SizedBox(height: 8),
                  Container(height: 12, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 4),
                  Container(height: 10, width: 60, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(5))),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}