// lib/screens/system_builder/system_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/system_builder_service.dart';
import 'auto_design_screen.dart';
import 'order_history_screen.dart';

class SystemBuilderScreen extends StatefulWidget {
  final AuthService authService;

  const SystemBuilderScreen({super.key, required this.authService});

  @override
  State<SystemBuilderScreen> createState() => _SystemBuilderScreenState();
}

class _SystemBuilderScreenState extends State<SystemBuilderScreen>
    with TickerProviderStateMixin {
  late SystemBuilderService _service;
  String? _analysisQuestion;
  final TextEditingController _questionController = TextEditingController();

  List<Map<String, dynamic>> _selectedPanels = [];
  List<Map<String, dynamic>> _selectedInverters = [];
  List<Map<String, dynamic>> _selectedBatteries = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isAnalyzing = false;
  String? _notes;
  String? _aiAnalysis;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFFFD700);

  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();
    _service = SystemBuilderService(authService: widget.authService);
    _pulseAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0;
    for (var panel in _selectedPanels) total += (panel['price'] ?? 0) * (panel['quantity'] ?? 1);
    for (var inverter in _selectedInverters) total += (inverter['price'] ?? 0) * (inverter['quantity'] ?? 1);
    for (var battery in _selectedBatteries) total += (battery['price'] ?? 0) * (battery['quantity'] ?? 1);
    return total;
  }

  int get _totalItems {
    int count = 0;
    for (var p in _selectedPanels) count += (p['quantity'] ?? 1) as int;
    for (var i in _selectedInverters) count += (i['quantity'] ?? 1) as int;
    for (var b in _selectedBatteries) count += (b['quantity'] ?? 1) as int;
    return count;
  }

  bool get _isComplete => _selectedPanels.isNotEmpty && _selectedInverters.isNotEmpty && _selectedBatteries.isNotEmpty;

  Future<void> _submitOrder() async {
    final isGuest = !widget.authService.isAuthenticated;
    if (isGuest) { _showSnackBar('يرجى تسجيل الدخول', Colors.orange); return; }
    if (!_isComplete) { _showSnackBar('يرجى اختيار جميع المكونات', Colors.orange); return; }
    setState(() => _isSubmitting = true);
    final result = await _service.createOrder(panels: _selectedPanels, inverters: _selectedInverters, batteries: _selectedBatteries, notes: _notes);
    setState(() => _isSubmitting = false);
    if (result['success']) {
      _showSnackBar('تم إرسال طلب التصميم بنجاح! 🎉', Colors.green);
      setState(() { _selectedPanels.clear(); _selectedInverters.clear(); _selectedBatteries.clear(); _notes = null; _aiAnalysis = null; });
    } else { _showSnackBar(result['message'] ?? 'حدث خطأ', Colors.red); }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.cairo()), backgroundColor: color,
      behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(20),
    ));
  }

  void _navigateToHistory() {
    if (!widget.authService.isAuthenticated) { _showSnackBar('يرجى تسجيل الدخول', Colors.orange); return; }
    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistoryScreen(authService: widget.authService)));
  }


  void _openAutoDesign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AutoDesignScreen(authService: widget.authService, service: _service)),
    );
    if (result != null && mounted) {
      _applyAutoDesign(result);
    }
  }


  void _applyAutoDesign(dynamic result) {
    if (result == null) return;
    setState(() {
      for (var panel in (result['panels'] as List? ?? [])) {
        _selectedPanels.add({'id': panel['id'], 'name': panel['name'], 'price': (panel['price'] ?? 0).toDouble(), 'quantity': panel['quantity'] ?? 1});
      }
      for (var inverter in (result['inverters'] as List? ?? [])) {
        _selectedInverters.add({'id': inverter['id'], 'name': inverter['name'], 'price': (inverter['price'] ?? 0).toDouble(), 'quantity': inverter['quantity'] ?? 1});
      }
      for (var battery in (result['batteries'] as List? ?? [])) {
        _selectedBatteries.add({'id': battery['id'], 'name': battery['name'], 'price': (battery['price'] ?? 0).toDouble(), 'quantity': battery['quantity'] ?? 1});
      }
    });
    _showSnackBar('تم تطبيق منتجات المنظومة! يمكنك التعديل عليها الآن ✏️', Colors.green);
  }

  void _addItem(String type) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductPickerScreen(type: type, authService: widget.authService, onSelected: (product, quantity) {
      setState(() {
        _aiAnalysis = null;
        double getPrice(dynamic price) {
          if (price == null) return 0.0;
          if (price is String) return double.tryParse(price) ?? 0.0;
          if (price is num) return price.toDouble();
          return 0.0;
        }
        final typeMap = {'panels': _selectedPanels, 'inverters': _selectedInverters, 'batteries': _selectedBatteries};
        final list = typeMap[type]!;
        final existingIndex = list.indexWhere((p) => p['id'] == product['id']);
        final price = getPrice(product['final_price'] ?? product['price']);
        final discountPrice = getPrice(product['discount_price']);
        final finalPrice = discountPrice > 0 ? discountPrice : price;
        if (existingIndex != -1) { list[existingIndex]['quantity'] += quantity; }
        else { list.add({'id': product['id'], 'name': product['name_ar'] ?? product['name'], 'price': finalPrice, 'quantity': quantity}); }
      });
    })));
  }

  void _updateQuantity(List<Map<String, dynamic>> list, Map<String, dynamic> item, int delta) {
    setState(() {
      _aiAnalysis = null;
      final newQty = (item['quantity'] ?? 1) + delta;
      if (newQty <= 0) { list.remove(item); } else { item['quantity'] = newQty; }
    });
  }

  Future<void> _analyzeSystem() async {
    setState(() => _isAnalyzing = true);
    final result = await _service.analyzeSystem(panels: _selectedPanels, inverters: _selectedInverters, batteries: _selectedBatteries, question: _analysisQuestion?.isNotEmpty == true ? _analysisQuestion : null);
    setState(() => _isAnalyzing = false);
    if (result['success'] == true) {
      setState(() => _aiAnalysis = result['data']['analysis'] ?? '');
      _showSnackBar('تم تحليل المنظومة بنجاح! 🎉', Colors.green);
    } else { _showSnackBar(result['message'] ?? 'فشل التحليل', Colors.red); }
  }

  void _showFullAnalysis() {
    if (_aiAnalysis == null) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.15), Colors.blue.withOpacity(0.08)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 24)), const SizedBox(width: 12), Expanded(child: Text('تحليل المنظومة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))])),
        const Divider(),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Text(_aiAnalysis ?? '', style: GoogleFonts.cairo(fontSize: 14, height: 1.8, color: Colors.grey.shade700)))),
      ]),
    ));
  }

  Widget _buildSelectedItems(String title, List<Map<String, dynamic>> items, Color color, String type) {
    final iconMap = {'الألواح الشمسية': Icons.solar_power_rounded, 'الانفرتر': Icons.memory_rounded, 'البطاريات': Icons.battery_charging_full_rounded};
    final totalPower = items.fold<double>(0, (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(iconMap[title] ?? Icons.category_rounded, color: color, size: 22)), const SizedBox(width: 12), Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)), if (items.isNotEmpty) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Text('${items.length}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)))]),
          Container(decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: TextButton.icon(onPressed: () => _addItem(type), icon: const Icon(Icons.add_circle_outline_rounded, size: 18), label: Text('إضافة', style: GoogleFonts.cairo()), style: TextButton.styleFrom(foregroundColor: primaryBlue))),
        ]),
        if (items.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Column(children: [Icon(iconMap[title] ?? Icons.category_rounded, size: 48, color: Colors.grey.shade300), const SizedBox(height: 8), Text('لم يتم اختيار أي عناصر', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500)), Text('اضغط على "إضافة" لاختيار ${title}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400))])))
        else ...[
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['name'] ?? 'غير معروف', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text('${(item['price'] ?? 0).toStringAsFixed(2)} \$ × ${item['quantity']}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600))])),
              Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: Row(children: [InkWell(onTap: () => _updateQuantity(items, item, -1), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(6), child: const Icon(Icons.remove_rounded, size: 16))), Container(width: 35, alignment: Alignment.center, child: Text('${item['quantity']}', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold))), InkWell(onTap: () => _updateQuantity(items, item, 1), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(6), child: const Icon(Icons.add_rounded, size: 16)))])),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text('${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
              const SizedBox(width: 4),
              InkWell(onTap: () => setState(() { _aiAnalysis = null; items.remove(item); }), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.close_rounded, color: Colors.red, size: 18))),
            ]),
          )).toList(),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('إجمالي ${title}', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)), Text('${totalPower.toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color))])),
        ],
      ]),
    );
  }

  Widget _buildStatisticsCard() {
    final panelPower = _selectedPanels.fold<double>(0, (sum, p) => sum + ((p['price'] ?? 0) * (p['quantity'] ?? 1)));
    final inverterPower = _selectedInverters.fold<double>(0, (sum, i) => sum + ((i['price'] ?? 0) * (i['quantity'] ?? 1)));
    final batteryPower = _selectedBatteries.fold<double>(0, (sum, b) => sum + ((b['price'] ?? 0) * (b['quantity'] ?? 1)));
    final hasData = _selectedPanels.isNotEmpty || _selectedInverters.isNotEmpty || _selectedBatteries.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.withOpacity(0.05), Colors.blue.withOpacity(0.05)]), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.green.withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 15)]),
      child: Column(children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.analytics_rounded, color: Colors.green, size: 24)), const SizedBox(width: 12), Text('إحصائيات مالية', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 20),
        _buildStatRow(icon: Icons.solar_power_rounded, label: 'الألواح الشمسية', detail: _selectedPanels.isNotEmpty ? '${_selectedPanels.length} نوع' : 'لم يتم الإضافة', total: _selectedPanels.isNotEmpty ? '${panelPower.toStringAsFixed(2)} \$' : '---', color: Colors.orange),
        const SizedBox(height: 12),
        _buildStatRow(icon: Icons.memory_rounded, label: 'الانفرتر', detail: _selectedInverters.isNotEmpty ? '${_selectedInverters.length} نوع' : 'لم يتم الإضافة', total: _selectedInverters.isNotEmpty ? '${inverterPower.toStringAsFixed(2)} \$' : '---', color: Colors.blue),
        const SizedBox(height: 12),
        _buildStatRow(icon: Icons.battery_charging_full_rounded, label: 'البطاريات', detail: _selectedBatteries.isNotEmpty ? '${_selectedBatteries.length} نوع' : 'لم يتم الإضافة', total: _selectedBatteries.isNotEmpty ? '${batteryPower.toStringAsFixed(2)} \$' : '---', color: Colors.green),
        if (hasData) ...[const SizedBox(height: 16), Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade200, primaryBlue.withOpacity(0.3), Colors.grey.shade200]))), const SizedBox(height: 16), _buildStatRow(icon: Icons.summarize_rounded, label: 'المجموع الكلي', detail: '${_totalItems} عنصر', total: '${_subtotal.toStringAsFixed(2)} \$', color: primaryBlue, isTotal: true)],
      ]),
    );
  }

  Widget _buildStatRow({required IconData icon, required String label, required String detail, required String total, required Color color, bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isTotal ? primaryBlue.withOpacity(0.3) : color.withOpacity(0.15), width: isTotal ? 1.5 : 1)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.12), color.withOpacity(0.06)]), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: isTotal ? 22 : 20)),
        const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.cairo(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)), const SizedBox(height: 2), Text(detail, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(gradient: LinearGradient(colors: isTotal ? [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)] : [color.withOpacity(0.08), color.withOpacity(0.04)]), borderRadius: BorderRadius.circular(12)), child: Text(total, style: GoogleFonts.cairo(fontSize: isTotal ? 16 : 14, fontWeight: FontWeight.bold, color: isTotal ? primaryBlue : color))),
      ]),
    );
  }

  Widget _buildAIAnalysisButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.05), Colors.blue.withOpacity(0.05)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple.withOpacity(0.2))),
      child: Column(children: [
        Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.15), Colors.blue.withOpacity(0.08)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 24)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تحليل المنظومة بالذكاء الاصطناعي', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text('اكتشف قوة منظومتك وما يمكن تشغيله', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))]))]),
        const SizedBox(height: 16),
        TextFormField(controller: _questionController, maxLines: 3, onChanged: (value) => _analysisQuestion = value, decoration: InputDecoration(hintText: 'هل لديك استفسارات إضافية؟', hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.2))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.purple.withOpacity(0.2))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple, width: 2)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(14), prefixIcon: const Icon(Icons.help_outline_rounded, color: Colors.purple, size: 22)), style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade700)),
        const SizedBox(height: 16),
        if (_aiAnalysis != null) ...[Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_aiAnalysis!, style: GoogleFonts.cairo(fontSize: 13, height: 1.6, color: Colors.grey.shade700), maxLines: 8, overflow: TextOverflow.ellipsis), const SizedBox(height: 12), TextButton.icon(onPressed: _showFullAnalysis, icon: const Icon(Icons.open_in_full_rounded, size: 16), label: Text('عرض التحليل الكامل', style: GoogleFonts.cairo(fontSize: 13)), style: TextButton.styleFrom(foregroundColor: Colors.purple))])), const SizedBox(height: 12)],
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _isAnalyzing ? null : _analyzeSystem, icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 20), label: Text(_isAnalyzing ? 'جاري التحليل...' : (_aiAnalysis != null ? 'إعادة التحليل' : 'تحليل المنظومة'), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _aiAnalysis != null ? Colors.teal : Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !widget.authService.isAuthenticated;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [primaryBlue, secondaryBlue]))),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [AnimatedBuilder(animation: _pulseAnimationController, builder: (context, child) => Transform.scale(scale: 1.0 + (_pulseAnimationController.value * 0.1), child: child), child: const Icon(Icons.design_services_rounded, color: gold, size: 24)), const SizedBox(width: 10), Text('تصميم منظومة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))]),
        elevation: 0, centerTitle: true,
        leading: Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context))),
        actions: [
          Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: IconButton(onPressed: _openAutoDesign, icon: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22), tooltip: 'صمم منظومتي تلقائياً')),
          Container(margin: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: IconButton(onPressed: _navigateToHistory, icon: const Icon(Icons.history_rounded, color: Colors.white), tooltip: 'سجل الطلبات')),
        ],
      ),
      body: _isSubmitting ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)), const SizedBox(height: 16), Text('جاري إرسال الطلب...', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600))])) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        if (isGuest) Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)), child: Row(children: [const Icon(Icons.info_outline_rounded, color: Colors.orange), const SizedBox(width: 12), Expanded(child: Text('سجل الدخول لحفظ وإرسال الطلبات', style: GoogleFonts.cairo(fontSize: 13, color: Colors.orange.shade800)))])),
        _buildSelectedItems('الألواح الشمسية', _selectedPanels, Colors.orange, 'panels'),
        _buildSelectedItems('الانفرتر', _selectedInverters, Colors.blue, 'inverters'),
        _buildSelectedItems('البطاريات', _selectedBatteries, Colors.green, 'batteries'),
        const SizedBox(height: 16), _buildStatisticsCard(), const SizedBox(height: 20),
        if (_selectedPanels.isNotEmpty && _selectedInverters.isNotEmpty && _selectedBatteries.isNotEmpty) _buildAIAnalysisButton(),
        if (_selectedPanels.isNotEmpty && _selectedInverters.isNotEmpty && _selectedBatteries.isNotEmpty) const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.note_rounded, color: primaryBlue, size: 20), const SizedBox(width: 8), Text('ملاحظات إضافية', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold))]), const SizedBox(height: 8), TextFormField(maxLines: 3, onChanged: (value) => _notes = value, decoration: InputDecoration(hintText: 'أضف ملاحظاتك هنا...', hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue)), filled: true, fillColor: Colors.grey.shade50), style: GoogleFonts.cairo())])),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isComplete ? _submitOrder : null, style: ElevatedButton.styleFrom(backgroundColor: _isComplete ? primaryBlue : Colors.grey.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: _isComplete ? 8 : 0), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isComplete ? Icons.send_rounded : Icons.lock_outline_rounded, size: 20), const SizedBox(width: 12), Text(_isComplete ? 'إرسال طلب التصميم' : 'أكمل اختيار جميع المكونات', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 16),
        if (!isGuest) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _navigateToHistory, icon: const Icon(Icons.history_rounded), label: Text('عرض سجل طلباتي', style: GoogleFonts.cairo(fontSize: 14)), style: OutlinedButton.styleFrom(foregroundColor: primaryBlue, side: BorderSide(color: primaryBlue.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 14)))),
      ])),
    );
  }
}


