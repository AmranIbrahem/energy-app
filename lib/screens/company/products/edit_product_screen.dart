// lib/screens/company/products/edit_product_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:GeniusHouse/screens/company/products/add_home_appliance_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:GeniusHouse/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ============================================================
// تعريفات حقول المواصفات لكل نوع منتج
// ============================================================

class ProductSpecField {
  final String key; // المفتاح العربي المطابق لـ specifications
  final String label; // عنوان الحقل
  final String
      inputType; // 'text' | 'number' | 'number_with_unit' | 'dropdown' | 'dimensions'
  final List<String>? options;
  final List<String>? unitOptions;
  final String? defaultUnit;
  final bool isRequired;

  const ProductSpecField({
    required this.key,
    required this.label,
    required this.inputType,
    this.options,
    this.unitOptions,
    this.defaultUnit,
    this.isRequired = false,
  });
}

class ProductSpecsDefinitions {
  static const Map<String, List<ProductSpecField>> specsByType = {
    // ==================== بطارية ====================
    'battery': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
        key: 'نوع البطارية',
        label: 'نوع البطارية',
        inputType: 'dropdown',
        options: ['أسيد (Lead Acid)', 'ليثيوم (Lithium)', 'جيل (Gel)'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'الجهد',
        label: 'الجهد',
        inputType: 'dropdown',
        options: ['12 فولت', '24 فولت', '48 فولت'],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'السعة',
          label: 'السعة',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي'],
          defaultUnit: 'كيلوواط ساعي',
          isRequired: true),
      ProductSpecField(
        key: 'السعة (أمبير ساعي)',
        label: 'السعة (أمبير ساعي)',
        inputType: 'number_with_unit',
        unitOptions: ['أمبير ساعي'],
        defaultUnit: 'أمبير ساعي',
      ),
      ProductSpecField(
          key: 'عمق التفريغ',
          label: 'عمق التفريغ',
          inputType: 'number_with_unit',
          unitOptions: ['%'],
          defaultUnit: '%',
          isRequired: true),
      ProductSpecField(
          key: 'عدد دورات الشحن',
          label: 'عدد دورات الشحن',
          inputType: 'number',
          isRequired: true),
      ProductSpecField(
          key: 'أقصى تيار تفريغ',
          label: 'أقصى تيار تفريغ',
          inputType: 'number_with_unit',
          unitOptions: ['أمبير'],
          defaultUnit: 'أمبير'),
      ProductSpecField(
          key: 'أقصى تيار شحن',
          label: 'أقصى تيار شحن',
          inputType: 'number_with_unit',
          unitOptions: ['أمبير'],
          defaultUnit: 'أمبير'),

      // ✅ جديد: حقول الربط على التوازي للبطارية
      ProductSpecField(
        key: 'يدعم الربط على التوازي',
        label: 'يدعم الربط على التوازي',
        inputType: 'dropdown',
        options: ['نعم', 'لا'],
      ),
      ProductSpecField(
        key: 'أقصى عدد بطاريات على التوازي',
        label: 'أقصى عدد بطاريات يمكن ربطها على التوازي',
        inputType: 'number',
      ),
    ],

