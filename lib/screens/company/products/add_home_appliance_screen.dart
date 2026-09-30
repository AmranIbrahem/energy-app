// lib/screens/company/products/add_home_appliance_screen.dart

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

class HomeApplianceCategory {
  final String id;
  final String labelAr;
  final IconData icon;

  const HomeApplianceCategory({
    required this.id,
    required this.labelAr,
    required this.icon,
  });
}

class HomeApplianceField {
  final String id;
  final String labelAr;
  final String inputType;
  final List<String>? options;
  final List<String>? unitOptions;
  final bool isRequired;
  final String? visibleWhenField;
  final List<String>? visibleWhenValues;

  const HomeApplianceField({
    required this.id,
    required this.labelAr,
    required this.inputType,
    this.options,
    this.unitOptions,
    this.isRequired = false,
    this.visibleWhenField,
    this.visibleWhenValues,
  });
}

class HomeApplianceData {
  static const List<HomeApplianceCategory> categories = [
    HomeApplianceCategory(
        id: 'air_conditioners',
        labelAr: 'المكيفات',
        icon: Icons.ac_unit_rounded),
    HomeApplianceCategory(
        id: 'fans', labelAr: 'المراوح', icon: Icons.toys_rounded),
    HomeApplianceCategory(
        id: 'air_coolers', labelAr: 'مبردات الهواء', icon: Icons.air_rounded),
    HomeApplianceCategory(
        id: 'heaters',
        labelAr: 'المدافئ',
        icon: Icons.local_fire_department_rounded),
    HomeApplianceCategory(
        id: 'air_treatment',
        labelAr: 'تنقية وترطيب الهواء',
        icon: Icons.filter_alt_rounded),
    HomeApplianceCategory(
        id: 'refrigerators', labelAr: 'الثلاجات', icon: Icons.kitchen_rounded),
    HomeApplianceCategory(
        id: 'freezers', labelAr: 'المجمدات', icon: Icons.ac_unit_rounded),
    HomeApplianceCategory(
        id: 'water_dispensers',
        labelAr: 'برادات المياه',
        icon: Icons.water_drop_rounded),
    HomeApplianceCategory(
        id: 'washing_machines',
        labelAr: 'الغسالات',
        icon: Icons.local_laundry_service_rounded),
    HomeApplianceCategory(
        id: 'dryers', labelAr: 'نشافات الملابس', icon: Icons.dry_rounded),
    HomeApplianceCategory(
        id: 'dishwashers',
        labelAr: 'جلايات الصحون',
        icon: Icons.countertops_rounded),
    HomeApplianceCategory(
        id: 'ovens_cookers',
        labelAr: 'الأفران والمواقد',
        icon: Icons.outdoor_grill_rounded),
    HomeApplianceCategory(
        id: 'microwaves',
        labelAr: 'أفران الأمواج الدقيقة',
        icon: Icons.microwave_rounded),
    HomeApplianceCategory(
        id: 'kitchen_hoods',
        labelAr: 'شفاطات المطابخ',
        icon: Icons.wind_power_rounded),
    HomeApplianceCategory(
        id: 'small_cooking',
        labelAr: 'أجهزة الطبخ الصغيرة',
        icon: Icons.blender_rounded),
    HomeApplianceCategory(
        id: 'food_preparation',
        labelAr: 'الخلاطات ومحضرات الطعام',
        icon: Icons.blender_rounded),
    HomeApplianceCategory(
        id: 'juicers', labelAr: 'العصارات', icon: Icons.local_drink_rounded),
    HomeApplianceCategory(
        id: 'mixers_kneaders',
        labelAr: 'العجانات والخفاقات',
        icon: Icons.bakery_dining_rounded),
    HomeApplianceCategory(
        id: 'kettles',
        labelAr: 'غلايات المياه',
        icon: Icons.coffee_maker_rounded),
    HomeApplianceCategory(
        id: 'coffee_machines',
        labelAr: 'آلات القهوة',
        icon: Icons.coffee_rounded),
    HomeApplianceCategory(
        id: 'irons', labelAr: 'المكاوي', icon: Icons.iron_rounded),
    HomeApplianceCategory(
        id: 'vacuum_cleaners',
        labelAr: 'المكانس',
        icon: Icons.cleaning_services_rounded),
    HomeApplianceCategory(
        id: 'water_heaters',
        labelAr: 'سخانات المياه',
        icon: Icons.water_rounded),
    HomeApplianceCategory(
        id: 'televisions', labelAr: 'التلفزيونات', icon: Icons.tv_rounded),
  ];

  static const List<HomeApplianceField> commonFields = [
    HomeApplianceField(
      id: 'energy_source',
      labelAr: 'مصدر التشغيل',
      inputType: 'single_select',
      options: ['كهرباء', 'غاز', 'كهرباء وغاز', 'قابل للشحن'],
      isRequired: true,
    ),
    HomeApplianceField(
      id: 'rated_voltage',
      labelAr: 'جهد التشغيل',
      inputType: 'multi_select',
      options: ['12 فولت', '24 فولت', '110 فولت', '220 - 240 فولت'],
      isRequired: true,
      visibleWhenField: 'energy_source',
      visibleWhenValues: ['كهرباء', 'كهرباء وغاز', 'قابل للشحن'],
    ),
    HomeApplianceField(
      id: 'frequency',
      labelAr: 'تردد التشغيل',
      inputType: 'single_select',
      options: ['50 هرتز', '60 هرتز', '50 و60 هرتز'],
      isRequired: true,
      visibleWhenField: 'energy_source',
      visibleWhenValues: ['كهرباء', 'كهرباء وغاز'],
    ),
    HomeApplianceField(
      id: 'rated_input_power_w',
      labelAr: 'استطاعة الاستهلاك الاسمية',
      inputType: 'number_with_unit',
      unitOptions: ['واط'],
      isRequired: true,
      visibleWhenField: 'energy_source',
      visibleWhenValues: ['كهرباء', 'كهرباء وغاز'],
    ),
    HomeApplianceField(
      id: 'startup_power_w',
      labelAr: 'استطاعة البدء',
      inputType: 'number_with_unit',
      unitOptions: ['واط'],
      isRequired: false,
    ),
    HomeApplianceField(
      id: 'spec_source',
      labelAr: 'مصدر المواصفات',
      inputType: 'single_select',
      options: ['لوحة بيانات المنتج', 'دليل الشركة المصنعة', 'تصريح المورد'],
      isRequired: true,
    ),
  ];

  static const Map<String, List<String>> typeOptions = {
    'air_conditioners': ['جداري منفصل', 'أرضي', 'شباك', 'متنقل'],
    'fans': ['أرضية', 'جدارية', 'سقفية', 'مكتبية', 'عمودية'],
    'air_coolers': ['شخصي', 'غرفة', 'كبير'],
    'heaters': ['مروحية', 'زيتية', 'كوارتز', 'خزفية', 'غازية'],
    'air_treatment': ['منقي هواء', 'مرطب', 'مزيل رطوبة'],
    'refrigerators': [
      'باب واحد',
      'مجمدة علوية',
      'مجمدة سفلية',
      'بابان متجاوران',
      'أبواب متعددة'
    ],
    'freezers': ['صندوقية', 'عمودية'],
    'water_dispensers': ['تحميل علوي', 'تحميل سفلي', 'توصيل مباشر', 'مكتبي'],
    'washing_machines': ['تحميل أمامي', 'تحميل علوي', 'حوضان'],
    'dryers': ['بفتحة تهوية', 'تكثيف', 'مضخة حرارية'],
    'dishwashers': ['مستقلة', 'مدمجة', 'مكتبية'],
    'ovens_cookers': ['مستقل', 'فرن مدمج', 'سطح مدمج', 'فرن طاولة'],
    'microwaves': ['تسخين فقط', 'مع شواية', 'مع فرن حراري'],
    'kitchen_hoods': ['جداري', 'جزيرة', 'تحت الخزانة', 'مدمج'],
    'small_cooking': [
      'قلاية هوائية',
      'قدر ضغط كهربائي',
      'طباخ أرز',
      'شواية كهربائية',
      'صانعة شطائر',
      'محمصة'
    ],
    'food_preparation': ['خلاط إبريق', 'خلاط يدوي', 'مفرمة', 'محضرة طعام'],
    'juicers': ['حمضيات', 'طرد مركزي', 'عصر بطيء'],
    'mixers_kneaders': ['خفاقة يدوية', 'خفاقة ثابتة', 'عجانة'],
    'kettles': ['عادية', 'بدرجات حرارة', 'سفر'],
    'coffee_machines': [
      'تقطير',
      'إسبرسو',
      'كبسولات',
      'قهوة عربية',
      'آلية بالكامل'
    ],
    'irons': ['جافة', 'بخارية', 'محطة بخار', 'عمودية'],
    'vacuum_cleaners': ['عادية', 'عمودية', 'يدوية', 'روبوتية', 'رطبة وجافة'],
    'water_heaters': ['بخزان', 'فوري'],
    'televisions': ['متصل بالإنترنت', 'عادي'],
  };

