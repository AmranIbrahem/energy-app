// lib/screens/company/products/edit_product_screen.dart

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

class EditProductScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int productId;

  const EditProductScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.productId,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  late ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingProduct = true;

  // Form Controllers
  final _nameArController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _wholesaleMinQtyController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _warrantyController = TextEditingController();
  final _descriptionArController = TextEditingController();

  // Dropdown Values
  String? _selectedSubCategoryId;
  String _selectedUnit = 'قطعة';
  bool _isActive = true;

  // ✅ متغيرات الوحدة المخصصة
  final _customUnitController = TextEditingController();
  bool _showCustomUnitInput = false;
  bool _showAllUnits = false;

  // ✅ متغيرات الشحن
  bool _hasShipping = false;
  Map<String, TextEditingController> _shippingCostControllers = {};
  Map<String, bool> _selectedShippingCities = {}; // ✅ جديد لتتبع التحديد

  // ✅ تمت إضافة ريف دمشق
  final List<String> _syrianCities = [
    'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'حماة', 'درعا',
    'السويداء', 'القنيطرة', 'دير الزور', 'الرقة', 'الحسكة', 'إدلب'
  ];

  // Subcategory Search
  List<dynamic> _filteredSubCategories = [];
  final TextEditingController _subCategorySearchController = TextEditingController();
  bool _showSubCategoryDropdown = false;

  // Images
  String? _currentMainImageUrl;
  File? _newMainImage;
  bool _removeMainImage = false;
  List<Map<String, dynamic>> _currentAdditionalImages = [];
  List<File> _newAdditionalImages = [];
  List<int> _deletedImageIds = [];

  // Data
  List<dynamic> _subCategories = [];

  // ✅ قائمة الوحدات بالعربي
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

  // Specifications
  List<Map<String, TextEditingController>> _specifications = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _initShippingCostControllers();
    _fetchCreateData();
    _fetchProductDetails();

    _descriptionArController.addListener(() {
      if (mounted) setState(() {});
    });
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
    _descriptionArController.removeListener(() {});
    _nameArController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMinQtyController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _warrantyController.dispose();
    _descriptionArController.dispose();
    _subCategorySearchController.dispose();
    _customUnitController.dispose();
    _shippingCostControllers.forEach((_, controller) => controller.dispose());
    _clearSpecifications();
    super.dispose();
  }

  void _clearSpecifications() {
    for (var spec in _specifications) {
      spec['key']?.dispose();
      spec['value']?.dispose();
    }
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

  // ==================== Helper Methods ====================

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
      _units.add({
        'key': customUnit,
        'label': customUnit,
      });
      _selectedUnit = customUnit;
      _showCustomUnitInput = false;
      _customUnitController.clear();
    });

    _showSnackBar('تم إضافة الوحدة بنجاح', successGreen);
  }

  bool _isDefaultUnit(String key) {
    const defaultUnits = [
      'قطعة', 'كيلوغرام', 'غرام', 'طن', 'لتر', 'ملليلتر', 'صندوق', 'كرتونة',
      'مجموعة', 'متر', 'سنتيمتر', 'ميلليمتر', 'دستة (12)', 'زوج', 'عبوة', 'كيس',
      'زجاجة', 'علبة', 'لفة', 'ورقة', 'وحدة'
    ];
    return defaultUnits.contains(key);
  }

  // ==================== Data Fetching ====================

  Future<void> _fetchCreateData() async {
    try {
      final response = await _apiService.get('/v1/company/products/create-data', requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() {
          _subCategories = response['data']['sub_categories'] ?? [];
          _filteredSubCategories = List.from(_subCategories);
          if (response['data']['units'] != null) {
            final apiUnits = List<Map<String, String>>.from(
              (response['data']['units'] as List).map((u) => {
                'key': u['label']?.toString() ?? u['key']?.toString() ?? '',
                'label': u['label']?.toString() ?? u['key']?.toString() ?? '',
              }),
            );
            for (var unit in apiUnits) {
              if (!_units.any((u) => u['key'] == unit['key'])) {
                _units.add(unit);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching create data: $e');
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoadingProduct = true);
    try {
      final response = await _apiService.get('/v1/company/products/${widget.productId}', requiresAuth: true);
      if (response['data'] != null && response['data']['product'] != null && mounted) {
        final product = response['data']['product'];
        _populateForm(product);
        setState(() => _isLoadingProduct = false);
      } else {
        if (mounted) {
          setState(() => _isLoadingProduct = false);
          _showSnackBar('فشل تحميل المنتج', dangerRed);
        }
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');
      if (mounted) {
        setState(() => _isLoadingProduct = false);
        _showSnackBar('حدث خطأ في تحميل المنتج', dangerRed);
      }
    }
  }

  void _populateForm(dynamic product) {
    _nameArController.text = product['name_ar'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _priceController.text = product['price'] ?? '';
    _discountPriceController.text = product['discount_price'] ?? '';
    _wholesalePriceController.text = product['wholesale_price'] ?? '';
    _wholesaleMinQtyController.text = product['wholesale_min_quantity']?.toString() ?? '';
    _stockController.text = product['stock']?.toString() ?? '0';
    _brandController.text = product['brand'] ?? '';
    _modelController.text = product['model'] ?? '';
    _warrantyController.text = product['warranty'] ?? '';
    _descriptionArController.text = product['description_ar'] ?? '';
    _selectedSubCategoryId = product['sub_category']?['id']?.toString();
    _selectedUnit = product['unit'] ?? 'قطعة';
    _isActive = product['is_active'] ?? true;
    _currentMainImageUrl = product['main_image'];

    _hasShipping = product['has_shipping'] ?? false;

    // ✅ تحميل مدن الشحن مع الأسعار وتحديد الحالة
    if (product['shipping_cities'] != null) {
      List<dynamic> citiesData = [];

      if (product['shipping_cities'] is List) {
        citiesData = product['shipping_cities'] as List;
      } else if (product['shipping_cities'] is String) {
        try {
          citiesData = jsonDecode(product['shipping_cities']) as List;
        } catch (_) {
          citiesData = [];
        }
      }

      for (var cityData in citiesData) {
        if (cityData is String) {
          // ✅ الصيغة القديمة - نص فقط
          if (_shippingCostControllers.containsKey(cityData)) {
            _selectedShippingCities[cityData] = true;
          }
        } else if (cityData is Map) {
          // ✅ الصيغة الجديدة - city + cost
          final city = cityData['city']?.toString() ?? '';
          final cost = cityData['cost']?.toString() ?? '';
          if (_shippingCostControllers.containsKey(city)) {
            _shippingCostControllers[city]!.text = cost;
            _selectedShippingCities[city] = true;
          }
        }
      }
    }

    if (_selectedSubCategoryId != null && _subCategories.isNotEmpty) {
      final selectedSub = _subCategories.firstWhere(
              (s) => s['id']?.toString() == _selectedSubCategoryId,
          orElse: () => null);
      if (selectedSub != null) {
        _subCategorySearchController.text =
            selectedSub['full_name'] ?? selectedSub['name_ar'] ?? '';
      }
    }

    if (product['additional_images'] != null) {
      _currentAdditionalImages = (product['additional_images'] as List)
          .map((img) => {'id': img['id'], 'url': img['image'] ?? ''})
          .toList()
          .cast<Map<String, dynamic>>();
    }

    if (product['specifications'] != null && product['specifications'] is Map) {
      final specs = product['specifications'] as Map<String, dynamic>;
      specs.forEach((key, value) {
        _specifications.add({
          'key': TextEditingController(text: key),
          'value': TextEditingController(text: value?.toString() ?? '')
        });
      });
    }

    setState(() {});
  }

  // ==================== Image Picker ====================

  Future<void> _pickNewMainImage() async {
    final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (image != null)
      setState(() {
        _newMainImage = File(image.path);
        _removeMainImage = false;
      });
  }

  void _markMainImageForRemoval() => setState(() {
    _removeMainImage = true;
    _newMainImage = null;
    _currentMainImageUrl = null;
  });

  void _undoRemoveMainImage() => setState(() {
    _removeMainImage = false;
    _newMainImage = null;
  });

  void _markAdditionalImageForDeletion(int index) {
    final imageData = _currentAdditionalImages[index];
    final imageId = imageData['id'];
    setState(() {
      _deletedImageIds.add(imageId);
      _currentAdditionalImages.removeAt(index);
    });
  }

  Future<void> _pickNewAdditionalImages() async {
    final List<XFile> images =
    await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (images.isNotEmpty)
      setState(() =>
          _newAdditionalImages.addAll(images.map((img) => File(img.path))));
  }

  void _removeNewAdditionalImage(int index) =>
      setState(() => _newAdditionalImages.removeAt(index));

  // ==================== Specifications ====================

  void _addSpecification() => setState(() => _specifications
      .add({'key': TextEditingController(), 'value': TextEditingController()}));

  void _removeSpecification(int index) {
    _specifications[index]['key']?.dispose();
    _specifications[index]['value']?.dispose();
    setState(() => _specifications.removeAt(index));
  }

  // ==================== Save Product ====================

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubCategoryId == null) { _showSnackBar('الرجاء اختيار التصنيف الفرعي', dangerRed); return; }

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}/v1/company/products/${widget.productId}'));
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      request.fields.addAll({
        'name_ar': _nameArController.text.trim(),
        'sku': _skuController.text.trim(),
        'price': _priceController.text.trim(),
        'discount_price': _discountPriceController.text.isNotEmpty ? _discountPriceController.text.trim() : '',
        'wholesale_price': _wholesalePriceController.text.isNotEmpty ? _wholesalePriceController.text.trim() : '',
        'wholesale_min_quantity': _wholesaleMinQtyController.text.isNotEmpty ? _wholesaleMinQtyController.text.trim() : '',
        'stock': _stockController.text.isNotEmpty ? _stockController.text.trim() : '0',
        'unit': _selectedUnit,
        'sub_category_id': _selectedSubCategoryId ?? '',
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'description_ar': _descriptionArController.text.trim(),
        'is_active': _isActive ? '1' : '0',
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

      if (_removeMainImage) request.fields['remove_main_image'] = '1';

      final specs = <String, String>{};
      for (var spec in _specifications) {
        final key = spec['key']?.text.trim() ?? '';
        final value = spec['value']?.text.trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) specs[key] = value;
      }
      if (specs.isNotEmpty) request.fields['specifications'] = jsonEncode(specs);

      if (_newMainImage != null) request.files.add(await http.MultipartFile.fromPath('main_image', _newMainImage!.path));

      for (var id in _deletedImageIds) { request.fields['delete_images[]'] = id.toString(); }
      for (var image in _newAdditionalImages) { request.files.add(await http.MultipartFile.fromPath('images[]', image.path)); }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('📢 Status Code: ${streamedResponse.statusCode}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(responseBody);
      } catch (e) {
        setState(() => _isSaving = false);
        _showSnackBar('استجابة غير صالحة من الخادم', dangerRed);
        return;
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (data['success'] == true || data['data'] != null) {
          _showSnackBar('تم تحديث المنتج بنجاح 🎉', successGreen);
          Navigator.pop(context, true);
        } else {
          _showSnackBar(data['message'] ?? 'فشل تحديث المنتج', dangerRed);
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      if (mounted) { setState(() => _isSaving = false); _showSnackBar('حدث خطأ في تحديث المنتج', dangerRed); }
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

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showSubCategoryDropdown)
          setState(() => _showSubCategoryDropdown = false);
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: AppBar(
            backgroundColor: cardWhite,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: darkColor),
                onPressed: () => Navigator.pop(context)),
            title: Text('تعديل المنتج',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor))),
        body: _isLoadingProduct ? _buildLoading() : _buildForm(),
      ),
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: primaryBlue));

  Widget _buildForm() {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionTitle('معلومات أساسية', Icons.info_rounded),
              const SizedBox(height: 12),
              _buildTextField(_nameArController, 'اسم المنتج *',
                  'أدخل اسم المنتج (عربي / English)',
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              _buildTextField(_skuController, 'رمز المنتج (SKU) *', 'SKU-001',
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
                        _discountPriceController, 'سعر الخصم', '0.00',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr))
              ]),
              const SizedBox(height: 12),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: successGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: successGreen.withOpacity(0.2))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.warehouse_rounded,
                              color: successGreen, size: 18),
                          const SizedBox(width: 6),
                          Text('سعر الجملة (اختياري)',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: successGreen))
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _buildTextField(_wholesalePriceController,
                                  'سعر الجملة', '0.00',
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildTextField(_wholesaleMinQtyController,
                                  'الحد الأدنى للكمية', 'مثال: 10',
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr))
                        ])
                      ])),
              const SizedBox(height: 12),
              _buildTextField(_stockController, 'الكمية المتاحة *', '0',
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr),
              const SizedBox(height: 24),
              _buildSectionTitle('معلومات إضافية', Icons.more_horiz_rounded),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(_brandController, 'العلامة التجارية',
                        'مثال: Samsung / سامسونج')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(
                        _modelController, 'الموديل', 'مثال: X1000',
                        textDirection: TextDirection.ltr))
              ]),
              const SizedBox(height: 12),
              _buildTextField(
                  _warrantyController, 'الضمان', 'مثال: سنة واحدة / 1 Year'),
              const SizedBox(height: 24),
              _buildSectionTitle('الصور', Icons.image_rounded),
              const SizedBox(height: 12),
              _buildMainImageSection(),
              const SizedBox(height: 12),
              _buildAdditionalImagesSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
              const SizedBox(height: 12),
              _buildSpecificationsSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('الحالة', Icons.toggle_on_rounded),
              const SizedBox(height: 12),
              _buildActiveToggle(),
              const SizedBox(height: 24),
              _buildSectionTitle('الشحن', Icons.local_shipping_rounded),
              const SizedBox(height: 12),
              _buildShippingSection(),
              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 30),
            ])));
  }

  // ✅ _buildUnitDropdown مع حقل إدخال واضح
  Widget _buildUnitDropdown() {
    final selectedUnitLabel = _units.firstWhere(
          (u) => u['key'] == _selectedUnit,
      orElse: () => {'key': 'قطعة', 'label': 'قطعة'},
    )['label'] ?? 'قطعة';

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
            Icon(Icons.straighten_rounded, size: 20, color: _showAllUnits ? primaryBlue : mediumGray),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedUnitLabel,
                style: GoogleFonts.cairo(fontSize: 14, color: darkColor, fontWeight: FontWeight.w600),
                textDirection: _getTextDirection(selectedUnitLabel),
              ),
            ),
            Icon(_showAllUnits ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: mediumGray),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
                        isSelected ? Icons.check_rounded : Icons.straighten_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : mediumGray,
                      ),
                    ),
                    title: Text(
                      unit['label'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? primaryBlue : darkColor,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20)
                        : const Icon(Icons.chevron_left_rounded, color: Colors.grey, size: 20),
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
                icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 20),
                label: Text('إضافة وحدة جديدة',
                    style: GoogleFonts.cairo(fontSize: 14, color: primaryBlue, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✏️ إضافة وحدة جديدة',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
              const SizedBox(height: 10),
              TextField(
                controller: _customUnitController,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب اسم الوحدة هنا... (مثال: حبة، كرتونة كبيرة)',
                  hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
                  hintTextDirection: TextDirection.rtl,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryBlue.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  prefixIcon: const Icon(Icons.edit_rounded, size: 20, color: primaryBlue),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('إضافة الوحدة',
                        style: GoogleFonts.cairo(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _showCustomUnitInput = false;
                      _customUnitController.clear();
                    }),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text('إلغاء', style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    ]);
  }

  // ✅ قسم الشحن - اختيار المدن بالنقر + أسعار للمحددة فقط
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
        // ✅ Toggle الشحن
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.local_shipping_rounded,
                color: _hasShipping ? primaryBlue : Colors.grey, size: 22),
            const SizedBox(width: 10),
            Text(_hasShipping ? 'الشحن متاح' : 'الشحن غير متاح',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _hasShipping ? primaryBlue : mediumGray))
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
                                color: Colors.white, shape: BoxShape.circle)))
                  ]))),
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
                style: GoogleFonts.cairo(
                    fontSize: 13, fontWeight: FontWeight.w600, color: darkColor),
              ),
              Text(
                '${selectedCities.length} مدينة',
                style: GoogleFonts.cairo(
                    fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600),
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
              style: GoogleFonts.cairo(
                  fontSize: 13, fontWeight: FontWeight.w600, color: darkColor),
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

  Widget _buildSectionTitle(String title, IconData icon) => Row(children: [
    Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              primaryBlue.withOpacity(0.12),
              secondaryBlue.withOpacity(0.06)
            ]),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: primaryBlue)),
    const SizedBox(width: 10),
    Text(title,
        style: GoogleFonts.cairo(
            fontSize: 16, fontWeight: FontWeight.bold, color: darkColor))
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
      Text('الوصف',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
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
              hintText:
              'اكتب وصفاً تفصيلياً للمنتج...\nيمكنك الكتابة بالعربية والإنجليزية معاً\nWrite product description in Arabic and English',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: mediumGray.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('يدعم العربية والإنجليزية',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: mediumGray.withOpacity(0.7))),
              const Spacer(),
              Text('${_descriptionArController.text.length} حرف',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: mediumGray.withOpacity(0.7))),
            ]),
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
                textDirection: _getTextDirection(_getSelectedSubCategoryName()),
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
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
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
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 12, color: Colors.grey.shade400),
                  hintTextDirection: TextDirection.rtl,
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
                onChanged: (v) => setState(() {
                  _filteredSubCategories = v.isEmpty
                      ? List.from(_subCategories)
                      : _subCategories
                      .where((s) => (s['full_name'] ?? s['name_ar'] ?? '')
                      .toLowerCase()
                      .contains(v.toLowerCase()))
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
                itemBuilder: (_, i) {
                  final sub = _filteredSubCategories[i];
                  final isSelected =
                      sub['id']?.toString() == _selectedSubCategoryId;
                  final displayName = sub['full_name'] ?? sub['name_ar'] ?? '';
                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.08),
                    title: Text(
                      displayName,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primaryBlue : darkColor),
                      textDirection: _getTextDirection(displayName),
                    ),
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
                    style: GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
              ),
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

  Widget _buildMainImageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الصورة الرئيسية *',
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      if (_newMainImage != null)
        _buildNewImagePreview(_newMainImage!,
            onRemove: () => setState(() => _newMainImage = null))
      else if (_currentMainImageUrl != null && !_removeMainImage)
        _buildCurrentImagePreview(_currentMainImageUrl!,
            onReplace: _pickNewMainImage, onRemove: _markMainImageForRemoval)
      else
        GestureDetector(
            onTap: _currentMainImageUrl != null
                ? _undoRemoveMainImage
                : _pickNewMainImage,
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
                          Icon(
                              _currentMainImageUrl != null
                                  ? Icons.undo_rounded
                                  : Icons.add_a_photo_rounded,
                              size: 40,
                              color: primaryBlue.withOpacity(0.6)),
                          const SizedBox(height: 8),
                          Text(
                              _currentMainImageUrl != null
                                  ? 'تراجع عن الحذف'
                                  : 'انقر لاختيار الصورة الرئيسية',
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: mediumGray))
                        ])))),
    ]);
  }

  Widget _buildCurrentImagePreview(String imageUrl,
      {required VoidCallback onReplace, required VoidCallback onRemove}) =>
      Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    height: 200,
                    color: lightGray,
                    child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primaryBlue))),
                errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: lightGray,
                    child: const Center(
                        child: Icon(Icons.image_not_supported_rounded,
                            size: 40, color: Colors.grey))))),
        Positioned(
            top: 8,
            left: 8,
            child: Row(children: [
              GestureDetector(
                  onTap: onReplace,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: primaryBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 16))),
              const SizedBox(width: 6),
              GestureDetector(
                  onTap: onRemove,
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: dangerRed, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white, size: 16)))
            ])),
        Positioned(
            bottom: 8,
            right: 8,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('الصورة الحالية',
                    style:
                    GoogleFonts.cairo(fontSize: 10, color: Colors.white))))
      ]);

  Widget _buildNewImagePreview(File image, {required VoidCallback onRemove}) =>
      Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(image,
                height: 200, width: double.infinity, fit: BoxFit.cover)),
        Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
                onTap: onRemove,
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: dangerRed, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18)))),
        Positioned(
            bottom: 8,
            right: 8,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: successGreen.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('الصورة الجديدة',
                    style:
                    GoogleFonts.cairo(fontSize: 10, color: Colors.white))))
      ]);

  Widget _buildAdditionalImagesSection() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('صور إضافية',
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ..._currentAdditionalImages
              .asMap()
              .entries
              .map((entry) => Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                    imageUrl: entry.value['url'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover)),
            Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                    onTap: () =>
                        _markAdditionalImageForDeletion(entry.key),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: dangerRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14))))
          ])),
          ..._newAdditionalImages
              .asMap()
              .entries
              .map((entry) => Stack(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(entry.value,
                    width: 80, height: 80, fit: BoxFit.cover)),
            Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                    onTap: () => _removeNewAdditionalImage(entry.key),
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: dangerRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14)))),
            Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('جديد',
                        style: GoogleFonts.cairo(
                            fontSize: 8, color: Colors.white))))
          ])),
          GestureDetector(
              onTap: _pickNewAdditionalImages,
              child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Center(
                      child: Icon(Icons.add_rounded,
                          size: 30, color: primaryBlue.withOpacity(0.6))))),
        ])
      ]);

  Widget _buildSpecificationsSection() => Column(children: [
    ..._specifications.asMap().entries.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: entry.value['key'],
                  textDirection:
                  _getTextDirection(entry.value['key']!.text),
                  style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                      hintText: 'المفتاح (مثال: اللون / Color)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade400),
                      hintTextDirection: TextDirection.rtl,
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
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                      hintText: 'القيمة (مثال: أحمر / Red)',
                      hintStyle: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade400),
                      hintTextDirection: TextDirection.rtl,
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
                      color: dangerRed, size: 18)))
        ]))),
    const SizedBox(height: 4),
    TextButton.icon(
        onPressed: _addSpecification,
        icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 18),
        label: Text('إضافة مواصفة',
            style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue)))
  ]);

  Widget _buildActiveToggle() => Container(
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
                  color: _isActive ? successGreen : mediumGray))
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
                              color: Colors.white, shape: BoxShape.circle)))
                ])))
      ]));

  Widget _buildSaveButton() => SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 5),
          child: _isSaving
              ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.save_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text('تحديث المنتج',
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))
          ])));
}