    // ==================== عاكس (انفرتر) ====================
    'inverter': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
          key: 'استطاعة العاكس',
          label: 'استطاعة العاكس',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          defaultUnit: 'واط',
          isRequired: true),
      ProductSpecField(
          key: 'قدرة الإقلاع',
          label: 'قدرة الإقلاع',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          defaultUnit: 'واط'),
      ProductSpecField(
        key: 'نوع العاكس',
        label: 'نوع العاكس',
        inputType: 'dropdown',
        options: [
          'هجين (Hybrid)',
          'منفصل (Off-Grid)',
          'مرتبط بالشبكة (On-Grid)'
        ],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'جهد البطارية',
        label: 'جهد البطارية',
        inputType: 'dropdown',
        options: ['12 فولت', '24 فولت', '48 فولت'],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'أدنى جهد للألواح',
          label: 'أدنى جهد للألواح',
          inputType: 'number_with_unit',
          unitOptions: ['فولت'],
          defaultUnit: 'فولت',
          isRequired: true),
      ProductSpecField(
          key: 'أقصى جهد للألواح',
          label: 'أقصى جهد للألواح',
          inputType: 'number_with_unit',
          unitOptions: ['فولت'],
          defaultUnit: 'فولت',
          isRequired: true),
      ProductSpecField(
        key: 'يدعم بطارية ليثيوم',
        label: 'يدعم بطارية ليثيوم',
        inputType: 'dropdown',
        options: ['نعم', 'لا'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'الطور',
        label: 'الطور',
        inputType: 'dropdown',
        options: ['أحادي الطور', 'ثلاثي الطور'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'عدد المداخل الشمسية',
        label: 'عدد المداخل الشمسية',
        inputType: 'dropdown',
        options: ['مدخل واحد', 'مدخلان'],
      ),
      ProductSpecField(
        key: 'تصنيف استخدام المحول',
        label: 'تصنيف استخدام المحول (منزلي، صناعي، زراعي)',
        inputType: 'text',
      ),

      // ✅ جديد: حقول الربط على التوازي للعاكس
      ProductSpecField(
        key: 'يدعم الربط على التوازي',
        label: 'يدعم الربط على التوازي',
        inputType: 'dropdown',
        options: ['نعم', 'لا'],
      ),
      ProductSpecField(
        key: 'أقصى عدد عواكس على التوازي',
        label: 'أقصى عدد عواكس يمكن ربطها على التوازي',
        inputType: 'number',
      ),
    ],

    // ==================== كابل ====================
    'cable': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
          key: 'مساحة المقطع',
          label: 'مساحة المقطع',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
        key: 'نوع الموصل',
        label: 'نوع الموصل',
        inputType: 'dropdown',
        options: ['نحاس', 'ألمنيوم'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'عدد النواقل',
        label: 'عدد النواقل',
        inputType: 'dropdown',
        options: ['1', '2', '3', '4', '5+'],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'طول الرول',
          label: 'طول الرول',
          inputType: 'number_with_unit',
          unitOptions: ['متر'],
          defaultUnit: 'متر'),
    ],

    // ==================== قاطع كهربائي ====================
    'circuit_breaker': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
          key: 'التيار',
          label: 'التيار',
          inputType: 'number_with_unit',
          unitOptions: ['أمبير'],
          defaultUnit: 'أمبير',
          isRequired: true),
      ProductSpecField(
          key: 'قدرة القطع',
          label: 'قدرة القطع',
          inputType: 'number_with_unit',
          unitOptions: ['kA'],
          defaultUnit: 'kA'),
      ProductSpecField(
        key: 'عدد الأقطاب',
        label: 'عدد الأقطاب',
        inputType: 'dropdown',
        options: ['1', '2', '3', '6'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'نوع التيار',
        label: 'نوع التيار',
        inputType: 'dropdown',
        options: ['تيار مستمر (DC)', 'تيار متناوب (AC)'],
        isRequired: true,
      ),
    ],

    // ==================== لوح طاقة شمسية ====================
    'solar_panel': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
          key: 'استطاعة اللوح',
          label: 'استطاعة اللوح',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          defaultUnit: 'واط',
          isRequired: true),
      ProductSpecField(
          key: 'الكفاءة',
          label: 'الكفاءة',
          inputType: 'number_with_unit',
          unitOptions: ['%'],
          defaultUnit: '%'),
      ProductSpecField(
          key: 'جهد الدارة المفتوحة (Voc)',
          label: 'جهد الدارة المفتوحة (Voc)',
          inputType: 'number_with_unit',
          unitOptions: ['فولت'],
          defaultUnit: 'فولت',
          isRequired: true),
      ProductSpecField(
          key: 'جهد التشغيل (Vmp)',
          label: 'جهد التشغيل (Vmp)',
          inputType: 'number_with_unit',
          unitOptions: ['فولت'],
          defaultUnit: 'فولت',
          isRequired: true),
      ProductSpecField(
        key: 'نوع اللوح',
        label: 'نوع اللوح',
        inputType: 'dropdown',
        options: [
          'أحادي البلورية (Mono)',
          'متعدد البلورات (Poly)',
          'الأغشية الرقيقة (Thin Film)',
          'ثنائي الوجه (Bifacial)',
          'PERC',
          'HJT',
          'TOPCon',
          'نصف خلية (Half-Cut)',
          'Shingled',
          'مرن (Flexible)',
        ],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'الأبعاد',
          label: 'الأبعاد (الطول × العرض × السمك)',
          inputType: 'text'),
    ],

    // ==================== وحدة إنارة ====================
    'lighting_unit': [
      ProductSpecField(
          key: 'الماركة',
          label: 'الماركة',
          inputType: 'text',
          isRequired: true),
      ProductSpecField(
        key: 'نوع الموديل',
        label: 'نوع الموديل',
        inputType: 'dropdown',
        options: [
          'سبوت (Spot)',
          'كشاف (Floodlight)',
          'شريط (Strip)',
          'ثريا (Chandelier)'
        ],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'الاستطاعة',
          label: 'الاستطاعة',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          defaultUnit: 'واط',
          isRequired: true),
      ProductSpecField(
          key: 'شدة الإضاءة',
          label: 'شدة الإضاءة',
          inputType: 'number_with_unit',
          unitOptions: ['لومن'],
          defaultUnit: 'لومن',
          isRequired: true),
      ProductSpecField(
        key: 'لون الإضاءة',
        label: 'لون الإضاءة',
        inputType: 'dropdown',
        options: ['دافئ (Warm)', 'طبيعي (Natural)', 'أبيض (White)'],
        isRequired: true,
      ),
      ProductSpecField(
        key: 'الاستخدام',
        label: 'الاستخدام',
        inputType: 'dropdown',
        options: ['داخلي (Indoor)', 'خارجي (Outdoor)'],
        isRequired: true,
      ),
      ProductSpecField(
          key: 'زاوية الإضاءة',
          label: 'زاوية الإضاءة',
          inputType: 'number_with_unit',
          unitOptions: ['درجة'],
          defaultUnit: 'درجة'),
      ProductSpecField(
          key: 'درجة حرارة اللون',
          label: 'درجة حرارة اللون',
          inputType: 'number_with_unit',
          unitOptions: ['كلفن'],
          defaultUnit: 'كلفن'),
      ProductSpecField(
          key: 'الأبعاد',
          label: 'الأبعاد (الطول × العرض × الارتفاع)',
          inputType: 'text'),
      ProductSpecField(
          key: 'درجة الحماية', label: 'درجة الحماية IP', inputType: 'text'),
    ],
  };

  static const List<String> homeApplianceTypes = [
    'air_conditioners',
    'fans',
    'air_coolers',
    'heaters',
    'air_treatment',
    'refrigerators',
    'freezers',
    'water_dispensers',
    'washing_machines',
    'dryers',
    'dishwashers',
    'ovens_cookers',
    'microwaves',
    'kitchen_hoods',
    'small_cooking',
    'food_preparation',
    'juicers',
    'mixers_kneaders',
    'kettles',
    'coffee_machines',
    'irons',
    'vacuum_cleaners',
    'water_heaters',
    'televisions',
  ];

  static String? getSubcategoriesEndpoint(String productType) {
    switch (productType) {
      case 'battery':
        return '/v1/company/products/getBatterySubcategories';
      case 'inverter':
        return '/v1/company/products/getInverterSubcategories';
      case 'cable':
        return '/v1/company/products/getCableSubcategories';
      case 'circuit_breaker':
        return '/v1/company/products/getCircuitBreakerSubcategories';
      case 'solar_panel':
        return '/v1/company/products/getSolarPanelSubcategories';
      case 'lighting_unit':
        return '/v1/company/products/getLightingUnitSubcategories';
      default:
        if (homeApplianceTypes.contains(productType)) {
          return '/v1/company/products/getHomeSubcategories';
        }
        return null;
    }
  }
}

