// lib/screens/system_builder/auto_design_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/services/system_builder_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';

class AutoDesignScreen extends StatefulWidget {
  final AuthService authService;
  final SystemBuilderService service;

  const AutoDesignScreen({
    super.key,
    required this.authService,
    required this.service,
  });

  @override
  State<AutoDesignScreen> createState() => _AutoDesignScreenState();
}

class _AutoDesignScreenState extends State<AutoDesignScreen> {
  final _budgetMinController = TextEditingController(text: '500');
  final _budgetMaxController = TextEditingController(text: '2000');
  final _sunHoursController = TextEditingController(text: '5');
  final _notesController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _devicePowerController = TextEditingController();
  final _deviceDayHoursController = TextEditingController();
  final _deviceNightHoursController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  List<DeviceItem> _devices = [];
  List<DeviceGroup> _groups = [];
  bool _isLoading = false;
  bool _isSendingToSupport = false;
  bool _showHumanDesignForm = false;
  Map<String, dynamic>? _result;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color dayColor = Color(0xFFF59E0B);
  static const Color nightColor = Color(0xFF6366F1);

  final List<Map<String, dynamic>> _suggestedDevices = [
    {'name': 'مكيف 1 طن', 'power': 1200, 'icon': Icons.ac_unit_rounded},
    {'name': 'مكيف 1.5 طن', 'power': 1800, 'icon': Icons.ac_unit_rounded},
    {'name': 'ثلاجة', 'power': 200, 'icon': Icons.kitchen_rounded},
    {'name': 'فريزر', 'power': 300, 'icon': Icons.kitchen_rounded},
    {
      'name': 'غسالة',
      'power': 500,
      'icon': Icons.local_laundry_service_rounded
    },
    {'name': 'تلفزيون LED', 'power': 100, 'icon': Icons.tv_rounded},
    {'name': 'لابتوب', 'power': 65, 'icon': Icons.laptop_rounded},
    {'name': 'راوتر', 'power': 10, 'icon': Icons.router_rounded},
    {'name': 'مروحة', 'power': 60, 'icon': Icons.air_rounded},
    {'name': 'إضاءة غرفة', 'power': 50, 'icon': Icons.lightbulb_rounded},
    {'name': 'إضاءة منزل', 'power': 200, 'icon': Icons.light_rounded},
    {'name': 'مضخة ماء 1HP', 'power': 750, 'icon': Icons.water_rounded},
    {'name': 'سخان كهربائي', 'power': 1500, 'icon': Icons.water_drop_rounded},
    {'name': 'ميكرويف', 'power': 1000, 'icon': Icons.microwave_rounded},
    {'name': 'شاحن موبايل', 'power': 20, 'icon': Icons.phone_android_rounded},
  ];

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _sunHoursController.dispose();
    _notesController.dispose();
    _deviceNameController.dispose();
    _devicePowerController.dispose();
    _deviceDayHoursController.dispose();
    _deviceNightHoursController.dispose();
    _groupNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  double get _totalDayWattHours =>
      _devices.fold(0, (sum, d) => sum + (d.power * d.dayHours));
  double get _totalNightWattHours =>
      _devices.fold(0, (sum, d) => sum + (d.power * d.nightHours));
  double get _totalDailyConsumption =>
      _totalDayWattHours + _totalNightWattHours;

