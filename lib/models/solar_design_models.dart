// lib/models/solar_design_models.dart

class SolarMoney {
  final double amount;
  final String currency;

  SolarMoney({required this.amount, required this.currency});

  factory SolarMoney.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SolarMoney(amount: 0, currency: 'USD');
    return SolarMoney(
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  bool get isSyp => currency == 'SYP';

  bool get isUsd => currency == 'USD';
}

class SolarProject {
  final int id;
  final String projectNumber;
  final String status;
  final String? governorate;
  final int loadsCount;
  final double dailyEnergyWh;
  final double designContinuousW;
  final String? chosenPlanKey;
  final int panelUnits;
  final int batteryUnits;
  final double inverterRatedW;
  final double pvArrayW;
  final SolarMoney equipmentTotal;
  final bool isSyp;
  final double? exchangeRate;
  final String? createdAt;

  SolarProject({
    required this.id,
    required this.projectNumber,
    required this.status,
    this.governorate,
    required this.loadsCount,
    required this.dailyEnergyWh,
    required this.designContinuousW,
    this.chosenPlanKey,
    required this.panelUnits,
    required this.batteryUnits,
    required this.inverterRatedW,
    required this.pvArrayW,
    required this.equipmentTotal,
    this.isSyp = false,
    this.exchangeRate,
    this.createdAt,
  });

  factory SolarProject.fromJson(Map<String, dynamic> json) {
    return SolarProject(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      projectNumber: json['project_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      governorate: json['governorate']?.toString(),
      loadsCount: int.tryParse((json['loads_count'] ?? 0).toString()) ?? 0,
      dailyEnergyWh:
          double.tryParse((json['daily_energy_wh'] ?? 0).toString()) ?? 0,
      designContinuousW:
          double.tryParse((json['design_continuous_w'] ?? 0).toString()) ?? 0,
      chosenPlanKey: json['chosen_plan_key']?.toString(),
      panelUnits: int.tryParse((json['panel_units'] ?? 0).toString()) ?? 0,
      batteryUnits: int.tryParse((json['battery_units'] ?? 0).toString()) ?? 0,
      inverterRatedW:
          double.tryParse((json['inverter_rated_w'] ?? 0).toString()) ?? 0,
      pvArrayW: double.tryParse((json['pv_array_w'] ?? 0).toString()) ?? 0,
      equipmentTotal: SolarMoney.fromJson(json['equipment_total'] is Map
          ? Map<String, dynamic>.from(json['equipment_total'])
          : null),
      isSyp: json['is_syp'] == true || json['is_syp'] == 1,
      exchangeRate: json['exchange_rate'] != null
          ? double.tryParse(json['exchange_rate'].toString())
          : null,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get statusAr {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'confirmed':
        return 'مؤكد';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  String get planKeyAr {
    switch (chosenPlanKey) {
      case 'economic':
        return 'اقتصادي';
      case 'balanced':
        return 'متوازن';
      case 'excellent':
        return 'ممتاز';
      default:
        return '';
    }
  }

  double get dailyEnergyKwh => dailyEnergyWh / 1000;

  double get continuousKw => designContinuousW / 1000;
}
