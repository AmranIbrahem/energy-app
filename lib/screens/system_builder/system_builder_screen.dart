// lib/screens/system_builder/system_builder_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:GeniusHouse/screens/products/product_details_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/system_builder_draft_service.dart';
import 'package:GeniusHouse/services/system_builder_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'order_history_screen.dart';

class PaymentMethodModel {
  final String paymentCompanyName;
  final String? paymentCompanyImageUrl;
  final String? recipientName;
  final String? city;
  final String? phone;
  final String? accountNumber;
  final String? accountImageUrl;

  PaymentMethodModel({
    required this.paymentCompanyName,
    this.paymentCompanyImageUrl,
    this.recipientName,
    this.city,
    this.phone,
    this.accountNumber,
    this.accountImageUrl,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return PaymentMethodModel(
      paymentCompanyName: json['payment_company_name']?.toString() ?? '',
      paymentCompanyImageUrl: clean(json['payment_company_image_url']),
      recipientName: clean(json['recipient_name']),
      city: clean(json['city']),
      phone: clean(json['phone']),
      accountNumber: clean(json['account_number']),
      accountImageUrl: clean(json['account_image_url']),
    );
  }

  bool get hasDetails =>
      recipientName != null ||
      city != null ||
      phone != null ||
      accountNumber != null ||
      accountImageUrl != null;

  String get id => paymentCompanyName;
}

/* ==========================================================================
   SystemBuilderScreen
   ========================================================================== */
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
  Map<String, dynamic>? _compatibilityResult;
  Map<String, dynamic>? _statistics;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _shippingAddressController =
      TextEditingController();
  final TextEditingController _userNotesController = TextEditingController();
  final TextEditingController _customCompanyController =
      TextEditingController();
  final TextEditingController _customWalletController = TextEditingController();

  List<Map<String, dynamic>> _selectedPanels = [];
  List<Map<String, dynamic>> _selectedInverters = [];
  List<Map<String, dynamic>> _selectedBatteries = [];
  List<Map<String, dynamic>> _selectedCables = [];
  List<Map<String, dynamic>> _selectedPanelBoards = [];

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isAnalyzing = false;
  String? _notes;
  String? _aiAnalysis;
  String _installationPrice = '0.00';
  double _mountingBasePricePerPanel = 0;

  String _selectedPaymentMethod = 'cash';
  bool _showDeliveryInfo = false;

  List<PaymentMethodModel> _bankTransferCompanies = [];
  List<PaymentMethodModel> _walletCompanies = [];
  bool _isLoadingBankTransfers = false;
  bool _isLoadingWallets = false;

  PaymentMethodModel? _selectedBankTransferCompany;
  bool _useCustomCompany = false;
  PaymentMethodModel? _selectedWalletCompany;
  bool _useCustomWallet = false;

  bool _isPrepaid = false;
  double _prepaidPercentage = 0;
  bool _isLoadingPrepaidPercentage = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color gold = Color(0xFFFFD700);
  static const Color darkColor = Color(0xFF111827);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color successGreen = Color(0xFF10B981);

