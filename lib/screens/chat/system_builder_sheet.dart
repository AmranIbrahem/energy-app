// lib/screens/chat/system_builder_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemBuilderSheet extends StatefulWidget {
  final Function(String message) onSend;

  const SystemBuilderSheet({
    super.key,
    required this.onSend,
  });

  @override
  State<SystemBuilderSheet> createState() => _SystemBuilderSheetState();
}

class _SystemBuilderSheetState extends State<SystemBuilderSheet> {
  final List<DeviceItem> _devices = [];
  final List<DeviceGroup> _groups = [];
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _devicePowerController = TextEditingController();
  final TextEditingController _deviceDayHoursController = TextEditingController();
  final TextEditingController _deviceNightHoursController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();


  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color dayColor = Color(0xFFF59E0B);
  static const Color nightColor = Color(0xFF6366F1);

  final List<Map<String, dynamic>> _suggestedDevices = [
    {'name': 'مكيف 1 طن', 'power': 1200, 'icon': Icons.ac_unit_rounded},
    {'name': 'مكيف 1.5 طن', 'power': 1800, 'icon': Icons.ac_unit_rounded},
    {'name': 'مكيف 2 طن', 'power': 2400, 'icon': Icons.ac_unit_rounded},
    {'name': 'ثلاجة', 'power': 200, 'icon': Icons.kitchen_rounded},
    {'name': 'فريزر', 'power': 300, 'icon': Icons.kitchen_rounded},
    {'name': 'غسالة', 'power': 500, 'icon': Icons.local_laundry_service_rounded},
    {'name': 'ميكرويف', 'power': 1000, 'icon': Icons.microwave_rounded},
    {'name': 'تلفزيون LED', 'power': 100, 'icon': Icons.tv_rounded},
    {'name': 'لابتوب', 'power': 65, 'icon': Icons.laptop_rounded},
    {'name': 'كمبيوتر مكتبي', 'power': 300, 'icon': Icons.desktop_windows_rounded},
    {'name': 'راوتر انترنت', 'power': 10, 'icon': Icons.router_rounded},
    {'name': 'شاحن موبايل', 'power': 20, 'icon': Icons.phone_android_rounded},
    {'name': 'سخان كهربائي', 'power': 1500, 'icon': Icons.water_drop_rounded},
    {'name': 'مروحة', 'power': 60, 'icon': Icons.air_rounded},
    {'name': 'مكنسة كهربائية', 'power': 800, 'icon': Icons.cleaning_services_rounded},
    {'name': 'مكواة', 'power': 1200, 'icon': Icons.iron_rounded},
    {'name': 'إضاءة غرفة', 'power': 50, 'icon': Icons.lightbulb_rounded},
    {'name': 'إضاءة منزل كامل', 'power': 200, 'icon': Icons.light_rounded},
    {'name': 'مضخة ماء 1HP', 'power': 750, 'icon': Icons.water_rounded},
    {'name': 'مضخة ماء 2HP', 'power': 1500, 'icon': Icons.water_rounded},
  ];