  static const Map<String, List<HomeApplianceField>> specialFields = {
    'air_conditioners': [
      HomeApplianceField(
          id: 'operating_mode',
          labelAr: 'وضع التشغيل',
          inputType: 'single_select',
          options: ['تبريد فقط', 'تبريد وتدفئة'],
          isRequired: true),
      HomeApplianceField(
          id: 'cooling_capacity',
          labelAr: 'قدرة التبريد',
          inputType: 'number_with_unit',
          unitOptions: ['طن تبريد', 'وحدة حرارية في الساعة'],
          isRequired: true),
      HomeApplianceField(
          id: 'compressor_control',
          labelAr: 'نوع التحكم بالضاغط',
          inputType: 'single_select',
          options: ['ثابت السرعة', 'متغيّر السرعة']),
      HomeApplianceField(
          id: 'climate_class',
          labelAr: 'الفئة المناخية',
          inputType: 'single_select',
          options: [
            'مناخ معتدل',
            'مناخ حار',
            'مناخ شديد الحرارة',
            'غير مذكورة'
          ]),
      HomeApplianceField(
          id: 'phase',
          labelAr: 'نوع التغذية',
          inputType: 'single_select',
          options: ['أحادي الطور', 'ثلاثي الطور']),
      HomeApplianceField(
          id: 'heating_input_power_w',
          labelAr: 'استطاعة الاستهلاك عند التدفئة',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          visibleWhenField: 'operating_mode',
          visibleWhenValues: ['تبريد وتدفئة']),
      HomeApplianceField(
          id: 'energy_class',
          labelAr: 'تصنيف كفاءة الطاقة',
          inputType: 'single_select',
          options: [
            'أعلى كفاءة A+++',
            'عالية جداً A++',
            'عالية A+',
            'جيدة A',
            'متوسطة B',
            'منخفضة C أو أقل',
            'غير مذكور'
          ]),
    ],
    'fans': [
      HomeApplianceField(
          id: 'fan_diameter_in',
          labelAr: 'قطر المروحة',
          inputType: 'number_with_unit',
          unitOptions: ['بوصة'],
          isRequired: true),
      HomeApplianceField(
          id: 'speed_count',
          labelAr: 'عدد السرعات',
          inputType: 'number',
          isRequired: false),
      HomeApplianceField(
          id: 'oscillation', labelAr: 'تحريك تلقائي', inputType: 'boolean'),
      HomeApplianceField(
          id: 'fan_features',
          labelAr: 'ميزات التحكم',
          inputType: 'multi_select',
          options: ['جهاز تحكم', 'مؤقت', 'وضع نوم', 'بدون ميزات إضافية']),
    ],
    'air_coolers': [
      HomeApplianceField(
          id: 'water_tank_l',
          labelAr: 'سعة خزان الماء',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'speed_count', labelAr: 'عدد السرعات', inputType: 'number'),
      HomeApplianceField(
          id: 'airflow_m3_h',
          labelAr: 'معدل دفع الهواء',
          inputType: 'number_with_unit',
          unitOptions: ['متر مكعب في الساعة']),
      HomeApplianceField(
          id: 'cooler_features',
          labelAr: 'الميزات',
          inputType: 'multi_select',
          options: ['ترطيب', 'جهاز تحكم', 'مؤقت', 'مكان للثلج']),
    ],
    'heaters': [
      HomeApplianceField(
          id: 'max_heating_power_w',
          labelAr: 'الاستطاعة الحرارية القصوى',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['كهرباء', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'gas_heat_output',
          labelAr: 'قدرة التدفئة بالغاز',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط حراري', 'وحدة حرارية في الساعة'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['غاز', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'gas_supply',
          labelAr: 'مصدر الغاز',
          inputType: 'single_select',
          options: ['أسطوانة غاز', 'شبكة غاز', 'كلاهما'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['غاز', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'heat_level_count',
          labelAr: 'عدد مستويات الحرارة',
          inputType: 'number'),
      HomeApplianceField(
          id: 'thermostat', labelAr: 'منظم حرارة', inputType: 'boolean'),
      HomeApplianceField(
          id: 'safety_features',
          labelAr: 'وسائل الأمان',
          inputType: 'multi_select',
          options: [
            'فصل عند الانقلاب',
            'حماية من الحرارة الزائدة',
            'قطع الغاز عند انطفاء اللهب',
            'قفل أطفال',
            'غير مذكورة'
          ]),
    ],
    'air_treatment': [
      HomeApplianceField(
          id: 'coverage_area_m2',
          labelAr: 'مساحة التغطية',
          inputType: 'number_with_unit',
          unitOptions: ['متر مربع'],
          isRequired: true),
      HomeApplianceField(
          id: 'air_delivery_m3_h',
          labelAr: 'معدل معالجة الهواء',
          inputType: 'number_with_unit',
          unitOptions: ['متر مكعب في الساعة'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['منقي هواء', 'مزيل رطوبة']),
      HomeApplianceField(
          id: 'filter_types',
          labelAr: 'أنواع المرشحات',
          inputType: 'multi_select',
          options: ['مرشح أولي', 'جسيمات دقيقة', 'كربوني', 'قابل للغسل'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['منقي هواء']),
      HomeApplianceField(
          id: 'tank_capacity_l',
          labelAr: 'سعة الخزان',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['مرطب', 'مزيل رطوبة']),
      HomeApplianceField(
          id: 'noise_db',
          labelAr: 'مستوى الضجيج',
          inputType: 'number_with_unit',
          unitOptions: ['ديسيبل']),
    ],
    'refrigerators': [
      HomeApplianceField(
          id: 'net_capacity_l',
          labelAr: 'السعة الصافية',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'freezer_capacity_l',
          labelAr: 'سعة قسم التجميد',
          inputType: 'number_with_unit',
          unitOptions: ['لتر']),
      HomeApplianceField(
          id: 'cooling_system',
          labelAr: 'نظام التبريد',
          inputType: 'single_select',
          options: ['تبريد عادي', 'بلا جليد']),
      HomeApplianceField(
          id: 'compressor_control',
          labelAr: 'نوع التحكم بالضاغط',
          inputType: 'single_select',
          options: ['ثابت السرعة', 'متغيّر السرعة', 'غير مذكور']),
      HomeApplianceField(
          id: 'annual_energy_kwh',
          labelAr: 'استهلاك الطاقة السنوي',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي سنوياً']),
      HomeApplianceField(
          id: 'climate_class',
          labelAr: 'الفئة المناخية',
          inputType: 'multi_select',
          options: ['معتدل', 'شبه حار', 'حار', 'مجال موسع', 'غير مذكورة']),
      HomeApplianceField(
          id: 'noise_db',
          labelAr: 'مستوى الضجيج',
          inputType: 'number_with_unit',
          unitOptions: ['ديسيبل']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'freezers': [
      HomeApplianceField(
          id: 'net_capacity_l',
          labelAr: 'السعة الصافية',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'cooling_system',
          labelAr: 'نظام التبريد',
          inputType: 'single_select',
          options: ['تبريد عادي', 'بلا جليد']),
      HomeApplianceField(
          id: 'compressor_control',
          labelAr: 'نوع التحكم بالضاغط',
          inputType: 'single_select',
          options: ['ثابت السرعة', 'متغيّر السرعة', 'غير مذكور']),
      HomeApplianceField(
          id: 'annual_energy_kwh',
          labelAr: 'استهلاك الطاقة السنوي',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي سنوياً']),
      HomeApplianceField(
          id: 'freezing_capacity_kg_day',
          labelAr: 'قدرة التجميد',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوغرام خلال 24 ساعة']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'water_dispensers': [
      HomeApplianceField(
          id: 'water_functions',
          labelAr: 'وظائف الماء',
          inputType: 'multi_select',
          options: ['بارد', 'ساخن', 'عادي'],
          isRequired: true),
      HomeApplianceField(
          id: 'cold_tank_l',
          labelAr: 'سعة خزان الماء البارد',
          inputType: 'number_with_unit',
          unitOptions: ['لتر']),
      HomeApplianceField(
          id: 'hot_tank_l',
          labelAr: 'سعة خزان الماء الساخن',
          inputType: 'number_with_unit',
          unitOptions: ['لتر']),
      HomeApplianceField(
          id: 'cooling_power_w',
          labelAr: 'استطاعة التبريد',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          visibleWhenField: 'water_functions',
          visibleWhenValues: ['بارد']),
      HomeApplianceField(
          id: 'heating_power_w',
          labelAr: 'استطاعة التسخين',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          visibleWhenField: 'water_functions',
          visibleWhenValues: ['ساخن']),
      HomeApplianceField(
          id: 'cooling_method',
          labelAr: 'طريقة التبريد',
          inputType: 'single_select',
          options: ['بضاغط', 'إلكتروني'],
          visibleWhenField: 'water_functions',
          visibleWhenValues: ['بارد']),
      HomeApplianceField(
          id: 'child_lock',
          labelAr: 'قفل ماء ساخن للأطفال',
          inputType: 'boolean',
          visibleWhenField: 'water_functions',
          visibleWhenValues: ['ساخن']),
    ],
    'washing_machines': [
      HomeApplianceField(
          id: 'wash_capacity_kg',
          labelAr: 'سعة الغسيل',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوغرام'],
          isRequired: true),
      HomeApplianceField(
          id: 'spin_speed_rpm',
          labelAr: 'سرعة العصر',
          inputType: 'number_with_unit',
          unitOptions: ['دورة في الدقيقة']),
      HomeApplianceField(
          id: 'motor_control',
          labelAr: 'نوع المحرك',
          inputType: 'single_select',
          options: ['تقليدي', 'متغيّر السرعة', 'دفع مباشر', 'غير مذكور']),
      HomeApplianceField(
          id: 'has_dryer', labelAr: 'تحتوي تنشيفاً', inputType: 'boolean'),
      HomeApplianceField(
          id: 'dry_capacity_kg',
          labelAr: 'سعة التنشيف',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوغرام'],
          visibleWhenField: 'has_dryer',
          visibleWhenValues: ['true']),
      HomeApplianceField(
          id: 'energy_per_cycle_kwh',
          labelAr: 'استهلاك الكهرباء للدورة',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي للدورة']),
      HomeApplianceField(
          id: 'water_per_cycle_l',
          labelAr: 'استهلاك الماء للدورة',
          inputType: 'number_with_unit',
          unitOptions: ['لتر للدورة']),
      HomeApplianceField(
          id: 'wash_features',
          labelAr: 'الميزات الأساسية',
          inputType: 'multi_select',
          options: [
            'تسخين ماء',
            'بخار',
            'غسيل سريع',
            'قفل أطفال',
            'تنظيف الحوض'
          ]),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'dryers': [
      HomeApplianceField(
          id: 'dry_capacity_kg',
          labelAr: 'سعة التجفيف',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوغرام'],
          isRequired: true),
      HomeApplianceField(
          id: 'energy_per_cycle_kwh',
          labelAr: 'استهلاك الكهرباء للدورة',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي للدورة']),
      HomeApplianceField(
          id: 'energy_class',
          labelAr: 'تصنيف كفاءة الطاقة',
          inputType: 'single_select',
          options: ['عالية', 'متوسطة', 'منخفضة', 'غير مذكورة']),
      HomeApplianceField(
          id: 'moisture_sensor', labelAr: 'حساس جفاف', inputType: 'boolean'),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'dishwashers': [
      HomeApplianceField(
          id: 'place_settings',
          labelAr: 'عدد الأطقم',
          inputType: 'number_with_unit',
          unitOptions: ['طقم'],
          isRequired: true),
      HomeApplianceField(
          id: 'energy_per_cycle_kwh',
          labelAr: 'استهلاك الكهرباء للدورة',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوواط ساعي للدورة']),
      HomeApplianceField(
          id: 'water_per_cycle_l',
          labelAr: 'استهلاك الماء للدورة',
          inputType: 'number_with_unit',
          unitOptions: ['لتر للدورة']),
      HomeApplianceField(
          id: 'program_count', labelAr: 'عدد البرامج', inputType: 'number'),
      HomeApplianceField(
          id: 'drying_method',
          labelAr: 'طريقة التجفيف',
          inputType: 'single_select',
          options: ['طبيعي', 'حراري', 'بمروحة', 'غير مذكور']),
      HomeApplianceField(
          id: 'noise_db',
          labelAr: 'مستوى الضجيج',
          inputType: 'number_with_unit',
          unitOptions: ['ديسيبل']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'ovens_cookers': [
      HomeApplianceField(
          id: 'installation_type',
          labelAr: 'طريقة التركيب',
          inputType: 'single_select',
          options: ['مستقل', 'مدمج', 'على الطاولة'],
          isRequired: true),
      HomeApplianceField(
          id: 'gas_supply',
          labelAr: 'مصدر الغاز',
          inputType: 'single_select',
          options: ['أسطوانة غاز', 'شبكة غاز', 'كلاهما'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['غاز', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'burner_count',
          labelAr: 'عدد العيون',
          inputType: 'number',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['مستقل', 'سطح مدمج']),
      HomeApplianceField(
          id: 'oven_capacity_l',
          labelAr: 'سعة الفرن',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['مستقل', 'فرن مدمج', 'فرن طاولة']),
      HomeApplianceField(
          id: 'cooking_features',
          labelAr: 'وظائف الطهي',
          inputType: 'multi_select',
          options: ['شواية', 'توزيع هواء', 'سيخ دوار', 'مؤقت', 'تنظيف ذاتي']),
      HomeApplianceField(
          id: 'gas_safety',
          labelAr: 'أمان الغاز',
          inputType: 'multi_select',
          options: ['إشعال ذاتي', 'قطع الغاز عند انطفاء اللهب', 'غير مذكور'],
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['غاز', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'microwaves': [
      HomeApplianceField(
          id: 'installation_type',
          labelAr: 'طريقة التركيب',
          inputType: 'single_select',
          options: ['مستقل', 'مدمج'],
          isRequired: true),
      HomeApplianceField(
          id: 'capacity_l',
          labelAr: 'السعة',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'microwave_output_power_w',
          labelAr: 'استطاعة الطهي',
          inputType: 'number_with_unit',
          unitOptions: ['واط']),
      HomeApplianceField(
          id: 'grill_power_w',
          labelAr: 'استطاعة الشواية',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['مع شواية', 'مع فرن حراري']),
      HomeApplianceField(
          id: 'control_type',
          labelAr: 'طريقة التحكم',
          inputType: 'single_select',
          options: ['ميكانيكي', 'أزرار', 'لمس']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'kitchen_hoods': [
      HomeApplianceField(
          id: 'width_cm',
          labelAr: 'العرض',
          inputType: 'number_with_unit',
          unitOptions: ['سنتيمتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'extraction_m3_h',
          labelAr: 'قوة السحب',
          inputType: 'number_with_unit',
          unitOptions: ['متر مكعب في الساعة'],
          isRequired: true),
      HomeApplianceField(
          id: 'ventilation_mode',
          labelAr: 'طريقة التهوية',
          inputType: 'multi_select',
          options: ['طرد خارجي', 'تدوير داخلي']),
      HomeApplianceField(
          id: 'speed_count', labelAr: 'عدد السرعات', inputType: 'number'),
      HomeApplianceField(
          id: 'noise_db',
          labelAr: 'مستوى الضجيج',
          inputType: 'number_with_unit',
          unitOptions: ['ديسيبل']),
      HomeApplianceField(
          id: 'filter_type',
          labelAr: 'نوع المرشح',
          inputType: 'multi_select',
          options: ['معدني', 'كربوني', 'قابل للغسل']),
    ],
    'small_cooking': [
      HomeApplianceField(
          id: 'capacity_l',
          labelAr: 'السعة',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['قلاية هوائية', 'قدر ضغط كهربائي', 'طباخ أرز']),
      HomeApplianceField(
          id: 'basket_or_plate_count',
          labelAr: 'عدد السلال أو الصفائح',
          inputType: 'number',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['قلاية هوائية', 'شواية كهربائية', 'صانعة شطائر']),
      HomeApplianceField(
          id: 'slice_count',
          labelAr: 'عدد الشرائح',
          inputType: 'number',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['محمصة', 'صانعة شطائر']),
      HomeApplianceField(
          id: 'temperature_min_c',
          labelAr: 'أدنى درجة حرارة',
          inputType: 'number_with_unit',
          unitOptions: ['درجة مئوية']),
      HomeApplianceField(
          id: 'temperature_max_c',
          labelAr: 'أعلى درجة حرارة',
          inputType: 'number_with_unit',
          unitOptions: ['درجة مئوية']),
      HomeApplianceField(
          id: 'control_type',
          labelAr: 'طريقة التحكم',
          inputType: 'single_select',
          options: ['ميكانيكي', 'رقمي', 'لمس']),
      HomeApplianceField(
          id: 'cooking_features',
          labelAr: 'ميزات الاستخدام',
          inputType: 'multi_select',
          options: [
            'مؤقت',
            'أجزاء قابلة للفك',
            'أجزاء قابلة للجلي',
            'فصل تلقائي'
          ]),
    ],
    'food_preparation': [
      HomeApplianceField(
          id: 'container_capacity_l',
          labelAr: 'سعة الوعاء',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'speed_count', labelAr: 'عدد السرعات', inputType: 'number'),
      HomeApplianceField(
          id: 'pulse_mode', labelAr: 'تشغيل نبضي', inputType: 'boolean'),
      HomeApplianceField(
          id: 'container_material',
          labelAr: 'مادة الوعاء',
          inputType: 'single_select',
          options: ['بلاستيك', 'زجاج', 'معدن']),
      HomeApplianceField(
          id: 'attachments',
          labelAr: 'الملحقات',
          inputType: 'multi_select',
          options: ['مطحنة', 'خفاقة', 'عجانة صغيرة', 'شرائح', 'مبشرة']),
      HomeApplianceField(
          id: 'ice_crushing', labelAr: 'تكسير الثلج', inputType: 'boolean'),
    ],
    'juicers': [
      HomeApplianceField(
          id: 'juice_container_l',
          labelAr: 'سعة وعاء العصير',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'speed_count', labelAr: 'عدد السرعات', inputType: 'number'),
      HomeApplianceField(
          id: 'pulp_separation',
          labelAr: 'فصل اللب',
          inputType: 'boolean',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['طرد مركزي', 'عصر بطيء']),
      HomeApplianceField(
          id: 'reverse_rotation',
          labelAr: 'دوران عكسي',
          inputType: 'boolean',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['عصر بطيء']),
      HomeApplianceField(
          id: 'feed_chute_mm',
          labelAr: 'عرض فتحة الإدخال',
          inputType: 'number_with_unit',
          unitOptions: ['مليمتر'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['طرد مركزي', 'عصر بطيء']),
    ],
    'mixers_kneaders': [
      HomeApplianceField(
          id: 'bowl_capacity_l',
          labelAr: 'سعة الوعاء',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true,
          visibleWhenField: 'product_type',
          visibleWhenValues: ['خفاقة ثابتة', 'عجانة']),
      HomeApplianceField(
          id: 'speed_count', labelAr: 'عدد السرعات', inputType: 'number'),
      HomeApplianceField(
          id: 'attachments',
          labelAr: 'الملحقات',
          inputType: 'multi_select',
          options: ['مضرب', 'خطاف عجين', 'خافق', 'خلاط', 'مطحنة']),
      HomeApplianceField(
          id: 'max_dough_kg',
          labelAr: 'أقصى كمية عجين',
          inputType: 'number_with_unit',
          unitOptions: ['كيلوغرام'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['عجانة', 'خفاقة ثابتة']),
    ],
    'kettles': [
      HomeApplianceField(
          id: 'capacity_l',
          labelAr: 'السعة',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'body_material',
          labelAr: 'مادة الجسم',
          inputType: 'single_select',
          options: ['بلاستيك', 'زجاج', 'فولاذ مقاوم للصدأ']),
      HomeApplianceField(
          id: 'temperature_control',
          labelAr: 'اختيار درجة الحرارة',
          inputType: 'boolean'),
      HomeApplianceField(
          id: 'auto_off', labelAr: 'فصل تلقائي', inputType: 'boolean'),
      HomeApplianceField(
          id: 'dry_boil_protection',
          labelAr: 'حماية من التشغيل دون ماء',
          inputType: 'boolean'),
    ],
    'coffee_machines': [
      HomeApplianceField(
          id: 'water_tank_l',
          labelAr: 'سعة خزان الماء',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'pump_pressure_bar',
          labelAr: 'ضغط المضخة',
          inputType: 'number_with_unit',
          unitOptions: ['بار'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['إسبرسو', 'آلية بالكامل']),
      HomeApplianceField(
          id: 'built_in_grinder',
          labelAr: 'مطحنة مدمجة',
          inputType: 'boolean',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['إسبرسو', 'آلية بالكامل', 'قهوة عربية']),
      HomeApplianceField(
          id: 'milk_system',
          labelAr: 'نظام الحليب',
          inputType: 'single_select',
          options: ['لا يوجد', 'أنبوب بخار', 'نظام آلي'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['إسبرسو', 'آلية بالكامل', 'كبسولات']),
      HomeApplianceField(
          id: 'coffee_input',
          labelAr: 'نوع القهوة',
          inputType: 'multi_select',
          options: ['مطحونة', 'حبوب', 'كبسولات']),
    ],
    'irons': [
      HomeApplianceField(
          id: 'continuous_steam_g_min',
          labelAr: 'البخار المستمر',
          inputType: 'number_with_unit',
          unitOptions: ['غرام في الدقيقة'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['بخارية', 'محطة بخار', 'عمودية']),
      HomeApplianceField(
          id: 'steam_boost_g',
          labelAr: 'دفعة البخار',
          inputType: 'number_with_unit',
          unitOptions: ['غرام'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['بخارية', 'محطة بخار']),
      HomeApplianceField(
          id: 'water_tank_ml',
          labelAr: 'سعة خزان الماء',
          inputType: 'number_with_unit',
          unitOptions: ['مليلتر'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['بخارية', 'محطة بخار', 'عمودية']),
      HomeApplianceField(
          id: 'soleplate_material',
          labelAr: 'سطح الكي',
          inputType: 'single_select',
          options: ['غير لاصق', 'خزفي', 'فولاذ مقاوم للصدأ', 'مطلي خاص']),
      HomeApplianceField(
          id: 'iron_features',
          labelAr: 'ميزات الأمان والصيانة',
          inputType: 'multi_select',
          options: [
            'فصل تلقائي',
            'مقاومة التكلس',
            'منع التنقيط',
            'بخار عمودي'
          ]),
    ],
    'vacuum_cleaners': [
      HomeApplianceField(
          id: 'power_source_type',
          labelAr: 'طريقة التغذية',
          inputType: 'single_select',
          options: ['سلك كهرباء', 'بطارية'],
          isRequired: true),
      HomeApplianceField(
          id: 'suction_power',
          labelAr: 'قوة الشفط الموثقة',
          inputType: 'number_with_unit',
          unitOptions: ['واط شفط', 'باسكال']),
      HomeApplianceField(
          id: 'dust_capacity_l',
          labelAr: 'سعة الغبار',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true),
      HomeApplianceField(
          id: 'battery_runtime_min',
          labelAr: 'مدة تشغيل البطارية',
          inputType: 'number_with_unit',
          unitOptions: ['دقيقة'],
          visibleWhenField: 'power_source_type',
          visibleWhenValues: ['بطارية']),
      HomeApplianceField(
          id: 'charge_time_min',
          labelAr: 'مدة الشحن',
          inputType: 'number_with_unit',
          unitOptions: ['دقيقة'],
          visibleWhenField: 'power_source_type',
          visibleWhenValues: ['بطارية']),
      HomeApplianceField(
          id: 'filter_type',
          labelAr: 'نوع المرشح',
          inputType: 'single_select',
          options: ['عادي', 'دقيق', 'قابل للغسل', 'غير مذكور']),
      HomeApplianceField(
          id: 'wet_pickup',
          labelAr: 'شفط سوائل',
          inputType: 'boolean',
          visibleWhenField: 'product_type',
          visibleWhenValues: ['رطبة وجافة']),
      HomeApplianceField(
          id: 'noise_db',
          labelAr: 'مستوى الضجيج',
          inputType: 'number_with_unit',
          unitOptions: ['ديسيبل']),
    ],
    'water_heaters': [
      HomeApplianceField(
          id: 'capacity_l',
          labelAr: 'سعة الخزان',
          inputType: 'number_with_unit',
          unitOptions: ['لتر'],
          isRequired: true,
          visibleWhenField: 'product_type',
          visibleWhenValues: ['بخزان']),
      HomeApplianceField(
          id: 'hot_water_flow_l_min',
          labelAr: 'تدفق الماء الساخن',
          inputType: 'number_with_unit',
          unitOptions: ['لتر في الدقيقة'],
          isRequired: true,
          visibleWhenField: 'product_type',
          visibleWhenValues: ['فوري']),
      HomeApplianceField(
          id: 'heating_power_w',
          labelAr: 'استطاعة التسخين',
          inputType: 'number_with_unit',
          unitOptions: ['واط'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['كهرباء', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'gas_supply',
          labelAr: 'مصدر الغاز',
          inputType: 'single_select',
          options: ['أسطوانة غاز', 'شبكة غاز', 'كلاهما'],
          isRequired: true,
          visibleWhenField: 'energy_source',
          visibleWhenValues: ['غاز', 'كهرباء وغاز']),
      HomeApplianceField(
          id: 'installation_orientation',
          labelAr: 'طريقة التركيب',
          inputType: 'single_select',
          options: ['عمودي', 'أفقي', 'تحت المغسلة', 'جداري'],
          isRequired: true),
      HomeApplianceField(
          id: 'max_pressure_bar',
          labelAr: 'أقصى ضغط تشغيل',
          inputType: 'number_with_unit',
          unitOptions: ['بار']),
      HomeApplianceField(
          id: 'heating_time_min',
          labelAr: 'زمن التسخين',
          inputType: 'number_with_unit',
          unitOptions: ['دقيقة'],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['بخزان']),
      HomeApplianceField(
          id: 'safety_features',
          labelAr: 'وسائل الأمان',
          inputType: 'multi_select',
          options: [
            'منظم حرارة',
            'حماية من الحرارة الزائدة',
            'صمام ضغط',
            'قطع الغاز عند انطفاء اللهب',
            'غير مذكورة'
          ]),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
    'televisions': [
      HomeApplianceField(
          id: 'screen_size_in',
          labelAr: 'قياس الشاشة',
          inputType: 'number_with_unit',
          unitOptions: ['بوصة'],
          isRequired: true),
      HomeApplianceField(
          id: 'display_technology',
          labelAr: 'تقنية الشاشة',
          inputType: 'single_select',
          options: ['LED', 'QLED', 'OLED', 'Mini LED', 'أخرى']),
      HomeApplianceField(
          id: 'resolution',
          labelAr: 'دقة العرض',
          inputType: 'single_select',
          options: [
            'عالية الدقة HD',
            'عالية الدقة الكاملة Full HD',
            'فائقة الدقة 4K',
            'فائقة الدقة 8K'
          ],
          isRequired: true),
      HomeApplianceField(
          id: 'refresh_rate_hz',
          labelAr: 'معدل تحديث الصورة',
          inputType: 'number_with_unit',
          unitOptions: ['هرتز']),
      HomeApplianceField(
          id: 'smart_features',
          labelAr: 'ميزات الاتصال',
          inputType: 'multi_select',
          options: [
            'اتصال لاسلكي',
            'بلوتوث',
            'مشاركة شاشة الهاتف',
            'تحكم صوتي',
            'تطبيقات مدمجة'
          ],
          visibleWhenField: 'product_type',
          visibleWhenValues: ['متصل بالإنترنت']),
      HomeApplianceField(
          id: 'hdmi_count',
          labelAr: 'عدد مداخل الفيديو الرقمية',
          inputType: 'number'),
      HomeApplianceField(
          id: 'usb_count', labelAr: 'عدد مداخل التخزين', inputType: 'number'),
      HomeApplianceField(
          id: 'built_in_receiver',
          labelAr: 'مستقبل بث مدمج',
          inputType: 'boolean'),
      HomeApplianceField(
          id: 'sound_power_w',
          labelAr: 'استطاعة الصوت',
          inputType: 'number_with_unit',
          unitOptions: ['واط']),
      HomeApplianceField(
          id: 'dimensions_mm',
          labelAr: 'الأبعاد',
          inputType: 'dimensions',
          isRequired: true),
    ],
  };

  static const List<String> colorOptions = [
    'أبيض',
    'أسود',
    'فضي',
    'رمادي',
    'بيج',
    'أحمر',
    'أزرق',
    'خشبي',
    'لون آخر',
  ];
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

class HomeApplianceTypeSelectorScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const HomeApplianceTypeSelectorScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<HomeApplianceTypeSelectorScreen> createState() =>
      _HomeApplianceTypeSelectorScreenState();
}

class _HomeApplianceTypeSelectorScreenState
    extends State<HomeApplianceTypeSelectorScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color specialGreen = Color(0xFF1E3A8A);

  final TextEditingController _searchController = TextEditingController();
  List<HomeApplianceCategory> _filtered =
      List.from(HomeApplianceData.categories);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    setState(() {
      _filtered = v.isEmpty
          ? List.from(HomeApplianceData.categories)
          : HomeApplianceData.categories
              .where((c) => c.labelAr.contains(v))
              .toList();
    });
  }

  void _onSelect(HomeApplianceCategory category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddHomeApplianceScreen(
          authService: widget.authService,
          storageService: widget.storageService,
          initialCategoryId: category.id,
        ),
      ),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'اختر نوع الأداة المنزلية',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
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
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: '🔍 بحث عن نوع...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    height: 1.5,
                  ),
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: primaryBlue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد نتائج',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: mediumGray,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final cat = _filtered[index];
                        return GestureDetector(
                          onTap: () => _onSelect(cat),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: specialGreen.withOpacity(0.15),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        specialGreen.withOpacity(0.15),
                                        specialGreen.withOpacity(0.06),
                                      ]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(cat.icon,
                                        color: specialGreen, size: 28),
                                  ),
                                  const SizedBox(height: 12),
                                  Flexible(
                                    child: Text(
                                      cat.labelAr,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: darkColor,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddHomeApplianceScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final String? initialCategoryId;

  const AddHomeApplianceScreen({
    super.key,
    required this.authService,
    required this.storageService,
    this.initialCategoryId,
  });

  @override
  State<AddHomeApplianceScreen> createState() => _AddHomeApplianceScreenState();
}

class _AddHomeApplianceScreenState extends State<AddHomeApplianceScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color specialGreen = Color(0xFF1E3A8A);
  static const Color sypAmber = Color(0xFFD97706);

  late ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingData = true;

  String? _selectedCategoryId;

  final _nameArController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _wholesaleMinQtyController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _customWarrantyController = TextEditingController();
  final _descriptionArController = TextEditingController();

  final _priceSypController = TextEditingController();
  final _discountPriceSypController = TextEditingController();
  final _wholesalePriceSypController = TextEditingController();

  double _exchangeRate = 0;
  bool _isLoadingRate = false;

  String _warrantyType = 'year';
  int _warrantyValue = 1;
  String _selectedUnit = 'قطعة';
  bool _isActive = true;

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
  bool _showAllUnits = false;
  final _customUnitController = TextEditingController();
  bool _showCustomUnitInput = false;

  List<dynamic> _subCategories = [];
  List<dynamic> _filteredSubCategories = [];
  final _subCategorySearchController = TextEditingController();
  bool _showSubCategoryDropdown = false;
  String? _selectedSubCategoryId;

  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, String?> _selectValues = {};
  final Map<String, Set<String>> _multiSelectValues = {};
  final Map<String, bool> _booleanValues = {};
  final Map<String, String?> _unitValues = {};
  final Set<String> _selectedColors = {};
  String? _selectedProductType;

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
    'إدلب',
  ];

  File? _mainImage;
  List<File> _additionalImages = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _selectedCategoryId = widget.initialCategoryId;
    _initShippingCostControllers();
    _initDynamicFields();
    _fetchCreateData();
    _fetchExchangeRate();
  }

  void _initShippingCostControllers() {
    for (var city in _syrianCities) {
      _shippingCostControllers[city] = TextEditingController();
      _selectedShippingCities[city] = false;
    }
  }

  void _initDynamicFields() {
    _fieldControllers.clear();
    _selectValues.clear();
    _multiSelectValues.clear();
    _booleanValues.clear();
    _unitValues.clear();

    final allFields = [
      ...HomeApplianceData.commonFields,
      ..._specialFieldsForCurrentCategory(),
    ];

    for (var f in allFields) {
      if (f.inputType == 'text' || f.inputType == 'number') {
        _fieldControllers[f.id] = TextEditingController();
      } else if (f.inputType == 'number_with_unit') {
        _fieldControllers[f.id] = TextEditingController();
        _unitValues[f.id] =
            f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null;
      } else if (f.inputType == 'dimensions') {
        _fieldControllers['${f.id}_length'] = TextEditingController();
        _fieldControllers['${f.id}_width'] = TextEditingController();
        _fieldControllers['${f.id}_height'] = TextEditingController();
      } else if (f.inputType == 'single_select') {
        _selectValues[f.id] = null;
      } else if (f.inputType == 'multi_select') {
        _multiSelectValues[f.id] = <String>{};
      } else if (f.inputType == 'boolean') {
        _booleanValues[f.id] = false;
      }
    }
  }

  List<HomeApplianceField> _specialFieldsForCurrentCategory() {
    if (_selectedCategoryId == null) return [];
    return HomeApplianceData.specialFields[_selectedCategoryId] ?? [];
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
    _customWarrantyController.dispose();
    _descriptionArController.dispose();
    _subCategorySearchController.dispose();
    _customUnitController.dispose();
    _fieldControllers.forEach((_, c) => c.dispose());
    _shippingCostControllers.forEach((_, c) => c.dispose());

    _priceSypController.dispose();
    _discountPriceSypController.dispose();
    _wholesalePriceSypController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreateData() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await _apiService
          .get('/v1/company/products/getHomeSubcategories', requiresAuth: true);
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

          if (widget.initialCategoryId != null) {
            final cat = HomeApplianceData.categories.firstWhere(
              (c) => c.id == widget.initialCategoryId,
              orElse: () => HomeApplianceData.categories.first,
            );
            final match = _subCategories.firstWhere(
              (s) {
                final name = (s['full_name'] ?? s['name_ar'] ?? '').toString();
                return name.contains(cat.labelAr) || name == cat.labelAr;
              },
              orElse: () => null,
            );
            if (match != null) {
              _selectedSubCategoryId = match['id']?.toString();
            }
          }

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
    if (arabicRegex.hasMatch(firstChar)) return TextDirection.rtl;
    return TextDirection.ltr;
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

  String _getSelectedSubCategoryName() {
    if (_selectedSubCategoryId == null) return 'اختر التصنيف الفرعي *';
    final selected = _subCategories.firstWhere(
        (s) => s['id']?.toString() == _selectedSubCategoryId,
        orElse: () => null);
    return selected?['full_name'] ??
        selected?['name_ar'] ??
        'اختر التصنيف الفرعي *';
  }

  bool _isFieldVisible(HomeApplianceField f) {
    if (f.visibleWhenField == null) return true;

    if (f.visibleWhenField == 'product_type') {
      if (_selectedProductType == null) return false;
      return f.visibleWhenValues!.contains(_selectedProductType!);
    }

    final parent = f.visibleWhenField!;
    if (parent == 'has_dryer' ||
        parent == 'wet_pickup' ||
        parent == 'child_lock' ||
        parent == 'moisture_sensor' ||
        parent == 'built_in_grinder' ||
        parent == 'thermostat' ||
        parent == 'pulse_mode' ||
        parent == 'temperature_control' ||
        parent == 'auto_off' ||
        parent == 'dry_boil_protection' ||
        parent == 'ice_crushing' ||
        parent == 'oscillation' ||
        parent == 'built_in_receiver' ||
        parent == 'reverse_rotation' ||
        parent == 'pulp_separation') {
      final boolVal = _booleanValues[parent] ?? false;
      return boolVal && (f.visibleWhenValues ?? []).contains('true');
    }

    if (_multiSelectValues.containsKey(parent)) {
      final set = _multiSelectValues[parent] ?? {};
      return set.any((v) => f.visibleWhenValues!.contains(v));
    }

    final parentValue = _selectValues[parent];
    if (parentValue == null) return false;
    return f.visibleWhenValues!.contains(parentValue);
  }

  void _handleParentChange() {
    final allFields = [
      ...HomeApplianceData.commonFields,
      ..._specialFieldsForCurrentCategory(),
    ];
    for (var f in allFields) {
      if (!_isFieldVisible(f)) {
        if (_fieldControllers.containsKey(f.id)) {
          _fieldControllers[f.id]!.clear();
        }
        if (f.inputType == 'dimensions') {
          _fieldControllers['${f.id}_length']?.clear();
          _fieldControllers['${f.id}_width']?.clear();
          _fieldControllers['${f.id}_height']?.clear();
        }
        if (_selectValues.containsKey(f.id)) {
          _selectValues[f.id] = null;
        }
        if (_multiSelectValues.containsKey(f.id)) {
          _multiSelectValues[f.id] = <String>{};
        }
        if (_booleanValues.containsKey(f.id)) {
          _booleanValues[f.id] = false;
        }
        if (_unitValues.containsKey(f.id)) {
          _unitValues[f.id] =
              f.unitOptions?.isNotEmpty == true ? f.unitOptions!.first : null;
        }
      }
    }
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
    if (images.isNotEmpty) {
      setState(
          () => _additionalImages.addAll(images.map((img) => File(img.path))));
    }
  }

  void _removeAdditionalImage(int index) =>
      setState(() => _additionalImages.removeAt(index));

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

  void _toggleCity(String city) {
    setState(() {
      _selectedShippingCities[city] = !_selectedShippingCities[city]!;
      if (!_selectedShippingCities[city]!) {
        _shippingCostControllers[city]?.clear();
      }
    });
  }

  String? _getFieldStringValue(HomeApplianceField f) {
    switch (f.inputType) {
      case 'text':
      case 'number':
        return _fieldControllers[f.id]?.text.trim();
      case 'number_with_unit':
        final v = _fieldControllers[f.id]?.text.trim() ?? '';
        final u = _unitValues[f.id];
        if (v.isEmpty) return null;
        return u == null || u.isEmpty ? v : '$v $u';
      case 'single_select':
        return _selectValues[f.id];
      case 'multi_select':
        final s = _multiSelectValues[f.id] ?? {};
        if (s.isEmpty) return null;
        return s.join('، ');
      case 'boolean':
        return (_booleanValues[f.id] ?? false) ? 'نعم' : null;
      case 'dimensions':
        final l = _fieldControllers['${f.id}_length']?.text.trim() ?? '';
        final w = _fieldControllers['${f.id}_width']?.text.trim() ?? '';
        final h = _fieldControllers['${f.id}_height']?.text.trim() ?? '';
        if (l.isEmpty && w.isEmpty && h.isEmpty) return null;
        return '$l × $w × $h ملم';
    }
    return null;
  }

  List<Map<String, String>> _buildSpecs() {
    final specs = <Map<String, String>>[];

    for (var f in HomeApplianceData.commonFields) {
      if (!_isFieldVisible(f)) continue;
      final v = _getFieldStringValue(f);
      if (v != null && v.isNotEmpty) {
        specs.add({'key': f.labelAr, 'value': v});
      }
    }

    if (_selectedProductType != null && _selectedProductType!.isNotEmpty) {
      specs.add({'key': 'نوع الجهاز', 'value': _selectedProductType!});
    }

    for (var f in _specialFieldsForCurrentCategory()) {
      if (!_isFieldVisible(f)) continue;
      final v = _getFieldStringValue(f);
      if (v != null && v.isNotEmpty) {
        specs.add({'key': f.labelAr, 'value': v});
      }
    }

    if (_selectedColors.isNotEmpty) {
      specs.add({
        'key': 'الألوان المتاحة',
        'value': _selectedColors.join('، '),
      });
    }

    return specs;
  }

  bool _validateRequired() {
    if (_selectedSubCategoryId == null) {
      _showSnackBar('الرجاء اختيار التصنيف الفرعي', dangerRed);
      return false;
    }
    if (_mainImage == null) {
      _showSnackBar('الرجاء اختيار الصورة الرئيسية', dangerRed);
      return false;
    }

    final allFields = [
      ...HomeApplianceData.commonFields,
      ..._specialFieldsForCurrentCategory(),
    ];

    for (var f in allFields) {
      if (!f.isRequired) continue;
      if (!_isFieldVisible(f)) continue;
      final v = _getFieldStringValue(f);
      if (v == null || v.isEmpty) {
        _showSnackBar('الحقل مطلوب: ${f.labelAr}', dangerRed);
        return false;
      }
    }
    return true;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateRequired()) return;

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
        'unit': _selectedUnit,
        'stock': _stockController.text.trim().isNotEmpty
            ? _stockController.text.trim()
            : '0',
        'is_active': _isActive ? '1' : '0',
        'has_shipping': _hasShipping ? '1' : '0',
        'product_type': _selectedCategoryId ?? '',
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

      if (_brandController.text.trim().isNotEmpty) {
        fields['brand'] = _brandController.text.trim();
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

      final specs = _buildSpecs();
      if (specs.isNotEmpty) {
        fields['specifications'] = jsonEncode(specs);
      }

      request.fields.addAll(fields);

      // debugPrint('═══════════════════════════════════');
      // debugPrint(
      //     '📢 Fields being sent (Home Appliance - ${_selectedCategoryId}):');
      fields.forEach((key, value) {
        final display =
            value.length > 100 ? '${value.substring(0, 100)}...' : value;
        // debugPrint('   $key: $display');
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
          _showSnackBar('تم إضافة المنتج بنجاح 🎉', successGreen);
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
      // debugPrint('❌ Error saving product: $e');
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
                  style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
                  textDirection: _getTextDirection(message))),
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
          if (_showSubCategoryDropdown) {
            setState(() => _showSubCategoryDropdown = false);
          }
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: lightGray,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'إضافة أداة منزلية',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
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
          ),
          body: _isLoadingData
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue))
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle('معلومات أساسية', Icons.info_rounded),
          const SizedBox(height: 12),
          _buildTextField(
              _nameArController, 'اسم المنتج *', 'مثال: مكيف جداري 1.5 طن',
              isRequired: true, textDirection: TextDirection.rtl),
          const SizedBox(height: 12),
          _buildTextField(_skuController, 'رمز المنتج (SKU) *', 'SKU-001',
              isRequired: true, textDirection: TextDirection.ltr),
          const SizedBox(height: 12),
          _buildSubCategoryDropdown(),
          const SizedBox(height: 12),
          _buildUnitDropdown(),
          const SizedBox(height: 12),
          _buildDescriptionField(),
          const SizedBox(height: 24),
          _buildSectionTitle('المواصفات المشتركة', Icons.settings_rounded),
          const SizedBox(height: 12),
          ..._buildDynamicFieldsList(HomeApplianceData.commonFields),
          const SizedBox(height: 24),
          if (_selectedCategoryId != null) ...[
            _buildSectionTitle(
              'مواصفات ${_categoryLabel()}',
              Icons.tune_rounded,
              color: specialGreen,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  specialGreen.withOpacity(0.06),
                  specialGreen.withOpacity(0.02),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: specialGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeOptionDropdown(),
                  const SizedBox(height: 12),
                  ..._buildDynamicFieldsList(
                      _specialFieldsForCurrentCategory()),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('الألوان المتاحة', Icons.palette_rounded),
          const SizedBox(height: 12),
          _buildColorsSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('السعر والمخزون', Icons.attach_money_rounded),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildTextField(_priceController, 'السعر *', '0.00',
                    isRequired: true,
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
                        color: successGreen,
                        height: 1.5)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _buildTextField(
                        _wholesalePriceController, 'سعر الجملة', '0.00',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(_wholesaleMinQtyController,
                        'الحد الأدنى للكمية', 'مثال: 5',
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          _buildTextField(_stockController, 'الكمية المتاحة *', '0',
              isRequired: true,
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
          Row(children: [
            Expanded(
                child: _buildTextField(
                    _brandController, 'العلامة التجارية *', 'مثال: نسيم',
                    isRequired: true, textDirection: TextDirection.rtl)),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField(
                    _modelController, 'رقم الطراز *', 'NS-18V',
                    isRequired: true, textDirection: TextDirection.ltr)),
          ]),
          const SizedBox(height: 12),
          _buildWarrantyField(),
          const SizedBox(height: 24),
          _buildSectionTitle('الصور', Icons.image_rounded),
          const SizedBox(height: 12),
          _buildMainImagePicker(),
          const SizedBox(height: 12),
          _buildAdditionalImagesPicker(),
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

  String _categoryLabel() {
    if (_selectedCategoryId == null) return '';
    final cat = HomeApplianceData.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => HomeApplianceData.categories.first,
    );
    return cat.labelAr;
  }

  List<Widget> _buildDynamicFieldsList(List<HomeApplianceField> fields) {
    final widgets = <Widget>[];
    for (var f in fields) {
      if (!_isFieldVisible(f)) continue;
      widgets.add(_buildDynamicField(f));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildDynamicField(HomeApplianceField f) {
    switch (f.inputType) {
      case 'text':
      case 'number':
        return _buildTextField(
          _fieldControllers[f.id]!,
          f.isRequired ? '${f.labelAr} *' : f.labelAr,
          f.inputType == 'number' ? '0' : 'أدخل ${f.labelAr}',
          isRequired: f.isRequired,
          keyboardType: f.inputType == 'number'
              ? TextInputType.number
              : TextInputType.text,
          textDirection: f.inputType == 'number'
              ? TextDirection.ltr
              : _getTextDirection(_fieldControllers[f.id]!.text),
        );

      case 'number_with_unit':
        return _buildNumberWithUnitField(f);

      case 'single_select':
        return _buildSelectField(f);

      case 'multi_select':
        return _buildMultiSelectField(f);

      case 'boolean':
        return _buildBooleanField(f);

      case 'dimensions':
        return _buildDimensionsField(f);
    }
    return const SizedBox();
  }

  Widget _buildNumberWithUnitField(HomeApplianceField f) {
    final units = f.unitOptions ?? [];
    final selectedUnit = _unitValues[f.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.isRequired ? '${f.labelAr} *' : f.labelAr,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _fieldControllers[f.id],
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
              decoration: _inputDecoration('0'),
              validator: f.isRequired
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
                  : null,
            ),
          ),
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
                  onChanged: (v) => setState(() => _unitValues[f.id] = v),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSelectField(HomeApplianceField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.isRequired ? '${f.labelAr} *' : f.labelAr,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: f.isRequired && _selectValues[f.id] == null
                    ? Colors.grey.shade300
                    : Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectValues[f.id],
              isExpanded: true,
              hint: Text('اختر',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade400, height: 1.5)),
              items: (f.options ?? [])
                  .map((o) => DropdownMenuItem<String>(
                        value: o,
                        child: Text(o,
                            style:
                                GoogleFonts.cairo(fontSize: 13, height: 1.5)),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectValues[f.id] = v;
                  _handleParentChange();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectField(HomeApplianceField f) {
    final selected = _multiSelectValues[f.id] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.isRequired ? '${f.labelAr} *' : f.labelAr,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (f.options ?? []).map((o) {
            final isSelected = selected.contains(o);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(o);
                  } else {
                    selected.add(o);
                  }
                  _handleParentChange();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (f.visibleWhenField == null
                          ? primaryBlue
                          : specialGreen)
                      : lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (f.visibleWhenField == null
                            ? primaryBlue
                            : specialGreen)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  o,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : mediumGray,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBooleanField(HomeApplianceField f) {
    final value = _booleanValues[f.id] ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              f.labelAr,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkColor,
                height: 1.6,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Switch(
            value: value,
            activeColor: specialGreen,
            onChanged: (v) {
              setState(() {
                _booleanValues[f.id] = v;
                _handleParentChange();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsField(HomeApplianceField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.isRequired ? '${f.labelAr} *' : f.labelAr,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: _buildDimInput('${f.id}_length', 'الطول', f.isRequired)),
          const SizedBox(width: 6),
          Expanded(
              child: _buildDimInput('${f.id}_width', 'العرض', f.isRequired)),
          const SizedBox(width: 6),
          Expanded(
              child:
                  _buildDimInput('${f.id}_height', 'الارتفاع', f.isRequired)),
        ]),
      ],
    );
  }

  Widget _buildDimInput(String key, String hint, bool isRequired) {
    return TextFormField(
      controller: _fieldControllers[key],
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      style: GoogleFonts.cairo(fontSize: 13, color: darkColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400),
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: specialGreen, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildTypeOptionDropdown() {
    final types = HomeApplianceData.typeOptions[_selectedCategoryId] ?? [];
    if (types.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الجهاز',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: specialGreen,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: specialGreen.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProductType,
              isExpanded: true,
              hint: Text('اختر نوع الجهاز',
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade400, height: 1.5)),
              items: types
                  .map((o) => DropdownMenuItem<String>(
                        value: o,
                        child: Text(o,
                            style:
                                GoogleFonts.cairo(fontSize: 13, height: 1.5)),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedProductType = v;
                  _handleParentChange();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: HomeApplianceData.colorOptions.map((c) {
          final isSelected = _selectedColors.contains(c);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedColors.remove(c);
                } else {
                  _selectedColors.add(c);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : lightGray,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryBlue : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  c,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : mediumGray,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
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
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkColor,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ]);

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
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
            borderSide: const BorderSide(color: primaryBlue, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isRequired = false,
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
      style: GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.6),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.cairo(fontSize: 12, color: mediumGray, height: 1.5),
        hintText: hint,
        hintStyle: GoogleFonts.cairo(
            fontSize: 12, color: Colors.grey.shade400, height: 1.5),
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
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildDescriptionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'الوصف (اختياري)',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkColor,
          height: 1.6,
        ),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: TextFormField(
          controller: _descriptionArController,
          maxLines: 4,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(fontSize: 14, color: darkColor, height: 1.8),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'اكتب وصفاً تفصيلياً للمنتج...',
            hintStyle: GoogleFonts.cairo(
                fontSize: 13, color: Colors.grey.shade400, height: 1.6),
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
      ),
    ]);
  }

  Widget _buildSubCategoryDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'التصنيف الفرعي *',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkColor,
          height: 1.6,
        ),
        textDirection: TextDirection.rtl,
      ),
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
                      : Colors.grey.shade400,
                  height: 1.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 8),
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
                style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
                decoration: InputDecoration(
                  hintText: '🔍 بحث عن تصنيف...',
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade400, height: 1.5),
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: primaryBlue),
                  filled: true,
                  fillColor: lightGray,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {
                  _filteredSubCategories = value.isEmpty
                      ? List.from(_subCategories)
                      : _subCategories
                          .where((s) => (s['full_name'] ?? s['name_ar'] ?? '')
                              .toString()
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
                    title: Text(
                      displayName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primaryBlue : darkColor,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
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
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: mediumGray, height: 1.5))),
          ]),
        ),
    ]);
  }

  Widget _buildUnitDropdown() {
    final selectedUnitLabel = _units.firstWhere(
          (u) => u['key'] == _selectedUnit,
          orElse: () => {'key': 'قطعة', 'label': 'قطعة'},
        )['label'] ??
        'قطعة';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'وحدة القياس *',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkColor,
          height: 1.6,
        ),
        textDirection: TextDirection.rtl,
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => setState(() {
          _showAllUnits = !_showAllUnits;
          _showCustomUnitInput = false;
        }),
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
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
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
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
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
                label: Text(
                  'إضافة وحدة جديدة',
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      height: 1.5),
                ),
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
            TextField(
              controller: _customUnitController,
              autofocus: true,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'اكتب اسم الوحدة هنا...',
                hintStyle: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey.shade400, height: 1.5),
                hintTextDirection: TextDirection.rtl,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primaryBlue.withOpacity(0.3))),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              onSubmitted: (_) => _addCustomUnit(),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: _addCustomUnit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text('إضافة',
                          style: GoogleFonts.cairo(
                              color: Colors.white, height: 1.5)))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(() {
                            _showCustomUnitInput = false;
                            _customUnitController.clear();
                          }),
                      child: Text('إلغاء',
                          style: GoogleFonts.cairo(
                              color: mediumGray, height: 1.5)))),
            ]),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildMainImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'الصورة الرئيسية *',
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkColor,
          height: 1.6,
        ),
        textDirection: TextDirection.rtl,
      ),
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
                      size: 40, color: specialGreen.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text('انقر لاختيار الصورة الرئيسية',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: mediumGray, height: 1.5)),
                ])),
          ),
        ),
    ]);
  }

  Widget _buildAdditionalImagesPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'صور إضافية (اختياري)',
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkColor,
          height: 1.6,
        ),
        textDirection: TextDirection.rtl,
      ),
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
                      size: 30, color: specialGreen.withOpacity(0.6)))),
        ),
      ]),
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
          Text(
            _isActive ? 'المنتج نشط' : 'المنتج غير نشط',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isActive ? successGreen : mediumGray,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
        ]),
        Switch(
          value: _isActive,
          activeColor: successGreen,
          onChanged: (v) => setState(() => _isActive = v),
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
            Text(
              _hasShipping ? 'الشحن متاح' : 'الشحن غير متاح',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _hasShipping ? primaryBlue : mediumGray,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ]),
          Switch(
            value: _hasShipping,
            activeColor: primaryBlue,
            onChanged: (v) => setState(() => _hasShipping = v),
          ),
        ]),
        if (_hasShipping) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'اختر المدن المتاحة للشحن',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: darkColor,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
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
                        color: isSelected ? primaryBlue : Colors.grey.shade300),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                      city,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : mediumGray,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
          if (selectedCities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'أسعار الشحن لكل مدينة',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkColor,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 10),
            ...selectedCities.map((city) {
              final ctrl = _shippingCostControllers[city]!;
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
                        Expanded(
                          child: Text(
                            city,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: darkColor,
                              height: 1.5,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ])),
                  const SizedBox(width: 6),
                  Expanded(
                      flex: 3,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style:
                            GoogleFonts.cairo(fontSize: 13, color: darkColor),
                        decoration: InputDecoration(
                          hintText: 'سعر الشحن',
                          hintStyle: GoogleFonts.cairo(
                              fontSize: 12, color: Colors.grey.shade400),
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

  Widget _buildWarrantyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الضمان (اختياري)',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkColor,
            height: 1.6,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
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
                    child: Text(
                  'المدة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mediumGray,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                )),
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
                        items: List.generate(12, (i) => i + 1)
                            .map((n) => DropdownMenuItem<int>(
                                  value: n,
                                  child: Text(n.toString(),
                                      style: GoogleFonts.cairo(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _warrantyValue = v ?? 1),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                _getWarrantyText(),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ] else
              TextField(
                controller: _customWarrantyController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'مثال: 10 سنوات، ضمان مدى الحياة',
                  hintStyle: GoogleFonts.cairo(
                      fontSize: 13, color: Colors.grey.shade400, height: 1.5),
                  hintTextDirection: TextDirection.rtl,
                  filled: true,
                  fillColor: lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
          ]),
        ),
      ],
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : mediumGray,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: specialGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: specialGreen.withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'حفظ المنتج',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ]),
      ),
    );
  }
}
