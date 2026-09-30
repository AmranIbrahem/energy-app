// lib/screens/company/products/add_cable_screen.dart

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

class AddCableScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AddCableScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AddCableScreen> createState() => _AddCableScreenState();
}

class _AddCableScreenState extends State<AddCableScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color cableBrown = Color(0xFF8B4513);
  static const Color sypAmber = Color(0xFFD97706);

  late ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameArController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _wholesaleMinQtyController = TextEditingController();
  final _stockController = TextEditingController();
  final _modelController = TextEditingController();
  final _descriptionArController = TextEditingController();

  final _priceSypController = TextEditingController();
  final _discountPriceSypController = TextEditingController();
  final _wholesalePriceSypController = TextEditingController();

  double _exchangeRate = 0;
  bool _isLoadingRate = false;

  String _warrantyType = 'year';
  int _warrantyValue = 1;
  final _customWarrantyController = TextEditingController();

  String? _selectedSubCategoryId;
  String _selectedUnit = 'متر';
  bool _isActive = true;

  final _customUnitController = TextEditingController();
  bool _showCustomUnitInput = false;
  bool _showAllUnits = false;

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

  final _cableBrandController = TextEditingController();
  final _customCrossSectionController = TextEditingController();
  final _rollLengthController = TextEditingController();

  String? _selectedCrossSection;
  String? _selectedMaterial;
  String? _selectedConductors;
  bool _showCustomCrossSectionInput = false;

  final List<String> _crossSections = [
    '2 مم مربع',
    '2.5 مم مربع',
    '6 مم مربع',
  ];

  final List<String> _materials = [
    'نحاس',
    'ألمنيوم',
  ];

  final List<String> _conductors = [
    '1',
    '2',
    '3',
    '4',
    '5+',
  ];

  List<dynamic> _filteredSubCategories = [];
  final TextEditingController _subCategorySearchController =
      TextEditingController();
  bool _showSubCategoryDropdown = false;
  List<dynamic> _subCategories = [];

  File? _mainImage;
  List<File> _additionalImages = [];

  List<Map<String, TextEditingController>> _specifications = [];

  List<Map<String, String>> _units = [
    {'key': 'قطعة', 'label': 'قطعة'},
    {'key': 'كيلوغرام', 'label': 'كيلوغرام'},
    {'key': 'غرام', 'label': 'غرام'},
    {'key': 'طن', 'label': 'طن'},
    {'key': 'لتر', 'label': 'لتر'},
    {'key': 'ملليلتر', 'label': 'ملليلتر'},
    {'key': 'صندوق', 'label': 'صندوق'},
    {'key': 'كرتونة', 'label': 'كرتونة'},
    {'key': 'مجموعة', 'label': 'مجموعة'},
    {'key': 'متر', 'label': 'متر'},
    {'key': 'سنتيمتر', 'label': 'سنتيمتر'},
    {'key': 'ميلليمتر', 'label': 'ميلليمتر'},
    {'key': 'دستة (12)', 'label': 'دستة (12)'},
    {'key': 'زوج', 'label': 'زوج'},
    {'key': 'عبوة', 'label': 'عبوة'},
    {'key': 'كيس', 'label': 'كيس'},
    {'key': 'زجاجة', 'label': 'زجاجة'},
    {'key': 'علبة', 'label': 'علبة'},
    {'key': 'لفة', 'label': 'لفة'},
    {'key': 'ورقة', 'label': 'ورقة'},
    {'key': 'وحدة', 'label': 'وحدة'},
  ];

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _initShippingCostControllers();
    _fetchCreateData();
    _fetchExchangeRate();
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
    _skuController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMinQtyController.dispose();
    _stockController.dispose();
    _modelController.dispose();
    _customWarrantyController.dispose();
    _descriptionArController.dispose();
    _subCategorySearchController.dispose();
    _customUnitController.dispose();
    _shippingCostControllers.forEach((_, controller) => controller.dispose());
    _clearSpecifications();
    _cableBrandController.dispose();
    _customCrossSectionController.dispose();
    _rollLengthController.dispose();
    _priceSypController.dispose();
    _discountPriceSypController.dispose();
    _wholesalePriceSypController.dispose();
    super.dispose();
  }

  void _clearSpecifications() {
    for (var spec in _specifications) {
      spec['key']?.dispose();
      spec['value']?.dispose();
    }
  }

  String _getWarrantyText() {
    if (_warrantyType == 'custom') {
      return _customWarrantyController.text.trim();
    }
    final int value = _warrantyValue;
    if (_warrantyType == 'year') {
      if (value == 1) return 'سنة واحدة';
      if (value == 2) return 'سنتان';
      if (value >= 3 && value <= 10) return '$value سنوات';
      return '$value سنة';
    } else {
      if (value == 1) return 'شهر واحد';
      if (value == 2) return 'شهران';
      if (value >= 3 && value <= 10) return '$value أشهر';
      return '$value شهرًا';
    }
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

  Future<void> _fetchCreateData() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await _apiService.get(
          '/v1/company/products/getCableSubcategories',
          requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() {
          _subCategories = response['data']['sub_categories'] ?? [];
          _filteredSubCategories = List.from(_subCategories);
          if (response['data']['units'] != null) {
            final apiUnits = List<Map<String, String>>.from(
              (response['data']['units'] as List).map((u) => {
                    'key': u['label']?.toString() ?? u['key']?.toString() ?? '',
                    'label':
                        u['label']?.toString() ?? u['key']?.toString() ?? '',
                  }),
            );
            for (var unit in apiUnits) {
              if (!_units.any((u) => u['key'] == unit['key'])) {
                _units.add(unit);
              }
            }
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      // debugPrint('Error fetching create data: $e');
      if (mounted) setState(() => _isLoadingData = false);
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

      final wholesaleUsd =
          double.tryParse(_wholesalePriceController.text.trim()) ?? 0;
      if (wholesaleUsd > 0) {
        _wholesalePriceSypController.text =
            (wholesaleUsd * _exchangeRate).toStringAsFixed(0);
      } else {
        _wholesalePriceSypController.clear();
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

  void _addCustomCrossSection() {
    final customValue = _customCrossSectionController.text.trim();
    if (customValue.isEmpty) {
      _showSnackBar('الرجاء إدخال مساحة المقطع', dangerRed);
      return;
    }

    final crossSectionLabel = '$customValue مم مربع';
    if (_crossSections.contains(crossSectionLabel)) {
      _showSnackBar('هذه المساحة موجودة بالفعل', warningOrange);
      return;
    }

    setState(() {
      _crossSections.add(crossSectionLabel);
      _selectedCrossSection = crossSectionLabel;
      _showCustomCrossSectionInput = false;
      _customCrossSectionController.clear();
    });

    _showSnackBar('تم إضافة المساحة بنجاح', successGreen);
  }

  void _addCustomUnit() {
    final customUnit = _customUnitController.text.trim();
    if (customUnit.isEmpty) {
      _showSnackBar('الرجاء إدخال اسم الوحدة', dangerRed);
      return;
    }
    if (_units.any((u) => u['key'] == customUnit || u['label'] == customUnit)) {
      _showSnackBar('هذه الوحدة موجودة بالفعل', warningOrange);
      return;
    }
    setState(() {
      _units.add({'key': customUnit, 'label': customUnit});
      _selectedUnit = customUnit;
      _showCustomUnitInput = false;
      _customUnitController.clear();
    });
    _showSnackBar('تم إضافة الوحدة بنجاح', successGreen);
  }

  Future<void> _pickMainImage() async {
    final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  void _removeMainImage() => setState(() => _mainImage = null);

  Future<void> _pickAdditionalImages() async {
    final List<XFile> images =
        await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (images.isNotEmpty)
      setState(
          () => _additionalImages.addAll(images.map((img) => File(img.path))));
  }

  void _removeAdditionalImage(int index) =>
      setState(() => _additionalImages.removeAt(index));

  void _addSpecification() => setState(() => _specifications
      .add({'key': TextEditingController(), 'value': TextEditingController()}));

  void _removeSpecification(int index) {
    _specifications[index]['key']?.dispose();
    _specifications[index]['value']?.dispose();
    setState(() => _specifications.removeAt(index));
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImage == null) {
      _showSnackBar('الرجاء اختيار الصورة الرئيسية للمنتج', dangerRed);
      return;
    }
    if (_selectedSubCategoryId == null) {
      _showSnackBar('الرجاء اختيار التصنيف الفرعي', dangerRed);
      return;
    }
    if (_cableBrandController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال ماركة الكابل', dangerRed);
      return;
    }
    if (_selectedCrossSection == null) {
      _showSnackBar('الرجاء اختيار مساحة المقطع', dangerRed);
      return;
    }
    if (_selectedMaterial == null) {
      _showSnackBar('الرجاء اختيار نوع الموصل', dangerRed);
      return;
    }
    if (_selectedConductors == null) {
      _showSnackBar('الرجاء اختيار عدد النواقل', dangerRed);
      return;
    }

    final warrantyValue = _getWarrantyText();

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('${AppConstants.baseUrl}/v1/company/products'));
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';

      final Map<String, String> fields = {
        'name_ar': _nameArController.text.trim(),
        'price': _priceController.text.trim(),
        'sub_category_id': _selectedSubCategoryId ?? '',
        'brand': _cableBrandController.text.trim(),
        'unit': _selectedUnit,
        'stock': _stockController.text.trim().isNotEmpty
            ? _stockController.text.trim()
            : '0',
        'is_active': _isActive ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
        'product_type': 'cable',
      };

      if (_skuController.text.trim().isNotEmpty) {
        fields['sku'] = _skuController.text.trim();
      }

      if (_discountPriceController.text.trim().isNotEmpty) {
        fields['discount_price'] = _discountPriceController.text.trim();
      }

      if (_wholesalePriceController.text.trim().isNotEmpty) {
        fields['wholesale_price'] = _wholesalePriceController.text.trim();
      }

      if (_wholesaleMinQtyController.text.trim().isNotEmpty) {
        fields['wholesale_min_quantity'] =
            _wholesaleMinQtyController.text.trim();
      }

      if (_priceSypController.text.trim().isNotEmpty) {
        fields['price_syp'] = _priceSypController.text.trim();
      }

      if (_discountPriceSypController.text.trim().isNotEmpty) {
        fields['discount_price_syp'] = _discountPriceSypController.text.trim();
      }

      if (_wholesalePriceSypController.text.trim().isNotEmpty) {
        fields['wholesale_price_syp'] =
            _wholesalePriceSypController.text.trim();
      }

      if (_modelController.text.trim().isNotEmpty) {
        fields['model'] = _modelController.text.trim();
      }

      if (_descriptionArController.text.trim().isNotEmpty) {
        fields['description_ar'] = _descriptionArController.text.trim();
      }

      if (warrantyValue.trim().isNotEmpty) {
        fields['warranty'] = warrantyValue.trim();
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
          fields['shipping_cities'] = jsonEncode(shippingCities);
        }
      }

      final specs = <Map<String, String>>[];

      specs.add({'key': 'نوع المنتج', 'value': 'كابل'});
      specs.add({'key': 'الماركة', 'value': _cableBrandController.text.trim()});
      specs.add({'key': 'مساحة المقطع', 'value': _selectedCrossSection!});
      specs.add({'key': 'نوع الموصل', 'value': _selectedMaterial!});
      specs.add({'key': 'عدد النواقل', 'value': _selectedConductors!});

      if (_rollLengthController.text.trim().isNotEmpty) {
        specs.add({
          'key': 'طول الرول',
          'value': '${_rollLengthController.text.trim()} متر'
        });
      }

      for (var spec in _specifications) {
        final key = spec['key']?.text.trim() ?? '';
        final value = spec['value']?.text.trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          specs.add({'key': key, 'value': value});
        }
      }

      if (specs.isNotEmpty) {
        fields['specifications'] = jsonEncode(specs);
      }

      request.fields.addAll(fields);

      // debugPrint('═══════════════════════════════════');
      // debugPrint('📢 Fields being sent (Cable):');
      fields.forEach((key, value) {
        // debugPrint('   $key: $value');
      });
      // debugPrint('═══════════════════════════════════');

      request.files.add(
          await http.MultipartFile.fromPath('main_image', _mainImage!.path));

      for (var image in _additionalImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', image.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // debugPrint('═══════════════════════════════════');
      // debugPrint('📢 Status Code: ${streamedResponse.statusCode}');
      // debugPrint('📢 Response Body: $responseBody');
      // debugPrint('═══════════════════════════════════');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(responseBody);
      } catch (e) {
        setState(() => _isSaving = false);
        _showSnackBar(
            'استجابة غير صالحة (${streamedResponse.statusCode})', dangerRed);
        return;
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (data['success'] == true || data['data'] != null) {
          _showSnackBar('تم إضافة الكابل بنجاح 🎉', successGreen);
          Navigator.pop(context, true);
        } else {
          String errorMsg = data['message'] ?? 'فشل إضافة المنتج';
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = '$errorMsg\n${firstError.first}';
              }
            }
          }
          _showSnackBar(errorMsg, dangerRed);
        }
      }
    } catch (e) {
      // debugPrint('❌ Error saving cable: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('حدث خطأ في حفظ المنتج', dangerRed);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            color == successGreen
                ? Icons.check_circle_rounded
                : color == warningOrange
                    ? Icons.warning_rounded
                    : Icons.info_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: GoogleFonts.cairo(fontSize: 14),
                  textDirection: _getTextDirection(message)))
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          if (_showSubCategoryDropdown)
            setState(() => _showSubCategoryDropdown = false);
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: lightGray,
          appBar: _buildAppBar(),
          body: _isLoadingData ? _buildLoading() : _buildForm(),
        ),
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
        'إضافة كابل',
        style: GoogleFonts.cairo(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
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

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: cableBrown));

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle('معلومات الكابل', Icons.cable_rounded,
              color: cableBrown),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cableBrown.withOpacity(0.08),
                  cableBrown.withOpacity(0.03)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cableBrown.withOpacity(0.3)),
            ),
            child: Column(children: [
              _buildTextField(_cableBrandController, 'الماركة *',
                  'مثال: Elsewedy, Riyadh Cables',
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              _buildCrossSectionDropdown(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'نوع الموصل *',
                    value: _selectedMaterial,
                    items: _materials,
                    icon: Icons.layers_rounded,
                    color: cableBrown,
                    onChanged: (value) =>
                        setState(() => _selectedMaterial = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField(
                    label: 'عدد النواقل *',
                    value: _selectedConductors,
                    items: _conductors,
                    icon: Icons.account_tree_rounded,
                    color: cableBrown,
                    onChanged: (value) =>
                        setState(() => _selectedConductors = value),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _buildTextField(_rollLengthController,
                  'طول الرول (متر) (اختياري)', 'مثال: 100',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr),
            ]),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('معلومات أساسية', Icons.info_rounded),
          const SizedBox(height: 12),
          _buildTextField(
              _nameArController, 'اسم المنتج *', 'مثال: كابل نحاس 6 مم 3 ناقل',
              textDirection: TextDirection.rtl),
          const SizedBox(height: 12),
          _buildTextField(_skuController, 'رمز المنتج (SKU) *', 'CAB-6-3',
              textDirection: TextDirection.ltr),
          const SizedBox(height: 12),
          _buildSubCategoryDropdown(),
          const SizedBox(height: 12),
          _buildUnitDropdown(),
          const SizedBox(height: 12),
          _buildDescriptionField(),
          const SizedBox(height: 24),
          _buildSectionTitle('السعر والمخزون', Icons.attach_money_rounded),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildTextField(_priceController, 'السعر *', '0.00',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(
                    _discountPriceController, 'سعر الخصم (اختياري)', '0.00',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: successGreen.withOpacity(0.2)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warehouse_rounded,
                    color: successGreen, size: 18),
                const SizedBox(width: 6),
                Text('سعر الجملة (اختياري)',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: successGreen)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _buildTextField(_wholesalePriceController,
                        'سعر الجملة (اختياري)', '0.00',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(_wholesaleMinQtyController,
                        'الحد الأدنى للكمية (اختياري)', 'مثال: 100',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _buildTextField(_stockController, 'الكمية المتاحة *', '0',
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr),
          const SizedBox(height: 24),
          _buildSectionTitle(
              'أسعار الليرة السورية (اختياري)', Icons.currency_exchange_rounded,
              color: sypAmber),
          const SizedBox(height: 12),
          _buildSypPricesSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('معلومات إضافية', Icons.more_horiz_rounded),
          const SizedBox(height: 12),
          _buildTextField(
              _modelController, 'الموديل (اختياري)', 'مثال: CU-6-3C',
              textDirection: TextDirection.ltr),
          const SizedBox(height: 12),
          _buildWarrantyField(),
          const SizedBox(height: 24),
          _buildSectionTitle('الصور', Icons.image_rounded),
          const SizedBox(height: 12),
          _buildMainImagePicker(),
          const SizedBox(height: 12),
          _buildAdditionalImagesPicker(),
          const SizedBox(height: 24),
          _buildSectionTitle(
              'مواصفات إضافية (اختياري)', Icons.list_alt_rounded),
          const SizedBox(height: 12),
          _buildSpecificationsSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('الحالة', Icons.toggle_on_rounded),
          const SizedBox(height: 12),
          _buildActiveToggle(),
          const SizedBox(height: 24),
          _buildSectionTitle('الشحن (اختياري)', Icons.local_shipping_rounded),
          const SizedBox(height: 12),
          _buildShippingSection(),
          const SizedBox(height: 30),
          _buildSaveButton(),
          const SizedBox(height: 30),
        ]),
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
                  'مثال: 15000',
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
            _wholesalePriceSypController,
            'سعر الجملة (ل.س) - اختياري',
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

  Widget _buildWarrantyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الضمان (اختياري)',
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildWarrantyTypeOption('year', 'سنة'),
                  const SizedBox(width: 8),
                  _buildWarrantyTypeOption('month', 'شهر'),
                  const SizedBox(width: 8),
                  _buildWarrantyTypeOption('custom', 'إدخال يدوي'),
                ],
              ),
              const SizedBox(height: 12),
              if (_warrantyType != 'custom') ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المدة',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mediumGray),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _warrantyValue,
                            isExpanded: true,
                            items: List.generate(12, (index) => index + 1)
                                .map((num) => DropdownMenuItem<int>(
                                      value: num,
                                      child: Text(
                                        num.toString(),
                                        style: GoogleFonts.cairo(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _warrantyValue = value ?? 1;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getWarrantyText(),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _customWarrantyController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'مثال: 10 سنوات، ضمان مدى الحياة، 6 أشهر',
                    filled: true,
                    fillColor: lightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyTypeOption(String value, String label) {
    final isSelected = _warrantyType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _warrantyType = value;
            if (value != 'custom') {
              _customWarrantyController.clear();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : lightGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryBlue : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : mediumGray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrossSectionDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('مساحة المقطع *',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () {
          setState(() {
            _showAllUnits = !_showAllUnits;
            _showCustomCrossSectionInput = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _showAllUnits ? cableBrown : Colors.grey.shade200,
                width: _showAllUnits ? 2 : 1),
          ),
          child: Row(children: [
            Icon(Icons.square_foot_rounded,
                size: 20, color: _showAllUnits ? cableBrown : mediumGray),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCrossSection ?? 'اختر مساحة المقطع',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: _selectedCrossSection != null
                      ? darkColor
                      : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
                _showAllUnits
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: mediumGray),
          ]),
        ),
      ),
      if (_showAllUnits) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cableBrown.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 250),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _crossSections.length,
                itemBuilder: (_, index) {
                  final crossSection = _crossSections[index];
                  final isSelected = crossSection == _selectedCrossSection;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: cableBrown.withOpacity(0.08),
                    leading: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: isSelected ? cableBrown : lightGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.square_foot_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : mediumGray,
                      ),
                    ),
                    title: Text(
                      crossSection,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? cableBrown : darkColor,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: cableBrown, size: 20)
                        : const Icon(Icons.chevron_left_rounded,
                            color: Colors.grey, size: 20),
                    onTap: () => setState(() {
                      _selectedCrossSection = crossSection;
                      _showAllUnits = false;
                      _showCustomCrossSectionInput = false;
                    }),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            if (!_showCustomCrossSectionInput)
              TextButton.icon(
                onPressed: () => setState(() {
                  _showCustomCrossSectionInput = true;
                  _showAllUnits = false;
                }),
                icon:
                    const Icon(Icons.add_rounded, color: cableBrown, size: 20),
                label: Text('إضافة مساحة أخرى',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: cableBrown,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
          ]),
        ),
      ],
      if (_showCustomCrossSectionInput) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cableBrown.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cableBrown.withOpacity(0.3)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✏️ إضافة مساحة مقطع جديدة',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cableBrown)),
            const SizedBox(height: 10),
            TextField(
              controller: _customCrossSectionController,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'أدخل المساحة (مم مربع)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cableBrown.withOpacity(0.5))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cableBrown.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: cableBrown, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                prefixIcon:
                    const Icon(Icons.edit_rounded, size: 20, color: cableBrown),
                suffixText: 'مم مربع',
                suffixStyle: GoogleFonts.cairo(fontSize: 12, color: cableBrown),
              ),
              onSubmitted: (value) => _addCustomCrossSection(),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addCustomCrossSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cableBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('إضافة المساحة',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _showCustomCrossSectionInput = false;
                    _customCrossSectionController.clear();
                  }),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text('إلغاء',
                      style:
                          GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
                ),
              ),
            ]),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Color color,
    required Function(String?) onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: mediumGray),
            style: GoogleFonts.cairo(
                fontSize: 14, color: darkColor, fontWeight: FontWeight.w600),
            hint: Row(children: [
              Icon(icon, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 10),
              Text('اختر',
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: Colors.grey.shade400)),
            ]),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Row(children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 10),
                        Text(item, style: GoogleFonts.cairo(fontSize: 14)),
                      ]),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _buildUnitDropdown() {
    final selectedUnitLabel = _units.firstWhere(
          (u) => u['key'] == _selectedUnit,
          orElse: () => {'key': 'متر', 'label': 'متر'},
        )['label'] ??
        'متر';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('وحدة القياس *',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () {
          setState(() {
            _showAllUnits = !_showAllUnits;
            _showCustomUnitInput = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _showAllUnits ? primaryBlue : Colors.grey.shade200,
                width: _showAllUnits ? 2 : 1),
          ),
          child: Row(children: [
            Icon(Icons.straighten_rounded,
                size: 20, color: _showAllUnits ? primaryBlue : mediumGray),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedUnitLabel,
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: darkColor,
                    fontWeight: FontWeight.w600),
                textDirection: _getTextDirection(selectedUnitLabel),
              ),
            ),
            Icon(
                _showAllUnits
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: mediumGray),
          ]),
        ),
      ),
      if (_showAllUnits) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          constraints: const BoxConstraints(maxHeight: 350),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _units.length,
                itemBuilder: (_, index) {
                  final unit = _units[index];
                  final isSelected = unit['key'] == _selectedUnit;
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.08),
                    leading: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : lightGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.straighten_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : mediumGray,
                      ),
                    ),
                    title: Text(
                      unit['label'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryBlue : darkColor,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: primaryBlue, size: 20)
                        : const Icon(Icons.chevron_left_rounded,
                            color: Colors.grey, size: 20),
                    onTap: () => setState(() {
                      _selectedUnit = unit['key']!;
                      _showAllUnits = false;
                      _showCustomUnitInput = false;
                    }),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            if (!_showCustomUnitInput)
              TextButton.icon(
                onPressed: () => setState(() {
                  _showCustomUnitInput = true;
                  _showAllUnits = false;
                }),
                icon:
                    const Icon(Icons.add_rounded, color: primaryBlue, size: 20),
                label: Text('إضافة وحدة جديدة',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: primaryBlue,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
          ]),
        ),
      ],
      if (_showCustomUnitInput) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✏️ إضافة وحدة جديدة',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
            const SizedBox(height: 10),
            TextField(
              controller: _customUnitController,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب اسم الوحدة هنا...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primaryBlue.withOpacity(0.5))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primaryBlue.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                prefixIcon: const Icon(Icons.edit_rounded,
                    size: 20, color: primaryBlue),
              ),
              onSubmitted: (value) => _addCustomUnit(),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: _addCustomUnit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: Text('إضافة الوحدة',
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(() {
                            _showCustomUnitInput = false;
                            _customUnitController.clear();
                          }),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300)),
                      child: Text('إلغاء',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: mediumGray)))),
            ]),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildSectionTitle(String title, IconData icon,
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

  Widget _buildDescriptionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الوصف (اختياري)',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
            controller: _descriptionArController,
            maxLines: 5,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textDirection: _getTextDirection(_descriptionArController.text),
            textAlign: TextAlign.start,
            style:
                GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.8),
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'اكتب وصفاً تفصيلياً للكابل... (اختياري)',
              hintStyle: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.grey.shade400, height: 1.5),
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: cardWhite,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildSubCategoryDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('التصنيف الفرعي *',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => setState(() {
          _showSubCategoryDropdown = !_showSubCategoryDropdown;
          if (_showSubCategoryDropdown) {
            _filteredSubCategories = List.from(_subCategories);
            _subCategorySearchController.clear();
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _showSubCategoryDropdown
                    ? primaryBlue
                    : Colors.grey.shade200,
                width: _showSubCategoryDropdown ? 2 : 1),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                _getSelectedSubCategoryName(),
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: _selectedSubCategoryId != null
                        ? darkColor
                        : Colors.grey.shade400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
                _showSubCategoryDropdown
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: mediumGray),
          ]),
        ),
      ),
      if (_showSubCategoryDropdown)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.3))),
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _subCategorySearchController,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '🔍 بحث عن تصنيف...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: primaryBlue),
                  filled: true,
                  fillColor: lightGray,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {
                  _filteredSubCategories = value.isEmpty
                      ? List.from(_subCategories)
                      : _subCategories
                          .where((s) => (s['full_name'] ?? s['name_ar'] ?? '')
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();
                }),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredSubCategories.length,
                itemBuilder: (_, index) {
                  final sub = _filteredSubCategories[index];
                  final isSelected =
                      sub['id']?.toString() == _selectedSubCategoryId;
                  final displayName = sub['full_name'] ?? sub['name_ar'] ?? '';
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.08),
                    title: Text(displayName,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? primaryBlue : darkColor)),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: primaryBlue, size: 20)
                        : null,
                    onTap: () => setState(() {
                      _selectedSubCategoryId = sub['id']?.toString();
                      _subCategorySearchController.text = displayName;
                      _showSubCategoryDropdown = false;
                    }),
                  );
                },
              ),
            ),
            if (_filteredSubCategories.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('لا توجد نتائج',
                      style:
                          GoogleFonts.cairo(fontSize: 13, color: mediumGray))),
          ]),
        ),
    ]);
  }

  String _getSelectedSubCategoryName() {
    if (_selectedSubCategoryId == null) return 'اختر التصنيف الفرعي *';
    final selected = _subCategories.firstWhere(
        (s) => s['id']?.toString() == _selectedSubCategoryId,
        orElse: () => null);
    return selected?['full_name'] ??
        selected?['name_ar'] ??
        'اختر التصنيف الفرعي *';
  }

  Widget _buildMainImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الصورة الرئيسية *',
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      if (_mainImage != null)
        Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_mainImage!,
                  height: 200, width: double.infinity, fit: BoxFit.cover)),
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                  onTap: _removeMainImage,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: dangerRed, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18)))),
        ])
      else
        GestureDetector(
          onTap: _pickMainImage,
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
                      size: 40, color: cableBrown.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text('انقر لاختيار الصورة الرئيسية',
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
        ..._additionalImages.asMap().entries.map((entry) => Stack(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(entry.value,
                      width: 80, height: 80, fit: BoxFit.cover)),
              Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                      onTap: () => _removeAdditionalImage(entry.key),
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: dangerRed, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14)))),
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
                      size: 30, color: cableBrown.withOpacity(0.6)))),
        ),
      ]),
    ]);
  }

  Widget _buildSpecificationsSection() {
    return Column(children: [
      ..._specifications.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: entry.value['key'],
                      textDirection:
                          _getTextDirection(entry.value['key']!.text),
                      style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                      decoration: InputDecoration(
                          hintText: 'المفتاح',
                          filled: true,
                          fillColor: cardWhite,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          isDense: true))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: entry.value['value'],
                      textDirection:
                          _getTextDirection(entry.value['value']!.text),
                      style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                      decoration: InputDecoration(
                          hintText: 'القيمة',
                          filled: true,
                          fillColor: cardWhite,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          isDense: true))),
              const SizedBox(width: 4),
              GestureDetector(
                  onTap: () => _removeSpecification(entry.key),
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_rounded,
                          color: dangerRed, size: 18))),
            ]),
          )),
      const SizedBox(height: 4),
      TextButton.icon(
          onPressed: _addSpecification,
          icon: const Icon(Icons.add_rounded, color: cableBrown, size: 18),
          label: Text('إضافة مواصفة',
              style: GoogleFonts.cairo(fontSize: 13, color: cableBrown))),
    ]);
  }

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.store_rounded,
              color: _isActive ? successGreen : Colors.grey, size: 22),
          const SizedBox(width: 10),
          Text(_isActive ? 'المنتج نشط' : 'المنتج غير نشط',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isActive ? successGreen : mediumGray)),
        ]),
        GestureDetector(
          onTap: () => setState(() => _isActive = !_isActive),
          child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                  color: _isActive ? successGreen : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14)),
              child: Stack(children: [
                AnimatedAlign(
                    alignment: _isActive
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle))),
              ])),
        ),
      ]),
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
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.local_shipping_rounded,
                color: _hasShipping ? primaryBlue : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Text(_hasShipping ? 'الشحن متاح' : 'الشحن غير متاح',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _hasShipping ? primaryBlue : mediumGray)),
          ]),
          GestureDetector(
            onTap: () => setState(() => _hasShipping = !_hasShipping),
            child: Container(
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                    color: _hasShipping ? primaryBlue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14)),
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
                              color: Colors.white, shape: BoxShape.circle))),
                ])),
          ),
        ]),
        if (_hasShipping) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
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
                        width: isSelected ? 1.5 : 1),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(city,
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : mediumGray)),
                  ]),
                ),
              );
            }).toList(),
          ),
          if (selectedCities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('أسعار الشحن لكل مدينة (اختياري)',
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkColor)),
            const SizedBox(height: 10),
            ...selectedCities.map((city) {
              final costController = _shippingCostControllers[city]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Row(children: [
                  Expanded(
                      flex: 2,
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: primaryBlue),
                        const SizedBox(width: 6),
                        Text(city,
                            style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: darkColor)),
                      ])),
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
                        decoration: InputDecoration(
                          hintText: 'سعر الشحن',
                          prefixText: '\$ ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          isDense: true,
                        ),
                      )),
                ]),
              );
            }).toList(),
          ],
        ],
      ]),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: cableBrown,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: cableBrown.withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.cable_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text('حفظ الكابل',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
      ),
    );
  }
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
