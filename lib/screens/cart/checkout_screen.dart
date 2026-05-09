import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:energy_store_app/services/cart_service.dart';
import 'package:energy_store_app/models/cart_item_model.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double totalPrice;
  final AuthService? authService;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalPrice,
    this.authService,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isLoading = false;
  double _discount = 0;
  double _shippingCost = 0;
  double _tax = 0;
  String _selectedPaymentMethod = 'cash';
  bool _showCouponField = false;
  bool _isCouponValid = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'الدفع عند الاستلام', 'icon': Icons.money, 'desc': 'ادفع نقداً عند استلام الطلب'},
    {'value': 'bank', 'label': 'تحويل بنكي', 'icon': Icons.account_balance, 'desc': 'حوالة مصرفية'},
    {'value': 'card', 'label': 'بطاقة ائتمان', 'icon': Icons.credit_card, 'desc': 'فيزا / ماستركارد'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.authService?.isAuthenticated == true) {
      final userData = widget.authService?.storageService.getUserDataMap();
      if (userData != null) {
        final fullName = (userData['name'] ?? '').toString().split(' ');
        if (fullName.isNotEmpty) {
          _firstNameController.text = fullName[0];
          if (fullName.length > 1) {
            _lastNameController.text = fullName.sublist(1).join(' ');
          }
        }
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
      }
    }
  }

  void _applyCoupon() {
    final coupon = _couponController.text.trim();
    if (coupon.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // ✅ محاكاة التحقق من الكوبون (يمكن ربطها مع API حقيقي)
    Future.delayed(const Duration(seconds: 1), () {
      if (coupon == 'WELCOME10') {
        setState(() {
          _discount = widget.totalPrice * 0.1;
          _isCouponValid = true;
          _isLoading = false;
          _showSnackBar('تم تطبيق الخصم 10% بنجاح!', Colors.green);
        });
      } else if (coupon == 'SAVE20') {
        setState(() {
          _discount = widget.totalPrice * 0.2;
          _isCouponValid = true;
          _isLoading = false;
          _showSnackBar('تم تطبيق الخصم 20% بنجاح!', Colors.green);
        });
      } else {
        setState(() {
          _discount = 0;
          _isCouponValid = false;
          _isLoading = false;
          _showSnackBar('رمز القسيمة غير صالح', Colors.red);
        });
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _discount = 0;
      _isCouponValid = false;
      _showCouponField = false;
    });
  }

  double get _subtotal => widget.totalPrice;
  double get _discountAmount => _discount;
  double get _shippingAmount => _shippingCost;
  double get _taxAmount => _tax;
  double get _grandTotal => _subtotal - _discountAmount + _shippingAmount + _taxAmount;

  void _submitOrder() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // ✅ محاكاة إرسال الطلب
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      _showOrderConfirmation();
    });
  }

  void _showOrderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 40, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              'تم استلام طلبك بنجاح!',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'شكراً لتسوقك معنا',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'رقم الطلب: #${DateTime.now().millisecondsSinceEpoch}',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إجمالي الطلب: ${Helpers.formatPrice(_grandTotal)}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'سيتم التواصل معك خلال 24 ساعة لتأكيد الطلب',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الحوار
              Navigator.pop(context); // العودة إلى السلة
              Navigator.pop(context); // العودة إلى الصفحة الرئيسية
              _showSnackBar('تم إرسال طلبك بنجاح! سنتواصل معك قريباً', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: Text('العودة إلى الرئيسية', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'تأكيد الطلب',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingOverlay()
          : Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // قائمة المنتجات
            SliverToBoxAdapter(
              child: _buildOrderSummary(),
            ),
            // معلومات التوصيل
            SliverToBoxAdapter(
              child: _buildShippingInfo(),
            ),
            // وسائل الدفع
            SliverToBoxAdapter(
              child: _buildPaymentMethods(),
            ),
            // ملاحظات إضافية
            SliverToBoxAdapter(
              child: _buildAdditionalNotes(),
            ),
            // تفاصيل السعر
            SliverToBoxAdapter(
              child: _buildPriceDetails(),
            ),
            // زر تأكيد الطلب
            SliverToBoxAdapter(
              child: _buildSubmitButton(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, size: 20, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 12),
              Text(
                'ملخص الطلب',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.items.length} منتجات',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length > 3 ? 3 : widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildOrderItem(item);
            },
          ),
          if (widget.items.length > 3) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'و ${widget.items.length - 3} منتجات أخرى',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 50,
            height: 50,
            child: item.image != null && item.image!.isNotEmpty
                ? Image.network(
              item.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported, size: 30),
              ),
            )
                : Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.shopping_bag, size: 30),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'الكمية: ${item.quantity} × ${Helpers.formatPrice(item.finalPrice)}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          Helpers.formatPrice(item.totalPrice),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping, size: 20, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textDirection: TextDirection.rtl,
                  decoration: _buildInputDecoration('الاسم الأول', Icons.person_outline),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textDirection: TextDirection.rtl,
                  decoration: _buildInputDecoration('الاسم الأخير', Icons.person_outline),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: _buildInputDecoration('رقم الهاتف', Icons.phone_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'مطلوب';
              if (!Helpers.isValidPhone(v)) return 'رقم غير صحيح';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            decoration: _buildInputDecoration('عنوان التوصيل', Icons.home_outlined),
            validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payment, size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Text(
                'وسيلة الدفع',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => RadioListTile<String>(
            value: method['value'],
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            title: Text(method['label'], style: GoogleFonts.cairo(fontWeight: FontWeight.w500)),
            subtitle: Text(method['desc'], style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
            secondary: Icon(method['icon'], color: const Color(0xFF4CAF50)),
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )),
        ],
      ),
    );
  }

  Widget _buildAdditionalNotes() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_add, size: 20, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Text(
                'ملاحظات إضافية',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: _buildInputDecoration('أضف ملاحظات (اختياري)', Icons.edit_note),
          ),
          const SizedBox(height: 16),
          // كود الخصم
          if (!_showCouponField && _discount == 0)
            TextButton.icon(
              onPressed: () => setState(() => _showCouponField = true),
              icon: const Icon(Icons.local_offer, size: 18),
              label: Text('لديك رمز خصم؟ اضغط هنا', style: GoogleFonts.cairo()),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
            ),
          if (_showCouponField || _discount > 0)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _isCouponValid ? Colors.green : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textDirection: TextDirection.ltr,
                      enabled: _discount == 0,
                      decoration: const InputDecoration(
                        hintText: 'رمز القسيمة',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  if (_discount > 0)
                    IconButton(
                      onPressed: _removeCoupon,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  if (_discount == 0)
                    ElevatedButton(
                      onPressed: _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('تطبيق'),
                    ),
                ],
              ),
            ),
          if (_isCouponValid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '✓ تم تطبيق الخصم بنجاح!',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt, size: 20, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل السعر',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow('المجموع الفرعي', Helpers.formatPrice(_subtotal)),
          if (_discountAmount > 0)
            _buildPriceRow('الخصم', '- ${Helpers.formatPrice(_discountAmount)}', isDiscount: true),
          _buildPriceRow('الشحن', Helpers.formatPrice(_shippingAmount)),
          _buildPriceRow('الضريبة', Helpers.formatPrice(_taxAmount)),
          const Divider(height: 24, thickness: 1),
          _buildPriceRow('الإجمالي', Helpers.formatPrice(_grandTotal), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.red : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF4CAF50) : (isDiscount ? Colors.red : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: _submitOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 22),
            const SizedBox(width: 10),
            Text(
              'تأكيد الطلب',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Helpers.formatPrice(_grandTotal),
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: const ModalBarrier(dismissible: false, color: Colors.black),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                const SizedBox(height: 16),
                Text(
                  'جاري تأكيد الطلب...',
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}