// lib/screens/chat/governorate_picker.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GovernoratePicker extends StatelessWidget {
  final String? selectedGovernorate;
  final Function(String) onSelected;

  const GovernoratePicker({
    super.key,
    this.selectedGovernorate,
    required this.onSelected,
  });

  final List<String> governorates = const [
    'دمشق',
    'ريف دمشق',
    'حلب',
    'حمص',
    'حماة',
    'اللاذقية',
    'طرطوس',
    'إدلب',
    'دير الزور',
    'الحسكة',
    'الرقة',
    'درعا',
    'السويداء',
    'القنيطرة'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر المحافظة',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'تساعدنا المحافظة في تقديم حسابات دقيقة تناسب منطقتك',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: governorates.map((gov) {
              final isSelected = gov == selectedGovernorate;
              return FilterChip(
                label: Text(gov, style: GoogleFonts.cairo()),
                selected: isSelected,
                onSelected: (_) => onSelected(gov),
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green,
                labelStyle: GoogleFonts.cairo(
                  color: isSelected ? Colors.green.shade700 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
