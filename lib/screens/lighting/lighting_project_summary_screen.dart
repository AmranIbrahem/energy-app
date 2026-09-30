// lib/screens/lighting/lighting_project_summary_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/lighting_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class LightingProjectSummaryScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final int projectId;
  final String? sessionId;

  const LightingProjectSummaryScreen({
    Key? key,
    required this.apiService,
    required this.storageService,
    required this.projectId,
    this.sessionId,
  }) : super(key: key);

  @override
  State<LightingProjectSummaryScreen> createState() =>
      _LightingProjectSummaryScreenState();
}

class _LightingProjectSummaryScreenState
    extends State<LightingProjectSummaryScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isSypPreferred {
    try {
      return widget.storageService.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    return '${buffer.toString()}.$decimalPart';
  }

  String _fmt(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    if (curr == 'SYP') {
      return '${_formatNumber(amount)} SYP';
    }
    return '\$${_formatNumber(amount)}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final token = widget.storageService.getToken();
      final isGuest = token == null || token.isEmpty;

      final res = await widget.apiService.lightingShowProject(
        projectId: widget.projectId,
        sessionId: isGuest ? widget.sessionId : null,
        requiresAuth: !isGuest,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] is Map) {
        setState(() {
          _data = Map<String, dynamic>.from(res['data']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message']?.toString() ?? 'فشل جلب المشروع';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطأ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildAppBarWithCurve(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarWithCurve() {
    return ClipPath(
      clipper: _BottomCurveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Center(
                    child: Text(
                      'ملخص المشروع',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                    onPressed: _load,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return Center(
        child: Text(
          'لا توجد بيانات',
          style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade600),
        ),
      );
    }

    final rawProject = _data!['project'];
    final project = rawProject is Map
        ? Map<String, dynamic>.from(rawProject)
        : <String, dynamic>{};

    final rawRooms = _data!['rooms'];
    final rooms = (rawRooms is List)
        ? rawRooms.map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProjectHeader(project),
        const SizedBox(height: 16),
        if (rooms.isEmpty)
          _buildEmptyRooms()
        else ...[
          Text(
            'الغرف (${rooms.length})',
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 10),
          ...rooms.map(_buildRoomCard),
        ],
        const SizedBox(height: 24),
        if (rooms.isNotEmpty) _buildCTAButtons(project, rooms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProjectHeader(Map<String, dynamic> project) {
    final number = project['project_number']?.toString() ?? '';
    final status = project['status']?.toString() ?? 'draft';
    final roomCount = project['room_count'] ?? 0;
    final totalPower = project['total_power_w'] ?? 0;

    final equipmentRaw = project['equipment_total'];
    final equipmentMap = equipmentRaw is Map
        ? Map<String, dynamic>.from(equipmentRaw)
        : <String, dynamic>{};

    final totalAmount =
        double.tryParse(equipmentMap['amount']?.toString() ?? '0') ?? 0;
    final currency = equipmentMap['currency']?.toString() ?? 'USD';

    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  number,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (currency == 'SYP')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SYP',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusAr(status),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat('الغرف', '$roomCount', Icons.meeting_room_rounded),
              const SizedBox(width: 22),
              _headerStat(
                  'الاستطاعة', '${_fmtNum(totalPower)}W', Icons.bolt_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Text(
                _fmt(totalAmount, currency: currency),
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyRooms() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'لا توجد غرف معتمدة بعد',
            style: GoogleFonts.cairo(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final titleRaw = room['room_title_ar']?.toString() ?? '';
    final roomTitle = titleRaw.isNotEmpty
        ? titleRaw
        : _roomTypeAr(room['room_type_key']?.toString() ?? '');

    final area = double.tryParse((room['area_m2'] ?? 0).toString()) ?? 0;
    final attempts = (room['attempts'] is List)
        ? (room['attempts'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final confirmedAttempt =
        attempts.where((a) => a['is_confirmed'] == true).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    size: 20, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomTitle,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '${_fmtNum(area)} م² · ${attempts.length} محاولة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (confirmedAttempt.isNotEmpty)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 22),
            ],
          ),
          if (confirmedAttempt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 10),
            _buildAttemptRow(confirmedAttempt.first),
          ],
        ],
      ),
    );
  }

  String _roomTypeAr(String key) {
    const map = {
      'living_room': 'صالون',
      'bedroom': 'غرفة نوم',
      'children_room': 'غرفة أطفال',
      'kitchen': 'مطبخ',
      'bathroom': 'حمام',
      'corridor': 'ممر',
      'office': 'مكتب',
      'shop': 'محل',
      'showroom': 'معرض',
      'warehouse': 'مستودع',
      'workshop': 'ورشة',
      'restaurant': 'مطعم',
      'cafe': 'مقهى',
      'other': 'غير ذلك',
    };
    return map[key] ?? key;
  }

  Widget _buildAttemptRow(Map<String, dynamic> attempt) {
    final planKey = attempt['plan_key']?.toString() ?? '';

    final equipmentMap = attempt['equipment_total'] is Map
        ? Map<String, dynamic>.from(attempt['equipment_total'])
        : <String, dynamic>{};
    final amount =
        double.tryParse(equipmentMap['amount']?.toString() ?? '0') ?? 0;
    final currency = equipmentMap['currency']?.toString() ?? 'USD';

    final lux =
        double.tryParse((attempt['estimated_lux'] ?? 0).toString()) ?? 0;
    final items = (attempt['items'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 4),
              Text(
                _planTitleAr(planKey),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$lux لوكس',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((it) => _buildProductCard(it, currency)),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مجموع الغرفة:',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              _fmt(amount, currency: currency),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item, String currency) {
    final imageUrl = item['image']?.toString() ?? '';
    final title = item['title_ar']?.toString() ?? '';
    final brand = item['brand']?.toString() ?? '';
    final model = item['model']?.toString() ?? '';
    final slug = item['slug']?.toString() ?? '';
    final quantity = item['quantity'] ?? 1;

    final finalPrice =
        double.tryParse(item['final_price']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;

    final discountPct = (item['discount_percentage'] as num?)?.toDouble() ?? 0;
    final hasDiscount = discountPct > 0;

    return GestureDetector(
      onTap: () {
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                productSlug: slug,
                apiService: widget.apiService,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                            width: 55, height: 55, color: Colors.grey.shade300),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 20),
                      ),
                    )
                  : Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded,
                        size: 16, color: Colors.grey),
                  ]),
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$brand${model.isNotEmpty ? " - $model" : ""}',
                      style: GoogleFonts.cairo(
                          fontSize: 10, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    if (hasDiscount) ...[
                      Text(
                        _fmt(price, currency: currency),
                        style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${_fmt(finalPrice, currency: currency)} × $quantity',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButtons(
      Map<String, dynamic> project, List<Map<String, dynamic>> rooms) {
    final status = project['status']?.toString() ?? 'draft';
    final projectId = int.tryParse((project['id'] ?? 0).toString()) ?? 0;

    return Column(
      children: [
        if (status == 'draft') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmProject(projectId),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                'تأكيد المشروع نهائياً',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                status == 'draft' ? null : () => _addProjectToCart(rooms),
            icon: const Icon(Icons.shopping_cart_rounded),
            label: Text(
              status == 'draft' ? 'أكّد المشروع أولاً' : 'إضافة المشروع للسلة',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareProject(project, rooms),
            icon: const Icon(Icons.share_rounded),
            label: Text(
              'مشاركة المشروع',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addProjectToCart(List<Map<String, dynamic>> rooms) {
    final cartService = CartService.instance;
    int addedCount = 0;
    int skippedCount = 0;

    for (final room in rooms) {
      final attempts = (room['attempts'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final confirmed =
          attempts.where((a) => a['is_confirmed'] == true).toList();
      if (confirmed.isEmpty) continue;

      final attemptEquipment = confirmed.first['equipment_total'] is Map
          ? Map<String, dynamic>.from(confirmed.first['equipment_total'])
          : <String, dynamic>{};
      final attemptCurrency = attemptEquipment['currency']?.toString() ?? 'USD';
      final isSyp = attemptCurrency == 'SYP';

      final items = (confirmed.first['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      for (final item in items) {
        final slug = item['slug']?.toString() ?? '';
        final name = item['title_ar']?.toString() ?? '';
        if (slug.isEmpty || name.isEmpty) {
          skippedCount++;
          continue;
        }

        List<Map<String, dynamic>>? shippingCities;
        if (item['shipping_cities'] is List) {
          shippingCities = List<Map<String, dynamic>>.from(
            (item['shipping_cities'] as List).map((c) {
              if (c is String) return {'city': c, 'cost': null};
              if (c is Map) {
                return {
                  'city': c['city']?.toString() ?? '',
                  'cost': c['cost']?.toString(),
                };
              }
              return {'city': '', 'cost': null};
            }),
          );
        }

        final priceValue =
            double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        final finalPriceValue =
            double.tryParse(item['final_price']?.toString() ?? '0') ?? 0;

        final cartItem = CartItemModel(
          id: item['product_id'] ?? 0,
          name: name,
          slug: slug,
          price: isSyp ? 0 : priceValue,
          finalPrice: isSyp ? 0 : finalPriceValue,
          priceSyp: isSyp ? priceValue : null,
          finalPriceSyp: isSyp ? finalPriceValue : null,
          image: item['image']?.toString(),
          stock: item['stock'] ?? 0,
          quantity: item['quantity'] ?? 1,
          discountPercentage: (item['discount_percentage'] as num?)?.toDouble(),
          shippingCities: shippingCities,
        );

        cartService.addItem(cartItem);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      _showSnackBar('تم إضافة $addedCount منتج إلى السلة 🛒', isSuccess: true);
    } else {
      _showSnackBar('لا توجد منتجات صالحة للإضافة');
    }
  }

  void _shareProject(
      Map<String, dynamic> project, List<Map<String, dynamic>> rooms) {
    final buffer = StringBuffer();

    buffer.writeln('🏠 *مشروع إنارة - Nex*');
    buffer.writeln('📋 الرقم: ${project['project_number'] ?? ''}');
    buffer.writeln('');

    final totalPower = project['total_power_w'] ?? 0;
    final equipmentMap = project['equipment_total'] is Map
        ? Map<String, dynamic>.from(project['equipment_total'])
        : <String, dynamic>{};

    final totalAmount =
        double.tryParse(equipmentMap['amount']?.toString() ?? '0') ?? 0;
    final currency = equipmentMap['currency']?.toString() ?? 'USD';

    buffer.writeln('📊 *الملخص:*');
    buffer.writeln('• الغرف: ${project['room_count'] ?? 0}');
    buffer.writeln('• الاستطاعة: ${_fmtNum(totalPower)} W');
    buffer.writeln('• الإجمالي: ${_fmt(totalAmount, currency: currency)}');
    buffer.writeln('');

    buffer.writeln('🏠 *الغرف:*');
    for (final room in rooms) {
      final attempts = (room['attempts'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final confirmed =
          attempts.where((a) => a['is_confirmed'] == true).toList();
      if (confirmed.isEmpty) continue;

      final title = _roomTypeAr(room['room_type_key']?.toString() ?? '');
      final attempt = confirmed.first;
      final planKey = attempt['plan_key']?.toString() ?? '';
      final attemptEquip = attempt['equipment_total'] is Map
          ? Map<String, dynamic>.from(attempt['equipment_total'])
          : <String, dynamic>{};
      final attemptCurrency = attemptEquip['currency']?.toString() ?? currency;
      final items = (attempt['items'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      buffer.writeln('• *$title* (${_planTitleAr(planKey)}):');
      for (final it in items) {
        final itemPrice =
            double.tryParse(it['final_price']?.toString() ?? '0') ?? 0;
        buffer.writeln(
            '  - ${it['title_ar']} × ${it['quantity']} → ${_fmt(itemPrice, currency: attemptCurrency)}');
      }
    }

    buffer.writeln('');
    buffer.writeln('💡 من Nex - ذكاء التصميم');

    final text = buffer.toString();

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      _showSnackBar('تم نسخ ملخص المشروع 📋 — الصقه في أي مكان للمشاركة',
          isSuccess: true);
    });
  }

  Future<void> _confirmProject(int projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF3B82F6), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'تأكيد المشروع؟',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بعد التأكيد، يمكنك إضافة المشروع للسلة.\nلن تتمكن من إضافة غرف جديدة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('تأكيد',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = widget.storageService.getToken();
      final isGuest = token == null || token.isEmpty;

      final res = await widget.apiService.lightingConfirmProject(
        projectId: projectId,
        sessionId: isGuest ? widget.sessionId : null,
        requiresAuth: !isGuest,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _showSnackBar('تم تأكيد المشروع ✅', isSuccess: true);
        _load();
      } else {
        _showSnackBar(res['message']?.toString() ?? 'فشل التأكيد');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('خطأ في التأكيد: $e');
    }
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontSize: 14)),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'ordered':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusAr(String s) {
    switch (s) {
      case 'draft':
        return 'مسودة';
      case 'confirmed':
        return 'مؤكد';
      case 'ordered':
        return 'تم الطلب';
      case 'cancelled':
        return 'ملغى';
      default:
        return s;
    }
  }

  String _planTitleAr(String key) {
    switch (key) {
      case 'economic':
        return 'اقتصادي';
      case 'balanced':
        return 'متوازن';
      case 'premium':
        return 'أعلى أداء';
      default:
        return key;
    }
  }

  String _fmtNum(dynamic n) {
    final v = double.tryParse(n.toString()) ?? 0;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(0, size.height, 30, size.height);
    path.lineTo(size.width - 30, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