  @override
  void dispose() {
    _deviceNameController.dispose();
    _devicePowerController.dispose();
    _deviceDayHoursController.dispose();
    _deviceNightHoursController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _addDevice() {
    final name = _deviceNameController.text.trim();
    final powerText = _devicePowerController.text.trim();
    final dayHoursText = _deviceDayHoursController.text.trim();
    final nightHoursText = _deviceNightHoursController.text.trim();

    if (name.isEmpty || powerText.isEmpty) {
      _showSnackBar('الرجاء تعبئة اسم الجهاز والقدرة على الأقل', Colors.orange);
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
      _showSnackBar('الرجاء إدخال ساعات التشغيل في النهار أو الليل', Colors.orange);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _devices.add(DeviceItem(
        name: name,
        power: power,
        dayHours: dayHours,
        nightHours: nightHours,
      ));
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
          if (group.deviceIndices[i] > index) {
            group.deviceIndices[i]--;
          }
        }
      }
      _devices.removeAt(index);
    });
  }


  void _showCreateGroupDialog({int? editGroupIndex}) {
    final isEditing = editGroupIndex != null;
    List<int> selectedIndices = [];

    if (isEditing) {
      selectedIndices = List.from(_groups[editGroupIndex].deviceIndices);
      _groupNameController.text = _groups[editGroupIndex].name;
    } else {
      _groupNameController.clear();

      _groupNameController.text = 'مجموعة ${_groups.length + 1}';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'تعديل المجموعة' : 'إنشاء مجموعة أجهزة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _groupNameController,
                  style: GoogleFonts.cairo(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'اسم المجموعة',
                    hintStyle: GoogleFonts.cairo(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('اختر الأجهزة:', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'لا توجد أجهزة مضافة. أضف أجهزة أولاً.',
                      style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
                    ),
                  ),
                ...List.generate(_devices.length, (index) {
                  final device = _devices[index];
                  final isSelected = selectedIndices.contains(index);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedIndices.add(index);
                        } else {
                          selectedIndices.remove(index);
                        }
                      });
                    },
                    title: Text(device.name, style: GoogleFonts.cairo(fontSize: 13)),
                    subtitle: Row(
                      children: [
                        Text(
                          '${device.power.toStringAsFixed(0)} واط',
                          style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
                        ),
                        if (device.dayHours > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.wb_sunny_rounded, size: 12, color: dayColor),
                          const SizedBox(width: 2),
                          Text(
                            '${device.dayHours.toStringAsFixed(1)}س',
                            style: GoogleFonts.cairo(fontSize: 10, color: dayColor),
                          ),
                        ],
                        if (device.nightHours > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.nights_stay_rounded, size: 12, color: nightColor),
                          const SizedBox(width: 2),
                          Text(
                            '${device.nightHours.toStringAsFixed(1)}س',
                            style: GoogleFonts.cairo(fontSize: 10, color: nightColor),
                          ),
                        ],
                      ],
                    ),
                    activeColor: primaryBlue,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            if (isEditing)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeGroup(editGroupIndex);
                },
                child: Text('حذف المجموعة', style: GoogleFonts.cairo(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () {
                if (_groupNameController.text.trim().isEmpty) {
                  _showSnackBar('الرجاء إدخال اسم المجموعة', Colors.orange);
                  return;
                }
                if (selectedIndices.length < 2) {
                  _showSnackBar('الرجاء اختيار جهازين على الأقل', Colors.orange);
                  return;
                }
                setState(() {
                  if (isEditing) {
                    _groups[editGroupIndex].name = _groupNameController.text.trim();
                    _groups[editGroupIndex].deviceIndices = List.from(selectedIndices);
                  } else {
                    _groups.add(DeviceGroup(
                      name: _groupNameController.text.trim(),
                      deviceIndices: List.from(selectedIndices),
                    ));
                  }
                });
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _showSnackBar(
                  isEditing ? 'تم تعديل المجموعة بنجاح' : 'تم إنشاء المجموعة بنجاح',
                  Colors.green,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? 'حفظ التعديلات' : 'إنشاء', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  void _removeGroup(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _groups.removeAt(index));
    _showSnackBar('تم حذف المجموعة', Colors.red);
  }

  void _buildAndSendMessage() {
    if (_devices.isEmpty) {
      _showSnackBar('الرجاء إضافة جهاز واحد على الأقل', Colors.orange);
      return;
    }

    double totalDayWattHours = 0;
    double totalNightWattHours = 0;
    double totalPower = 0;

    final buffer = StringBuffer();
    buffer.writeln('أريد بناء منظومة طاقة شمسية للأجهزة التالية:');
    buffer.writeln();


    buffer.writeln('📋 قائمة الأجهزة:');
    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      final dayWattHours = device.power * device.dayHours;
      final nightWattHours = device.power * device.nightHours;
      totalDayWattHours += dayWattHours;
      totalNightWattHours += nightWattHours;
      totalPower += device.power;

      buffer.writeln('${i + 1}. ${device.name}:');
      buffer.writeln('   - القدرة: ${device.power.toStringAsFixed(0)} واط');
      if (device.dayHours > 0) {
        buffer.writeln('   - ساعات النهار: ${device.dayHours.toStringAsFixed(1)} ساعة (${dayWattHours.toStringAsFixed(0)} واط/ساعة)');
      }
      if (device.nightHours > 0) {
        buffer.writeln('   - ساعات الليل: ${device.nightHours.toStringAsFixed(1)} ساعة (${nightWattHours.toStringAsFixed(0)} واط/ساعة)');
      }
      buffer.writeln();
    }


    buffer.writeln('📊 الإحصائيات:');
    buffer.writeln('- عدد الأجهزة: ${_devices.length} جهاز');
    buffer.writeln('- إجمالي القدرة: ${totalPower.toStringAsFixed(0)} واط');
    buffer.writeln('- استهلاك النهار: ${totalDayWattHours.toStringAsFixed(0)} واط/ساعة');
    buffer.writeln('- استهلاك الليل: ${totalNightWattHours.toStringAsFixed(0)} واط/ساعة');
    buffer.writeln('- إجمالي الاستهلاك اليومي: ${(totalDayWattHours + totalNightWattHours).toStringAsFixed(0)} واط/ساعة');
    buffer.writeln();


    if (_groups.isNotEmpty) {
      buffer.writeln('🔗 مجموعات الأجهزة المتزامنة:');
      for (var group in _groups) {
        buffer.writeln('• ${group.name}:');
        double groupPower = 0;
        for (var index in group.deviceIndices) {
          if (index < _devices.length) {
            buffer.writeln('  - ${_devices[index].name} (${_devices[index].power.toStringAsFixed(0)} واط)');
            groupPower += _devices[index].power;
          }
        }
        buffer.writeln('  إجمالي قدرة المجموعة: ${groupPower.toStringAsFixed(0)} واط');
        buffer.writeln();
      }
    }

    buffer.writeln('ما هي المنظومة المناسبة لاحتياجاتي؟ مع حساب عدد الألواح والبطاريات المطلوبة والانفرتر.');

    widget.onSend(buffer.toString());
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(color == Colors.red ? Icons.error_rounded : Icons.info_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.solar_power_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بناء المنظومة الشمسية',
                          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('أضف أجهزتك مع توزيع ساعات النهار والليل',
                          style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),


          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text('أجهزة شائعة',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                  const SizedBox(height: 10),
                  SizedBox(
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
                              color: lightGray,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(device['icon'], size: 28, color: primaryBlue),
                                const SizedBox(height: 6),
                                Text(device['name'],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: darkColor)),
                                const SizedBox(height: 2),
                                Text('${device['power']} واط',
                                    style: GoogleFonts.cairo(fontSize: 9, color: mediumGray)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),


                  Text('إضافة جهاز',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                  const SizedBox(height: 12),


                  TextField(
                    controller: _deviceNameController,
                    style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
                    decoration: InputDecoration(
                      hintText: 'اسم الجهاز (مثال: مكيف، ثلاجة...)',
                      hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.devices_rounded, color: primaryBlue, size: 20),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),


                  TextField(
                    controller: _devicePowerController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
                    decoration: InputDecoration(
                      hintText: 'القدرة (واط)',
                      hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.bolt_rounded, color: primaryBlue, size: 20),
                      filled: true,
                      fillColor: lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),


                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deviceDayHoursController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
                          decoration: InputDecoration(
                            hintText: 'ساعات النهار ☀️',
                            hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.wb_sunny_rounded, color: dayColor, size: 20),
                            filled: true,
                            fillColor: lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _deviceNightHoursController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
                          decoration: InputDecoration(
                            hintText: 'ساعات الليل 🌙',
                            hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.nights_stay_rounded, color: nightColor, size: 20),
                            filled: true,
                            fillColor: lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),


                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addDevice,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('إضافة الجهاز',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                        shadowColor: primaryBlue.withOpacity(0.3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),


                  if (_devices.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('الأجهزة المضافة',
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue.withOpacity(0.08), secondaryBlue.withOpacity(0.04)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${_devices.length} أجهزة',
                              style: GoogleFonts.cairo(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_devices.length, (index) {
                      final device = _devices[index];
                      final dayWattHours = device.power * device.dayHours;
                      final nightWattHours = device.power * device.nightHours;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue.withOpacity(0.1), secondaryBlue.withOpacity(0.05)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text('${index + 1}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.name,
                                      style: GoogleFonts.cairo(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
                                  const SizedBox(height: 4),
                                  Text('${device.power.toStringAsFixed(0)} واط',
                                      style: GoogleFonts.cairo(fontSize: 11, color: mediumGray)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (device.dayHours > 0)
                                        Row(
                                          children: [
                                            Icon(Icons.wb_sunny_rounded, size: 12, color: dayColor),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${device.dayHours.toStringAsFixed(1)}س نهار (${dayWattHours.toStringAsFixed(0)} و.س)',
                                              style: GoogleFonts.cairo(fontSize: 10, color: dayColor),
                                            ),
                                          ],
                                        ),
                                      if (device.dayHours > 0 && device.nightHours > 0)
                                        const SizedBox(width: 8),
                                      if (device.nightHours > 0)
                                        Row(
                                          children: [
                                            Icon(Icons.nights_stay_rounded, size: 12, color: nightColor),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${device.nightHours.toStringAsFixed(1)}س ليل (${nightWattHours.toStringAsFixed(0)} و.س)',
                                              style: GoogleFonts.cairo(fontSize: 10, color: nightColor),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _removeDevice(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 20),


                  if (_devices.length >= 2) ...[
                    Row(
                      children: [
                        Text('مجموعات الأجهزة المتزامنة',
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor)),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showCreateGroupDialog(),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentBlue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.group_add_rounded, size: 16, color: primaryBlue),
                                  const SizedBox(width: 4),
                                  Text('إضافة مجموعة',
                                      style: GoogleFonts.cairo(fontSize: 11, color: primaryBlue, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_groups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Text(
                            'لم تقم بإنشاء مجموعات بعد. اضغط على "إضافة مجموعة" لتحديد الأجهزة التي تعمل معاً',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 11, color: mediumGray),
                          ),
                        ),
                      ),
                    ...List.generate(_groups.length, (index) {
                      final group = _groups[index];
                      double groupPower = 0;
                      for (var deviceIndex in group.deviceIndices) {
                        if (deviceIndex < _devices.length) {
                          groupPower += _devices[deviceIndex].power;
                        }
                      }
                      return GestureDetector(
                        onTap: () => _showCreateGroupDialog(editGroupIndex: index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accentBlue.withOpacity(0.3)),
                            boxShadow: [BoxShadow(color: accentBlue.withOpacity(0.05), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentBlue.withOpacity(0.2), accentBlue.withOpacity(0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(Icons.link_rounded, size: 18, color: primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(group.name,
                                              style: GoogleFonts.cairo(
                                                  fontSize: 13, fontWeight: FontWeight.w600, color: darkColor)),
                                        ),
                                        Icon(Icons.edit_rounded, size: 14, color: accentBlue),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${group.deviceIndices.length} أجهزة - إجمالي القدرة: ${groupPower.toStringAsFixed(0)} واط',
                                      style: GoogleFonts.cairo(fontSize: 10, color: mediumGray),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: group.deviceIndices.map((deviceIndex) {
                                        if (deviceIndex < _devices.length) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: accentBlue.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _devices[deviceIndex].name,
                                              style: GoogleFonts.cairo(fontSize: 10, color: primaryBlue),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _removeGroup(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),


          if (_devices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardWhite,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _buildAndSendMessage,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text('إرسال للمساعد الذكي',
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: primaryBlue.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DeviceItem {
  final String name;
  final double power;
  final double dayHours;
  final double nightHours;

  DeviceItem({
    required this.name,
    required this.power,
    this.dayHours = 0,
    this.nightHours = 0,
  });
}

class DeviceGroup {
  String name;
  List<int> deviceIndices;

  DeviceGroup({
    required this.name,
    required this.deviceIndices,
  });
}