  final String _baseUrl = 'https://nexsy.shop';

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'cash',
      'label': 'الدفع عند الاستلام',
      'icon': Icons.money_rounded,
      'color': Colors.green,
    },
    {
      'value': 'bank_transfer',
      'label': 'تحويل بنكي',
      'icon': Icons.account_balance_rounded,
      'color': Colors.blue,
    },
    {
      'value': 'wallet',
      'label': 'المحفظة الإلكترونية',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _service = SystemBuilderService(authService: widget.authService);
    _fetchInstallationPrice();
    _fetchMountingBasePrice();
    _fetchPrepaidPercentage();
    _loadUserData();
    _loadDraftComponents();

    _fetchPaymentMethodsByType('bank_transfer');
    _fetchPaymentMethodsByType('electronic_wallet');

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _shippingAddressController.dispose();
    _userNotesController.dispose();
    _customCompanyController.dispose();
    _customWalletController.dispose();
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  /* ==========================================================================
     جلب طرق الدفع من الـ API
     ========================================================================== */
  Future<void> _fetchPaymentMethodsByType(String type) async {
    setState(() {
      if (type == 'bank_transfer') {
        _isLoadingBankTransfers = true;
      } else {
        _isLoadingWallets = true;
      }
    });

    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/nex/v1/user/public/payment-methods/type/$type'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded['data'] as List?) ?? [];
        final methods =
            list.map((e) => PaymentMethodModel.fromJson(e)).toList();

        if (mounted) {
          setState(() {
            if (type == 'bank_transfer') {
              _bankTransferCompanies = methods;
            } else {
              _walletCompanies = methods;
            }
          });
        }
      } else {
        //
      }
    } catch (e) {
      //
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'bank_transfer') {
            _isLoadingBankTransfers = false;
          } else {
            _isLoadingWallets = false;
          }
        });
      }
    }
  }

  /* ==========================================================================
     جلب سعر القاعدة الكلاسيكية لكل لوح
     ========================================================================== */
  Future<void> _fetchMountingBasePrice() async {
    final result = await _service.getMountingBasePrice(isSyp: _isSypPreferred);
    if (result['success'] == true && mounted) {
      setState(() {
        _mountingBasePricePerPanel = (result['value'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _fetchPrepaidPercentage() async {
    setState(() => _isLoadingPrepaidPercentage = true);
    final result = await _service.getPrepaidPercentage();
    if (mounted) {
      setState(() {
        _prepaidPercentage = result['value'] ?? 0;
        _isLoadingPrepaidPercentage = false;
      });
    }
  }

  double get _installationPriceValue {
    return double.tryParse(_installationPrice) ?? 0;
  }

  double get _prepaidBaseAmount => _subtotal + _installationPriceValue;

  double get _prepaidDiscountAmount {
    if (!_isPrepaid || _prepaidPercentage <= 0) return 0;
    return _prepaidBaseAmount * (_prepaidPercentage / 100);
  }

  double get _prepaidAmount {
    if (!_isPrepaid || _prepaidPercentage <= 0) return 0;
    return _prepaidBaseAmount - _prepaidDiscountAmount;
  }

  bool get _isSypPreferred {
    try {
      return widget.authService.storageService.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _fmt(double amount) {
    final num = amount.toStringAsFixed(2);
    return _isSypPreferred ? '$num SYP' : '\$$num';
  }

  Future<void> _loadUserData() async {
    try {
      if (widget.authService.isAuthenticated) {
        final userData = await widget.authService.getUserData();
        if (userData != null && mounted) {
          setState(() {
            _fullNameController.text = userData['name'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _shippingAddressController.text = userData['address'] ?? '';
          });
        }
      }
    } catch (e) {
      //
    }
  }

  void _saveCurrentDraft() {
    SystemBuilderDraftService.instance.saveDraft(
      panels: _selectedPanels,
      inverters: _selectedInverters,
      batteries: _selectedBatteries,
      cables: _selectedCables,
      panelBoards: _selectedPanelBoards,
    );
  }

  Future<void> _loadDraftComponents() async {
    final draft = SystemBuilderDraftService.instance;
    await draft.loadDraft();
    if (draft.hasDraft) {
      setState(() {
        _selectedPanels.addAll(draft.panels);
        _selectedInverters.addAll(draft.inverters);
        _selectedBatteries.addAll(draft.batteries);
        _selectedCables.addAll(draft.cables);
        _selectedPanelBoards.addAll(draft.panelBoards);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showSnackBar('تم تحميل مكونات 🎉', Colors.green);
          _saveCurrentDraft();
        }
      });
    }
  }

  Future<void> _fetchInstallationPrice() async {
    final result = await _service.getInstallationPrice(isSyp: _isSypPreferred);
    if (result['success'] == true && mounted) {
      setState(() {
        _installationPrice = result['formatted_value'] ?? '0.00';
      });
    }
  }

  double get _subtotal {
    double total = 0;
    for (var panel in _selectedPanels)
      total += (panel['price'] ?? 0) * (panel['quantity'] ?? 1);
    for (var inverter in _selectedInverters)
      total += (inverter['price'] ?? 0) * (inverter['quantity'] ?? 1);
    for (var battery in _selectedBatteries)
      total += (battery['price'] ?? 0) * (battery['quantity'] ?? 1);
    for (var cable in _selectedCables)
      total += (cable['price'] ?? 0) * (cable['quantity'] ?? 1);
    for (var panelBoard in _selectedPanelBoards)
      total += (panelBoard['price'] ?? 0) * (panelBoard['quantity'] ?? 1);
    return total;
  }

  int get _totalItems {
    int count = 0;
    for (var p in _selectedPanels) count += (p['quantity'] ?? 1) as int;
    for (var i in _selectedInverters) count += (i['quantity'] ?? 1) as int;
    for (var b in _selectedBatteries) count += (b['quantity'] ?? 1) as int;
    for (var c in _selectedCables) count += (c['quantity'] ?? 1) as int;
    for (var pb in _selectedPanelBoards) count += (pb['quantity'] ?? 1) as int;
    return count;
  }

  int get _totalPanelCount {
    int count = 0;
    for (var p in _selectedPanels) {
      count += (p['quantity'] ?? 1) as int;
    }
    return count;
  }

  double get _mountingBaseTotal {
    if (_mountingBasePricePerPanel <= 0 || _totalPanelCount <= 0) return 0;
    return _mountingBasePricePerPanel * _totalPanelCount;
  }

  double get _installationPriceNumeric {
    final cleaned = _installationPrice.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  double get _standardFeesTotal {
    return _installationPriceNumeric + _mountingBaseTotal;
  }

  bool get _isComplete =>
      _selectedPanels.isNotEmpty ||
      _selectedInverters.isNotEmpty ||
      _selectedBatteries.isNotEmpty ||
      _selectedCables.isNotEmpty ||
      _selectedPanelBoards.isNotEmpty;

  List<String> get _missingComponents {
    final missing = <String>[];
    if (_selectedPanels.isEmpty) missing.add('الألواح الشمسية');
    if (_selectedInverters.isEmpty) missing.add('الانفرتر');
    if (_selectedBatteries.isEmpty) missing.add('البطاريات');
    return missing;
  }

  bool get _hasMissingEssentialComponents => _missingComponents.isNotEmpty;

  bool get _isDeliveryInfoValid =>
      _fullNameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _shippingAddressController.text.trim().isNotEmpty;

  String _getSelectedBankTransferCompanyName() {
    if (_useCustomCompany) return _customCompanyController.text.trim();
    return _selectedBankTransferCompany?.paymentCompanyName ?? '';
  }

  String _getSelectedWalletCompanyName() {
    if (_useCustomWallet) return _customWalletController.text.trim();
    return _selectedWalletCompany?.paymentCompanyName ?? '';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ $label', Colors.green);
  }

  Future<void> _shareImage(String url, String title) async {
    try {
      _showSnackBar('جاري تجهيز الصورة...', Colors.blue);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _showSnackBar('فشل تحميل الصورة (${response.statusCode})', Colors.red);
        return;
      }

      final tempDir = await getTemporaryDirectory();

      String ext = 'jpg';
      try {
        final rawExt = url.split('.').last.split('?').first.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(rawExt)) {
          ext = rawExt;
        }
      } catch (_) {}

      final fileName = 'payment_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles([XFile(file.path)], text: title);
    } catch (e) {
      //
      _showSnackBar('تعذّر مشاركة الصورة', Colors.red);
    }
  }

  void _showPaymentMethodDetails(PaymentMethodModel method) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: lightGray,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: method.paymentCompanyImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: method.paymentCompanyImageUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) =>
                                          _companyPlaceholder(),
                                      placeholder: (_, __) =>
                                          _companyPlaceholder(),
                                    )
                                  : _companyPlaceholder(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.paymentCompanyName,
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تفاصيل التحويل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (method.recipientName != null)
                            _buildDetailRow(
                              icon: Icons.person_rounded,
                              label: 'اسم المستلم',
                              value: method.recipientName!,
                              onCopy: () => _copyToClipboard(
                                  method.recipientName!, 'اسم المستلم'),
                            ),
                          if (method.city != null)
                            _buildDetailRow(
                              icon: Icons.location_city_rounded,
                              label: 'المدينة',
                              value: method.city!,
                              onCopy: () =>
                                  _copyToClipboard(method.city!, 'المدينة'),
                            ),
                          if (method.phone != null)
                            _buildDetailRow(
                              icon: Icons.phone_rounded,
                              label: 'رقم الهاتف',
                              value: method.phone!,
                              onCopy: () =>
                                  _copyToClipboard(method.phone!, 'رقم الهاتف'),
                            ),
                          if (method.accountNumber != null)
                            _buildDetailRow(
                              icon: Icons.credit_card_rounded,
                              label: 'رقم الحساب',
                              value: method.accountNumber!,
                              onCopy: () => _copyToClipboard(
                                  method.accountNumber!, 'رقم الحساب'),
                            ),
                          if (method.accountImageUrl != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'صورة الحساب',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: CachedNetworkImage(
                                imageUrl: method.accountImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  height: 220,
                                  color: lightGray,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 220,
                                  color: lightGray,
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _shareImage(
                                  method.accountImageUrl!,
                                  'صورة حساب ${method.paymentCompanyName}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded),
                                label: Text(
                                  'حفظ / مشاركة صورة الحساب',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                          if (method.paymentCompanyImageUrl != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _shareImage(
                                  method.paymentCompanyImageUrl!,
                                  'شعار ${method.paymentCompanyName}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryBlue,
                                  side: BorderSide(
                                    color: primaryBlue.withOpacity(0.4),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded, size: 18),
                                label: Text(
                                  'مشاركة شعار الشركة',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  if (_selectedPaymentMethod ==
                                      'bank_transfer') {
                                    _selectedBankTransferCompany = method;
                                    _useCustomCompany = false;
                                    _customCompanyController.clear();
                                  } else if (_selectedPaymentMethod ==
                                      'wallet') {
                                    _selectedWalletCompany = method;
                                    _useCustomWallet = false;
                                    _customWalletController.clear();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: Text(
                                'اختيار هذه الطريقة',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.12),
                  secondaryBlue.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'نسخ',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.copy_rounded, size: 16, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyPlaceholder() {
    return Container(
      color: lightGray,
      child: Icon(
        Icons.account_balance_rounded,
        size: 28,
        color: Colors.grey.shade400,
      ),
    );
  }

  Future<bool> _showMissingComponentsWarning() async {
    if (!_hasMissingEssentialComponents) return true;

    final missingText = _missingComponents.join('، ');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تنبيه',
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827)),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لم تقم باختيار: $missingText',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Text(
                  'هل تريد المتابعة بدون هذه المكونات؟\n\nقد تحتاج منظومتك لهذه المكونات لتعمل بشكل كامل.',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إكمال المنظومة',
                style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('المتابعة بدونها',
                style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _submitOrder() async {
    final isGuest = !widget.authService.isAuthenticated;
    if (isGuest) {
      _showSnackBar('يرجى تسجيل الدخول', Colors.orange);
      return;
    }
    if (!_isComplete) {
      _showSnackBar('يرجى اختيار مكون واحد على الأقل', Colors.orange);
      return;
    }

    if (_isPrepaid && _selectedPaymentMethod == 'cash') {
      _showSnackBar(
          'الدفع المسبق لا يتوفر مع الدفع عند الاستلام - يرجى اختيار وسيلة دفع أخرى',
          Colors.red);
      return;
    }

    final shouldContinue = await _showMissingComponentsWarning();
    if (!shouldContinue) return;

    if (!_isDeliveryInfoValid) {
      _showSnackBar(
          'يرجى تعبئة معلومات التوصيل (الاسم، الهاتف، العنوان)', Colors.orange);
      setState(() => _showDeliveryInfo = true);
      return;
    }

    if (_selectedPaymentMethod == 'bank_transfer') {
      if (_useCustomCompany) {
        if (_customCompanyController.text.trim().isEmpty) {
          _showSnackBar('يرجى إدخال اسم شركة التحويل', Colors.orange);
          return;
        }
      } else {
        if (_selectedBankTransferCompany == null) {
          _showSnackBar('يرجى اختيار شركة التحويل', Colors.orange);
          return;
        }
      }
    }

    if (_selectedPaymentMethod == 'wallet') {
      if (_useCustomWallet) {
        if (_customWalletController.text.trim().isEmpty) {
          _showSnackBar('يرجى إدخال اسم المحفظة الإلكترونية', Colors.orange);
          return;
        }
      } else {
        if (_selectedWalletCompany == null) {
          _showSnackBar('يرجى اختيار المحفظة الإلكترونية', Colors.orange);
          return;
        }
      }
    }

    String userNotes = _userNotesController.text.trim();
    if (_selectedPaymentMethod == 'bank_transfer') {
      final companyName = _getSelectedBankTransferCompanyName();
      if (companyName.isNotEmpty) {
        if (userNotes.isNotEmpty) userNotes += '\n';
        userNotes += 'تحويل بنكي عن طريق: $companyName';
      }
    } else if (_selectedPaymentMethod == 'wallet') {
      final walletName = _getSelectedWalletCompanyName();
      if (walletName.isNotEmpty) {
        if (userNotes.isNotEmpty) userNotes += '\n';
        userNotes += 'محفظة إلكترونية: $walletName';
      }
    }

    setState(() => _isSubmitting = true);

    final additionalFees = _standardFeesTotal;

    final result = await _service.createOrder(
      panels: _selectedPanels,
      inverters: _selectedInverters,
      batteries: _selectedBatteries,
      cables: _selectedCables,
      panelBoards: _selectedPanelBoards,
      notes: _notes,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      userNotes: userNotes,
      isPrepaid: _isPrepaid,
      additionalFees: additionalFees,
      isSyp: _isSypPreferred,
    );
    setState(() => _isSubmitting = false);

    if (result['success']) {
      final compatibility = result['compatibility'];
      final bool hasWarnings = compatibility != null &&
          compatibility['warnings'] != null &&
          (compatibility['warnings'] as List).isNotEmpty;
      await SystemBuilderDraftService.instance.clearDraft();

      setState(() {
        _selectedPanels.clear();
        _selectedInverters.clear();
        _selectedBatteries.clear();
        _selectedCables.clear();
        _selectedPanelBoards.clear();
        _notes = null;
        _aiAnalysis = null;
      });

      if (hasWarnings) {
        _showCompatibilityWarningDialog(
          score: compatibility['score'] ?? 0,
          warnings: List<String>.from(compatibility['warnings'] ?? []),
          summary: compatibility['summary'] ?? '',
        );
      } else {
        _showSuccessDialog(
          score: compatibility?['score'] ?? 100,
          summary: compatibility?['summary'] ?? 'تم إرسال طلب التصميم بنجاح',
        );
      }
    } else {
      final compatibility = result['compatibility'];
      if (compatibility != null && !compatibility['compatible']) {
        _showIncompatibilityDialog(
          score: compatibility['score'] ?? 0,
          issues: List<String>.from(compatibility['issues'] ?? []),
          warnings: List<String>.from(compatibility['warnings'] ?? []),
          summary: compatibility['summary'] ?? '',
        );
      } else {
        _showErrorDialog(result['message'] ?? 'حدث خطأ');
      }
    }
  }

  Widget _buildCompanyCard(
    PaymentMethodModel company,
    bool isSelected, {
    required bool isBank,
    VoidCallback? onDetails,
  }) {
    final color = isBank ? Colors.blue : Colors.orange;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          setState(() {
            if (isBank) {
              _selectedBankTransferCompany = company;
              _useCustomCompany = false;
              _customCompanyController.clear();
            } else {
              _selectedWalletCompany = company;
              _useCustomWallet = false;
              _customWalletController.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)])
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 5),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: company.paymentCompanyImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: company.paymentCompanyImageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            color: lightGray,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: color.withOpacity(0.1),
                            child: Icon(
                              isBank
                                  ? Icons.account_balance_rounded
                                  : Icons.account_balance_wallet_rounded,
                              size: 24,
                              color: color,
                            ),
                          ),
                        )
                      : Container(
                          color: color.withOpacity(0.1),
                          child: Icon(
                            isBank
                                ? Icons.account_balance_rounded
                                : Icons.account_balance_wallet_rounded,
                            size: 24,
                            color: color,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                company.paymentCompanyName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color.shade700 : Colors.grey.shade700,
                ),
              ),
              if (company.hasDetails && onDetails != null)
                GestureDetector(
                  onTap: onDetails,
                  child: Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 10, color: color),
                        const SizedBox(width: 3),
                        Text(
                          'التفاصيل',
                          style: GoogleFonts.cairo(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: isSelected ? color : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferCompaniesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'اختر شركة التحويل',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingBankTransfers)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            )
          else if (_bankTransferCompanies.isEmpty && !_useCustomCompany)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لا توجد طرق متاحة حاليًا من هذا النوع',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _bankTransferCompanies.length,
              itemBuilder: (context, index) {
                final company = _bankTransferCompanies[index];
                final isSelected =
                    _selectedBankTransferCompany?.id == company.id &&
                        !_useCustomCompany;
                return _buildCompanyCard(
                  company,
                  isSelected,
                  isBank: true,
                  onDetails: () => _showPaymentMethodDetails(company),
                );
              },
            ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _useCustomCompany = !_useCustomCompany;
                  if (_useCustomCompany) {
                    _selectedBankTransferCompany = null;
                  } else {
                    _customCompanyController.clear();
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _useCustomCompany
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        _useCustomCompany ? Colors.teal : Colors.grey.shade300,
                    width: _useCustomCompany ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 18,
                        color: _useCustomCompany ? Colors.teal : Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'شركة أخرى',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _useCustomCompany
                                ? Colors.teal.shade700
                                : Colors.grey.shade700),
                      ),
                    ),
                    if (_useCustomCompany)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.teal, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (_useCustomCompany) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customCompanyController,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(color: const Color(0xFF111827)),
              decoration: _buildInputDecoration(
                  'اسم شركة التحويل', Icons.business_rounded),
            ),
          ],
          if (_getSelectedBankTransferCompanyName().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم اختيار: ${_getSelectedBankTransferCompanyName()}',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletCompaniesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'اختر المحفظة الإلكترونية',
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingWallets)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            )
          else if (_walletCompanies.isEmpty && !_useCustomWallet)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'لا توجد طرق متاحة حاليًا من هذا النوع',
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.78,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _walletCompanies.length,
              itemBuilder: (context, index) {
                final company = _walletCompanies[index];
                final isSelected = _selectedWalletCompany?.id == company.id &&
                    !_useCustomWallet;
                return _buildCompanyCard(
                  company,
                  isSelected,
                  isBank: false,
                  onDetails: () => _showPaymentMethodDetails(company),
                );
              },
            ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _useCustomWallet = !_useCustomWallet;
                  if (_useCustomWallet) {
                    _selectedWalletCompany = null;
                  } else {
                    _customWalletController.clear();
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _useCustomWallet
                      ? Colors.deepOrange.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _useCustomWallet
                        ? Colors.deepOrange
                        : Colors.grey.shade300,
                    width: _useCustomWallet ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 18,
                        color:
                            _useCustomWallet ? Colors.deepOrange : Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'محفظة أخرى',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _useCustomWallet
                                ? Colors.deepOrange.shade700
                                : Colors.grey.shade700),
                      ),
                    ),
                    if (_useCustomWallet)
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.deepOrange, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (_useCustomWallet) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customWalletController,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(color: const Color(0xFF111827)),
              decoration: _buildInputDecoration('اسم المحفظة الإلكترونية',
                  Icons.account_balance_wallet_rounded),
            ),
          ],
          if (_getSelectedWalletCompanyName().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم اختيار: ${_getSelectedWalletCompanyName()}',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /* ==========================================================================
     بطاقة الرسوم القياسية — ✅ محدّثة للعملة
     ========================================================================== */
  Widget _buildStandardFeesCard() {
    if (_selectedPanels.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.teal.withOpacity(0.05),
            Colors.teal.withOpacity(0.02)
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.build_rounded, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('أجور التركيب',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700)),
                const SizedBox(height: 2),
                Text('يشمل تركيب المنظومة بالكامل',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade600]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_fmt(_installationPriceNumeric),
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.teal.withOpacity(0.05),
          Colors.teal.withOpacity(0.02)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handyman_rounded,
                  color: Colors.teal, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رسوم التركيب والقاعدة',
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700)),
                  const SizedBox(height: 2),
                  Text('رسوم إضافية تُحسب تلقائياً',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_fmt(_standardFeesTotal),
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildFeeRow(
            icon: Icons.build_rounded,
            color: const Color(0xFF10B981),
            title: 'أجور التركيب',
            subtitle: 'يشمل تركيب المنظومة بالكامل',
            amount: _installationPriceNumeric,
          ),
          if (_mountingBasePricePerPanel > 0 && _totalPanelCount > 0)
            _buildFeeRow(
              icon: Icons.construction_rounded,
              color: const Color(0xFFF59E0B),
              title: 'قاعدة كلاسيكية للألواح',
              subtitle:
                  '$_totalPanelCount لوح × ${_fmt(_mountingBasePricePerPanel)}',
              amount: _mountingBaseTotal,
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي الرسوم:',
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700)),
                Text(_fmt(_standardFeesTotal),
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required double amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(_fmt(amount),
              style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _showDeliveryInfo = !_showDeliveryInfo);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          primaryBlue.withOpacity(0.12),
                          secondaryBlue.withOpacity(0.06)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'معلومات التوصيل ووسيلة الدفع',
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isDeliveryInfoValid
                                ? '${_fullNameController.text.trim()} • ${_phoneController.text.trim()}'
                                : 'اضغط لإدخال معلومات التوصيل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: _isDeliveryInfoValid
                                  ? Colors.green
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isDeliveryInfoValid)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.green, size: 18),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _showDeliveryInfo ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade500, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(color: const Color(0xFF111827)),
                    decoration: _buildInputDecoration(
                        'الاسم الكامل', Icons.person_rounded),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(color: const Color(0xFF111827)),
                    decoration: _buildInputDecoration(
                        'رقم الهاتف', Icons.phone_rounded),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _shippingAddressController,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: GoogleFonts.cairo(color: const Color(0xFF111827)),
                    decoration: _buildInputDecoration(
                        'عنوان التوصيل', Icons.home_rounded),
                  ),
                  const SizedBox(height: 20),
                  if (_prepaidPercentage > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isPrepaid
                            ? Colors.green.withOpacity(0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isPrepaid
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.shade200,
                          width: _isPrepaid ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.savings_rounded,
                                    color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الدفع المسبق',
                                      style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF111827)),
                                    ),
                                    Text(
                                      'احصل على خصم ${_prepaidPercentage.toStringAsFixed(0)}% عند الدفع المسبق',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isPrepaid,
                                onChanged: (value) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _isPrepaid = value;
                                    if (value &&
                                        _selectedPaymentMethod == 'cash') {
                                      _selectedPaymentMethod = 'bank_transfer';
                                      _showSnackBar(
                                        'تم تغيير وسيلة الدفع لأن الدفع المسبق لا يتوافق مع الدفع عند الاستلام',
                                        Colors.orange,
                                      );
                                    }
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                          if (_isPrepaid && _prepaidPercentage > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_rounded,
                                      color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'الدفع المسبق لا يتوفر مع الدفع عند الاستلام',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المبلغ الأصلي',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                                Text(_fmt(_prepaidBaseAmount),
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111827))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('نسبة الخصم',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                                Text(
                                    '${_prepaidPercentage.toStringAsFixed(2)}%',
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('قيمة الخصم',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                                Text('- ${_fmt(_prepaidDiscountAmount)}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('المبلغ بعد الخصم',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF111827))),
                                Text(_fmt(_prepaidAmount),
                                    style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.payment_rounded,
                            color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('وسيلة الدفع',
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._paymentMethods.where((method) {
                    if (_isPrepaid && method['value'] == 'cash') {
                      return false;
                    }
                    return true;
                  }).map((method) {
                    final isSelected =
                        _selectedPaymentMethod == method['value'];
                    final color = method['color'] as Color;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedPaymentMethod =
                                  method['value'] as String;
                              if (_selectedPaymentMethod != 'bank_transfer') {
                                _selectedBankTransferCompany = null;
                                _useCustomCompany = false;
                                _customCompanyController.clear();
                              }
                              if (_selectedPaymentMethod != 'wallet') {
                                _selectedWalletCompany = null;
                                _useCustomWallet = false;
                                _customWalletController.clear();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(colors: [
                                      color.withOpacity(0.1),
                                      color.withOpacity(0.05)
                                    ])
                                  : null,
                              color: isSelected ? null : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isSelected
                                      ? color.withOpacity(0.5)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withOpacity(0.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(method['icon'] as IconData,
                                      size: 20,
                                      color: isSelected
                                          ? color
                                          : Colors.grey.shade500),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    method['label'] as String,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF111827)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isSelected
                                            ? color
                                            : Colors.grey.shade400,
                                        width: 2),
                                    color:
                                        isSelected ? color : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_selectedPaymentMethod == 'bank_transfer')
                    _buildBankTransferCompaniesSection(),
                  if (_selectedPaymentMethod == 'wallet')
                    _buildWalletCompaniesSection(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _userNotesController,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: GoogleFonts.cairo(color: const Color(0xFF111827)),
                    decoration: _buildInputDecoration(
                        'ملاحظات إضافية (اختياري)', Icons.note_rounded),
                  ),
                ],
              ),
            ),
            crossFadeState: _showDeliveryInfo
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            primaryBlue.withOpacity(0.12),
            secondaryBlue.withOpacity(0.06)
          ]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryBlue, size: 18),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _showSuccessDialog({required int score, required String summary}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: null,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.grey.shade600,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.withOpacity(0.15),
                    Colors.teal.withOpacity(0.08)
                  ]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 56),
              ),
              const SizedBox(height: 16),
              Text('✅ تم إرسال الطلب بنجاح!',
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827)),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 8),
              Text('شكراً لك، سيتم مراجعة طلبك وتجهيزه قريباً',
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.withOpacity(0.08),
                    Colors.green.withOpacity(0.04)
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text('درجة التوافق',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.grey.shade600),
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text('$score/100',
                        style: GoogleFonts.cairo(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.info_outline_rounded,
                            color: Colors.green, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(summary,
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: const Color(0xFF111827),
                                height: 1.5),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('حسناً',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        actions: const [],
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: null,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: Colors.grey.shade600,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              Text('❌ حدث خطأ',
                  style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827)),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(message,
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.red.shade800, height: 1.5),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('حسناً',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        actions: const [],
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  void _showIncompatibilityDialog(
      {required int score,
      required List<String> issues,
      required List<String> warnings,
      required String summary}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: true,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: null,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.grey.shade600,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 48),
                ),
                const SizedBox(height: 16),
                Text('⚠️ المكونات غير متوافقة',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827)),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl),
                const SizedBox(height: 8),
                Text('يرجى تعديل المكونات قبل الإرسال',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.red.withOpacity(0.08),
                      Colors.red.withOpacity(0.04)
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('درجة التوافق',
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: Colors.grey.shade600),
                          textDirection: TextDirection.rtl),
                      const SizedBox(height: 8),
                      Text('$score/100',
                          style: GoogleFonts.cairo(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: score >= 50 ? Colors.orange : Colors.red)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              score >= 50 ? Colors.orange : Colors.red),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('الحد الأدنى للتوافق: 70/100',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey.shade500),
                          textDirection: TextDirection.rtl),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (summary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(summary,
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: const Color(0xFF111827),
                                  height: 1.5),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (issues.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('❌ مشاكل يجب حلها قبل الإرسال:',
                        style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(height: 10),
                  ...issues.map((issue) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.cancel_rounded,
                                  color: Colors.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(issue,
                                  style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: Colors.red.shade800,
                                      height: 1.5),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      )),
                ],
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('⚠️ تحذيرات إضافية:',
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right),
                  ),
                  const SizedBox(height: 8),
                  ...warnings.map((warning) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(warning,
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      height: 1.4),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    label: Text('تعديل المكونات',
                        style: GoogleFonts.cairo(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: const [],
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  void _showCompatibilityWarningDialog(
      {required int score,
      required List<String> warnings,
      required String summary}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text('✅ تم إرسال الطلب بنجاح',
                style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827)),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('المنظومة متوافقة مع بعض الملاحظات',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: Colors.orange.shade600),
                textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.withOpacity(0.08),
                    Colors.green.withOpacity(0.04)
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text('درجة التوافق',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text('$score/100',
                        style: GoogleFonts.cairo(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(summary,
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: const Color(0xFF111827),
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('⚠️ ملاحظات:',
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700)),
                const SizedBox(height: 8),
                ...warnings.map((warning) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(warning,
                                style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('حسناً',
                  style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
              color == Colors.green
                  ? Icons.check_circle_rounded
                  : color == Colors.red
                      ? Icons.error_rounded
                      : Icons.info_rounded,
              color: Colors.white,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  void _navigateToHistory() {
    if (!widget.authService.isAuthenticated) {
      _showSnackBar('يرجى تسجيل الدخول', Colors.orange);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                OrderHistoryScreen(authService: widget.authService)));
  }

  void _addItem(String type) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPickerScreen(
                type: type,
                authService: widget.authService,
                onSelected: (product, quantity) {
                  setState(() {
                    _aiAnalysis = null;
                    double getPrice(dynamic price) {
                      if (price == null) return 0.0;
                      if (price is String) return double.tryParse(price) ?? 0.0;
                      if (price is num) return price.toDouble();
                      return 0.0;
                    }

                    final typeMap = {
                      'panels': _selectedPanels,
                      'inverters': _selectedInverters,
                      'batteries': _selectedBatteries,
                      'Cables': _selectedCables,
                      'Panel': _selectedPanelBoards,
                    };
                    final list = typeMap[type]!;
                    final existingIndex =
                        list.indexWhere((p) => p['id'] == product['id']);

                    final bool isSyp = _isSypPreferred;
                    final price = isSyp
                        ? getPrice(
                            product['final_price_syp'] ?? product['price_syp'])
                        : getPrice(product['final_price'] ?? product['price']);
                    final discountPrice = isSyp
                        ? getPrice(product['discount_price_syp'])
                        : getPrice(product['discount_price']);
                    final finalPrice =
                        discountPrice > 0 ? discountPrice : price;

                    if (existingIndex != -1) {
                      list[existingIndex]['quantity'] += quantity;
                    } else {
                      list.add({
                        'id': product['id'],
                        'name': product['name_ar'] ?? product['name'],
                        'price': finalPrice,
                        'quantity': quantity
                      });
                    }
                  });
                  _saveCurrentDraft();
                })));
  }

  void _updateQuantity(
      List<Map<String, dynamic>> list, Map<String, dynamic> item, int delta) {
    setState(() {
      _aiAnalysis = null;
      final newQty = (item['quantity'] ?? 1) + delta;
      if (newQty <= 0) {
        list.remove(item);
      } else {
        item['quantity'] = newQty;
      }
    });
    _saveCurrentDraft();
  }

  Future<void> _analyzeSystem() async {
    setState(() => _isAnalyzing = true);
    final result = await _service.analyzeSystem(
        panels: _selectedPanels,
        inverters: _selectedInverters,
        batteries: _selectedBatteries,
        cables: _selectedCables,
        panelBoards: _selectedPanelBoards,
        question:
            _analysisQuestion?.isNotEmpty == true ? _analysisQuestion : null);
    setState(() => _isAnalyzing = false);

    if (result['success'] == true) {
      setState(() {
        _aiAnalysis = result['data']['ai_analysis']?.toString() ?? '';
        _compatibilityResult =
            result['data']['compatibility'] as Map<String, dynamic>?;
        _statistics = result['data']['statistics'] as Map<String, dynamic>?;
      });
      _showSnackBar('تم تحليل المنظومة بنجاح! 🎉', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'فشل التحليل', Colors.red);
    }
  }

  Widget _buildFormattedAnalysis(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return SelectableText(
      text,
      style: GoogleFonts.cairo(
          fontSize: 14, height: 1.8, color: Colors.grey.shade700),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  void _showFullAnalysis() {
    if (_aiAnalysis == null) return;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(children: [
                Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.purple.withOpacity(0.15),
                                Colors.blue.withOpacity(0.08)
                              ]),
                              borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: Colors.purple, size: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text('تحليل المنظومة',
                              style: GoogleFonts.cairo(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded))
                    ])),
                const Divider(),
                Expanded(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _buildFormattedAnalysis(_aiAnalysis ?? ''))),
              ]),
            ));
  }

  Widget _buildSelectedItems(String title, List<Map<String, dynamic>> items,
      Color color, String type) {
    final iconMap = {
      'الألواح الشمسية': Icons.solar_power_rounded,
      'الانفرتر': Icons.memory_rounded,
      'البطاريات': Icons.battery_charging_full_rounded,
      'الكابلات': Icons.cable_rounded,
      'تابلو الحماية': Icons.electrical_services_rounded,
    };
    final totalPower = items.fold<double>(0,
        (sum, item) => sum + ((item['price'] ?? 0) * (item['quantity'] ?? 1)));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(iconMap[title] ?? Icons.category_rounded,
                    color: color, size: 22)),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (items.isNotEmpty)
              Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${items.length}',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color)))
          ]),
          Container(
              decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: TextButton.icon(
                  onPressed: () => _addItem(type),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text('إضافة', style: GoogleFonts.cairo()),
                  style: TextButton.styleFrom(foregroundColor: primaryBlue))),
        ]),
        if (items.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Column(children: [
                Icon(iconMap[title] ?? Icons.category_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text('لم يتم اختيار أي عناصر',
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey.shade500)),
                Text('اضغط على "إضافة" لاختيار ${title}',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade400))
              ])))
        else ...[
          ...items
              .map((item) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item['name'] ?? 'غير معروف',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                                '${_fmt((item['price'] ?? 0).toDouble())} × ${item['quantity']}',
                                style: GoogleFonts.cairo(
                                    fontSize: 12, color: Colors.grey.shade600))
                          ])),
                      Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            InkWell(
                                onTap: () => _updateQuantity(items, item, -1),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.remove_rounded,
                                        size: 16))),
                            Container(
                                width: 35,
                                alignment: Alignment.center,
                                child: Text('${item['quantity']}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold))),
                            InkWell(
                                onTap: () => _updateQuantity(items, item, 1),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.add_rounded,
                                        size: 16)))
                          ])),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              _fmt(((item['price'] ?? 0) *
                                      (item['quantity'] ?? 1))
                                  .toDouble()),
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color))),
                      const SizedBox(width: 4),
                      InkWell(
                          onTap: () {
                            setState(() {
                              _aiAnalysis = null;
                              items.remove(item);
                            });
                            _saveCurrentDraft();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.red, size: 18))),
                    ]),
                  ))
              .toList(),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('إجمالي ${title}',
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(_fmt(totalPower),
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color))
                  ])),
        ],
      ]),
    );
  }

  Widget _buildStatisticsCard() {
    final panelPower = _selectedPanels.fold<double>(
        0, (sum, p) => sum + ((p['price'] ?? 0) * (p['quantity'] ?? 1)));
    final inverterPower = _selectedInverters.fold<double>(
        0, (sum, i) => sum + ((i['price'] ?? 0) * (i['quantity'] ?? 1)));
    final batteryPower = _selectedBatteries.fold<double>(
        0, (sum, b) => sum + ((b['price'] ?? 0) * (b['quantity'] ?? 1)));
    final cablesPower = _selectedCables.fold<double>(
        0, (sum, c) => sum + ((c['price'] ?? 0) * (c['quantity'] ?? 1)));
    final panelBoardsPower = _selectedPanelBoards.fold<double>(
        0, (sum, pb) => sum + ((pb['price'] ?? 0) * (pb['quantity'] ?? 1)));
    final hasData = _selectedPanels.isNotEmpty ||
        _selectedInverters.isNotEmpty ||
        _selectedBatteries.isNotEmpty ||
        _selectedCables.isNotEmpty ||
        _selectedPanelBoards.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.green.withOpacity(0.05),
            Colors.blue.withOpacity(0.05)
          ]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.green.withOpacity(0.08), blurRadius: 15)
          ]),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.green.withOpacity(0.15),
                    Colors.teal.withOpacity(0.08)
                  ]),
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.analytics_rounded,
                  color: Colors.green, size: 24)),
          const SizedBox(width: 12),
          Text('إحصائيات مالية',
              style:
                  GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 20),
        _buildStatRow(
            icon: Icons.solar_power_rounded,
            label: 'الألواح الشمسية',
            detail: _selectedPanels.isNotEmpty
                ? '${_selectedPanels.length} نوع'
                : 'لم يتم الإضافة',
            total: _selectedPanels.isNotEmpty ? _fmt(panelPower) : '---',
            color: Colors.orange),
        const SizedBox(height: 12),
        _buildStatRow(
            icon: Icons.memory_rounded,
            label: 'الانفرتر',
            detail: _selectedInverters.isNotEmpty
                ? '${_selectedInverters.length} نوع'
                : 'لم يتم الإضافة',
            total: _selectedInverters.isNotEmpty ? _fmt(inverterPower) : '---',
            color: Colors.blue),
        const SizedBox(height: 12),
        _buildStatRow(
            icon: Icons.battery_charging_full_rounded,
            label: 'البطاريات',
            detail: _selectedBatteries.isNotEmpty
                ? '${_selectedBatteries.length} نوع'
                : 'لم يتم الإضافة',
            total: _selectedBatteries.isNotEmpty ? _fmt(batteryPower) : '---',
            color: Colors.green),
        const SizedBox(height: 12),
        _buildStatRow(
            icon: Icons.cable_rounded,
            label: 'الكابلات',
            detail: _selectedCables.isNotEmpty
                ? '${_selectedCables.length} نوع'
                : 'لم يتم الإضافة',
            total: _selectedCables.isNotEmpty ? _fmt(cablesPower) : '---',
            color: Colors.purple),
        const SizedBox(height: 12),
        _buildStatRow(
            icon: Icons.electrical_services_rounded,
            label: 'تابلو الحماية',
            detail: _selectedPanelBoards.isNotEmpty
                ? '${_selectedPanelBoards.length} نوع'
                : 'لم يتم الإضافة',
            total: _selectedPanelBoards.isNotEmpty
                ? _fmt(panelBoardsPower)
                : '---',
            color: Colors.teal),
        if (hasData) ...[
          const SizedBox(height: 16),
          Container(
              height: 1.5,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                Colors.grey.shade200,
                primaryBlue.withOpacity(0.3),
                Colors.grey.shade200
              ]))),
          const SizedBox(height: 16),
          _buildStatRow(
              icon: Icons.summarize_rounded,
              label: 'المجموع الكلي',
              detail: '${_totalItems} عنصر',
              total: _fmt(_subtotal),
              color: primaryBlue,
              isTotal: true)
        ],
      ]),
    );
  }

  Widget _buildStatRow(
      {required IconData icon,
      required String label,
      required String detail,
      required String total,
      required Color color,
      bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isTotal
                  ? primaryBlue.withOpacity(0.3)
                  : color.withOpacity(0.15),
              width: isTotal ? 1.5 : 1)),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.12), color.withOpacity(0.06)]),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: isTotal ? 22 : 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: isTotal ? 15 : 13,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
          const SizedBox(height: 2),
          Text(detail,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey))
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isTotal
                        ? [
                            primaryBlue.withOpacity(0.12),
                            secondaryBlue.withOpacity(0.06)
                          ]
                        : [color.withOpacity(0.08), color.withOpacity(0.04)]),
                borderRadius: BorderRadius.circular(12)),
            child: Text(total,
                style: GoogleFonts.cairo(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: isTotal ? primaryBlue : color))),
      ]),
    );
  }

  Widget _buildAIAnalysisButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.purple.withOpacity(0.05),
            Colors.blue.withOpacity(0.05)
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withOpacity(0.2))),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.purple.withOpacity(0.15),
                    Colors.blue.withOpacity(0.08)
                  ]),
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.purple, size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('تحليل المنظومة بالذكاء الاصطناعي',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('اكتشف قوة منظومتك وما يمكن تشغيله',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey))
              ]))
        ]),
        const SizedBox(height: 16),
        TextFormField(
            controller: _questionController,
            maxLines: 3,
            onChanged: (value) => _analysisQuestion = value,
            decoration: InputDecoration(
                hintText: 'هل لديك استفسارات إضافية؟',
                hintStyle: GoogleFonts.cairo(
                    fontSize: 12, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.purple.withOpacity(0.2))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.purple.withOpacity(0.2))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                prefixIcon: const Icon(Icons.help_outline_rounded,
                    color: Colors.purple, size: 22)),
            style:
                GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade700)),
        const SizedBox(height: 16),
        if (_compatibilityResult != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                (_compatibilityResult!['compatible'] == true)
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                (_compatibilityResult!['compatible'] == true)
                    ? Colors.teal.withOpacity(0.04)
                    : Colors.orange.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_compatibilityResult!['compatible'] == true)
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_compatibilityResult!['compatible'] == true)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _compatibilityResult!['compatible'] == true
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: _compatibilityResult!['compatible'] == true
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'درجة التوافق: ${_compatibilityResult!['score']}/100',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _compatibilityResult!['summary']?.toString() ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color:
                                  (_compatibilityResult!['compatible'] == true)
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_compatibilityResult!['score'] ?? 0) / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (_compatibilityResult!['score'] ?? 0) >= 70
                          ? Colors.green
                          : (_compatibilityResult!['score'] ?? 0) >= 40
                              ? Colors.orange
                              : Colors.red,
                    ),
                    minHeight: 8,
                  ),
                ),
                if ((_compatibilityResult!['issues'] as List?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 12),
                  Text('❌ المشاكل:',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700)),
                  const SizedBox(height: 4),
                  ...((_compatibilityResult!['issues'] as List)
                      .map((issue) => Text(
                            '• $issue',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.red.shade800,
                                height: 1.4),
                          ))),
                ],
                if ((_compatibilityResult!['warnings'] as List?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(height: 8),
                  Text('⚠️ التحذيرات:',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700)),
                  const SizedBox(height: 4),
                  ...((_compatibilityResult!['warnings'] as List)
                      .map((warning) => Text(
                            '• $warning',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                                height: 1.4),
                          ))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_aiAnalysis != null) ...[
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedAnalysis(_aiAnalysis!),
                    const SizedBox(height: 12),
                    TextButton.icon(
                        onPressed: _showFullAnalysis,
                        icon: const Icon(Icons.open_in_full_rounded, size: 16),
                        label: Text('عرض التحليل الكامل',
                            style: GoogleFonts.cairo(fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.purple))
                  ])),
          const SizedBox(height: 12)
        ],
        SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeSystem,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                    _isAnalyzing
                        ? 'جاري التحليل...'
                        : (_aiAnalysis != null
                            ? 'إعادة التحليل'
                            : 'تحليل المنظومة'),
                    style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _aiAnalysis != null ? Colors.teal : Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = !widget.authService.isAuthenticated;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F7FA)],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) =>
                                        Transform.scale(
                                      scale: 1.0 +
                                          (_pulseAnimationController.value *
                                              0.1),
                                      child: child,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                          Icons.design_services_rounded,
                                          color: gold,
                                          size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'تصميم منظومة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _navigateToHistory,
                              icon: const Icon(Icons.history_rounded,
                                  color: Colors.white),
                              tooltip: 'سجل الطلبات',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isSubmitting
                    ? _buildLoadingState()
                    : TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            if (isGuest)
                              Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.orange.shade200)),
                                  child: Row(children: [
                                    const Icon(Icons.info_outline_rounded,
                                        color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                            'سجل الدخول لحفظ وإرسال الطلبات',
                                            style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: Colors.orange.shade800)))
                                  ])),
                            _buildSelectedItems('الألواح الشمسية',
                                _selectedPanels, Colors.orange, 'panels'),
                            _buildSelectedItems('الانفرتر', _selectedInverters,
                                Colors.blue, 'inverters'),
                            _buildSelectedItems('البطاريات', _selectedBatteries,
                                Colors.green, 'batteries'),
                            _buildSelectedItems('الكابلات', _selectedCables,
                                Colors.purple, 'Cables'),
                            _buildSelectedItems('تابلو الحماية',
                                _selectedPanelBoards, Colors.teal, 'Panel'),
                            const SizedBox(height: 16),
                            _buildStatisticsCard(),
                            _buildStandardFeesCard(),
                            const SizedBox(height: 16),
                            if (_isComplete) ...[
                              _buildDeliveryInfoSection(),
                            ],
                            const SizedBox(height: 16),
                            if (_totalItems >= 2) _buildAIAnalysisButton(),
                            if (_totalItems >= 2) const SizedBox(height: 20),
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.note_rounded,
                                            color: primaryBlue, size: 20),
                                        const SizedBox(width: 8),
                                        Text('ملاحظات إضافية',
                                            style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold))
                                      ]),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                          maxLines: 3,
                                          onChanged: (value) => _notes = value,
                                          decoration: InputDecoration(
                                              hintText: 'أضف ملاحظاتك هنا...',
                                              hintStyle: GoogleFonts.cairo(
                                                  color: Colors.grey.shade400),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .grey.shade300)),
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .grey.shade300)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: primaryBlue)),
                                              filled: true,
                                              fillColor: Colors.grey.shade50),
                                          style: GoogleFonts.cairo())
                                    ])),
                            const SizedBox(height: 20),
                            SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                    onPressed:
                                        _isComplete ? _submitOrder : null,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _isComplete
                                            ? primaryBlue
                                            : Colors.grey.shade400,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        elevation: _isComplete ? 8 : 0),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                              _isComplete
                                                  ? Icons.send_rounded
                                                  : Icons.lock_outline_rounded,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                              _isComplete
                                                  ? 'إرسال طلب التصميم'
                                                  : 'اختر مكون واحد على الأقل',
                                              style: GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold))
                                        ]))),
                            const SizedBox(height: 16),
                            if (!isGuest)
                              SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                      onPressed: _navigateToHistory,
                                      icon: const Icon(Icons.history_rounded),
                                      label: Text('عرض سجل طلباتي',
                                          style:
                                              GoogleFonts.cairo(fontSize: 14)),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: primaryBlue,
                                          side: BorderSide(
                                              color:
                                                  primaryBlue.withOpacity(0.3)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14)))),
                          ]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimationController,
            builder: (context, child) {
              return Transform.scale(
                  scale: 1.0 + (_pulseAnimationController.value * 0.2),
                  child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  primaryBlue.withOpacity(0.15),
                  secondaryBlue.withOpacity(0.08)
                ]),
              ),
              child: const CircularProgressIndicator(
                  color: primaryBlue, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 20),
          Text('جاري إرسال الطلب...',
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w600, color: darkColor)),
        ],
      ),
    );
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

