// lib/screens/system_builder/edit_system_order_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/system_builder_service.dart';
import 'package:GeniusHouse/screens/system_builder/system_builder_screen.dart';

class EditSystemOrderScreen extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> order;

  const EditSystemOrderScreen({
    super.key,
    required this.authService,
    required this.order,
  });

  @override
  State<EditSystemOrderScreen> createState() => _EditSystemOrderScreenState();
}

class _EditSystemOrderScreenState extends State<EditSystemOrderScreen>
    with TickerProviderStateMixin {
  late SystemBuilderService _service;

  // ✅ المكونات
  List<Map<String, dynamic>> _selectedPanels = [];
  List<Map<String, dynamic>> _selectedInverters = [];
  List<Map<String, dynamic>> _selectedBatteries = [];
  List<Map<String, dynamic>> _selectedCables = [];
  List<Map<String, dynamic>> _selectedPanelBoards = [];

  // ✅ معلومات التوصيل
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _userNotesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ✅ الدفع
  String _selectedPaymentMethod = 'cash';
  bool _isPrepaid = false;
  double _prepaidPercentage = 0;
  String _installationPrice = '0.00';

  bool _isSubmitting = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color gold = Color(0xFFFFD700);

  late AnimationController _pulseAnimationController;

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
      'value': 'card',
      'label': 'بطاقة ائتمان',
      'icon': Icons.credit_card_rounded,
      'color': Colors.purple,
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
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadOrderData();
    _fetchInstallationPrice();
    _fetchPrepaidPercentage();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _shippingAddressController.dispose();
    _userNotesController.dispose();
    _notesController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  // ✅ تحميل بيانات الطلب
  void _loadOrderData() {
    final order = widget.order;

    // تحميل المكونات
    _selectedPanels = _parseItems(order['panels']);
    _selectedInverters = _parseItems(order['inverters']);
    _selectedBatteries = _parseItems(order['batteries']);
    _selectedCables = _parseItems(order['cables']);
    _selectedPanelBoards = _parseItems(order['panel_boards']);

    // تحميل معلومات التوصيل
    _fullNameController.text = order['full_name'] ?? '';
    _phoneController.text = order['phone'] ?? '';
    _shippingAddressController.text = order['shipping_address'] ?? '';
    _userNotesController.text = order['user_notes'] ?? '';
    _notesController.text = order['notes'] ?? '';

    // تحميل الدفع
    _selectedPaymentMethod = order['payment_method'] ?? 'cash';
    _isPrepaid = order['is_prepaid'] == true || order['is_prepaid'] == 1;
  }

  // ✅ تحويل المكونات من JSON إلى List
  List<Map<String, dynamic>> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is List) {
      return items.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (items is String) {
      try {
        final decoded = jsonDecode(items);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> _fetchInstallationPrice() async {
    final result = await _service.getInstallationPrice();
    if (result['success'] == true && mounted) {
      setState(() {
        _installationPrice = result['formatted_value'] ?? '0.00';
      });
    }
  }

  Future<void> _fetchPrepaidPercentage() async {
    final result = await _service.getPrepaidPercentage();
    if (mounted) {
      setState(() {
        _prepaidPercentage = result['value'] ?? 0;
      });
    }
  }

  double _getPrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) return double.tryParse(price) ?? 0.0;
    if (price is num) return price.toDouble();
    return 0.0;
  }

  double get _installationPriceValue => double.tryParse(_installationPrice) ?? 0;

  double get _subtotal {
    double total = 0;
    for (var panel in _selectedPanels)
      total += _getPrice(panel['price']) * (panel['quantity'] ?? 1);
    for (var inverter in _selectedInverters)
      total += _getPrice(inverter['price']) * (inverter['quantity'] ?? 1);
    for (var battery in _selectedBatteries)
      total += _getPrice(battery['price']) * (battery['quantity'] ?? 1);
    for (var cable in _selectedCables)
      total += _getPrice(cable['price']) * (cable['quantity'] ?? 1);
    for (var panelBoard in _selectedPanelBoards)
      total += _getPrice(panelBoard['price']) * (panelBoard['quantity'] ?? 1);
    return total;
  }

  double get _prepaidBaseAmount => _subtotal + _installationPriceValue;

  double get _prepaidDiscountAmount {
    if (!_isPrepaid || _prepaidPercentage <= 0) return 0;
    return _prepaidBaseAmount * (_prepaidPercentage / 100);
  }

  // ✅ تعديل: يكفي وجود مكون واحد على الأقل
  bool get _isComplete =>
      _selectedPanels.isNotEmpty ||
          _selectedInverters.isNotEmpty ||
          _selectedBatteries.isNotEmpty ||
          _selectedCables.isNotEmpty ||
          _selectedPanelBoards.isNotEmpty;

  // ✅ المكونات الأساسية الناقصة
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

  // ✅ دالة عرض تحذير المكونات الناقصة
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
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تنبيه',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
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
                style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF111827), fontWeight: FontWeight.w600),
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
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
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
            child: Text('إكمال المنظومة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('المتابعة بدونها', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ✅ إضافة منتج
  void _addItem(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPickerScreen(
          type: type,
          authService: widget.authService,
          onSelected: (product, quantity) {
            setState(() {
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
              final existingIndex = list.indexWhere((p) => p['id'] == product['id']);
              final price = getPrice(product['final_price'] ?? product['price']);
              final discountPrice = getPrice(product['discount_price']);
              final finalPrice = discountPrice > 0 ? discountPrice : price;
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
          },
        ),
      ),
    );
  }

  // ✅ تحديث الكمية
  void _updateQuantity(List<Map<String, dynamic>> list, Map<String, dynamic> item, int delta) {
    setState(() {
      final newQty = (item['quantity'] ?? 1) + delta;
      if (newQty <= 0) {
        list.remove(item);
      } else {
        item['quantity'] = newQty;
      }
    });
  }

  // ✅ تعيين الكمية مباشرة من حقل الإدخال
  void _setQuantity(List<Map<String, dynamic>> list, Map<String, dynamic> item, String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        item['quantity'] = parsed;
      });
    }
  }

  // ✅ إزالة منتج
  void _removeItem(List<Map<String, dynamic>> list, Map<String, dynamic> item) {
    setState(() {
      list.remove(item);
    });
  }

  // ✅ إرسال التعديل
  Future<void> _submitUpdate() async {
    if (!_isComplete) {
      _showSnackBar('يرجى اختيار مكون واحد على الأقل', Colors.orange);
      return;
    }

    final shouldContinue = await _showMissingComponentsWarning();
    if (!shouldContinue) return;

    if (!_isDeliveryInfoValid) {
      _showSnackBar('يرجى تعبئة معلومات التوصيل', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.updateOrder(
      orderId: widget.order['id'],
      panels: _selectedPanels,
      inverters: _selectedInverters,
      batteries: _selectedBatteries,
      cables: _selectedCables,
      panelBoards: _selectedPanelBoards,
      notes: _notesController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      userNotes: _userNotesController.text.trim(),
      isPrepaid: _isPrepaid,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        _showSnackBar('تم تحديث الطلب بنجاح 🎉', Colors.green);
        Navigator.pop(context, true);
      } else {
        if (result['compatibility'] != null && !result['compatibility']['compatible']) {
          _showIncompatibilityDialog(result['compatibility']);
        } else {
          _showSnackBar(result['message'] ?? 'فشل تحديث الطلب', Colors.red);
        }
      }
    }
  }

  void _showIncompatibilityDialog(Map<String, dynamic> compatibility) {
    final issues = List<String>.from(compatibility['issues'] ?? []);
    final warnings = List<String>.from(compatibility['warnings'] ?? []);
    final summary = compatibility['summary'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('⚠️ المكونات غير متوافقة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary.isNotEmpty) ...[
                Text(summary, style: GoogleFonts.cairo(fontSize: 13, color: darkColor)),
                const SizedBox(height: 12),
              ],
              if (issues.isNotEmpty) ...[
                Text('❌ مشاكل:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 6),
                ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $issue', style: GoogleFonts.cairo(fontSize: 12, color: Colors.red.shade700)),
                )),
                const SizedBox(height: 12),
              ],
              if (warnings.isNotEmpty) ...[
                Text('⚠️ تحذيرات:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 6),
                ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $warning', style: GoogleFonts.cairo(fontSize: 12, color: Colors.orange.shade700)),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // ✅ بناء قسم المكونات
  // ✅ بناء قسم المكونات
  Widget _buildSelectedItems(String title, List<Map<String, dynamic>> items, Color color, String type) {
    final iconMap = {
      'الألواح الشمسية': Icons.solar_power_rounded,
      'الانفرتر': Icons.memory_rounded,
      'البطاريات': Icons.battery_charging_full_rounded,
      'الكابلات': Icons.cable_rounded,
      'تابلو الحماية': Icons.electrical_services_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconMap[title] ?? Icons.category_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
                ],
              ),
              Container(
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: TextButton.icon(
                  onPressed: () => _addItem(type),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text('إضافة', style: GoogleFonts.cairo(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: primaryBlue),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('لا توجد عناصر - اضغط "إضافة" للاختيار',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500)),
              ),
            )
          else
            ...items.map((item) {
              // ✅ إنشاء controller لكل عنصر
              final quantityController = TextEditingController(
                text: '${item['quantity'] ?? 1}',
              );

              return Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? 'غير معروف',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: darkColor)),
                          const SizedBox(height: 4),
                          Text('${_getPrice(item['price']).toStringAsFixed(2)} \$ × ${item['quantity']}',
                              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),

                    // ✅ أزرار + و - مع حقل الإدخال
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر النقصان
                          InkWell(
                            onTap: () {
                              final newQty = (item['quantity'] ?? 1) - 1;
                              if (newQty <= 0) {
                                _removeItem(items, item);
                              } else {
                                _updateQuantity(items, item, -1);
                                quantityController.text = '${item['quantity']}';
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.remove_rounded, size: 16, color: Colors.black87),
                            ),
                          ),

                          // ✅ حقل إدخال الكمية
                          Container(
                            width: 45,
                            height: 36,
                            alignment: Alignment.center,
                            child: TextFormField(
                              controller: quantityController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              onChanged: (value) {
                                _setQuantity(items, item, value);
                              },
                              onTap: () {
                                // ✅ تحديد النص عند الضغط
                                quantityController.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: quantityController.text.length,
                                );
                              },
                            ),
                          ),

                          // زر الزيادة
                          InkWell(
                            onTap: () {
                              _updateQuantity(items, item, 1);
                              quantityController.text = '${item['quantity']}';
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.add_rounded, size: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر الحذف
                    InkWell(
                      onTap: () => _removeItem(items, item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // ✅ بناء معلومات التوصيل
  Widget _buildDeliveryInfoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue.withOpacity(0.12), secondaryBlue.withOpacity(0.06)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text('معلومات التوصيل والدفع',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
            decoration: _buildInputDecoration('الاسم الكامل', Icons.person_rounded),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
            decoration: _buildInputDecoration('رقم الهاتف', Icons.phone_rounded),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shippingAddressController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
            decoration: _buildInputDecoration('عنوان التوصيل', Icons.home_rounded),
          ),
          const SizedBox(height: 16),
          Text('وسيلة الدفع', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor)),
          const SizedBox(height: 10),
          ..._paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method['value'];
            final color = method['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedPaymentMethod = method['value'] as String);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(method['icon'] as IconData, size: 20, color: isSelected ? color : Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(method['label'] as String,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? darkColor : Colors.grey.shade600)),
                      ),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextFormField(
            controller: _userNotesController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
            decoration: _buildInputDecoration('ملاحظات إضافية (اختياري)', Icons.note_rounded),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryBlue, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ✅ ملخص التكلفة
  Widget _buildCostSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.withOpacity(0.05), Colors.blue.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 24),
              const SizedBox(width: 10),
              Text('ملخص التكلفة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkColor)),
            ],
          ),
          const SizedBox(height: 16),
          _buildCostRow('المجموع الفرعي', '${_subtotal.toStringAsFixed(2)} \$', false),
          const SizedBox(height: 8),
          _buildCostRow('سعر التركيب', '$_installationPrice \$', false),
          if (_isPrepaid && _prepaidPercentage > 0) ...[
            const SizedBox(height: 8),
            _buildCostRow('خصم الدفع المسبق (${_prepaidPercentage.toStringAsFixed(0)}%)', '- ${_prepaidDiscountAmount.toStringAsFixed(2)} \$', true, Colors.green),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildCostRow('الإجمالي النهائي', '${(_prepaidBaseAmount - (_isPrepaid ? _prepaidDiscountAmount : 0)).toStringAsFixed(2)} \$', true, primaryBlue),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, bool isBold, [Color? color]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: darkColor)),
        Text(value, style: GoogleFonts.cairo(fontSize: isBold ? 18 : 14, fontWeight: FontWeight.bold, color: color ?? (isBold ? primaryBlue : darkColor))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [primaryBlue, secondaryBlue]),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, child) => Transform.scale(
                scale: 1.0 + (_pulseAnimationController.value * 0.1),
                child: child,
              ),
              child: const Icon(Icons.edit_rounded, color: gold, size: 24),
            ),
            const SizedBox(width: 10),
            Text('تعديل الطلب', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)),
            const SizedBox(height: 16),
            Text('جاري تحديث الطلب...', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ رقم الطلب
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_rounded, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text('رقم الطلب: ${widget.order['order_number'] ?? widget.order['id']}',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ المكونات
            _buildSelectedItems('الألواح الشمسية', _selectedPanels, Colors.orange, 'panels'),
            _buildSelectedItems('الانفرتر', _selectedInverters, Colors.blue, 'inverters'),
            _buildSelectedItems('البطاريات', _selectedBatteries, Colors.green, 'batteries'),
            _buildSelectedItems('الكابلات', _selectedCables, Colors.purple, 'Cables'),
            _buildSelectedItems('تابلو الحماية', _selectedPanelBoards, Colors.teal, 'Panel'),

            // ✅ معلومات التوصيل
            _buildDeliveryInfoSection(),

            // ✅ ملخص التكلفة
            _buildCostSummary(),

            const SizedBox(height: 20),

            // ✅ زر التحديث
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isComplete ? _submitUpdate : null,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: Text('تحديث الطلب', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isComplete ? primaryBlue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: _isComplete ? 8 : 0,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}