class ProductPickerScreen extends StatefulWidget {
  final String type;
  final AuthService authService;
  final Function(Map<String, dynamic>, int) onSelected;
  const ProductPickerScreen({super.key, required this.type, required this.authService, required this.onSelected});
  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  late SystemBuilderService _service;
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _service = SystemBuilderService(authService: widget.authService); _loadProducts(); }

  String _getTitle() { switch (widget.type) { case 'panels': return 'اختر الألواح الشمسية'; case 'inverters': return 'اختر الانفرتر'; case 'batteries': return 'اختر البطاريات'; default: return 'اختر المنتج'; } }
  Color _getColor() { switch (widget.type) { case 'panels': return Colors.orange; case 'inverters': return Colors.blue; case 'batteries': return Colors.green; default: return Colors.grey; } }
  IconData _getIcon() { switch (widget.type) { case 'panels': return Icons.solar_power_rounded; case 'inverters': return Icons.memory_rounded; case 'batteries': return Icons.battery_charging_full_rounded; default: return Icons.category_rounded; } }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getProducts(widget.type, search: _search, page: 1);
      if (result['success'] == true && mounted) {
        final data = result['data'];
        List<dynamic> productsList = [];
        if (data is List) { productsList = data; } else if (data is Map) { productsList = (data['data'] ?? data['products'] ?? data['items'] ?? []) as List; }
        setState(() { _products = productsList; _isLoading = false; });
      } else { setState(() => _isLoading = false); }
    } catch (e) { setState(() => _isLoading = false); }
  }

  double _getPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: Text(_getTitle(), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context))),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(12), color: Colors.white, child: TextField(onChanged: (value) { _search = value; _loadProducts(); }, decoration: InputDecoration(hintText: 'بحث...', hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400), prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(vertical: 8)), style: GoogleFonts.cairo())),
        Expanded(child: _isLoading ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(color)), const SizedBox(height: 16), Text('جاري التحميل...', style: GoogleFonts.cairo(color: Colors.grey.shade600))])) : _products.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_getIcon(), size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text('لا توجد منتجات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600))])) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _products.length, itemBuilder: (context, index) {
          final product = _products[index];
          final price = _getPrice(product['final_price'] ?? product['price']);
          final discountPrice = _getPrice(product['discount_price']);
          final finalPrice = discountPrice > 0 ? discountPrice : price;
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 60, height: 60, child: product['main_image'] != null ? Image.network(product['main_image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(_getIcon(), color: Colors.grey.shade400))) : Container(color: Colors.grey.shade100, child: Icon(_getIcon(), color: Colors.grey.shade400)))),
            const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['name_ar'] ?? product['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${finalPrice.toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color))), if (discountPrice > 0) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${price.toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.red)))])])),
            const SizedBox(width: 8), ElevatedButton(onPressed: () => _showQuantityDialog(product, finalPrice, price, discountPrice), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)), child: Text('اختيار', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold))),
          ]));
        })),
      ]),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> product, double finalPrice, double price, double discountPrice) {
    int quantity = 1;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(_getIcon(), color: _getColor()), const SizedBox(width: 12), Expanded(child: Text('اختر الكمية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(product['name_ar'] ?? product['name'] ?? '', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center), const SizedBox(height: 4), Text('السعر: ${finalPrice.toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)), if (discountPrice > 0) Text('${price.toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.red))])),
        const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Row(children: [IconButton(onPressed: () { if (quantity > 1) setDialogState(() => quantity--); }, icon: const Icon(Icons.remove_rounded), color: quantity > 1 ? Colors.black87 : Colors.grey.shade400), Container(width: 50, alignment: Alignment.center, child: Text('$quantity', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold))), IconButton(onPressed: () => setDialogState(() => quantity++), icon: const Icon(Icons.add_rounded), color: Colors.black87)]))]),
        const SizedBox(height: 8), Text('المجموع: ${(quantity * finalPrice).toStringAsFixed(2)} \$', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: _getColor())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey.shade600))), ElevatedButton(onPressed: () { Navigator.pop(context); widget.onSelected(product, quantity); }, style: ElevatedButton.styleFrom(backgroundColor: _getColor(), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: Text('تأكيد الاختيار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)))],
    )));
  }
}