// lib/screens/company/offers/edit_offer_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditOfferScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int offerId;

  const EditOfferScreen({super.key, required this.authService, required this.storageService, required this.offerId});

  @override
  State<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;
  bool _isLoading = true;

  final _nameArController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _installationPriceController = TextEditingController();
  final _totalWattageController = TextEditingController();
  final _totalCapacityController = TextEditingController();
  final _descriptionArController = TextEditingController();

  bool _isActive = true;
  bool _isFeatured = false;

  // ✅ متغيرات الشحن
  bool _hasShipping = false;
  Map<String, TextEditingController> _shippingCostControllers = {};
  Map<String, bool> _selectedShippingCities = {}; // ✅ جديد لتتبع التحديد

  // ✅ تمت إضافة ريف دمشق
  final List<String> _syrianCities = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'حماة', 'درعا',
    'السويداء', 'القنيطرة', 'دير الزور', 'الرقة', 'الحسكة', 'إدلب'
  ];

  String? _currentCoverUrl;
  File? _newCoverImage;
  bool _removeCover = false;

  List<Map<String, dynamic>> _currentImages = [];
  List<File> _newImages = [];
  List<int> _deletedImageIds = [];

  List<dynamic> _availableProducts = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  final TextEditingController _productSearchController = TextEditingController();

  List<Map<String, TextEditingController>> _components = [];
  List<Map<String, TextEditingController>> _specifications = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) _apiService.setToken(widget.authService.token!);
    _initShippingCostControllers();
    _fetchProducts();
    _fetchOffer();
  }

  // ✅ تهيئة Controllers لأسعار الشحن مع التحديد
  void _initShippingCostControllers() {
    for (var city in _syrianCities) {
      _shippingCostControllers[city] = TextEditingController();
      _selectedShippingCities[city] = false;
    }
  }

  @override
  void dispose() {
    _nameArController.dispose(); _priceController.dispose(); _discountPriceController.dispose();
    _installationPriceController.dispose(); _totalWattageController.dispose(); _totalCapacityController.dispose();
    _descriptionArController.dispose(); _productSearchController.dispose();
    _shippingCostControllers.forEach((_, controller) => controller.dispose());
    for (var c in _components) { c['key']?.dispose(); c['value']?.dispose(); }
    for (var s in _specifications) { s['key']?.dispose(); s['value']?.dispose(); }
    super.dispose();
  }

  // ✅ دالة تحديد اتجاه النص
  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final firstChar = trimmed.characters.first;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
    return TextDirection.ltr;
  }

  // ✅ تبديل اختيار المدينة
  void _toggleCity(String city) {
    setState(() {
      _selectedShippingCities[city] = !_selectedShippingCities[city]!;
      if (!_selectedShippingCities[city]!) {
        _shippingCostControllers[city]?.clear();
      }
    });
  }

  // ✅ عدد المدن المحددة
  int get _selectedCitiesCount =>
      _selectedShippingCities.values.where((selected) => selected).length;

  Future<void> _fetchProducts() async {
    try {
      final response = await _apiService.get('/v1/company/offers/products', requiresAuth: true);
      if (response['data'] != null && mounted) setState(() => _availableProducts = response['data']['products'] ?? []);
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _fetchOffer() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/company/offers/${widget.offerId}', requiresAuth: true);
      if (response['data'] != null && mounted) {
        final offer = response['data']['offer'];
        _nameArController.text = offer['name_ar'] ?? '';
        _priceController.text = offer['price'] ?? '';
        _discountPriceController.text = offer['discount_price'] ?? '';
        _installationPriceController.text = offer['installation_price'] ?? '';
        _totalWattageController.text = offer['total_wattage']?.toString() ?? '';
        _totalCapacityController.text = offer['total_capacity']?.toString() ?? '';
        _descriptionArController.text = offer['description_ar'] ?? '';
        _isActive = offer['is_active'] ?? true;
        _isFeatured = offer['is_featured'] ?? false;
        _currentCoverUrl = offer['cover_image'];

        _hasShipping = offer['has_shipping'] ?? false;

        // ✅ تحميل مدن الشحن مع الأسعار والتحديد
        if (offer['shipping_cities'] != null) {
          List<dynamic> citiesData = [];

          if (offer['shipping_cities'] is List) {
            citiesData = offer['shipping_cities'] as List;
          } else if (offer['shipping_cities'] is String) {
            try {
              citiesData = jsonDecode(offer['shipping_cities']) as List;
            } catch (_) {
              citiesData = [];
            }
          }

          for (var cityData in citiesData) {
            if (cityData is String) {
              if (_shippingCostControllers.containsKey(cityData)) {
                _shippingCostControllers[cityData]!.text = '';
                _selectedShippingCities[cityData] = true;
              }
            } else if (cityData is Map) {
              final city = cityData['city']?.toString() ?? '';
              final cost = cityData['cost']?.toString() ?? '';
              if (_shippingCostControllers.containsKey(city)) {
                _shippingCostControllers[city]!.text = cost;
                _selectedShippingCities[city] = true;
              }
            }
          }
        }

        _currentImages = (offer['additional_images'] as List?)?.map((img) => {'id': img['id'], 'url': img['image'] ?? ''}).toList().cast<Map<String, dynamic>>() ?? [];
        _selectedProducts = (offer['products'] as List?)?.map((p) => {'id': p['id'], 'name': p['name_ar'] ?? p['name'] ?? '', 'quantity': p['quantity'] ?? 1}).toList() ?? [];

        final comps = offer['components'] as List?;
        if (comps != null) for (var c in comps) _components.add({'key': TextEditingController(text: c['key'] ?? ''), 'value': TextEditingController(text: c['value'] ?? '')});
        if (_components.isEmpty) _components.add({'key': TextEditingController(), 'value': TextEditingController()});

        final specs = offer['specifications'] as List?;
        if (specs != null) for (var s in specs) _specifications.add({'key': TextEditingController(text: s['key'] ?? ''), 'value': TextEditingController(text: s['value'] ?? '')});
        if (_specifications.isEmpty) _specifications.add({'key': TextEditingController(), 'value': TextEditingController()});

        setState(() => _isLoading = false);
      }
    } catch (e) { if (mounted) { setState(() => _isLoading = false); _showSnackBar('حدث خطأ', dangerRed); } }
  }

  Future<void> _pickNewCover() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (image != null) setState(() { _newCoverImage = File(image.path); _removeCover = false; });
  }

  void _markCoverForRemoval() => setState(() { _removeCover = true; _newCoverImage = null; _currentCoverUrl = null; });
  void _undoRemoveCover() => setState(() { _removeCover = false; _newCoverImage = null; });

  Future<void> _pickNewImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (images.isNotEmpty) setState(() => _newImages.addAll(images.map((img) => File(img.path))));
  }

  void _markImageForDeletion(int index) {
    final imageData = _currentImages[index];
    setState(() { _deletedImageIds.add(imageData['id']); _currentImages.removeAt(index); });
  }

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));

  void _addComponent() => setState(() => _components.add({'key': TextEditingController(), 'value': TextEditingController()}));
  void _removeComponent(int i) { _components[i]['key']?.dispose(); _components[i]['value']?.dispose(); setState(() => _components.removeAt(i)); }
  void _addSpecification() => setState(() => _specifications.add({'key': TextEditingController(), 'value': TextEditingController()}));
  void _removeSpecification(int i) { _specifications[i]['key']?.dispose(); _specifications[i]['value']?.dispose(); setState(() => _specifications.removeAt(i)); }

  void _showAddProductDialog() {
    int? selectedId; int quantity = 1;
    List<dynamic> searchResults = List.from(_availableProducts);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('إضافة منتج', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          TextField(
              controller: searchController,
              style: GoogleFonts.cairo(fontSize: 13),
              textDirection: _getTextDirection(searchController.text),
              decoration: InputDecoration(
                  hintText: '🔍 بحث عن منتج...',
                  prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
                  suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { searchController.clear(); setModalState(() => searchResults = List.from(_availableProducts)); }) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14)
              ),
              onChanged: (v) => setModalState(() => searchResults = v.isEmpty ? List.from(_availableProducts) : _availableProducts.where((p) => (p['name_ar'] ?? '').toLowerCase().contains(v.toLowerCase()) || (p['sku'] ?? '').toLowerCase().contains(v.toLowerCase())).toList())
          ),
          const SizedBox(height: 12),
          Flexible(child: ListView.builder(shrinkWrap: true, itemCount: searchResults.length, itemBuilder: (_, i) {
            final p = searchResults[i]; final isAlreadyAdded = _selectedProducts.any((sp) => sp['id'] == p['id']);
            return ListTile(
                enabled: !isAlreadyAdded,
                selected: p['id'] == selectedId,
                selectedTileColor: primaryBlue.withOpacity(0.08),
                title: Text(p['name_ar'] ?? '', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600), textDirection: _getTextDirection(p['name_ar'] ?? '')),
                subtitle: Text('SKU: ${p['sku']} | ${p['price']} \$', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
                trailing: isAlreadyAdded ? Text('مضاف', style: GoogleFonts.cairo(fontSize: 11, color: successGreen)) : (p['id'] == selectedId ? const Icon(Icons.check_rounded, color: primaryBlue) : null),
                onTap: () => setModalState(() => selectedId = p['id'])
            );
          })),
          const SizedBox(height: 12),
          if (selectedId != null) TextField(keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: 'الكمية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: (v) => quantity = int.tryParse(v) ?? 1),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: selectedId != null ? () { final product = _availableProducts.firstWhere((p) => p['id'] == selectedId); setState(() => _selectedProducts.add({'id': product['id'], 'name': product['name_ar'] ?? '', 'quantity': quantity})); Navigator.pop(ctx); } : null,
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('إضافة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ]),
      )),
    );
  }

  void _removeProduct(int index) => setState(() => _selectedProducts.removeAt(index));

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProducts.isEmpty) { _showSnackBar('الرجاء إضافة منتج واحد على الأقل', dangerRed); return; }
    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/v1/company/offers/${widget.offerId}'));
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      request.fields.addAll({
        'name_ar': _nameArController.text.trim(), 'price': _priceController.text.trim(),
        'discount_price': _discountPriceController.text.isNotEmpty ? _discountPriceController.text.trim() : '',
        'installation_price': _installationPriceController.text.isNotEmpty ? _installationPriceController.text.trim() : '',
        'total_wattage': _totalWattageController.text.isNotEmpty ? _totalWattageController.text.trim() : '',
        'total_capacity': _totalCapacityController.text.isNotEmpty ? _totalCapacityController.text.trim() : '',
        'description_ar': _descriptionArController.text.trim(),
        'is_active': _isActive ? '1' : '0', 'is_featured': _isFeatured ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
      });

      // ✅ إرسال المدن المحددة فقط
      if (_hasShipping) {
        final shippingCities = _syrianCities
            .where((city) => _selectedShippingCities[city] == true)
            .map((city) {
          final costText = _shippingCostControllers[city]!.text.trim();
          return {
            'city': city,
            'cost': costText.isEmpty ? null : costText,
          };
        }).toList();

        if (shippingCities.isNotEmpty) {
          request.fields['shipping_cities'] = jsonEncode(shippingCities);
          debugPrint('📢 Shipping Cities (JSON): ${jsonEncode(shippingCities)}');
        } else {
          request.fields['shipping_cities'] = jsonEncode([]);
        }
      }

      if (_removeCover) request.fields['remove_cover_image'] = '1';

      final comps = <Map<String, String>>[];
      for (var c in _components) { final k = c['key']?.text.trim() ?? ''; final v = c['value']?.text.trim() ?? ''; if (k.isNotEmpty || v.isNotEmpty) comps.add({'key': k, 'value': v}); }
      if (comps.isNotEmpty) request.fields['components'] = jsonEncode(comps);

      final specs = <Map<String, String>>[];
      for (var s in _specifications) { final k = s['key']?.text.trim() ?? ''; final v = s['value']?.text.trim() ?? ''; if (k.isNotEmpty || v.isNotEmpty) specs.add({'key': k, 'value': v}); }
      if (specs.isNotEmpty) request.fields['specifications'] = jsonEncode(specs);

      for (int i = 0; i < _selectedProducts.length; i++) {
        request.fields['products[$i][id]'] = _selectedProducts[i]['id'].toString();
        request.fields['products[$i][quantity]'] = _selectedProducts[i]['quantity'].toString();
      }

      for (var id in _deletedImageIds) request.fields['delete_images[]'] = id.toString();

      if (_newCoverImage != null) request.files.add(await http.MultipartFile.fromPath('cover_image', _newCoverImage!.path));
      for (var img in _newImages) request.files.add(await http.MultipartFile.fromPath('images[]', img.path));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (mounted) {
        setState(() => _isSaving = false);
        if (data['success'] == true || data['data'] != null) { _showSnackBar('تم تحديث العرض بنجاح 🎉', successGreen); Navigator.pop(context, true); }
        else { _showSnackBar(data['message'] ?? 'فشل تحديث العرض', dangerRed); }
      }
    } catch (e) { if (mounted) { setState(() => _isSaving = false); _showSnackBar('حدث خطأ', dangerRed); } }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.info_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 14), textDirection: _getTextDirection(message)))
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
          backgroundColor: cardWhite, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: darkColor), onPressed: () => Navigator.pop(context)),
          title: Text('تعديل العرض', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor))
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryBlue)) : Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildSection('معلومات أساسية', Icons.info_rounded), const SizedBox(height: 12),
                _buildTextField(_nameArController, 'اسم العرض *', 'أدخل اسم العرض'), const SizedBox(height: 12),
                _buildTextField(_descriptionArController, 'الوصف', 'وصف العرض', maxLines: 3), const SizedBox(height: 24),

                _buildSection('السعر', Icons.attach_money_rounded), const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildTextField(_priceController, 'السعر *', '0.00', keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_discountPriceController, 'سعر الخصم', '0.00', keyboardType: TextInputType.number, textDirection: TextDirection.ltr))
                ]),
                const SizedBox(height: 12),
                _buildTextField(_installationPriceController, 'سعر التركيب', '0.00', keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
                const SizedBox(height: 24),

                _buildSolarEnergySection(),
                const SizedBox(height: 24),

                _buildSection('الصور', Icons.image_rounded), const SizedBox(height: 12),
                _buildCoverImageSection(), const SizedBox(height: 12),
                _buildImagesSection(), const SizedBox(height: 24),

                _buildSection('منتجات العرض *', Icons.inventory_2_rounded), const SizedBox(height: 12),
                _buildProductsSection(), const SizedBox(height: 24),

                _buildSection('المكونات والمواصفات', Icons.list_alt_rounded), const SizedBox(height: 12),
                _buildComponentsSection(), const SizedBox(height: 12),
                _buildSpecificationsSection(), const SizedBox(height: 24),

                _buildSection('الشحن', Icons.local_shipping_rounded), const SizedBox(height: 12),
                _buildShippingSection(), const SizedBox(height: 24),

                _buildToggles(), const SizedBox(height: 30),
                _buildSaveButton(), const SizedBox(height: 30),
              ])
          )
      ),
    );
  }

  Widget _buildSolarEnergySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warningOrange.withOpacity(0.08), warningOrange.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.solar_power_rounded, size: 20, color: warningOrange),
              ),
              const SizedBox(width: 10),
              Text(
                'خاص بالعروض الطاقة الشمسية',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: warningOrange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'هذه الحقول اختيارية وتستخدم فقط لعروض الطاقة الشمسية',
            style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
          ),
          const SizedBox(height: 14),
          _buildSolarField(
            controller: _totalWattageController,
            label: 'الواطية',
            hint: 'مثال: 800',
            icon: Icons.bolt_rounded,
            description: 'قوة الكهرباء اللحظية - قديش بينتج باللحظة',
          ),
          const SizedBox(height: 12),
          _buildSolarField(
            controller: _totalCapacityController,
            label: 'السعة',
            hint: 'مثال: 4800',
            icon: Icons.battery_charging_full_rounded,
            description: 'قديش ممكن يخزن من الطاقة',
          ),
        ],
      ),
    );
  }

  Widget _buildSolarField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
          style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
            hintText: hint,
            hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
            hintTextDirection: TextDirection.ltr,
            filled: true,
            fillColor: cardWhite,
            prefixIcon: Icon(icon, size: 20, color: warningOrange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: warningOrange, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: warningOrange.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(description, style: GoogleFonts.cairo(fontSize: 11, color: mediumGray.withOpacity(0.8))),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ قسم الشحن - اختيار المدن بالنقر + أسعار للمحددة فقط
  Widget _buildShippingSection() {
    final selectedCities = _syrianCities
        .where((city) => _selectedShippingCities[city] == true)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ✅ Toggle الشحن
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.local_shipping_rounded, color: _hasShipping ? primaryBlue : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Text(_hasShipping ? 'الشحن متاح' : 'الشحن غير متاح', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: _hasShipping ? primaryBlue : mediumGray)),
          ]),
          GestureDetector(
            onTap: () => setState(() => _hasShipping = !_hasShipping),
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(color: _hasShipping ? primaryBlue : Colors.grey.shade300, borderRadius: BorderRadius.circular(14)),
              child: Stack(children: [
                AnimatedAlign(
                  alignment: _hasShipping ? Alignment.centerRight : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ]),
            ),
          ),
        ]),

        if (_hasShipping) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ✅ عنوان + عدد المدن المحددة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اختر المدن المتاحة للشحن',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor),
              ),
              Text(
                '${selectedCities.length} مدينة',
                style: GoogleFonts.cairo(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ شبكة المدن القابلة للنقر
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _syrianCities.map((city) {
              final isSelected = _selectedShippingCities[city] == true;

              return GestureDetector(
                onTap: () => _toggleCity(city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryBlue : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        city,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // ✅ قسم أسعار الشحن للمدن المحددة فقط
          if (selectedCities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'أسعار الشحن لكل مدينة',
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor),
            ),
            const SizedBox(height: 4),
            Text(
              'اترك السعر فارغاً لتحديده لاحقاً، أو ضع 0 للشحن المجاني',
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),

            // ✅ حقول أسعار الشحن للمدن المحددة
            ...selectedCities.map((city) {
              final costController = _shippingCostControllers[city]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lightGray,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: primaryBlue),
                          const SizedBox(width: 6),
                          Text(city, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'سعر الشحن (اختياري)',
                          hintStyle: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400),
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.cairo(fontSize: 12, color: successGreen, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: costController.text.isNotEmpty ? successGreen : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: costController.text.isNotEmpty ? successGreen : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ]),
    );
  }

  Widget _buildSection(String title, IconData icon) => Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.12), primaryBlue.withOpacity(0.06)]), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: primaryBlue)), const SizedBox(width: 10), Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor))]);

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        TextDirection? textDirection,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      textDirection: textDirection ?? _getTextDirection(controller.text),
      textAlign: TextAlign.start,
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.5),
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
        hintTextDirection: _getTextDirection(hint),
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
      validator: label.contains('*') ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null : null,
    );
  }

  Widget _buildCoverImageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('صورة الغلاف', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)), const SizedBox(height: 8),
      if (_newCoverImage != null) Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_newCoverImage!, height: 200, width: double.infinity, fit: BoxFit.cover)), Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => setState(() => _newCoverImage = null), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: dangerRed, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))))])
      else if (_currentCoverUrl != null && !_removeCover) Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: _currentCoverUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)), Positioned(top: 8, right: 8, child: Row(children: [GestureDetector(onTap: _pickNewCover, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16))), const SizedBox(width: 6), GestureDetector(onTap: _markCoverForRemoval, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: dangerRed, shape: BoxShape.circle), child: const Icon(Icons.delete_rounded, color: Colors.white, size: 16)))])), Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)), child: Text('الصورة الحالية', style: GoogleFonts.cairo(fontSize: 10, color: Colors.white))))])
      else GestureDetector(onTap: _currentCoverUrl != null ? _undoRemoveCover : _pickNewCover, child: Container(height: 120, decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_currentCoverUrl != null ? Icons.undo_rounded : Icons.add_a_photo_rounded, size: 40, color: primaryBlue.withOpacity(0.6)), const SizedBox(height: 8), Text(_currentCoverUrl != null ? 'تراجع عن الحذف' : 'انقر لاختيار صورة الغلاف', style: GoogleFonts.cairo(fontSize: 12, color: mediumGray))])))),
    ]);
  }

  Widget _buildImagesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('صور إضافية', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)), const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ..._currentImages.asMap().entries.map((e) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: e.value['url'] ?? '', width: 80, height: 80, fit: BoxFit.cover)), Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => _markImageForDeletion(e.key), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: dangerRed, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 14))))])),
        ..._newImages.asMap().entries.map((e) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(e.value, width: 80, height: 80, fit: BoxFit.cover)), Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => _removeNewImage(e.key), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: dangerRed, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 14))))])),
        GestureDetector(onTap: _pickNewImages, child: Container(width: 80, height: 80, decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)), child: Center(child: Icon(Icons.add_rounded, size: 30, color: primaryBlue.withOpacity(0.6))))),
      ]),
    ]);
  }

  Widget _buildProductsSection() {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [
      if (_selectedProducts.isNotEmpty) ..._selectedProducts.asMap().entries.map((e) => Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))), child: Row(children: [Expanded(child: Text('${e.value['name']} (${e.value['quantity']} قطعة)', style: GoogleFonts.cairo(fontSize: 13, color: darkColor), textDirection: _getTextDirection(e.value['name'] ?? ''))), GestureDetector(onTap: () => _removeProduct(e.key), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.delete_rounded, color: dangerRed, size: 18)))]))).toList(),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _showAddProductDialog, icon: const Icon(Icons.add_rounded, color: primaryBlue), label: Text('إضافة منتج', style: GoogleFonts.cairo(color: primaryBlue)), style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ]));
  }

  Widget _buildComponentsSection() => Column(children: [
    ..._components.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: TextField(controller: e.value['key'], textDirection: _getTextDirection(e.value['key']!.text), style: GoogleFonts.cairo(fontSize: 13), decoration: InputDecoration(hintText: 'المكون', filled: true, fillColor: cardWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), isDense: true))), const SizedBox(width: 8), Expanded(child: TextField(controller: e.value['value'], textDirection: _getTextDirection(e.value['value']!.text), style: GoogleFonts.cairo(fontSize: 13), decoration: InputDecoration(hintText: 'القيمة', filled: true, fillColor: cardWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), isDense: true))), const SizedBox(width: 4), GestureDetector(onTap: () => _removeComponent(e.key), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: dangerRed, size: 18)))]))),
    TextButton.icon(onPressed: _addComponent, icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 18), label: Text('إضافة مكون', style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue))),
  ]);

  Widget _buildSpecificationsSection() => Column(children: [
    ..._specifications.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: TextField(controller: e.value['key'], textDirection: _getTextDirection(e.value['key']!.text), style: GoogleFonts.cairo(fontSize: 13), decoration: InputDecoration(hintText: 'المواصفة', filled: true, fillColor: cardWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), isDense: true))), const SizedBox(width: 8), Expanded(child: TextField(controller: e.value['value'], textDirection: _getTextDirection(e.value['value']!.text), style: GoogleFonts.cairo(fontSize: 13), decoration: InputDecoration(hintText: 'القيمة', filled: true, fillColor: cardWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), isDense: true))), const SizedBox(width: 4), GestureDetector(onTap: () => _removeSpecification(e.key), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: dangerRed, size: 18)))]))),
    TextButton.icon(onPressed: _addSpecification, icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 18), label: Text('إضافة مواصفة', style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue))),
  ]);

  Widget _buildToggles() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [
    SwitchListTile(title: Text('عرض نشط', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)), value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: successGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    const Divider(),
    SwitchListTile(title: Text('عرض مميز', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text('يظهر في قسم العروض المميزة', style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v), activeColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
  ]));

  Widget _buildSaveButton() => SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isSaving ? null : _saveOffer, style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5), child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.save_rounded, color: Colors.white, size: 22), const SizedBox(width: 10), Text('تحديث العرض', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))])));
}