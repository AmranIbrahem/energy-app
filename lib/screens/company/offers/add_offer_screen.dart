// lib/screens/company/offers/add_offer_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddOfferScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AddOfferScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color sypAmber = Color(0xFFD97706);

  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  final _nameArController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _installationPriceController = TextEditingController();
  final _totalWattageController = TextEditingController();
  final _totalCapacityController = TextEditingController();
  final _descriptionArController = TextEditingController();

  final _priceSypController = TextEditingController();
  final _discountPriceSypController = TextEditingController();
  final _installationPriceSypController = TextEditingController();

  double _exchangeRate = 0;
  bool _isLoadingRate = false;

  bool _isActive = true;
  bool _isFeatured = false;

  bool _hasShipping = false;
  Map<String, TextEditingController> _shippingCostControllers = {};
  Map<String, bool> _selectedShippingCities = {};

  final List<String> _syrianCities = [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'اللاذقية',
    'طرطوس',
    'حماة',
    'درعا',
    'السويداء',
    'القنيطرة',
    'دير الزور',
    'الرقة',
    'الحسكة',
    'إدلب'
  ];

  File? _coverImage;
  List<File> _additionalImages = [];

  List<dynamic> _availableProducts = [];
  List<Map<String, dynamic>> _selectedProducts = [];

  List<Map<String, TextEditingController>> _components = [];
  List<Map<String, TextEditingController>> _specifications = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _initShippingCostControllers();
    _fetchProducts();
    _fetchExchangeRate();
    _addComponent();
    _addSpecification();
  }

  void _initShippingCostControllers() {
    for (var city in _syrianCities) {
      _shippingCostControllers[city] = TextEditingController();
      _selectedShippingCities[city] = false;
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _installationPriceController.dispose();
    _totalWattageController.dispose();
    _totalCapacityController.dispose();
    _descriptionArController.dispose();

    _priceSypController.dispose();
    _discountPriceSypController.dispose();
    _installationPriceSypController.dispose();
    _shippingCostControllers.forEach((_, controller) => controller.dispose());
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var c in _components) {
      c['key']?.dispose();
      c['value']?.dispose();
    }
    for (var s in _specifications) {
      s['key']?.dispose();
      s['value']?.dispose();
    }
  }

  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final firstChar = trimmed.characters.first;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(firstChar)) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  void _toggleCity(String city) {
    setState(() {
      _selectedShippingCities[city] = !_selectedShippingCities[city]!;
      if (!_selectedShippingCities[city]!) {
        _shippingCostControllers[city]?.clear();
      }
    });
  }

  int get _selectedCitiesCount =>
      _selectedShippingCities.values.where((selected) => selected).length;

  Future<void> _fetchProducts() async {
    try {
      final response = await _apiService.get('/v1/company/offers/products',
          requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() => _availableProducts = response['data']['products'] ?? []);
      }
    } catch (e) {
      // debugPrint('Error fetching products: $e');
    }
  }

  Future<void> _fetchExchangeRate() async {
    setState(() => _isLoadingRate = true);
    try {
      final response = await _apiService.get(
        '/v1/user/public/setting/usd_to_syp_exchange_rate',
        requiresAuth: false,
      );
      if (response['data'] != null && mounted) {
        setState(() {
          _exchangeRate =
              double.tryParse(response['data']['value']?.toString() ?? '0') ??
                  0;
          _isLoadingRate = false;
        });
        // debugPrint('✅ سعر الصرف: $_exchangeRate');
      } else {
        if (mounted) setState(() => _isLoadingRate = false);
      }
    } catch (e) {
      // debugPrint('❌ Error fetching exchange rate: $e');
      if (mounted) setState(() => _isLoadingRate = false);
    }
  }

  void _autoFillSypPrices() {
    if (_exchangeRate <= 0) {
      _showSnackBar('سعر الصرف غير متوفر حالياً', dangerRed);
      return;
    }

    final priceUsd = double.tryParse(_priceController.text.trim()) ?? 0;
    if (priceUsd <= 0) {
      _showSnackBar('أدخل سعر الدولار أولاً', warningOrange);
      return;
    }

    setState(() {
      _priceSypController.text = (priceUsd * _exchangeRate).toStringAsFixed(0);

      final discountUsd =
          double.tryParse(_discountPriceController.text.trim()) ?? 0;
      if (discountUsd > 0) {
        _discountPriceSypController.text =
            (discountUsd * _exchangeRate).toStringAsFixed(0);
      } else {
        _discountPriceSypController.clear();
      }

      final installationUsd =
          double.tryParse(_installationPriceController.text.trim()) ?? 0;
      if (installationUsd > 0) {
        _installationPriceSypController.text =
            (installationUsd * _exchangeRate).toStringAsFixed(0);
      } else {
        _installationPriceSypController.clear();
      }
    });

    _showSnackBar('تم تعبئة الأسعار تلقائياً 🎉', successGreen);
  }

  String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) {
      return rate.toStringAsFixed(0);
    }
    return rate.toStringAsFixed(2);
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) setState(() => _coverImage = File(image.path));
  }

  Future<void> _pickAdditionalImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (images.isNotEmpty) {
      setState(
          () => _additionalImages.addAll(images.map((img) => File(img.path))));
    }
  }

  void _addComponent() => setState(() => _components.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      }));

  void _removeComponent(int i) {
    _components[i]['key']?.dispose();
    _components[i]['value']?.dispose();
    setState(() => _components.removeAt(i));
  }

  void _addSpecification() => setState(() => _specifications.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      }));

  void _removeSpecification(int i) {
    _specifications[i]['key']?.dispose();
    _specifications[i]['value']?.dispose();
    setState(() => _specifications.removeAt(i));
  }

  void _showAddProductDialog() {
    int? selectedId;
    int quantity = 1;
    List<dynamic> searchResults = List.from(_availableProducts);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('إضافة منتج',
                      style: GoogleFonts.cairo(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    style: GoogleFonts.cairo(fontSize: 13),
                    textDirection: _getTextDirection(searchController.text),
                    decoration: InputDecoration(
                      hintText: '🔍 بحث عن منتج...',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: primaryBlue),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() => searchResults =
                                    List.from(_availableProducts));
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                    ),
                    onChanged: (v) {
                      setModalState(() {
                        if (v.isEmpty) {
                          searchResults = List.from(_availableProducts);
                        } else {
                          searchResults = _availableProducts.where((p) {
                            final name = (p['name_ar'] ?? '').toLowerCase();
                            final sku = (p['sku'] ?? '').toLowerCase();
                            return name.contains(v.toLowerCase()) ||
                                sku.contains(v.toLowerCase());
                          }).toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (_, i) {
                        final p = searchResults[i];
                        final isAlreadyAdded =
                            _selectedProducts.any((sp) => sp['id'] == p['id']);
                        return ListTile(
                          enabled: !isAlreadyAdded,
                          selected: p['id'] == selectedId,
                          selectedTileColor: primaryBlue.withOpacity(0.08),
                          title: Text(
                            p['name_ar'] ?? '',
                            style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            textDirection:
                                _getTextDirection(p['name_ar'] ?? ''),
                          ),
                          subtitle: Text(
                            'SKU: ${p['sku']} | ${p['price']} \$',
                            style: GoogleFonts.cairo(
                                fontSize: 11, color: mediumGray),
                          ),
                          trailing: isAlreadyAdded
                              ? Text('مضاف',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: successGreen))
                              : (p['id'] == selectedId
                                  ? const Icon(Icons.check_rounded,
                                      color: primaryBlue)
                                  : null),
                          onTap: () =>
                              setModalState(() => selectedId = p['id']),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedId != null)
                    TextField(
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => quantity = int.tryParse(v) ?? 1,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: selectedId != null
                        ? () {
                            final product = _availableProducts
                                .firstWhere((p) => p['id'] == selectedId);
                            setState(() => _selectedProducts.add({
                                  'id': product['id'],
                                  'name': product['name_ar'] ?? '',
                                  'quantity': quantity,
                                }));
                            Navigator.pop(ctx);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('إضافة',
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeProduct(int index) =>
      setState(() => _selectedProducts.removeAt(index));

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImage == null) {
      _showSnackBar('الرجاء اختيار صورة الغلاف', dangerRed);
      return;
    }
    if (_selectedProducts.isEmpty) {
      _showSnackBar('الرجاء إضافة منتج واحد على الأقل', dangerRed);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/v1/company/offers'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'name_ar': _nameArController.text.trim(),
        'price': _priceController.text.trim(),
        'discount_price': _discountPriceController.text.isNotEmpty
            ? _discountPriceController.text.trim()
            : '',
        'installation_price': _installationPriceController.text.isNotEmpty
            ? _installationPriceController.text.trim()
            : '',
        'total_wattage': _totalWattageController.text.isNotEmpty
            ? _totalWattageController.text.trim()
            : '',
        'total_capacity': _totalCapacityController.text.isNotEmpty
            ? _totalCapacityController.text.trim()
            : '',
        'description_ar': _descriptionArController.text.trim(),
        'is_active': _isActive ? '1' : '0',
        'is_featured': _isFeatured ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
      });

      if (_priceSypController.text.trim().isNotEmpty) {
        request.fields['price_syp'] = _priceSypController.text.trim();
      } else {
        request.fields['price_syp'] = '0';
      }

      if (_discountPriceSypController.text.trim().isNotEmpty) {
        request.fields['discount_price_syp'] =
            _discountPriceSypController.text.trim();
      } else {
        request.fields['discount_price_syp'] = '';
      }

      if (_installationPriceSypController.text.trim().isNotEmpty) {
        request.fields['installation_price_syp'] =
            _installationPriceSypController.text.trim();
      } else {
        request.fields['installation_price_syp'] = '';
      }

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
          // debugPrint(
          //     '📢 Shipping Cities (JSON): ${jsonEncode(shippingCities)}');
        } else {
          request.fields['shipping_cities'] = jsonEncode([]);
        }
      }

      final comps = <Map<String, String>>[];
      for (var c in _components) {
        final k = c['key']?.text.trim() ?? '';
        final v = c['value']?.text.trim() ?? '';
        if (k.isNotEmpty || v.isNotEmpty) comps.add({'key': k, 'value': v});
      }
      if (comps.isNotEmpty) request.fields['components'] = jsonEncode(comps);

      final specs = <Map<String, String>>[];
      for (var s in _specifications) {
        final k = s['key']?.text.trim() ?? '';
        final v = s['value']?.text.trim() ?? '';
        if (k.isNotEmpty || v.isNotEmpty) specs.add({'key': k, 'value': v});
      }
      if (specs.isNotEmpty)
        request.fields['specifications'] = jsonEncode(specs);

      for (int i = 0; i < _selectedProducts.length; i++) {
        request.fields['products[$i][id]'] =
            _selectedProducts[i]['id'].toString();
        request.fields['products[$i][quantity]'] =
            _selectedProducts[i]['quantity'].toString();
      }

      request.files.add(
          await http.MultipartFile.fromPath('cover_image', _coverImage!.path));
      for (var img in _additionalImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', img.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (mounted) {
        setState(() => _isSaving = false);
        if (data['success'] == true || data['data'] != null) {
          _showSnackBar('تم إضافة العرض بنجاح 🎉', successGreen);
          Navigator.pop(context, true);
        } else {
          _showSnackBar(data['message'] ?? 'فشل إضافة العرض', dangerRed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('حدث خطأ في حفظ العرض', dangerRed);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.info_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.cairo(fontSize: 14),
                  textDirection: _getTextDirection(message))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('معلومات أساسية', Icons.info_rounded),
                const SizedBox(height: 12),
                _buildTextField(
                    _nameArController, 'اسم العرض *', 'أدخل اسم العرض'),
                const SizedBox(height: 12),
                _buildTextField(
                    _descriptionArController, 'الوصف (اختياري)', 'وصف العرض',
                    maxLines: 3),
                const SizedBox(height: 24),
                _buildSection('السعر', Icons.attach_money_rounded),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _buildTextField(
                          _priceController, 'السعر *', '0.00',
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTextField(_discountPriceController,
                          'سعر الخصم (اختياري)', '0.00',
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr)),
                ]),
                const SizedBox(height: 12),
                _buildTextField(_installationPriceController,
                    'سعر التركيب (اختياري)', '0.00',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr),
                const SizedBox(height: 24),
                _buildSectionWithColor('أسعار الليرة السورية (اختياري)',
                    Icons.currency_exchange_rounded,
                    color: sypAmber),
                const SizedBox(height: 12),
                _buildSypPricesSection(),
                const SizedBox(height: 24),
                _buildSolarEnergySection(),
                const SizedBox(height: 24),
                _buildSection('الصور', Icons.image_rounded),
                const SizedBox(height: 12),
                _buildCoverImagePicker(),
                const SizedBox(height: 12),
                _buildAdditionalImagesPicker(),
                const SizedBox(height: 24),
                _buildSection('منتجات العرض *', Icons.inventory_2_rounded),
                const SizedBox(height: 12),
                _buildProductsSection(),
                const SizedBox(height: 24),
                _buildSection(
                    'المكونات والمواصفات (اختياري)', Icons.list_alt_rounded),
                const SizedBox(height: 12),
                _buildComponentsSection(),
                const SizedBox(height: 12),
                _buildSpecificationsSection(),
                const SizedBox(height: 24),
                _buildSection('الشحن (اختياري)', Icons.local_shipping_rounded),
                const SizedBox(height: 12),
                _buildShippingSection(),
                const SizedBox(height: 24),
                _buildToggles(),
                const SizedBox(height: 30),
                _buildSaveButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSypPricesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sypAmber.withOpacity(0.08),
            sypAmber.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sypAmber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sypAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoadingRate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: sypAmber,
                        ),
                      )
                    : const Icon(Icons.currency_exchange_rounded,
                        size: 18, color: sypAmber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سعر الصرف الحالي',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(
                      _exchangeRate > 0
                          ? '1\$ = ${_formatRate(_exchangeRate)} ل.س'
                          : 'غير متوفر',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: sypAmber,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: (_exchangeRate > 0 && !_isLoadingRate)
                    ? _autoFillSypPrices
                    : null,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: Text('تعبئة تلقائية',
                    style: GoogleFonts.cairo(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sypAmber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _priceSypController,
                  'السعر (ل.س)',
                  'مثال: 750000',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _discountPriceSypController,
                  'سعر الخصم (ل.س)',
                  '0',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _installationPriceSypController,
            'سعر التركيب (ل.س) - اختياري',
            '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF92400E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذه الأسعار اختيارية. إذا تركتها فارغة، سيعرض التطبيق السعر بالدولار فقط. اضغط "تعبئة تلقائية" لتحويل السعر من الدولار.',
                    style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: const Color(0xFF92400E),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'إضافة عرض جديد',
        style: GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) => Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              primaryBlue.withOpacity(0.12),
              primaryBlue.withOpacity(0.06)
            ]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryBlue),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
      ]);

  Widget _buildSectionWithColor(String title, IconData icon,
          {Color color = primaryBlue}) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.06)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
      ]);

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
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
      validator: label.contains('*')
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildSolarEnergySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            warningOrange.withOpacity(0.08),
            warningOrange.withOpacity(0.03)
          ],
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
                child: const Icon(Icons.solar_power_rounded,
                    size: 20, color: warningOrange),
              ),
              const SizedBox(width: 10),
              Text('خاص بالعروض الطاقة الشمسية',
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: warningOrange)),
            ],
          ),
          const SizedBox(height: 10),
          Text('هذه الحقول اختيارية وتستخدم فقط لعروض الطاقة الشمسية',
              style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
          const SizedBox(height: 14),
          _buildSolarFieldWithInfo(
            controller: _totalWattageController,
            label: 'الواطية (اختياري)',
            hint: 'مثال: 800',
            icon: Icons.bolt_rounded,
            description: 'قوة الكهرباء اللحظية - قديش بينتج باللحظة',
          ),
          const SizedBox(height: 12),
          _buildSolarFieldWithInfo(
            controller: _totalCapacityController,
            label: 'السعة (اختياري)',
            hint: 'مثال: 4800',
            icon: Icons.battery_charging_full_rounded,
            description: 'قديش ممكن يخزن من الطاقة',
          ),
        ],
      ),
    );
  }

  Widget _buildSolarFieldWithInfo({
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
            hintStyle:
                GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
            hintTextDirection: TextDirection.ltr,
            filled: true,
            fillColor: cardWhite,
            prefixIcon: Icon(icon, size: 20, color: warningOrange),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: warningOrange, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: warningOrange.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(description,
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: mediumGray.withOpacity(0.8))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingSection() {
    final selectedCities = _syrianCities
        .where((city) => _selectedShippingCities[city] == true)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(Icons.local_shipping_rounded,
                  color: _hasShipping ? primaryBlue : Colors.grey, size: 22),
              const SizedBox(width: 10),
              Text(
                _hasShipping ? 'الشحن متاح' : 'الشحن غير متاح',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hasShipping ? primaryBlue : mediumGray,
                ),
              ),
            ]),
            GestureDetector(
              onTap: () => setState(() => _hasShipping = !_hasShipping),
              child: Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  color: _hasShipping ? primaryBlue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(children: [
                  AnimatedAlign(
                    alignment: _hasShipping
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر المدن المتاحة للشحن',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkColor),
                ),
                Text(
                  '${selectedCities.length} مدينة',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _syrianCities.map((city) {
                final isSelected = _selectedShippingCities[city] == true;

                return GestureDetector(
                  onTap: () => _toggleCity(city),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : lightGray,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primaryBlue : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: primaryBlue.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          city,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedCities.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'أسعار الشحن لكل مدينة',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkColor),
              ),
              const SizedBox(height: 4),
              Text(
                'اترك السعر فارغاً لتحديده لاحقاً، أو ضع 0 للشحن المجاني',
                style: GoogleFonts.cairo(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 10),
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
                            const Icon(Icons.location_on_rounded,
                                size: 18, color: primaryBlue),
                            const SizedBox(width: 6),
                            Text(city,
                                style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: costController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.cairo(fontSize: 13, color: darkColor),
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'سعر الشحن (اختياري)',
                            hintStyle: GoogleFonts.cairo(
                                fontSize: 11, color: Colors.grey.shade400),
                            prefixText: '\$ ',
                            prefixStyle: GoogleFonts.cairo(
                                fontSize: 12,
                                color: successGreen,
                                fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: costController.text.isNotEmpty
                                      ? successGreen
                                      : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: costController.text.isNotEmpty
                                      ? successGreen
                                      : Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryBlue, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
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
        ],
      ),
    );
  }

  Widget _buildCoverImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('صورة الغلاف *',
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      if (_coverImage != null)
        Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_coverImage!,
                  height: 200, width: double.infinity, fit: BoxFit.cover)),
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _coverImage = null),
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: dangerRed, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18)),
              )),
        ])
      else
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.add_a_photo_rounded,
                      size: 40, color: primaryBlue.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text('انقر لاختيار صورة الغلاف',
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                ])),
          ),
        ),
    ]);
  }

  Widget _buildAdditionalImagesPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('صور إضافية (اختياري)',
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ..._additionalImages.asMap().entries.map((e) => Stack(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(e.value,
                      width: 80, height: 80, fit: BoxFit.cover)),
              Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _additionalImages.removeAt(e.key)),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: dangerRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14)),
                  )),
            ])),
        GestureDetector(
          onTap: _pickAdditionalImages,
          child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Center(
                  child: Icon(Icons.add_rounded,
                      size: 30, color: primaryBlue.withOpacity(0.6)))),
        ),
      ]),
    ]);
  }

  Widget _buildProductsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: [
        if (_selectedProducts.isNotEmpty)
          ..._selectedProducts
              .asMap()
              .entries
              .map((e) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          '${e.value['name']} (${e.value['quantity']} قطعة)',
                          style:
                              GoogleFonts.cairo(fontSize: 13, color: darkColor),
                          textDirection:
                              _getTextDirection(e.value['name'] ?? ''),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeProduct(e.key),
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: dangerRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.delete_rounded,
                                color: dangerRed, size: 18)),
                      ),
                    ]),
                  ))
              .toList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add_rounded, color: primaryBlue),
          label:
              Text('إضافة منتج', style: GoogleFonts.cairo(color: primaryBlue)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    );
  }

  Widget _buildComponentsSection() => Column(children: [
        ..._components.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: e.value['key'],
                        textDirection: _getTextDirection(e.value['key']!.text),
                        style: GoogleFonts.cairo(fontSize: 13),
                        decoration: InputDecoration(
                            hintText: 'المكون',
                            filled: true,
                            fillColor: cardWhite,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            isDense: true))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: e.value['value'],
                        textDirection:
                            _getTextDirection(e.value['value']!.text),
                        style: GoogleFonts.cairo(fontSize: 13),
                        decoration: InputDecoration(
                            hintText: 'القيمة',
                            filled: true,
                            fillColor: cardWhite,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            isDense: true))),
                const SizedBox(width: 4),
                GestureDetector(
                    onTap: () => _removeComponent(e.key),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_rounded,
                            color: dangerRed, size: 18))),
              ]),
            )),
        TextButton.icon(
            onPressed: _addComponent,
            icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 18),
            label: Text('إضافة مكون',
                style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue))),
      ]);

  Widget _buildSpecificationsSection() => Column(children: [
        ..._specifications.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: e.value['key'],
                        textDirection: _getTextDirection(e.value['key']!.text),
                        style: GoogleFonts.cairo(fontSize: 13),
                        decoration: InputDecoration(
                            hintText: 'المواصفة',
                            filled: true,
                            fillColor: cardWhite,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            isDense: true))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: e.value['value'],
                        textDirection:
                            _getTextDirection(e.value['value']!.text),
                        style: GoogleFonts.cairo(fontSize: 13),
                        decoration: InputDecoration(
                            hintText: 'القيمة',
                            filled: true,
                            fillColor: cardWhite,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            isDense: true))),
                const SizedBox(width: 4),
                GestureDetector(
                    onTap: () => _removeSpecification(e.key),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: dangerRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_rounded,
                            color: dangerRed, size: 18))),
              ]),
            )),
        TextButton.icon(
            onPressed: _addSpecification,
            icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 18),
            label: Text('إضافة مواصفة',
                style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue))),
      ]);

  Widget _buildToggles() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          SwitchListTile(
            title: Text('عرض نشط',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: successGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const Divider(),
          SwitchListTile(
            title: Text('عرض مميز',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('يظهر في قسم العروض المميزة',
                style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeColor: const Color(0xFFF59E0B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ]),
      );

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            shadowColor: primaryBlue.withOpacity(0.4),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('حفظ العرض',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
        ),
      );
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height);
    path.lineTo(size.width - 20, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