  void _addDevice() {
    final name = _deviceNameController.text.trim();
    final powerText = _devicePowerController.text.trim();
    final dayHoursText = _deviceDayHoursController.text.trim();
    final nightHoursText = _deviceNightHoursController.text.trim();
    if (name.isEmpty || powerText.isEmpty) {
      _showSnackBar('الرجاء تعبئة اسم الجهاز والقدرة', Colors.orange);
      return;
    }
    final power = double.tryParse(powerText);
    if (power == null || power <= 0) {
      _showSnackBar('الرجاء إدخال قدرة صحيحة', Colors.red);
      return;
    }
    final dayHours = double.tryParse(dayHoursText) ?? 0;
    final nightHours = double.tryParse(nightHoursText) ?? 0;
    if (dayHours == 0 && nightHours == 0) {
      _showSnackBar('الرجاء إدخال ساعات التشغيل', Colors.orange);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _devices.add(DeviceItem(
          name: name,
          power: power,
          dayHours: dayHours,
          nightHours: nightHours));
      _deviceNameController.clear();
      _devicePowerController.clear();
      _deviceDayHoursController.clear();
      _deviceNightHoursController.clear();
    });
  }

  void _addSuggestedDevice(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    setState(() {
      _deviceNameController.text = device['name'];
      _devicePowerController.text = device['power'].toString();
      _deviceDayHoursController.text = '1';
      _deviceNightHoursController.text = '0';
    });
  }

  void _removeDevice(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var group in _groups) {
        group.deviceIndices.remove(index);
        for (int i = 0; i < group.deviceIndices.length; i++) {
          if (group.deviceIndices[i] > index) group.deviceIndices[i]--;
        }
      }
      _devices.removeAt(index);
    });
  }

  void _showCreateGroupDialog({int? editGroupIndex}) {/* ... unchanged ... */}
  void _removeGroup(int index) {
    setState(() => _groups.removeAt(index));
  }

  Future<void> _designSystem() async {
    if (_devices.isEmpty) {
      _showSnackBar('أضف جهازاً واحداً على الأقل', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    final appliances = _devices
        .map((d) => {
              'name': d.name,
              'wattage': d.power.toInt(),
              'hours': ((d.dayHours + d.nightHours)).toInt(),
              'quantity': 1,
              'day_hours': d.dayHours,
              'night_hours': d.nightHours
            })
        .toList();
    final result = await widget.service.autoDesign(
        budgetMin: double.parse(_budgetMinController.text),
        budgetMax: double.parse(_budgetMaxController.text),
        appliances: appliances,
        sunHours: double.parse(_sunHoursController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null);
    setState(() {
      _isLoading = false;
      _result = result;
    });
    if (result['success'] == true) {
      _showSnackBar('تم تصميم منظومتك! 🎉', Colors.green);
    } else {
      _showSnackBar(result['message'] ?? 'فشل التصميم', Colors.red);
    }
  }

  Future<void> _sendToHumanSupport() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال الاسم', Colors.orange);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('الرجاء إدخال رقم الهاتف', Colors.orange);
      return;
    }
    if (_devices.isEmpty) {
      _showSnackBar('أضف جهازاً واحداً على الأقل', Colors.orange);
      return;
    }
    setState(() => _isSendingToSupport = true);
    final appliances = _devices
        .map((d) => {
              'name': d.name,
              'wattage': d.power.toInt(),
              'hours': ((d.dayHours + d.nightHours)).toInt(),
              'quantity': 1,
              'day_hours': d.dayHours,
              'night_hours': d.nightHours
            })
        .toList();
    final result = await widget.service.requestHumanDesign(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        budgetMin: double.parse(_budgetMinController.text),
        budgetMax: double.parse(_budgetMaxController.text),
        sunHours: int.parse(_sunHoursController.text),
        appliances: appliances,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        aiRecommendations:
            _result != null ? (_result!['data']?['recommendations']) : null);
    setState(() => _isSendingToSupport = false);
    if (result['success'] == true) {
      _showSnackBar(
          'تم إرسال طلبك لفريق الدعم! سنتواصل معك قريباً 📞', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(result['message'] ?? 'فشل الإرسال', Colors.red);
    }
  }

  void _applyToSystemBuilder(Map<String, dynamic> recommendations) {
    Navigator.pop(context, {
      'panels': (recommendations['panels'] as List?)
              ?.map((p) => {
                    'id': p['id'],
                    'name': p['name'],
                    'price': p['price'],
                    'quantity': p['quantity']
                  })
              .toList() ??
          [],
      'inverters': (recommendations['inverters'] as List?)
              ?.map((i) => {
                    'id': i['id'],
                    'name': i['name'],
                    'price': i['price'],
                    'quantity': i['quantity']
                  })
              .toList() ??
          [],
      'batteries': (recommendations['batteries'] as List?)
              ?.map((b) => {
                    'id': b['id'],
                    'name': b['name'],
                    'price': b['price'],
                    'quantity': b['quantity']
                  })
              .toList() ??
          [],
    });
  }

  void _addAllToCart(Map<String, dynamic> recommendations) {
    /* ... unchanged ... */
  }

  void _showFullAnalysis(String analysis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
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
                Text('تحليل المنظومة',
                    style: GoogleFonts.cairo(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ])),
          const Divider(),
          Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(analysis,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.8,
                          color: Colors.grey.shade700)))),
        ]),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [primaryBlue, secondaryBlue]))),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 10),
          Text('صمم منظومتي',
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))
        ]),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading || _isSendingToSupport
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)),
                  const SizedBox(height: 16),
                  Text(
                      _isSendingToSupport
                          ? 'جاري إرسال طلبك...'
                          : 'جاري تصميم المنظومة...',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: Colors.grey.shade600))
                ]))
          : _result != null
              ? _buildResultView()
              : _buildInputView(),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'يمكنك التصميم بالذكاء الاصطناعي أو طلب تصميم من مهندس بشري. كلا الخيارين متاحين لك!',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.blue.shade700)))
              ])),
          _buildSectionCard(
              icon: Icons.monetization_on_rounded,
              title: 'الميزانية (\$)',
              color: Colors.green,
              child: Row(children: [
                Expanded(
                    child: _buildTextField(
                        controller: _budgetMinController, label: 'من')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        controller: _budgetMaxController, label: 'إلى'))
              ])),
          const SizedBox(height: 16),
          _buildSectionCard(
              icon: Icons.wb_sunny_rounded,
              title: 'ساعات الشمس اليومية',
              color: Colors.orange,
              child: _buildTextField(
                  controller: _sunHoursController,
                  label: 'عدد الساعات (عادة 5-6)')),
          const SizedBox(height: 16),
          _buildSectionCard(
              icon: Icons.devices_rounded,
              title: 'أجهزة شائعة (اضغط للإضافة)',
              color: Colors.blue,
              child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestedDevices.length,
                      itemBuilder: (context, index) {
                        final device = _suggestedDevices[index];
                        return GestureDetector(
                            onTap: () => _addSuggestedDevice(device),
                            child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(device['icon'] as IconData,
                                          size: 28, color: primaryBlue),
                                      const SizedBox(height: 6),
                                      Text(device['name'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text('${device['power']} واط',
                                          style: GoogleFonts.cairo(
                                              fontSize: 9, color: Colors.grey))
                                    ])));
                      }))),
          const SizedBox(height: 16),
          _buildSectionCard(
              icon: Icons.add_circle_outline_rounded,
              title: 'إضافة جهاز',
              color: primaryBlue,
              child: Column(children: [
                _buildTextField(
                    controller: _deviceNameController, label: 'اسم الجهاز'),
                const SizedBox(height: 10),
                _buildTextField(
                    controller: _devicePowerController,
                    label: 'القدرة (واط)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _buildTextField(
                          controller: _deviceDayHoursController,
                          label: 'ساعات النهار ☀️',
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField(
                          controller: _deviceNightHoursController,
                          label: 'ساعات الليل 🌙',
                          keyboardType: TextInputType.number))
                ]),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        onPressed: _addDevice,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text('إضافة الجهاز',
                            style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)))))
              ])),
          const SizedBox(height: 16),
          if (_devices.isNotEmpty) ...[
            _buildSectionCard(
                icon: Icons.checklist_rounded,
                title: 'الأجهزة المضافة (${_devices.length})',
                color: Colors.teal,
                child: Column(children: [
                  ...List.generate(_devices.length, (index) {
                    final device = _devices[index];
                    return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200)),
                        child: Row(children: [
                          Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    primaryBlue.withOpacity(0.1),
                                    secondaryBlue.withOpacity(0.05)
                                  ]),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text('${index + 1}',
                                      style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue)))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(device.name,
                                    style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text('${device.power.toStringAsFixed(0)} واط',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: Colors.grey)),
                                if (device.dayHours > 0 ||
                                    device.nightHours > 0)
                                  Row(children: [
                                    if (device.dayHours > 0)
                                      Row(children: [
                                        Icon(Icons.wb_sunny_rounded,
                                            size: 12, color: dayColor),
                                        const SizedBox(width: 3),
                                        Text('${device.dayHours}h',
                                            style: GoogleFonts.cairo(
                                                fontSize: 10, color: dayColor))
                                      ]),
                                    if (device.dayHours > 0 &&
                                        device.nightHours > 0)
                                      const SizedBox(width: 8),
                                    if (device.nightHours > 0)
                                      Row(children: [
                                        Icon(Icons.nights_stay_rounded,
                                            size: 12, color: nightColor),
                                        const SizedBox(width: 3),
                                        Text('${device.nightHours}h',
                                            style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: nightColor))
                                      ])
                                  ])
                              ])),
                          IconButton(
                              onPressed: () => _removeDevice(index),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.red, size: 18))
                        ]));
                  }),
                  const Divider(),
                  _buildStatRow('استهلاك النهار',
                      '${_totalDayWattHours.toStringAsFixed(0)} واط/ساعة'),
                  _buildStatRow('استهلاك الليل',
                      '${_totalNightWattHours.toStringAsFixed(0)} واط/ساعة'),
                  _buildStatRow('الإجمالي اليومي',
                      '${_totalDailyConsumption.toStringAsFixed(0)} واط/ساعة',
                      bold: true),
                ])),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          _buildSectionCard(
              icon: Icons.note_rounded,
              title: 'ملاحظات (اختياري)',
              color: Colors.teal,
              child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                      hintText: 'مثال: منزل ريفي 3 غرف...',
                      hintStyle:
                          GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade50))),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                  onPressed: _devices.isEmpty ? null : _designSystem,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 24),
                  label: Text(
                      _devices.isEmpty
                          ? 'أضف جهازاً أولاً'
                          : 'صمم منظومتي بالذكاء الاصطناعي ✨',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _devices.isEmpty ? Colors.grey : primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 12),
          if (_devices.isNotEmpty) _buildHumanSupportSection(),
          const SizedBox(height: 40),
        ]));
  }

  Widget _buildHumanSupportSection() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.blue.withOpacity(0.05),
              Colors.indigo.withOpacity(0.05)
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.2))),
        child: Column(children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.blue, size: 24)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('هل تفضل التصميم البشري؟',
                      style: GoogleFonts.cairo(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('فريقنا الهندسي سيصمم لك المنظومة خصيصاً',
                      style:
                          GoogleFonts.cairo(fontSize: 11, color: Colors.grey))
                ]))
          ]),
          if (!_showHumanDesignForm) ...[
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showHumanDesignForm = true),
                    icon: const Icon(Icons.engineering_rounded, size: 18),
                    label: Text('اطلب تصميم من مهندس بشري',
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12))))
          ] else ...[
            const SizedBox(height: 16),
            _buildTextField(
                controller: _nameController, label: 'الاسم الكامل *'),
            const SizedBox(height: 10),
            _buildTextField(
                controller: _phoneController,
                label: 'رقم الهاتف *',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _buildTextField(
                controller: _emailController,
                label: 'البريد الإلكتروني (اختياري)',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _showHumanDesignForm = false),
                      child:
                          Text('إلغاء', style: GoogleFonts.cairo(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: _sendToHumanSupport,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text('إرسال الطلب',
                          style: GoogleFonts.cairo(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12))))
            ])
          ]
        ]));
  }

  Widget _buildResultView() {
    final data = _result!['data'];
    final recommendations = data['recommendations'];
    final stats = data['statistics'];

    final aiAnalysis = data['ai_analysis'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Colors.orange, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'هذه المنظومة صممت بواسطة الذكاء الاصطناعي. يرجى مراجعة التصميم مع مهندس مختص قبل الشراء.',
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          height: 1.5))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.purple.withOpacity(0.05),
                  Colors.blue.withOpacity(0.05)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.purple.withOpacity(0.2))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.purple.withOpacity(0.15),
                          Colors.blue.withOpacity(0.1)
                        ]),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.purple, size: 24)),
                const SizedBox(width: 12),
                Text('تحليل الذكاء الاصطناعي',
                    style: GoogleFonts.cairo(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _buildAISectionTitle(
                  Icons.tune_rounded, 'مواصفات النظام', Colors.blue),
              const SizedBox(height: 10),
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(children: [
                    _buildSpecRow(
                        Icons.bolt_rounded,
                        'فولتية النظام',
                        '${aiAnalysis['system_voltage'] ?? 12} فولت',
                        Colors.blue),
                    const Divider(height: 16),
                    _buildSpecRow(
                        Icons.solar_power_rounded,
                        'الإنتاج اليومي',
                        '${aiAnalysis['daily_production_wh'] ?? 0} Wh',
                        Colors.orange),
                    const Divider(height: 16),
                    _buildSpecRow(
                        Icons.battery_charging_full_rounded,
                        'ساعات التشغيل بالبطارية',
                        '${aiAnalysis['battery_backup_hours'] ?? 0} ساعة',
                        Colors.green),
                  ])),
              const SizedBox(height: 20),
              if ((aiAnalysis['explanation'] ?? '').isNotEmpty) ...[
                _buildAISectionTitle(
                    Icons.description_rounded, 'شرح التصميم', Colors.teal),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.teal.withOpacity(0.2))),
                    child: Text(aiAnalysis['explanation'] ?? '',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            height: 1.7,
                            color: Colors.grey.shade700))),
                const SizedBox(height: 20),
              ],
              if ((aiAnalysis['analysis'] ?? '').isNotEmpty) ...[
                _buildAISectionTitle(
                    Icons.analytics_rounded, 'تحليل المنظومة', Colors.purple),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.purple.withOpacity(0.2))),
                    child: Text(aiAnalysis['analysis'] ?? '',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            height: 1.7,
                            color: Colors.grey.shade700),
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis)),
                if ((aiAnalysis['analysis'] ?? '').length > 300)
                  TextButton.icon(
                      onPressed: () =>
                          _showFullAnalysis(aiAnalysis['analysis'] ?? ''),
                      icon: const Icon(Icons.open_in_full_rounded, size: 16),
                      label: Text('عرض التحليل كاملاً',
                          style: GoogleFonts.cairo(fontSize: 13))),
                const SizedBox(height: 20),
              ],
              if ((aiAnalysis['warnings'] as List?)?.isNotEmpty == true) ...[
                _buildAISectionTitle(
                    Icons.warning_amber_rounded, 'تحذيرات', Colors.orange),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3))),
                    child: Column(
                        children: (aiAnalysis['warnings'] as List)
                            .map((w) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_rounded,
                                          color: Colors.orange, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(w.toString(),
                                              style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  color: Colors.orange.shade800,
                                                  height: 1.5)))
                                    ])))
                            .toList())),
                const SizedBox(height: 20),
              ],
              if ((aiAnalysis['recommendations'] as List?)?.isNotEmpty ==
                  true) ...[
                _buildAISectionTitle(
                    Icons.lightbulb_rounded, 'توصيات للتحسين', Colors.green),
                const SizedBox(height: 10),
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3))),
                    child: Column(
                        children: (aiAnalysis['recommendations'] as List)
                            .asMap()
                            .entries
                            .map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Center(
                                              child: Text('${entry.key + 1}',
                                                  style: GoogleFonts.cairo(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green)))),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(entry.value.toString(),
                                              style: GoogleFonts.cairo(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                  height: 1.5)))
                                    ])))
                            .toList())),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          if ((recommendations['panels'] as List?)?.isNotEmpty == true ||
              (recommendations['inverters'] as List?)?.isNotEmpty == true ||
              (recommendations['batteries'] as List?)?.isNotEmpty == true)
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03), blurRadius: 10)
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.green.withOpacity(0.15),
                                  Colors.teal.withOpacity(0.08)
                                ]),
                                borderRadius: BorderRadius.circular(15)),
                            child: const Icon(Icons.shopping_cart_rounded,
                                color: Colors.green, size: 22)),
                        const SizedBox(width: 12),
                        Text('المنتجات الموصى بها',
                            style: GoogleFonts.cairo(
                                fontSize: 18, fontWeight: FontWeight.bold))
                      ]),
                      const SizedBox(height: 16),
                      if ((recommendations['panels'] as List?)?.isNotEmpty ==
                          true)
                        _buildProductSection('☀️ الألواح الشمسية',
                            recommendations['panels'], Colors.orange),
                      if ((recommendations['inverters'] as List?)?.isNotEmpty ==
                          true)
                        _buildProductSection('⚡ الانفرتر',
                            recommendations['inverters'], Colors.blue),
                      if ((recommendations['batteries'] as List?)?.isNotEmpty ==
                          true)
                        _buildProductSection('🔋 البطاريات',
                            recommendations['batteries'], Colors.green),
                      const SizedBox(height: 12),
                      Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [primaryBlue, secondaryBlue]),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الإجمالي التقديري',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14, color: Colors.white70)),
                                Text(
                                    '${(recommendations['total_cost'] ?? 0).toStringAsFixed(2)} \$',
                                    style: GoogleFonts.cairo(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber))
                              ])),
                    ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => setState(() => _result = null),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('إعادة التصميم',
                        style: GoogleFonts.cairo(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: BorderSide(color: primaryBlue.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => _applyToSystemBuilder(recommendations),
                    icon: const Icon(Icons.design_services_rounded, size: 18),
                    label: Text('فتح في المصمم',
                        style: GoogleFonts.cairo(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: () => _addAllToCart(recommendations),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text('أضف الكل إلى السلة',
                      style: GoogleFonts.cairo(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14)))),
          const SizedBox(height: 16),
          _buildHumanSupportSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAISectionTitle(IconData icon, String title, Color color) {
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.cairo(
              fontSize: 15, fontWeight: FontWeight.bold, color: color))
    ]);
  }

  Widget _buildSpecRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(
          child: Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: Colors.grey.shade600))),
      Text(value,
          style: GoogleFonts.cairo(
              fontSize: 15, fontWeight: FontWeight.bold, color: color))
    ]);
  }

  Widget _buildSectionCard(
      {required IconData icon,
      required String title,
      required Color color,
      required Widget child}) {
    return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 16, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 12),
          child
        ]));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(fontSize: 13),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.cairo(fontSize: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50));
  }

  Widget _buildProductSection(String title, List products, Color color) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...products.map((p) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  radius: 16,
                  child: Icon(Icons.inventory_2, color: color, size: 16)),
              title: Text('${p['quantity']}× ${p['name']}',
                  style: GoogleFonts.cairo(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              trailing: Text(
                  '${(p['price'] * (p['quantity'] ?? 1)).toStringAsFixed(2)} \$',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color))))
        ]));
  }

  Widget _buildStatRow(String label, String value, {bool bold = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style:
                  GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600))
        ]));
  }
}

class DeviceItem {
  final String name;
  final double power;
  final double dayHours;
  final double nightHours;
  DeviceItem(
      {required this.name,
      required this.power,
      this.dayHours = 0,
      this.nightHours = 0});
}

class DeviceGroup {
  String name;
  List<int> deviceIndices;
  DeviceGroup({required this.name, required this.deviceIndices});
}
