// lib/screens/company/products/add_lighting_unit_screen.dart

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

class FieldDef {
  final String key;
  final String label;
  final String type;
  final bool required;
  final List<String>? options;
  final String? hint;
  final String? dependsOnKey;
  final String? dependsOnValue;

  const FieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.hint,
    this.dependsOnKey,
    this.dependsOnValue,
  });
}

class AddLightingUnitScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const AddLightingUnitScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<AddLightingUnitScreen> createState() => _AddLightingUnitScreenState();
}

class _AddLightingUnitScreenState extends State<AddLightingUnitScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color lightingAmber = Color(0xFFD97706);
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
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _descriptionArController = TextEditingController();

  String _warrantyType = 'year';
  int _warrantyValue = 1;
  final _customWarrantyController = TextEditingController();

  final _priceSypController = TextEditingController();
  final _discountPriceSypController = TextEditingController();
  final _wholesalePriceSypController = TextEditingController();

  double _exchangeRate = 0;
  bool _isLoadingRate = false;

  List<dynamic> _subCategories = [];
  List<dynamic> _filteredSubCategories = [];
  final _subCategorySearchController = TextEditingController();
  bool _showSubCategoryDropdown = false;
  String? _selectedSubCategoryId;
  String? _selectedSubCategoryName;

  String? _selectedTypeId;
  String? _selectedTypeName;
  bool _showTypeDropdown = false;

  final Map<String, dynamic> _fieldValues = {};
  final Map<String, TextEditingController> _fieldControllers = {};

  File? _mainImage;
  List<File> _additionalImages = [];
  File? _designImage;

  List<Map<String, TextEditingController>> _specifications = [];

  bool _isActive = true;
  bool _isDraft = false;

  bool _hasShipping = false;
  final Map<String, TextEditingController> _shippingCostControllers = {};
  final Map<String, bool> _selectedShippingCities = {};

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

  bool _isLoadingData = true;

  List<Map<String, String>> _getTypesForSubCategory(String? name) {
    if (name == null) return [];
    if (name.contains('لمبات')) {
      return [
        {'id': 'bulb', 'name': 'لمبة'},
      ];
    }
    if (name.contains('شرائط') || name.contains('زخرفية')) {
      return [
        {'id': 'strip_rope', 'name': 'شريط أو حبل إنارة'},
        {'id': 'decorative', 'name': 'ضوء زخرفي'},
      ];
    }
    if (name.contains('جدارية') || name.contains('أرضية')) {
      return [
        {'id': 'wall', 'name': 'إنارة جدارية'},
        {'id': 'garden_floor', 'name': 'إنارة حدائق وأرضية'},
        {'id': 'floodlight', 'name': 'كشاف'},
        {'id': 'track', 'name': 'إنارة مسار'},
        {'id': 'recessed_spot', 'name': 'سبوت مخفي'},
        {'id': 'surface_spot', 'name': 'سبوت سطحي'},
        {'id': 'panel', 'name': 'بانل أو إنارة سقفية'},
        {'id': 'chandelier', 'name': 'ثريا أو تعليقة'},
        {'id': 'solar_street', 'name': 'إنارة شمسية أو شوارع'},
        {'id': 'emergency', 'name': 'إنارة طوارئ'},
      ];
    }
    return [];
  }

  final Map<String, List<FieldDef>> _fieldsByType = {
    'bulb': [
      const FieldDef(
          key: 'base_type',
          label: 'القاعدة',
          type: 'dropdown',
          required: true,
          options: ['E27', 'E14', 'GU10', 'G9', 'MR16', 'أخرى']),
      const FieldDef(
          key: 'shape',
          label: 'الشكل',
          type: 'dropdown',
          options: ['كروي', 'شمعة', 'سبوت', 'أنبوبي', 'آخر']),
    ],
    'strip_rope': [
      const FieldDef(
          key: 'sale_unit',
          label: 'وحدة البيع',
          type: 'dropdown',
          required: true,
          options: ['متر', 'لفة']),
      const FieldDef(
          key: 'watt_per_meter',
          label: 'الاستطاعة لكل متر (واط/م)',
          type: 'number',
          required: true,
          hint: 'مثال: 10'),
      const FieldDef(
          key: 'lumen_per_meter',
          label: 'اللومن لكل متر (لومن/م)',
          type: 'number',
          required: true,
          hint: 'مثال: 800'),
      const FieldDef(
          key: 'roll_length',
          label: 'طول اللفة (م)',
          type: 'number',
          hint: 'مثال: 5',
          dependsOnKey: 'sale_unit',
          dependsOnValue: 'لفة'),
      const FieldDef(
          key: 'strip_width',
          label: 'عرض الشريط (مم)',
          type: 'number',
          hint: 'مثال: 10'),
    ],
    'decorative': [
      const FieldDef(
          key: 'decoration_type',
          label: 'نوع الزخرفة',
          type: 'text',
          hint: 'مثال: نجمة، قلب، خط'),
    ],
    'wall': [
      const FieldDef(
          key: 'light_direction',
          label: 'اتجاه الضوء',
          type: 'dropdown',
          required: true,
          options: ['أعلى', 'أسفل', 'أعلى وأسفل', 'محيطي']),
      const FieldDef(
          key: 'movement',
          label: 'الحركة',
          type: 'dropdown',
          required: true,
          options: ['ثابت', 'قابل للتوجيه']),
    ],
    'garden_floor': [
      const FieldDef(
          key: 'installation_type',
          label: 'نوع التركيب',
          type: 'dropdown',
          required: true,
          options: ['وتد داخل الأرض', 'سطحي', 'مخفي داخل الأرض']),
      const FieldDef(
          key: 'light_direction',
          label: 'اتجاه الضوء',
          type: 'dropdown',
          required: true,
          options: ['أعلى', 'أسفل', 'الاتجاهان', 'محيطي']),
      const FieldDef(
          key: 'sensor',
          label: 'الحساس',
          type: 'dropdown',
          required: true,
          options: ['دون حساس', 'حركة', 'ضوء', 'حركة وضوء']),
    ],
    'floodlight': [
      const FieldDef(
          key: 'installation_place',
          label: 'مكان التثبيت',
          type: 'multiSelect',
          required: true,
          options: ['جدار', 'سقف', 'أرض']),
      const FieldDef(
          key: 'sensor',
          label: 'الحساس',
          type: 'dropdown',
          required: true,
          options: ['دون حساس', 'حركة', 'ضوء', 'حركة وضوء']),
      const FieldDef(
          key: 'beam_angle',
          label: 'زاوية الانتشار',
          type: 'dropdown',
          options: ['24', '36', '60', '90', '120', 'أخرى']),
    ],
    'track': [
      const FieldDef(
          key: 'track_type',
          label: 'نوع المسار',
          type: 'dropdown',
          required: true,
          options: ['عادي 220V', 'مغناطيسي 48V', 'آخر']),
      const FieldDef(
          key: 'movement',
          label: 'الحركة',
          type: 'dropdown',
          required: true,
          options: ['ثابت', 'متحرك']),
      const FieldDef(
          key: 'beam_angle',
          label: 'زاوية الانتشار',
          type: 'dropdown',
          options: ['24', '36', '60', '90', '120', 'أخرى']),
    ],
    'recessed_spot': [
      const FieldDef(
          key: 'shape',
          label: 'الشكل',
          type: 'dropdown',
          required: true,
          options: ['دائري', 'مربع']),
      const FieldDef(
          key: 'recess_opening',
          label: 'فتحة التركيب',
          type: 'text',
          required: true,
          hint: 'قطر أو طول×عرض'),
      const FieldDef(
          key: 'external_size',
          label: 'المقاس الخارجي',
          type: 'text',
          hint: 'اختياري'),
      const FieldDef(
          key: 'movement',
          label: 'الحركة',
          type: 'dropdown',
          required: true,
          options: ['ثابت', 'متحرك']),
      const FieldDef(
          key: 'beam_angle',
          label: 'زاوية الانتشار',
          type: 'dropdown',
          options: ['24', '36', '60', '90', '120', 'أخرى']),
    ],
    'surface_spot': [
      const FieldDef(
          key: 'shape',
          label: 'الشكل',
          type: 'dropdown',
          required: true,
          options: ['دائري', 'مربع']),
      const FieldDef(
          key: 'movement',
          label: 'الحركة',
          type: 'dropdown',
          required: true,
          options: ['ثابت', 'متحرك']),
      const FieldDef(
          key: 'beam_angle',
          label: 'زاوية الانتشار',
          type: 'dropdown',
          options: ['24', '36', '60', '90', '120', 'أخرى']),
    ],
    'panel': [
      const FieldDef(
          key: 'installation_method',
          label: 'طريقة التركيب',
          type: 'multiSelect',
          required: true,
          options: ['مخفي', 'سطحي', 'معلق']),
      const FieldDef(
          key: 'shape',
          label: 'الشكل',
          type: 'dropdown',
          required: true,
          options: ['دائري', 'مربع', 'مستطيل']),
      const FieldDef(
          key: 'size',
          label: 'المقاس',
          type: 'text',
          required: true,
          hint: 'قطر أو طول×عرض'),
      const FieldDef(
          key: 'recess_opening',
          label: 'فتحة التركيب',
          type: 'text',
          hint: 'اختياري',
          dependsOnKey: 'installation_method',
          dependsOnValue: 'مخفي'),
    ],
    'chandelier': [
      const FieldDef(
          key: 'bulbs_count',
          label: 'عدد اللمبات',
          type: 'number',
          hint: 'مثال: 6'),
      const FieldDef(
          key: 'base_type',
          label: 'القاعدة',
          type: 'dropdown',
          required: true,
          options: ['E27', 'E14', 'GU10', 'G9', 'أخرى']),
      const FieldDef(
          key: 'bulbs_included',
          label: 'اللمبات مرفقة',
          type: 'dropdown',
          required: true,
          options: ['نعم', 'لا']),
      const FieldDef(
          key: 'suspension',
          label: 'التعليق',
          type: 'dropdown',
          required: true,
          options: ['ثابت', 'قابل لتعديل الارتفاع']),
    ],
    'solar_street': [
      const FieldDef(
          key: 'power_source',
          label: 'مصدر الطاقة',
          type: 'dropdown',
          required: true,
          options: ['كهرباء', 'شمسي', 'الاثنين']),
      const FieldDef(
          key: 'battery_duration',
          label: 'مدة التشغيل على البطارية',
          type: 'dropdown',
          options: ['حتى 6 ساعات', '6-10 ساعات', 'أكثر من 10 ساعات'],
          dependsOnKey: 'power_source',
          dependsOnValue: 'شمسي'),
      const FieldDef(
          key: 'sensor',
          label: 'الحساس',
          type: 'dropdown',
          required: true,
          options: ['دون حساس', 'حركة', 'ضوء', 'حركة وضوء']),
    ],
    'emergency': [
      const FieldDef(
          key: 'backup_duration',
          label: 'مدة التشغيل الاحتياطي',
          type: 'dropdown',
          required: true,
          options: ['ساعة', 'ساعتان', '3 ساعات', 'أكثر']),
      const FieldDef(
          key: 'operation_mode',
          label: 'طريقة العمل',
          type: 'dropdown',
          required: true,
          options: ['دائماً', 'عند انقطاع الكهرباء فقط']),
    ],
  };

  final List<FieldDef> _sharedFields = const [
    FieldDef(
        key: 'source_type',
        label: 'مصدر الإضاءة',
        type: 'dropdown',
        required: true,
        options: ['ليد مدمج', 'لمبات قابلة للاستبدال', 'هيكل دون لمبات']),
    FieldDef(
        key: 'power',
        label: 'الاستطاعة (واط)',
        type: 'number',
        required: true,
        hint: 'مثال: 50'),
    FieldDef(
        key: 'lumen',
        label: 'شدة الإضاءة (لومن)',
        type: 'number',
        required: true,
        hint: 'مثال: 5000'),
    FieldDef(
        key: 'voltage',
        label: 'جهد التشغيل',
        type: 'multiSelect',
        required: true,
        options: ['12', '24', '48', '110', '220-240']),
    FieldDef(
        key: 'color_temperature',
        label: 'درجة حرارة اللون (كلفن)',
        type: 'multiSelect',
        required: true,
        options: ['2700', '3000', '4000', '5000']),
    FieldDef(
        key: 'control_method',
        label: 'طريقة التحكم',
        type: 'multiSelect',
        required: true,
        options: [
          'مفتاح عادي',
          'طقات مفتاح',
          'جهاز تحكم',
          'منظم شدة الإضاءة',
          'تطبيق ذكي'
        ]),
    FieldDef(
        key: 'transformer',
        label: 'محوّل التشغيل',
        type: 'dropdown',
        required: true,
        options: ['مدمج', 'خارجي مرفق', 'يحتاج محول غير مرفق', 'لا ينطبق']),
    FieldDef(
        key: 'usage',
        label: 'الاستخدام',
        type: 'multiSelect',
        required: true,
        options: ['داخلي', 'خارجي', 'حمام أو مكان رطب']),
    FieldDef(
        key: 'ip_rating',
        label: 'درجة الحماية IP',
        type: 'dropdown',
        options: ['IP54', 'IP65', 'IP66', 'IP67']),
    FieldDef(
        key: 'body_color',
        label: 'لون الجسم',
        type: 'dropdown',
        required: true,
        options: [
          'أبيض',
          'أسود',
          'ذهبي',
          'فضي',
          'رمادي',
          'خشبي',
          'شفاف',
          'آخر'
        ]),
    FieldDef(
        key: 'body_material',
        label: 'مادة الجسم',
        type: 'dropdown',
        options: [
          'ألمنيوم',
          'حديد',
          'بلاستيك',
          'زجاج',
          'خشب',
          'كريستال',
          'مختلط'
        ]),
    FieldDef(
        key: 'dim_length',
        label: 'الطول (مم)',
        type: 'number',
        hint: 'اختياري'),
    FieldDef(
        key: 'dim_width', label: 'العرض (مم)', type: 'number', hint: 'اختياري'),
    FieldDef(
        key: 'dim_height',
        label: 'الارتفاع (مم)',
        type: 'number',
        hint: 'اختياري'),
  ];

  final Set<String> _sharedFieldKeys = {
    'source_type',
    'power',
    'lumen',
    'voltage',
    'color_temperature',
    'control_method',
    'transformer',
    'usage',
    'ip_rating',
    'body_color',
    'body_material',
    'dim_length',
    'dim_width',
    'dim_height',
  };

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

  @override
  void dispose() {
    _nameArController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMinQtyController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _descriptionArController.dispose();
    _customWarrantyController.dispose();
    _subCategorySearchController.dispose();
    _priceSypController.dispose();
    _discountPriceSypController.dispose();
    _wholesalePriceSypController.dispose();
    _shippingCostControllers.forEach((_, c) => c.dispose());
    _fieldControllers.forEach((_, c) => c.dispose());
    for (var spec in _specifications) {
      spec['key']?.dispose();
      spec['value']?.dispose();
    }
    super.dispose();
  }

  void _initShippingCostControllers() {
    for (var city in _syrianCities) {
      _shippingCostControllers[city] = TextEditingController();
      _selectedShippingCities[city] = false;
    }
  }

  Future<void> _fetchCreateData() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await _apiService.get(
          '/v1/company/products/getLightingUnitSubcategories',
          requiresAuth: true);
      if (response['data'] != null && mounted) {
        setState(() {
          _subCategories = response['data']['sub_categories'] ?? [];
          _filteredSubCategories = List.from(_subCategories);
          _isLoadingData = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingData = false);
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
      } else {
        if (mounted) setState(() => _isLoadingRate = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRate = false);
    }
  }

  TextDirection _getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final firstChar = trimmed.characters.first;
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
    return TextDirection.ltr;
  }

  String _getWarrantyText() {
    if (_warrantyType == 'custom') return _customWarrantyController.text.trim();
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

  String _formatRate(double rate) {
    if (rate == rate.roundToDouble()) return rate.toStringAsFixed(0);
    return rate.toStringAsFixed(2);
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
                  textDirection: _getTextDirection(message))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  TextEditingController _controllerFor(String key) {
    if (!_fieldControllers.containsKey(key)) {
      _fieldControllers[key] = TextEditingController();
      _fieldControllers[key]!.addListener(() {
        _fieldValues[key] = _fieldControllers[key]!.text;
        setState(() {});
      });
    }
    return _fieldControllers[key]!;
  }

  void _resetDynamicFields() {
    final keysToRemove =
        _fieldValues.keys.where((k) => !_sharedFieldKeys.contains(k)).toList();
    for (var k in keysToRemove) {
      _fieldValues.remove(k);
      _fieldControllers[k]?.dispose();
      _fieldControllers.remove(k);
    }
  }

  bool _shouldShowField(FieldDef field) {
    if (field.dependsOnKey == null) return true;
    final depValue = _fieldValues[field.dependsOnKey];
    if (depValue is List) {
      return depValue.contains(field.dependsOnValue);
    }
    return depValue == field.dependsOnValue;
  }

  bool get _isEligibleForCalculation {
    final source = _fieldValues['source_type']?.toString() ?? '';
    if (source == 'هيكل دون لمبات') return true;
    final lumen = _fieldValues['lumen']?.toString().trim() ?? '';
    return lumen.isNotEmpty;
  }

  bool get _isEligibleForImageGeneration {
    return _designImage != null;
  }

  Future<void> _saveProduct({bool asDraft = false}) async {
    if (!asDraft && !_formKey.currentState!.validate()) return;

    if (_selectedSubCategoryId == null) {
      _showSnackBar('الرجاء اختيار التصنيف الفرعي', dangerRed);
      return;
    }
    if (_selectedTypeId == null) {
      _showSnackBar('الرجاء اختيار النوع', dangerRed);
      return;
    }
    if (!asDraft) {
      if (_mainImage == null) {
        _showSnackBar('الرجاء اختيار الصورة الرئيسية', dangerRed);
        return;
      }
      if (_nameArController.text.trim().isEmpty) {
        _showSnackBar('الرجاء إدخال اسم المنتج', dangerRed);
        return;
      }
      if (_brandController.text.trim().isEmpty) {
        _showSnackBar('الرجاء إدخال الماركة', dangerRed);
        return;
      }
      if (_priceController.text.trim().isEmpty) {
        _showSnackBar('الرجاء إدخال السعر', dangerRed);
        return;
      }

      final allFields = [
        ..._sharedFields,
        ...(_fieldsByType[_selectedTypeId] ?? []),
      ];
      for (var field in allFields) {
        if (!field.required) continue;
        if (!_shouldShowField(field)) continue;
        final val = _fieldValues[field.key];
        if (val == null ||
            (val is String && val.trim().isEmpty) ||
            (val is List && val.isEmpty)) {
          _showSnackBar('الحقل "${field.label}" مطلوب', dangerRed);
          return;
        }
      }
    }

    final warrantyValue = _getWarrantyText();
    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('${AppConstants.baseUrl}/v1/company/products'));
      request.headers['Authorization'] = 'Bearer ${widget.authService.token}';
      request.headers['Accept'] = 'application/json';

      final fields = <String, String>{
        'name_ar': _nameArController.text.trim(),
        'sub_category_id': _selectedSubCategoryId ?? '',
        'brand': _brandController.text.trim(),
        'unit': 'قطعة',
        'stock': _stockController.text.trim().isNotEmpty
            ? _stockController.text.trim()
            : '0',
        'is_active': (asDraft ? false : _isActive) ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
        'product_type': 'lighting_unit',
      };

      if (_priceController.text.trim().isNotEmpty) {
        fields['price'] = _priceController.text.trim();
      }
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
          return {'city': city, 'cost': costText.isEmpty ? null : costText};
        }).toList();
        if (shippingCities.isNotEmpty) {
          fields['shipping_cities'] = jsonEncode(shippingCities);
        }
      }

      final specs = <Map<String, String>>[];

      specs.add({'key': 'النوع', 'value': _selectedTypeName ?? ''});

      for (var field in _sharedFields) {
        final val = _fieldValues[field.key];
        if (val == null) continue;
        if (val is List) {
          if (val.isNotEmpty) {
            specs.add({'key': field.label, 'value': val.join('، ')});
          }
        } else {
          final s = val.toString().trim();
          if (s.isNotEmpty) specs.add({'key': field.label, 'value': s});
        }
      }

      final typeFields = _fieldsByType[_selectedTypeId] ?? [];
      for (var field in typeFields) {
        if (!_shouldShowField(field)) continue;
        final val = _fieldValues[field.key];
        if (val == null) continue;
        if (val is List) {
          if (val.isNotEmpty) {
            specs.add({'key': field.label, 'value': val.join('، ')});
          }
        } else {
          final s = val.toString().trim();
          if (s.isNotEmpty) specs.add({'key': field.label, 'value': s});
        }
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

      if (_mainImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('main_image', _mainImage!.path));
      }
      for (var image in _additionalImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images[]', image.path));
      }

      if (_designImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'design_image', _designImage!.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

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
          _showSnackBar(
              asDraft
                  ? 'تم حفظ المسودة بنجاح 🎉'
                  : 'تم إضافة وحدة الإنارة بنجاح 🎉',
              successGreen);
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
      // debugPrint('❌ Error saving lighting unit: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('حدث خطأ في حفظ المنتج', dangerRed);
      }
    }
  }

  Future<void> _pickMainImage() async {
    final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (image != null) setState(() => _mainImage = File(image.path));
  }

  Future<void> _pickAdditionalImages() async {
    final List<XFile> images =
        await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (images.isNotEmpty) {
      setState(
          () => _additionalImages.addAll(images.map((img) => File(img.path))));
    }
  }

  Future<void> _pickDesignImage() async {
    final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (image != null) setState(() => _designImage = File(image.path));
  }

  void _addSpecification() => setState(() => _specifications
      .add({'key': TextEditingController(), 'value': TextEditingController()}));

  void _removeSpecification(int index) {
    _specifications[index]['key']?.dispose();
    _specifications[index]['value']?.dispose();
    setState(() => _specifications.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showSubCategoryDropdown) {
            setState(() => _showSubCategoryDropdown = false);
          }
          if (_showTypeDropdown) {
            setState(() => _showTypeDropdown = false);
          }
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
        'إضافة وحدة إنارة',
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
      const Center(child: CircularProgressIndicator(color: lightingAmber));

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('التصنيف والنوع', Icons.category_rounded,
                color: lightingAmber),
            const SizedBox(height: 12),
            _buildSubCategoryDropdown(),
            const SizedBox(height: 12),
            if (_selectedSubCategoryId != null) _buildTypeDropdown(),
            if (_selectedTypeId != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('معلومات أساسية', Icons.info_rounded),
              const SizedBox(height: 12),
              _buildTextField(
                  _nameArController, 'اسم المنتج *', 'مثال: كشاف LED 50 واط',
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              _buildTextField(
                  _brandController, 'الماركة *', 'مثال: Philips, Osram',
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              _buildTextField(
                  _modelController, 'الموديل (اختياري)', 'مثال: FL-50W',
                  textDirection: TextDirection.ltr),
              const SizedBox(height: 12),
              _buildTextField(_skuController, 'رمز المنتج (SKU) *', 'LGT-50W',
                  textDirection: TextDirection.ltr),
              const SizedBox(height: 12),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildSectionTitle('بيانات الإضاءة', Icons.lightbulb_rounded,
                  color: lightingAmber),
              const SizedBox(height: 12),
              ..._buildSharedFieldsGroup([
                'source_type',
                'power',
                'lumen',
                'voltage',
                'color_temperature',
                'control_method',
                'transformer',
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('الاستخدام والشكل', Icons.home_work_rounded),
              const SizedBox(height: 12),
              ..._buildSharedFieldsGroup([
                'usage',
                'ip_rating',
                'body_color',
                'body_material',
                'dim_length',
                'dim_width',
                'dim_height',
              ]),
              ..._buildTypeSpecificSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('الصور', Icons.image_rounded),
              const SizedBox(height: 12),
              _buildMainImagePicker(),
              const SizedBox(height: 12),
              _buildAdditionalImagesPicker(),
              const SizedBox(height: 12),
              _buildDesignImagePicker(),
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
              Row(children: [
                Expanded(
                    child: _buildTextField(_wholesalePriceController,
                        'سعر الجملة (اختياري)', '0.00',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(
                        _wholesaleMinQtyController, 'الحد الأدنى للكمية', '10',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
              ]),
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
              _buildWarrantyField(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'مواصفات إضافية (اختياري)', Icons.list_alt_rounded),
              const SizedBox(height: 12),
              _buildSpecificationsSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('الحالة والأهلية', Icons.toggle_on_rounded),
              const SizedBox(height: 12),
              _buildEligibilityCard(),
              const SizedBox(height: 12),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  'الشحن (اختياري)', Icons.local_shipping_rounded),
              const SizedBox(height: 12),
              _buildShippingSection(),
              const SizedBox(height: 30),
              _buildSaveButtons(),
              const SizedBox(height: 30),
            ] else ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'اختر التصنيف الفرعي والنوع للبدء',
                      style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSharedFieldsGroup(List<String> keys) {
    final widgets = <Widget>[];
    for (var key in keys) {
      final field = _sharedFields.firstWhere((f) => f.key == key);

      if (key == 'ip_rating') {
        final usage = _fieldValues['usage'];
        final hasOutdoorOrWet = usage is List &&
            (usage.contains('خارجي') || usage.contains('حمام أو مكان رطب'));
        if (!hasOutdoorOrWet) continue;
      }
      widgets.add(_buildFieldWidget(field));
      widgets.add(const SizedBox(height: 12));
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  List<Widget> _buildTypeSpecificSection() {
    final typeFields = _fieldsByType[_selectedTypeId] ?? [];
    if (typeFields.isEmpty) return [];

    final visibleFields = typeFields.where((f) => _shouldShowField(f)).toList();
    if (visibleFields.isEmpty) return [];

    final widgets = <Widget>[
      const SizedBox(height: 24),
      _buildSectionTitle('خصائص ${_selectedTypeName ?? ""}', Icons.tune_rounded,
          color: lightingAmber),
      const SizedBox(height: 12),
    ];
    for (var field in visibleFields) {
      widgets.add(_buildFieldWidget(field));
      widgets.add(const SizedBox(height: 12));
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  Widget _buildFieldWidget(FieldDef field) {
    switch (field.type) {
      case 'multiSelect':
        return _buildMultiSelectField(field);
      case 'dropdown':
        return _buildDropdownSelectField(field);
      case 'number':
      case 'text':
      default:
        return _buildDynamicTextField(field);
    }
  }

  Widget _buildDynamicTextField(FieldDef field) {
    final controller = _controllerFor(field.key);
    return TextFormField(
      controller: controller,
      keyboardType: field.type == 'number'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textDirection: field.type == 'number'
          ? TextDirection.ltr
          : _getTextDirection(controller.text),
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        labelStyle: GoogleFonts.cairo(fontSize: 12, color: mediumGray),
        hintText: field.hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
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
            borderSide: const BorderSide(color: lightingAmber, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      ),
    );
  }

  Widget _buildDropdownSelectField(FieldDef field) {
    final currentValue = _fieldValues[field.key]?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.required ? '${field.label} *' : field.label,
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
              value: (currentValue != null &&
                      (field.options ?? []).contains(currentValue))
                  ? currentValue
                  : null,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: mediumGray),
              style: GoogleFonts.cairo(
                  fontSize: 14, color: darkColor, fontWeight: FontWeight.w600),
              hint: Text('اختر',
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: Colors.grey.shade400)),
              items: (field.options ?? [])
                  .map((opt) => DropdownMenuItem<String>(
                        value: opt,
                        child:
                            Text(opt, style: GoogleFonts.cairo(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _fieldValues[field.key] = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectField(FieldDef field) {
    final selected = (_fieldValues[field.key] as List<String>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.required ? '${field.label} *' : field.label,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (field.options ?? []).map((opt) {
            final isSelected = selected.contains(opt);
            return GestureDetector(
              onTap: () {
                setState(() {
                  final list = List<String>.from(selected);
                  if (isSelected) {
                    list.remove(opt);
                  } else {
                    list.add(opt);
                  }
                  _fieldValues[field.key] = list;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? lightingAmber : cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected ? lightingAmber : Colors.grey.shade300),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : mediumGray,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التصنيف الفرعي *',
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            _showSubCategoryDropdown = !_showSubCategoryDropdown;
            _showTypeDropdown = false;
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
                  _selectedSubCategoryName ?? 'اختر التصنيف الفرعي *',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: _selectedSubCategoryName != null
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _subCategorySearchController,
                    autofocus: true,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '🔍 بحث...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: primaryBlue),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() {
                      _filteredSubCategories = value.isEmpty
                          ? List.from(_subCategories)
                          : _subCategories
                              .where((s) =>
                                  (s['full_name'] ?? s['name_ar'] ?? '')
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
                      final displayName =
                          sub['full_name'] ?? sub['name_ar'] ?? '';
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
                          _selectedSubCategoryName = displayName;
                          _selectedTypeId = null;
                          _selectedTypeName = null;
                          _resetDynamicFields();
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
                            GoogleFonts.cairo(fontSize: 13, color: mediumGray)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    final types = _getTypesForSubCategory(_selectedSubCategoryName);
    if (types.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('النوع *',
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.w600, color: darkColor)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            _showTypeDropdown = !_showTypeDropdown;
            _showSubCategoryDropdown = false;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      _showTypeDropdown ? lightingAmber : Colors.grey.shade200,
                  width: _showTypeDropdown ? 2 : 1),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _selectedTypeName ?? 'اختر النوع *',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: _selectedTypeName != null
                          ? darkColor
                          : Colors.grey.shade400),
                ),
              ),
              Icon(
                  _showTypeDropdown
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: mediumGray),
            ]),
          ),
        ),
        if (_showTypeDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightingAmber.withOpacity(0.3))),
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: types.length,
              itemBuilder: (_, index) {
                final type = types[index];
                final isSelected = type['id'] == _selectedTypeId;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: lightingAmber.withOpacity(0.08),
                  title: Text(type['name'] ?? '',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? lightingAmber : darkColor)),
                  trailing: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: lightingAmber, size: 20)
                      : null,
                  onTap: () => setState(() {
                    _selectedTypeId = type['id'];
                    _selectedTypeName = type['name'];
                    _resetDynamicFields();
                    _showTypeDropdown = false;
                  }),
                );
              },
            ),
          ),
      ],
    );
  }

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
        child: TextFormField(
          controller: _descriptionArController,
          maxLines: 5,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.8),
          decoration: InputDecoration(
            hintText: 'اكتب وصفاً تفصيلياً...',
            hintStyle:
                GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
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

  Widget _buildEligibilityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEligibilityRow(
            label: 'مؤهل للحساب',
            isEligible: _isEligibleForCalculation,
            hint: _isEligibleForCalculation
                ? 'البيانات مكتملة'
                : 'أدخل اللومن لتفعيل الحساب',
          ),
          const SizedBox(height: 10),
          _buildEligibilityRow(
            label: 'مؤهل لتوليد الصورة',
            isEligible: _isEligibleForImageGeneration,
            hint: _isEligibleForImageGeneration
                ? 'صورة التصميم محددة'
                : 'اختر صورة التصميم لتفعيل التوليد',
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityRow({
    required String label,
    required bool isEligible,
    required String hint,
  }) {
    final color = isEligible ? successGreen : warningOrange;
    return Row(
      children: [
        Icon(
          isEligible ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: darkColor)),
              Text(hint,
                  style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(_isDraft ? Icons.edit_note_rounded : Icons.store_rounded,
                    color: _isDraft ? warningOrange : successGreen, size: 22),
                const SizedBox(width: 10),
                Text(_isDraft ? 'مسودة' : 'منتج نشط',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isDraft ? warningOrange : successGreen)),
              ]),
              GestureDetector(
                onTap: () => setState(() => _isDraft = !_isDraft),
                child: Container(
                    width: 50,
                    height: 28,
                    decoration: BoxDecoration(
                        color: _isDraft ? warningOrange : successGreen,
                        borderRadius: BorderRadius.circular(14)),
                    child: Stack(children: [
                      AnimatedAlign(
                          alignment: _isDraft
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle))),
                    ])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSypPricesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          sypAmber.withOpacity(0.08),
          sypAmber.withOpacity(0.03),
        ]),
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
                    borderRadius: BorderRadius.circular(10)),
                child: _isLoadingRate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: sypAmber))
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
                          color: sypAmber),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _buildTextField(
                    _priceSypController, 'السعر (ل.س)', '750000',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(
                    _discountPriceSypController, 'سعر الخصم (ل.س)', '0',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr)),
          ]),
          const SizedBox(height: 12),
          _buildTextField(
              _wholesalePriceSypController, 'سعر الجملة (ل.س) - اختياري', '0',
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr),
        ],
      ),
    );
  }

  void _autoFillSypPrices() {
    if (_exchangeRate <= 0) {
      _showSnackBar('سعر الصرف غير متوفر', dangerRed);
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
      }
      final wholesaleUsd =
          double.tryParse(_wholesalePriceController.text.trim()) ?? 0;
      if (wholesaleUsd > 0) {
        _wholesalePriceSypController.text =
            (wholesaleUsd * _exchangeRate).toStringAsFixed(0);
      }
    });
    _showSnackBar('تم التعبئة 🎉', successGreen);
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
                  onTap: () => setState(() => _mainImage = null),
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
                      size: 40, color: lightingAmber.withOpacity(0.6)),
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
                      onTap: () =>
                          setState(() => _additionalImages.removeAt(entry.key)),
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
                      size: 30, color: lightingAmber.withOpacity(0.6)))),
        ),
      ]),
    ]);
  }

  Widget _buildDesignImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.auto_awesome_rounded, size: 18, color: lightingAmber),
        const SizedBox(width: 6),
        Text('صورة التصميم (اختياري)',
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
      ]),
      const SizedBox(height: 4),
      Text(
        'تُستخدم في أداة تصميم الإضاءة وتوليد صور الغرف. '
        'المنتج بدون صورة تصميم يبقى قابلاً للبيع لكن لا يدخل توليد الصور.',
        style: GoogleFonts.cairo(fontSize: 11, color: mediumGray, height: 1.5),
      ),
      const SizedBox(height: 8),
      if (_designImage != null)
        Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_designImage!,
                  height: 180, width: double.infinity, fit: BoxFit.cover)),
          Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                  onTap: () => setState(() => _designImage = null),
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: dangerRed, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18)))),
          Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: successGreen,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('صورة التصميم',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ]))),
        ])
      else
        GestureDetector(
          onTap: _pickDesignImage,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: lightingAmber.withOpacity(0.4),
                    width: 1.5,
                    style: BorderStyle.solid)),
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 36, color: lightingAmber.withOpacity(0.7)),
                  const SizedBox(height: 8),
                  Text('انقر لاختيار صورة التصميم',
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: mediumGray)),
                ])),
          ),
        ),
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
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(fontSize: 13),
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
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(fontSize: 13),
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
          icon: const Icon(Icons.add_rounded, color: lightingAmber, size: 18),
          label: Text('إضافة مواصفة',
              style: GoogleFonts.cairo(fontSize: 13, color: lightingAmber))),
    ]);
  }

  Widget _buildWarrantyField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(children: [
            _buildWarrantyTypeOption('year', 'سنة'),
            const SizedBox(width: 8),
            _buildWarrantyTypeOption('month', 'شهر'),
            const SizedBox(width: 8),
            _buildWarrantyTypeOption('custom', 'إدخال يدوي'),
          ]),
          const SizedBox(height: 12),
          if (_warrantyType != 'custom') ...[
            Row(children: [
              Expanded(
                  child: Text('المدة',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: mediumGray))),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _warrantyValue,
                      isExpanded: true,
                      items: List.generate(12, (i) => i + 1)
                          .map((num) => DropdownMenuItem<int>(
                                value: num,
                                child: Text(num.toString(),
                                    style: GoogleFonts.cairo(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _warrantyValue = v ?? 1),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(_getWarrantyText(),
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
          ] else
            TextField(
              controller: _customWarrantyController,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'مثال: 10 سنوات، 6 أشهر',
                filled: true,
                fillColor: lightGray,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarrantyTypeOption(String value, String label) {
    final isSelected = _warrantyType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _warrantyType = value;
          if (value != 'custom') _customWarrantyController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : lightGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? primaryBlue : Colors.grey.shade300),
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
                onTap: () => setState(() {
                  _selectedShippingCities[city] = !isSelected;
                  if (!_selectedShippingCities[city]!) {
                    _shippingCostControllers[city]?.clear();
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? primaryBlue : Colors.grey.shade300),
                  ),
                  child: Text(city,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : mediumGray)),
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
                    color: lightGray, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(
                      flex: 2,
                      child: Text(city,
                          style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkColor))),
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
            }),
          ],
        ],
      ]),
    );
  }

  Widget _buildSaveButtons() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isSaving ? null : () => _saveProduct(asDraft: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: lightingAmber,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('حفظ وحدة الإنارة',
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _isSaving ? null : () => _saveProduct(asDraft: true),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: warningOrange),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.edit_note_rounded, color: warningOrange, size: 20),
            const SizedBox(width: 8),
            Text('حفظ كمسودة',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: warningOrange)),
          ]),
        ),
      ),
    ]);
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