class ProductPickerScreen extends StatefulWidget {
  final String type;
  final AuthService authService;
  final Function(Map<String, dynamic>, int) onSelected;

  const ProductPickerScreen({
    super.key,
    required this.type,
    required this.authService,
    required this.onSelected,
  });

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen>
    with TickerProviderStateMixin {
  late SystemBuilderService _service;
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _search = '';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);

  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _service = SystemBuilderService(authService: widget.authService);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadProducts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isSypPreferred {
    try {
      return widget.authService.storageService.isSypPreferred();
    } catch (_) {
      return false;
    }
  }

  String _fmt(double amount) {
    final num = amount.toStringAsFixed(2);
    return _isSypPreferred ? '$num SYP' : '\$$num';
  }

  String _getTitle() {
    switch (widget.type) {
      case 'panels':
        return 'اختر الألواح الشمسية';
      case 'inverters':
        return 'اختر الانفرتر';
      case 'batteries':
        return 'اختر البطاريات';
      case 'Cables':
        return 'اختر الكابلات';
      case 'Panel':
        return 'اختر تابلو الحماية';
      default:
        return 'اختر المنتج';
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case 'panels':
        return Colors.orange;
      case 'inverters':
        return Colors.blue;
      case 'batteries':
        return Colors.green;
      case 'Cables':
        return Colors.purple;
      case 'Panel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'panels':
        return Icons.solar_power_rounded;
      case 'inverters':
        return Icons.memory_rounded;
      case 'batteries':
        return Icons.battery_charging_full_rounded;
      case 'Cables':
        return Icons.cable_rounded;
      case 'Panel':
        return Icons.electrical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getProducts(
        widget.type,
        search: _search,
        page: 1,
      );
      if (result['success'] == true && mounted) {
        final data = result['data'];
        List<dynamic> productsList = [];
        if (data is List) {
          productsList = data;
        } else if (data is Map) {
          productsList =
              (data['data'] ?? data['products'] ?? data['items'] ?? []) as List;
        }
        setState(() {
          _products = productsList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _getPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  void _navigateToProductDetails(Map<String, dynamic> product) {
    final String slug = product['slug']?.toString() ?? '';
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('عذراً، لا يمكن عرض تفاصيل هذا المنتج',
              style: GoogleFonts.cairo()),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }
    final storageService = widget.authService.storageService;
    final apiService = ApiService(storageService: storageService);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productSlug: slug,
          apiService: apiService,
          authService: widget.authService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F7FA)],
            ),
          ),
          child: Column(
            children: [
              ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) =>
                                        Transform.scale(
                                      scale:
                                          1.0 + (_pulseController.value * 0.1),
                                      child: child,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_getIcon(),
                                          color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _getTitle(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _search = value;
                      _loadProducts();
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(Icons.search_rounded, color: color, size: 20),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator(color)
                    : _products.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];

                              final bool isSyp = _isSypPreferred;
                              final price = isSyp
                                  ? _getPrice(product['final_price_syp'] ??
                                      product['price_syp'])
                                  : _getPrice(product['final_price'] ??
                                      product['price']);
                              final discountPrice = isSyp
                                  ? _getPrice(product['discount_price_syp'])
                                  : _getPrice(product['discount_price']);
                              final finalPrice =
                                  discountPrice > 0 ? discountPrice : price;

                              return _buildProductCard(product, finalPrice,
                                  price, discountPrice, color, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, double finalPrice,
      double price, double discountPrice, Color color, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToProductDetails(product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade50,
                  child: product['main_image'] != null
                      ? Image.network(
                          product['main_image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(_getIcon(), color: Colors.grey.shade400),
                        )
                      : Icon(_getIcon(), color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name_ar'] ?? product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkColor),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _fmt(finalPrice),
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                        ),
                        if (discountPrice > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _fmt(price),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showQuantityDialog(
                    product, finalPrice, price, discountPrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('اختيار',
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color)),
          const SizedBox(height: 16),
          Text('جاري التحميل...',
              style: GoogleFonts.cairo(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIcon(), size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('لا توجد منتجات',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> product, double finalPrice,
      double price, double discountPrice) {
    int quantity = 1;
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    final int stock = product['stock'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(_getIcon(), color: _getColor()),
              const SizedBox(width: 12),
              Expanded(
                child: Text('اختر الكمية',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(product['name_ar'] ?? product['name'] ?? '',
                        style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('السعر: ${_fmt(finalPrice)}',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.grey.shade600)),
                    if (discountPrice > 0)
                      Text(_fmt(price),
                          style: GoogleFonts.cairo(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.red)),
                    if (stock > 0) ...[
                      const SizedBox(height: 4),
                      Text('المتاح: $stock قطعة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (quantity > 1) {
                          setDialogState(() {
                            quantity--;
                            quantityController.text = '$quantity';
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_rounded),
                      color:
                          quantity > 1 ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 70,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: _getColor(), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: _getColor().withOpacity(0.05),
                    ),
                    child: TextFormField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkColor),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed <= 0) return;
                        if (stock > 0 && parsed > stock) {
                          setDialogState(() {
                            quantity = stock;
                            quantityController.text = '$stock';
                          });
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('الكمية المتاحة: $stock فقط',
                                    style: GoogleFonts.cairo(fontSize: 13)),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                        } else {
                          setDialogState(() => quantity = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (stock > 0 && quantity >= stock) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text('الكمية المتاحة: $stock فقط',
                                    style: GoogleFonts.cairo(fontSize: 13)),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          return;
                        }
                        setDialogState(() {
                          quantity++;
                          quantityController.text = '$quantity';
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('المجموع: ${_fmt(quantity * finalPrice)}',
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getColor())),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: GoogleFonts.cairo(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSelected(product, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('تأكيد الاختيار',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