// ============================================================
// شاشة تعديل المنتج
// ============================================================

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
  static const Color sypAmber = Color(0xFFD97706);

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

  // ✅ أسعار الليرة السورية
  final _priceSypController = TextEditingController();
  final _discountPriceSypController = TextEditingController();
  final _wholesalePriceSypController = TextEditingController();

  // ✅ سعر الصرف الحالي
  double _exchangeRate = 0;
  bool _isLoadingRate = false;

  // Dropdown Values
  String? _selectedSubCategoryId;
  String _selectedUnit = 'قطعة';
  bool _isActive = true;

  // ✅ نوع المنتج الحالي
  String? _productType;

  // ✅ حقول المواصفات الديناميكية
  final Map<String, TextEditingController> _specFieldControllers = {};
  final Map<String, String?> _specFieldSelectValues = {};
  final Map<String, String?> _specFieldUnitValues = {};

  // ✅ متغيرات الوحدة المخصصة
  final _customUnitController = TextEditingController();
  bool _showCustomUnitInput = false;
  bool _showAllUnits = false;

  // ✅ متغيرات الشحن
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

  // Subcategory Search
  List<dynamic> _filteredSubCategories = [];
  final TextEditingController _subCategorySearchController =
      TextEditingController();
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

  // ✅ الوحدات
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

  // ✅ المواصفات الإضافية فقط (key/value)
  List<Map<String, TextEditingController>> _specifications = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _initShippingCostControllers();
    _fetchProductDetails();
    _fetchExchangeRate();

    _descriptionArController.addListener(() {
      if (mounted) setState(() {});
    });
  }

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
    _specFieldControllers.forEach((_, c) => c.dispose());
    _shippingCostControllers.forEach((_, controller) => controller.dispose());
    _clearSpecifications();
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

  // ==================== Helpers ====================

  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final firstChar = trimmed.characters.first;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
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
      _units.add({'key': customUnit, 'label': customUnit});
      _selectedUnit = customUnit;
      _showCustomUnitInput = false;
      _customUnitController.clear();
    });
    _showSnackBar('تم إضافة الوحدة بنجاح', successGreen);
  }

  // ==================== Exchange Rate ====================

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

  // ==================== Data Fetching ====================

  Future<void> _fetchCreateData() async {
    if (_productType == null) return;

    final endpoint =
        ProductSpecsDefinitions.getSubcategoriesEndpoint(_productType!);
    final String apiPath = endpoint ?? '/v1/company/products/create-data';

    try {
      final response = await _apiService.get(apiPath, requiresAuth: true);
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
        });
      }
    } catch (e) {
      // debugPrint('Error fetching create data: $e');
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() => _isLoadingProduct = true);
    try {
      final response = await _apiService
          .get('/v1/company/products/${widget.productId}', requiresAuth: true);
      if (response['data'] != null &&
          response['data']['product'] != null &&
          mounted) {
        final product = response['data']['product'];
        _populateForm(product);
        await _fetchCreateData();
        if (mounted) {
          setState(() => _isLoadingProduct = false);
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingProduct = false);
          _showSnackBar('فشل تحميل المنتج', dangerRed);
        }
      }
    } catch (e) {
      // debugPrint('Error fetching product: $e');
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
    _wholesaleMinQtyController.text =
        product['wholesale_min_quantity']?.toString() ?? '';
    _stockController.text = product['stock']?.toString() ?? '0';
    _brandController.text = product['brand'] ?? '';
    _modelController.text = product['model'] ?? '';
    _warrantyController.text = product['warranty'] ?? '';
    _descriptionArController.text = product['description_ar'] ?? '';

    _priceSypController.text = _formatSypFromApi(product['price_syp']);
    _discountPriceSypController.text =
        _formatSypFromApi(product['discount_price_syp']);
    _wholesalePriceSypController.text =
        _formatSypFromApi(product['wholesale_price_syp']);

    _selectedSubCategoryId = product['sub_category']?['id']?.toString();
    _selectedUnit = product['unit'] ?? 'قطعة';
    _isActive = product['is_active'] ?? true;
    _currentMainImageUrl = product['main_image'];

    _productType = product['product_type']?.toString();

    _hasShipping = product['has_shipping'] ?? false;

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
          if (_shippingCostControllers.containsKey(cityData)) {
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

    // ✅ قراءة المواصفات من الـ API وتوزيعها
    final rawSpecs = <Map<String, String>>[];
    if (product['specifications'] != null) {
      if (product['specifications'] is List) {
        for (var spec in (product['specifications'] as List)) {
          if (spec is Map) {
            rawSpecs.add({
              'key': spec['key']?.toString() ?? '',
              'value': spec['value']?.toString() ?? '',
            });
          }
        }
      } else if (product['specifications'] is Map) {
        final specs = product['specifications'] as Map<String, dynamic>;
        specs.forEach((key, value) {
          rawSpecs.add({
            'key': key.toString(),
            'value': value?.toString() ?? '',
          });
        });
      } else if (product['specifications'] is String) {
        try {
          final decoded = jsonDecode(product['specifications'] as String);
          if (decoded is List) {
            for (var spec in decoded) {
              if (spec is Map) {
                rawSpecs.add({
                  'key': spec['key']?.toString() ?? '',
                  'value': spec['value']?.toString() ?? '',
                });
              }
            }
          } else if (decoded is Map) {
            decoded.forEach((key, value) {
              rawSpecs.add({
                'key': key.toString(),
                'value': value?.toString() ?? '',
              });
            });
          }
        } catch (_) {
          // debugPrint('Error parsing specifications JSON');
        }
      }
    }

    _initializeSpecFields(rawSpecs);

    setState(() {});
  }

  String _formatSypFromApi(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty) return '';
    final parsed = double.tryParse(str);
    if (parsed == null) return str;
    if (parsed == parsed.roundToDouble()) {
      return parsed.toStringAsFixed(0);
    }
    return parsed.toStringAsFixed(2);
  }

  void _initializeSpecFields(List<Map<String, String>> rawSpecs) {
    _specFieldControllers.forEach((_, c) => c.dispose());
    _specFieldControllers.clear();
    _specFieldSelectValues.clear();
    _specFieldUnitValues.clear();
    _clearSpecifications();
    _specifications.clear();

    if (_productType == null) {
      for (var spec in rawSpecs) {
        _specifications.add({
          'key': TextEditingController(text: spec['key'] ?? ''),
          'value': TextEditingController(text: spec['value'] ?? ''),
        });
      }
      return;
    }

    final allFields = <ProductSpecField>[];
    allFields.addAll(ProductSpecsDefinitions.specsByType[_productType!] ?? []);
    if (ProductSpecsDefinitions.homeApplianceTypes.contains(_productType)) {
      allFields.addAll(_getHomeSpecFields());
    }

    final knownKeys = <String, ProductSpecField>{};
    for (var f in allFields) {
      knownKeys[f.key] = f;
    }

    final valuesMap = <String, String>{};
    for (var spec in rawSpecs) {
      final k = (spec['key'] ?? '').trim();
      final v = (spec['value'] ?? '').trim();
      if (k.isNotEmpty) valuesMap[k] = v;
    }

    for (var field in allFields) {
      final existing = valuesMap[field.key];

      if (field.inputType == 'text' || field.inputType == 'number') {
        _specFieldControllers[field.key] =
            TextEditingController(text: existing ?? '');
      } else if (field.inputType == 'number_with_unit') {
        final parsed = _parseValueWithUnit(existing, field.unitOptions);
        _specFieldControllers[field.key] =
            TextEditingController(text: parsed['value'] ?? '');
        _specFieldUnitValues[field.key] = parsed['unit'] ??
            field.defaultUnit ??
            (field.unitOptions?.isNotEmpty == true
                ? field.unitOptions!.first
                : null);
      } else if (field.inputType == 'dropdown') {
        if (existing != null && (field.options?.contains(existing) ?? false)) {
          _specFieldSelectValues[field.key] = existing;
        } else {
          _specFieldSelectValues[field.key] = null;
        }
      } else if (field.inputType == 'dimensions') {
        _specFieldControllers[field.key] =
            TextEditingController(text: existing ?? '');
      }
    }

    for (var spec in rawSpecs) {
      final k = (spec['key'] ?? '').trim();
      final v = (spec['value'] ?? '').trim();
      if (k.isEmpty) continue;
      if (!knownKeys.containsKey(k)) {
        _specifications.add({
          'key': TextEditingController(text: k),
          'value': TextEditingController(text: v),
        });
      }
    }
  }

  List<ProductSpecField> _getHomeSpecFields() {
    if (_productType == null) return [];
    final result = <ProductSpecField>[];

    for (var f in HomeApplianceData.commonFields) {
      result.add(ProductSpecField(
        key: f.labelAr,
        label: f.labelAr,
        inputType: _mapHomeInputType(f.inputType),
        options: f.options,
        unitOptions: f.unitOptions,
        defaultUnit:
            f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null,
      ));
    }

    final special = HomeApplianceData.specialFields[_productType!] ?? [];
    for (var f in special) {
      result.add(ProductSpecField(
        key: f.labelAr,
        label: f.labelAr,
        inputType: _mapHomeInputType(f.inputType),
        options: f.options,
        unitOptions: f.unitOptions,
        defaultUnit:
            f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null,
      ));
    }
    return result;
  }

  String _mapHomeInputType(String homeType) {
    switch (homeType) {
      case 'single_select':
        return 'dropdown';
      case 'multi_select':
        return 'text';
      case 'boolean':
        return 'text';
      case 'number_with_unit':
        return 'number_with_unit';
      case 'number':
        return 'number';
      case 'text':
        return 'text';
      case 'dimensions':
        return 'text';
      default:
        return 'text';
    }
  }

  Map<String, String?> _parseValueWithUnit(String? raw, List<String>? units) {
    if (raw == null || raw.isEmpty) {
      return {
        'value': null,
        'unit': units?.isNotEmpty == true ? units!.first : null,
      };
    }
    if (units == null || units.isEmpty) {
      return {'value': raw, 'unit': null};
    }
    for (var u in units) {
      if (raw.endsWith(u)) {
        return {
          'value': raw.substring(0, raw.length - u.length).trim(),
          'unit': u,
        };
      }
    }
    final parts = raw.split(' ');
    if (parts.length > 1) {
      return {
        'value': parts.sublist(0, parts.length - 1).join(' '),
        'unit': parts.last,
      };
    }
    return {'value': raw, 'unit': units.first};
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
    if (_selectedSubCategoryId == null) {
      _showSnackBar('الرجاء اختيار التصنيف الفرعي', dangerRed);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '${AppConstants.baseUrl}/v1/company/products/${widget.productId}'));
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      request.fields.addAll({
        'name_ar': _nameArController.text.trim(),
        'sku': _skuController.text.trim(),
        'price': _priceController.text.trim(),
        'discount_price': _discountPriceController.text.isNotEmpty
            ? _discountPriceController.text.trim()
            : '',
        'wholesale_price': _wholesalePriceController.text.isNotEmpty
            ? _wholesalePriceController.text.trim()
            : '',
        'wholesale_min_quantity': _wholesaleMinQtyController.text.isNotEmpty
            ? _wholesaleMinQtyController.text.trim()
            : '',
        'stock': _stockController.text.isNotEmpty
            ? _stockController.text.trim()
            : '0',
        'unit': _selectedUnit,
        'sub_category_id': _selectedSubCategoryId ?? '',
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'description_ar': _descriptionArController.text.trim(),
        'is_active': _isActive ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
      });

      // ✅ أسعار الليرة السورية
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

      if (_wholesalePriceSypController.text.trim().isNotEmpty) {
        request.fields['wholesale_price_syp'] =
            _wholesalePriceSypController.text.trim();
      } else {
        request.fields['wholesale_price_syp'] = '';
      }

      // ═══════════════════════════════════════════════════════════
      // ✅ جديد: استخراج حقول الربط على التوازي وإرسالها top-level
      // ═══════════════════════════════════════════════════════════
      final supportsParallelValue =
          _specFieldSelectValues['يدعم الربط على التوازي'];
      final supportsParallel =
          (supportsParallelValue != null && supportsParallelValue == 'نعم')
              ? '1'
              : '0';
      request.fields['supports_parallel'] = supportsParallel;

      if (_productType == 'battery') {
        final maxCount = _specFieldControllers['أقصى عدد بطاريات على التوازي']
                ?.text
                .trim() ??
            '';
        if (supportsParallel == '1' && maxCount.isNotEmpty) {
          request.fields['max_parallel_count'] = maxCount;
        }
      } else if (_productType == 'inverter') {
        final maxCount =
            _specFieldControllers['أقصى عدد عواكس على التوازي']?.text.trim() ??
                '';
        if (supportsParallel == '1' && maxCount.isNotEmpty) {
          request.fields['max_parallel_count'] = maxCount;
        }
      }

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
        } else {
          request.fields['shipping_cities'] = jsonEncode([]);
        }
      }

      if (_removeMainImage) request.fields['remove_main_image'] = '1';

      // ============================================================
      // ✅ جمع المواصفات: الحقول الديناميكية + الإضافية
      // ============================================================
      final specs = <Map<String, String>>[];

      final allFields = <ProductSpecField>[];
      if (_productType != null) {
        allFields
            .addAll(ProductSpecsDefinitions.specsByType[_productType!] ?? []);
        if (ProductSpecsDefinitions.homeApplianceTypes.contains(_productType)) {
          allFields.addAll(_getHomeSpecFields());
        }
      }

      for (var field in allFields) {
        String? value;

        if (field.inputType == 'text' ||
            field.inputType == 'number' ||
            field.inputType == 'dimensions') {
          value = _specFieldControllers[field.key]?.text.trim();
        } else if (field.inputType == 'number_with_unit') {
          final v = _specFieldControllers[field.key]?.text.trim() ?? '';
          final u = _specFieldUnitValues[field.key] ?? field.defaultUnit;
          if (v.isNotEmpty) {
            value = (u == null || u.isEmpty) ? v : '$v $u';
          }
        } else if (field.inputType == 'dropdown') {
          value = _specFieldSelectValues[field.key];
        }

        if (value != null && value.isNotEmpty) {
          specs.add({'key': field.key, 'value': value});
        }
      }

      for (var spec in _specifications) {
        final k = spec['key']?.text.trim() ?? '';
        final v = spec['value']?.text.trim() ?? '';
        if (k.isEmpty || v.isEmpty) continue;
        if (specs.any((s) => s['key'] == k)) continue;
        specs.add({'key': k, 'value': v});
      }

      if (specs.isNotEmpty) {
        request.fields['specifications'] = jsonEncode(specs);
      }

      if (_newMainImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'main_image', _newMainImage!.path));
      }

      for (var id in _deletedImageIds) {
        request.fields['delete_images[]'] = id.toString();
      }

      for (var image in _newAdditionalImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', image.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

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
      // debugPrint('❌ Error updating product: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('حدث خطأ في تحديث المنتج', dangerRed);
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

  // ==================== Build ====================

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
          body: _isLoadingProduct ? _buildLoading() : _buildForm(),
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
        'تعديل المنتج',
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
                        _discountPriceController, 'سعر الخصم (اختياري)', '0.00',
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
                                  'سعر الجملة (اختياري)', '0.00',
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildTextField(_wholesaleMinQtyController,
                                  'الحد الأدنى للكمية (اختياري)', 'مثال: 10',
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr))
                        ])
                      ])),
              const SizedBox(height: 12),
              _buildTextField(_stockController, 'الكمية المتاحة *', '0',
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr),
              const SizedBox(height: 24),
              _buildSectionTitle('أسعار الليرة السورية (اختياري)',
                  Icons.currency_exchange_rounded,
                  color: sypAmber),
              const SizedBox(height: 12),
              _buildSypPricesSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('معلومات إضافية', Icons.more_horiz_rounded),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(
                        _brandController,
                        'العلامة التجارية (اختياري)',
                        'مثال: Samsung / سامسونج')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(
                        _modelController, 'الموديل (اختياري)', 'مثال: X1000',
                        textDirection: TextDirection.ltr))
              ]),
              const SizedBox(height: 12),
              _buildTextField(_warrantyController, 'الضمان (اختياري)',
                  'مثال: سنة واحدة / 1 Year'),
              const SizedBox(height: 24),
              _buildSectionTitle('الصور', Icons.image_rounded),
              const SizedBox(height: 12),
              _buildMainImageSection(),
              const SizedBox(height: 12),
              _buildAdditionalImagesSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('المواصفات (اختياري)', Icons.list_alt_rounded),
              const SizedBox(height: 12),
              _buildSpecificationsSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('الحالة', Icons.toggle_on_rounded),
              const SizedBox(height: 12),
              _buildActiveToggle(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'الشحن (اختياري)', Icons.local_shipping_rounded),
              const SizedBox(height: 12),
              _buildShippingSection(),
              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 30),
            ])));
  }

  // ═══════════════════════════════════════════════════════
  // ✅ قسم أسعار الليرة السورية
  // ═══════════════════════════════════════════════════════
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

  // ==================== Specifications UI ====================

  Widget _buildSpecificationsSection() {
    final fields = <ProductSpecField>[];
    if (_productType != null) {
      fields.addAll(ProductSpecsDefinitions.specsByType[_productType!] ?? []);
      if (ProductSpecsDefinitions.homeApplianceTypes.contains(_productType)) {
        fields.addAll(_getHomeSpecFields());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fields.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                primaryBlue.withOpacity(0.04),
                secondaryBlue.withOpacity(0.02),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              children: fields
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSpecField(f),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('مواصفات إضافية (اختياري)',
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
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
                          hintText: 'المفتاح',
                          hintStyle: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey.shade400),
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
                          hintText: 'القيمة',
                          hintStyle: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey.shade400),
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
            label: Text('إضافة مواصفة إضافية',
                style: GoogleFonts.cairo(fontSize: 13, color: primaryBlue)))
      ],
    );
  }

  Widget _buildSpecField(ProductSpecField field) {
    switch (field.inputType) {
      case 'text':
        return _buildSpecTextField(field.key, field.label,
            isRequired: field.isRequired);
      case 'number':
        return _buildSpecTextField(field.key, field.label,
            isRequired: field.isRequired, keyboardType: TextInputType.number);
      case 'number_with_unit':
        return _buildSpecNumberWithUnit(field);
      case 'dropdown':
        return _buildSpecDropdown(field);
      case 'dimensions':
        return _buildSpecTextField(field.key, field.label);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSpecTextField(String key, String label,
      {bool isRequired = false,
      TextInputType keyboardType = TextInputType.text}) {
    final controller = _specFieldControllers[key] ??= TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isRequired ? '$label *' : label,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: keyboardType == TextInputType.number
              ? TextDirection.ltr
              : _getTextDirection(controller.text),
          style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: keyboardType == TextInputType.number ? '0' : null,
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
        ),
      ],
    );
  }

  Widget _buildSpecNumberWithUnit(ProductSpecField field) {
    final controller =
        _specFieldControllers[field.key] ??= TextEditingController();
    final units = field.unitOptions ?? [];
    final selectedUnit = _specFieldUnitValues[field.key] ??
        field.defaultUnit ??
        (units.isNotEmpty ? units.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.isRequired ? '${field.label} *' : field.label,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0',
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
            ),
          ),
          if (units.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedUnit,
                    isExpanded: true,
                    isDense: true,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: darkColor, height: 1.5),
                    items: units
                        .map((u) => DropdownMenuItem<String>(
                              value: u,
                              child: Text(u,
                                  style: GoogleFonts.cairo(
                                      fontSize: 13, height: 1.5)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _specFieldUnitValues[field.key] = v),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ],
    );
  }

  Widget _buildSpecDropdown(ProductSpecField field) {
    final selected = _specFieldSelectValues[field.key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.isRequired ? '${field.label} *' : field.label,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              hint: Text('اختر',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade400, height: 1.5)),
              items: (field.options ?? [])
                  .map((o) => DropdownMenuItem<String>(
                        value: o,
                        child: Text(o,
                            style:
                                GoogleFonts.cairo(fontSize: 13, height: 1.5)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _specFieldSelectValues[field.key] = v),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Unit Dropdown ====================

  Widget _buildUnitDropdown() {
    final selectedUnitLabel = _units.firstWhere(
          (u) => u['key'] == _selectedUnit,
          orElse: () => {'key': 'قطعة', 'label': 'قطعة'},
        )['label'] ??
        'قطعة';

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
                  borderSide: BorderSide(color: primaryBlue.withOpacity(0.5)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('إضافة الوحدة',
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
                    _showCustomUnitInput = false;
                    _customUnitController.clear();
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

  // ==================== Shipping ====================

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('اختر المدن المتاحة للشحن',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: darkColor)),
              Text('${selectedCities.length} مدينة',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600)),
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
            Text('أسعار الشحن لكل مدينة',
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
                          hintText: 'سعر الشحن',
                          prefixText: '\$ ',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: costController.text.isNotEmpty
                                    ? successGreen
                                    : Colors.grey.shade300),
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
      ]),
    );
  }

  // ==================== Common Widgets ====================

  Widget _buildSectionTitle(String title, IconData icon,
          {Color color = primaryBlue}) =>
      Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.06)]),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color)),
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
      Text('الوصف (اختياري)',
          style: GoogleFonts.cairo(
              fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextFormField(
          controller: _descriptionArController,
          maxLines: 5,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textDirection: _getTextDirection(_descriptionArController.text),
          textAlign: TextAlign.start,
          style: GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.8),
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'اكتب وصفاً تفصيلياً للمنتج...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: Colors.grey.shade400, height: 1.5),
            hintTextDirection: TextDirection.rtl,
            filled: true,
            fillColor: cardWhite,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
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
            border: Border.all(color: primaryBlue.withOpacity(0.3)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الصورة الرئيسية *',
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        if (_newMainImage != null)
          _buildNewImagePreview(
            _newMainImage!,
            onRemove: () => setState(() => _newMainImage = null),
          )
        else if (_currentMainImageUrl != null && !_removeMainImage)
          _buildCurrentImagePreview(
            _currentMainImageUrl!,
            onReplace: _pickNewMainImage,
            onRemove: _markMainImageForRemoval,
          )
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentMainImageUrl != null
                          ? Icons.undo_rounded
                          : Icons.add_a_photo_rounded,
                      size: 40,
                      color: primaryBlue.withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentMainImageUrl != null
                          ? 'تراجع عن الحذف'
                          : 'انقر لاختيار الصورة الرئيسية',
                      style: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
        Text('صور إضافية (اختياري)',
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
        ]),
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

// ✅ كلاس المنحنى السفلي للـ AppBar
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
