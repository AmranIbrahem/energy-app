// lib/screens/solar/solar_project_summary_screen.dart

import 'dart:ui' as ui;

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/solar_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/services/system_builder_draft_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class SolarProjectSummaryScreen extends StatefulWidget {
  final ApiService apiService;
  final StorageService storageService;
  final int projectId;
  final String? sessionId;

  const SolarProjectSummaryScreen({
    Key? key,
    required this.apiService,
    required this.storageService,
    required this.projectId,
    this.sessionId,
  }) : super(key: key);

  @override
  State<SolarProjectSummaryScreen> createState() =>
      _SolarProjectSummaryScreenState();
}

class _SolarProjectSummaryScreenState extends State<SolarProjectSummaryScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  bool get _isSypPreferred {
    try {
      return widget.storageService.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _fmt(double amount, {String? currency}) {
    final curr = currency ?? (_isSypPreferred ? 'SYP' : 'USD');
    final n = amount.toStringAsFixed(2);
    if (curr == 'SYP') return '$n SYP';
    return '\$$n';
  }

  String _fmtNum(dynamic n) {
    final v = double.tryParse(n.toString()) ?? 0;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    _load();
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

      final res = await widget.apiService.solarShowProject(
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

  Future<void> _duplicate() async {
    final token = widget.storageService.getToken();
    final isGuest = token == null || token.isEmpty;

    final res = await widget.apiService.solarDuplicateProject(
      projectId: widget.projectId,
      sessionId: isGuest ? widget.sessionId : null,
      requiresAuth: !isGuest,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackBar('تم إنشاء نسخة: ${res['data']?['project_number'] ?? ''}',
          isSuccess: true);
    } else {
      _showSnackBar(res['message']?.toString() ?? 'فشل النسخ');
    }
  }

  void _addProjectToDesign() {
    final chosenPlan = _data?['chosen_plan'];
    if (chosenPlan is! Map) {
      _showSnackBar('لا توجد خطة محفوظة في هذا المشروع');
      return;
    }

    final products = (chosenPlan['products'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (products.isEmpty) {
      _showSnackBar('لا توجد منتجات في هذه الخطة');
      return;
    }

    final panels = <Map<String, dynamic>>[];
    final inverters = <Map<String, dynamic>>[];
    final batteries = <Map<String, dynamic>>[];

    for (final p in products) {
      final product = Map<String, dynamic>.from(p);
      final type = product['product_type']?.toString() ?? '';
      final price =
          double.tryParse(product['final_price']?.toString() ?? '0') ?? 0;
      final quantity = product['quantity'] ?? 1;
      final item = {
        'id': product['product_id'],
        'name': product['title_ar'] ?? '',
        'price': price,
        'quantity': quantity,
      };
      switch (type) {
        case 'inverter':
          inverters.add(item);
          break;
        case 'battery':
          batteries.add(item);
          break;
        case 'solar_panel':
          panels.add(item);
          break;
      }
    }

    SystemBuilderDraftService.instance.saveDraft(
      panels: panels,
      inverters: inverters,
      batteries: batteries,
      cables: [],
      panelBoards: [],
    );

    _showSnackBar('تم حفظ مكونات الخطة في مسودة التصميم اليدوي 📋',
        isSuccess: true);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                    child: Text('ملخص المشروع',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _duplicate,
                    tooltip: 'إنشاء نسخة',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, color: Colors.red)),
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
      );
    }

    if (_data == null) {
      return Center(
        child: Text('لا توجد بيانات',
            style: GoogleFonts.cairo(color: Colors.grey.shade600)),
      );
    }

    final chosenPlan = _data!['chosen_plan'];
    final plan = chosenPlan is Map
        ? Map<String, dynamic>.from(chosenPlan)
        : <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 16),
        if (plan.isNotEmpty) ...[
          _buildPlanSection(plan),
          const SizedBox(height: 16),
        ],
        _buildLoadsSection(),
        const SizedBox(height: 16),
        if (plan.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addProjectToDesign,
              icon: const Icon(Icons.design_services_rounded),
              label: Text(
                'أضف إلى التصميم اليدوي',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final number = _data!['project_number']?.toString() ?? '';
    final status = _data!['status']?.toString() ?? 'draft';
    final equipmentRaw = _data!['equipment_total'];
    final equipmentMap = equipmentRaw is Map
        ? Map<String, dynamic>.from(equipmentRaw)
        : <String, dynamic>{};

    final amount =
        double.tryParse(equipmentMap['amount']?.toString() ?? '0') ?? 0;
    final currency = equipmentMap['currency']?.toString() ?? 'USD';

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
                child: Text(number,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
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
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  )),
              Text(_fmt(amount, currency: currency),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(Map<String, dynamic> plan) {
    final title = plan['title_ar']?.toString() ?? '';
    final panelUnits = plan['panel_units'] ?? 0;
    final batteryUnits = plan['battery_units'] ?? 0;
    final inverterW = plan['inverter_rated_w'] ?? 0;
    final pvW = plan['pv_array_w'] ?? 0;
    final batteryWh = plan['battery_nominal_wh'] ?? 0;
    final panelsPerString = plan['panels_per_string'] ?? 0;
    final stringCount = plan['string_count'] ?? 0;

    final products = (plan['products'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 6),
              Text('الخطة: $title',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip('الألواح', '$panelUnits', Icons.solar_power_rounded),
              _chip('البطاريات', '$batteryUnits',
                  Icons.battery_charging_full_rounded),
              _chip('العاكس', '${_fmtNum(inverterW)} W', Icons.power_rounded),
              _chip('مصفوفة PV', '${_fmtNum(pvW)} W', Icons.wb_sunny_rounded),
              if (batteryWh > 0)
                _chip(
                    'سعة البطارية',
                    '${(double.tryParse(batteryWh.toString()) ?? 0 / 1000).toStringAsFixed(1)} kWh',
                    Icons.ev_station_rounded),
              if (panelsPerString > 0 && stringCount > 0)
                _chip('السلاسل', '$panelsPerString × $stringCount',
                    Icons.link_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          Text('المنتجات (${products.length})',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              )),
          const SizedBox(height: 10),
          ...products.map(_buildProductRow),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 5),
          Text('$label: ',
              style:
                  GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              )),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> p) {
    final name = p['title_ar']?.toString() ?? '';
    final brand = p['brand']?.toString() ?? '';
    final model = p['model']?.toString() ?? '';
    final image = p['image']?.toString() ?? '';
    final qty = p['quantity'] ?? 1;
    final finalPrice = p['final_price']?.toString() ?? '0';
    final currency = p['unit_price'] is Map
        ? (p['unit_price']['currency']?.toString() ?? 'USD')
        : 'USD';

    return Container(
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
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 18),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 18),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (brand.isNotEmpty || model.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$brand${model.isNotEmpty ? " - $model" : ""}',
                    style: GoogleFonts.cairo(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_fmt(double.tryParse(finalPrice) ?? 0, currency: currency)} × $qty',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadsSection() {
    final engineResult = _data!['engine_result'];
    if (engineResult is! Map) return const SizedBox.shrink();

    final loadProfile =
        (engineResult['technical_data']?['load_profile'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    if (loadProfile.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأجهزة (${loadProfile.length})',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              )),
          const SizedBox(height: 10),
          ...loadProfile.map((l) => _buildLoadRow(l)),
        ],
      ),
    );
  }

  Widget _buildLoadRow(Map<String, dynamic> load) {
    final name = load['name_ar']?.toString() ?? '';
    final qty = load['quantity'] ?? 1;
    final power = load['power_w'] ?? 0;
    final dayH = load['day_hours'] ?? 0;
    final nightH = load['night_hours'] ?? 0;
    final heavy = load['heavy'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (heavy)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.whatshot_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
            ),
          Expanded(
            child: Text('$name × $qty', style: GoogleFonts.cairo(fontSize: 12)),
          ),
          Text('${_fmtNum(power)}W',
              style:
                  GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          if ((dayH as num) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('نهار $dayH',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: const Color(0xFF92400E))),
            ),
          const SizedBox(width: 4),
          if ((nightH as num) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('مساء $nightH',
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: const Color(0xFF4338CA))),
            ),
        ],
      ),
    );
  }

  String _statusAr(String s) {
    switch (s) {
      case 'draft':
        return 'مسودة';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغى';
      default:
        return s;
    }
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
