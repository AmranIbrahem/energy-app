// lib/models/lighting_design_models.dart



// ═══════════════════════════════════════════════════════════
// 1) Money
// ═══════════════════════════════════════════════════════════

class LightingMoney {
  final double amount;
  final String currency;

  LightingMoney({
    required this.amount,
    required this.currency,
  });

  factory LightingMoney.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LightingMoney(amount: 0, currency: 'USD');
    return LightingMoney(
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  bool get isSyp => currency == 'SYP';

  bool get isUsd => currency == 'USD';

  String get formatted {
    if (isSyp) return '${amount.toStringAsFixed(2)} SYP';
    return '\$${amount.toStringAsFixed(2)}';
  }
}

// ═══════════════════════════════════════════════════════════
// 2) Room Profile
// ═══════════════════════════════════════════════════════════

class LightingRoomProfile {
  final String key;
  final String titleAr;
  final double targetLux;
  final List<String> recommendedPrimaryTypes;
  final List<String> decorativeTypes;
  final String defaultLightColor;

  LightingRoomProfile({
    required this.key,
    required this.titleAr,
    required this.targetLux,
    required this.recommendedPrimaryTypes,
    required this.decorativeTypes,
    required this.defaultLightColor,
  });

  factory LightingRoomProfile.fromJson(Map<String, dynamic> json) {
    return LightingRoomProfile(
      key: json['key']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      targetLux: double.tryParse((json['target_lux'] ?? 0).toString()) ?? 0,
      recommendedPrimaryTypes:
          (json['recommended_primary_types'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      decorativeTypes: (json['decorative_types'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      defaultLightColor: json['default_light_color']?.toString() ?? 'natural',
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3) Config Response
// ═══════════════════════════════════════════════════════════

class LightingConfig {
  final int maxAttemptsPerRoom;
  final List<LightingPlanMeta> plans;
  final bool visualizationRequiresPhoto;
  final bool visualizationRequiresConfirmedDesign;
  final List<LightingRoomProfile> roomTypes;
  final List<String> initialUserFields;
  final bool lightColorIsSuggestedByNex;

  LightingConfig({
    required this.maxAttemptsPerRoom,
    required this.plans,
    required this.visualizationRequiresPhoto,
    required this.visualizationRequiresConfirmedDesign,
    required this.roomTypes,
    required this.initialUserFields,
    required this.lightColorIsSuggestedByNex,
  });

  factory LightingConfig.fromJson(Map<String, dynamic> json) {
    final rawRoomTypes = (json['room_types'] as List? ?? []);
    final profiles = <LightingRoomProfile>[];

    for (final rt in rawRoomTypes) {
      if (rt is! Map) continue;
      final map = Map<String, dynamic>.from(rt);

      if (map['key'] == 'other') {
        profiles.add(LightingRoomProfile(
          key: 'other',
          titleAr: 'غير ذلك',
          targetLux: 0,
          recommendedPrimaryTypes: [],
          decorativeTypes: [],
          defaultLightColor: 'auto',
        ));
        continue;
      }

      profiles.add(LightingRoomProfile.fromJson(map));
    }

    return LightingConfig(
      maxAttemptsPerRoom: json['max_attempts_per_room'] ?? 2,
      plans: (json['plans'] as List? ?? [])
          .map((e) => LightingPlanMeta.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      visualizationRequiresPhoto: json['visualization_requires_photo'] ?? true,
      visualizationRequiresConfirmedDesign:
          json['visualization_requires_confirmed_design'] ?? true,
      roomTypes: profiles,
      initialUserFields: (json['initial_user_fields'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      lightColorIsSuggestedByNex:
          json['light_color_is_suggested_by_nex'] ?? true,
    );
  }

  List<LightingRoomProfile> get knownRoomTypes =>
      roomTypes.where((r) => r.key != 'other').toList();

  LightingRoomProfile? profileFor(String key) {
    try {
      return roomTypes.firstWhere((r) => r.key == key);
    } catch (_) {
      return null;
    }
  }
}

class LightingPlanMeta {
  final String key;
  final String titleAr;
  final bool recommended;

  LightingPlanMeta({
    required this.key,
    required this.titleAr,
    this.recommended = false,
  });

  factory LightingPlanMeta.fromJson(Map<String, dynamic> json) {
    return LightingPlanMeta(
      key: json['key']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      recommended: json['recommended'] == true,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 4) Room Input
// ═══════════════════════════════════════════════════════════

class LightingRoomInput {
  final String roomId;
  final String roomTypeKey;
  final String? customRoomTypeAr;
  final String? resolvedRoomTypeKey;
  final double lengthM;
  final double widthM;
  final double heightM;
  final String coveCeiling;
  final String? photoRef;
  final int attemptNo;
  final String preferredLightColor;

  LightingRoomInput({
    required this.roomId,
    required this.roomTypeKey,
    this.customRoomTypeAr,
    this.resolvedRoomTypeKey,
    required this.lengthM,
    required this.widthM,
    required this.heightM,
    this.coveCeiling = 'unknown',
    this.photoRef,
    this.attemptNo = 1,
    this.preferredLightColor = 'auto',
  });

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'room_type_key': roomTypeKey,
      if (customRoomTypeAr != null) 'custom_room_type_ar': customRoomTypeAr,
      if (resolvedRoomTypeKey != null)
        'resolved_room_type_key': resolvedRoomTypeKey,
      'length_m': lengthM,
      'width_m': widthM,
      'height_m': heightM,
      'cove_ceiling': coveCeiling,
      if (photoRef != null) 'photo_ref': photoRef,
      'attempt_no': attemptNo,
      'preferred_light_color': preferredLightColor,
    };
  }

  LightingRoomInput copyWith({
    String? roomId,
    String? roomTypeKey,
    String? customRoomTypeAr,
    String? resolvedRoomTypeKey,
    double? lengthM,
    double? widthM,
    double? heightM,
    String? coveCeiling,
    String? photoRef,
    int? attemptNo,
    String? preferredLightColor,
  }) {
    return LightingRoomInput(
      roomId: roomId ?? this.roomId,
      roomTypeKey: roomTypeKey ?? this.roomTypeKey,
      customRoomTypeAr: customRoomTypeAr ?? this.customRoomTypeAr,
      resolvedRoomTypeKey: resolvedRoomTypeKey ?? this.resolvedRoomTypeKey,
      lengthM: lengthM ?? this.lengthM,
      widthM: widthM ?? this.widthM,
      heightM: heightM ?? this.heightM,
      coveCeiling: coveCeiling ?? this.coveCeiling,
      photoRef: photoRef ?? this.photoRef,
      attemptNo: attemptNo ?? this.attemptNo,
      preferredLightColor: preferredLightColor ?? this.preferredLightColor,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 5) Assumption
// ═══════════════════════════════════════════════════════════

class LightingAssumption {
  final String code;
  final String messageAr;

  LightingAssumption({required this.code, required this.messageAr});

  factory LightingAssumption.fromJson(Map<String, dynamic> json) {
    return LightingAssumption(
      code: json['code']?.toString() ?? '',
      messageAr: json['message_ar']?.toString() ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 6) Product Pick
// ═══════════════════════════════════════════════════════════

class LightingProductPick {
  final String productId;
  final String titleAr;
  final String? fixtureType;
  final String role;
  final int quantity;
  final LightingMoney unitPrice;
  final LightingMoney lineTotal;
  final double? lumensPerUnit;
  final double? wattsPerUnit;
  final String? noteAr;

  final String? productType;
  final String? slug;
  final String? image;
  final double? price;
  final double? finalPrice;
  final double? discountPercentage;
  final int stock;
  final String? brand;
  final String? model;
  final bool hasShipping;
  final List<Map<String, dynamic>>? shippingCities;

  LightingProductPick({
    required this.productId,
    required this.titleAr,
    this.fixtureType,
    required this.role,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.lumensPerUnit,
    this.wattsPerUnit,
    this.noteAr,
    this.productType,
    this.slug,
    this.image,
    this.price,
    this.finalPrice,
    this.discountPercentage,
    this.stock = 0,
    this.brand,
    this.model,
    this.hasShipping = false,
    this.shippingCities,
  });

  String get currency => unitPrice.currency;

  factory LightingProductPick.fromJson(Map<String, dynamic> json) {
    return LightingProductPick(
      productId: json['product_id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      fixtureType: json['fixture_type']?.toString(),
      role: json['role']?.toString() ?? 'primary',
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      unitPrice: LightingMoney.fromJson(json['unit_price'] is Map
          ? Map<String, dynamic>.from(json['unit_price'])
          : null),
      lineTotal: LightingMoney.fromJson(json['line_total'] is Map
          ? Map<String, dynamic>.from(json['line_total'])
          : null),
      lumensPerUnit:
          double.tryParse((json['lumens_per_unit'] ?? 0).toString()) ?? 0,
      wattsPerUnit:
          double.tryParse((json['watts_per_unit'] ?? 0).toString()) ?? 0,
      noteAr: json['note_ar']?.toString(),
      productType: json['product_type']?.toString(),
      slug: json['slug']?.toString(),
      image: json['image']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      finalPrice: json['final_price'] != null
          ? double.tryParse(json['final_price'].toString())
          : null,
      discountPercentage: json['discount_percentage'] != null
          ? double.tryParse(json['discount_percentage'].toString())
          : null,
      stock: int.tryParse((json['stock'] ?? 0).toString()) ?? 0,
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      hasShipping: json['has_shipping'] == true,
      shippingCities: json['shipping_cities'] is List
          ? List<Map<String, dynamic>>.from(
              (json['shipping_cities'] as List).map((c) {
                if (c is String) return {'city': c, 'cost': null};
                if (c is Map) {
                  return {
                    'city': c['city']?.toString() ?? '',
                    'cost': c['cost']?.toString(),
                  };
                }
                return {'city': '', 'cost': null};
              }),
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 7) Distribution Plan
// ═══════════════════════════════════════════════════════════

class LightingDistributionPlan {
  final String layoutType;
  final int? rows;
  final int? columns;
  final double? spacingXM;
  final double? spacingYM;
  final double? wallOffsetXM;
  final double? wallOffsetYM;
  final String messageAr;

  LightingDistributionPlan({
    required this.layoutType,
    this.rows,
    this.columns,
    this.spacingXM,
    this.spacingYM,
    this.wallOffsetXM,
    this.wallOffsetYM,
    required this.messageAr,
  });

  factory LightingDistributionPlan.fromJson(Map<String, dynamic> json) {
    return LightingDistributionPlan(
      layoutType: json['layout_type']?.toString() ?? 'grid',
      rows: json['rows'] != null ? int.tryParse(json['rows'].toString()) : null,
      columns: json['columns'] != null
          ? int.tryParse(json['columns'].toString())
          : null,
      spacingXM: json['spacing_x_m'] != null
          ? double.tryParse(json['spacing_x_m'].toString())
          : null,
      spacingYM: json['spacing_y_m'] != null
          ? double.tryParse(json['spacing_y_m'].toString())
          : null,
      wallOffsetXM: json['wall_offset_x_m'] != null
          ? double.tryParse(json['wall_offset_x_m'].toString())
          : null,
      wallOffsetYM: json['wall_offset_y_m'] != null
          ? double.tryParse(json['wall_offset_y_m'].toString())
          : null,
      messageAr: json['message_ar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layout_type': layoutType,
      if (rows != null) 'rows': rows,
      if (columns != null) 'columns': columns,
      if (spacingXM != null) 'spacing_x_m': spacingXM,
      if (spacingYM != null) 'spacing_y_m': spacingYM,
      if (wallOffsetXM != null) 'wall_offset_x_m': wallOffsetXM,
      if (wallOffsetYM != null) 'wall_offset_y_m': wallOffsetYM,
      'message_ar': messageAr,
    };
  }
}

// ═══════════════════════════════════════════════════════════
// 8) Lighting Plan
// ═══════════════════════════════════════════════════════════

class LightingPlan {
  final String key;
  final String titleAr;
  final bool recommended;
  final String suggestedLightColor;
  final double targetLumens;
  final double primaryLumens;
  final double estimatedLux;
  final double totalPowerW;
  final List<LightingProductPick> products;
  final List<LightingProductPick> decorativeSuggestions;
  final LightingMoney equipmentTotal;
  final LightingDistributionPlan distribution;
  final String adequacy;
  final List<String> reasoningAr;
  final List<String> warningsAr;

  LightingPlan({
    required this.key,
    required this.titleAr,
    required this.recommended,
    required this.suggestedLightColor,
    required this.targetLumens,
    required this.primaryLumens,
    required this.estimatedLux,
    required this.totalPowerW,
    required this.products,
    required this.decorativeSuggestions,
    required this.equipmentTotal,
    required this.distribution,
    required this.adequacy,
    required this.reasoningAr,
    required this.warningsAr,
  });

  factory LightingPlan.fromJson(Map<String, dynamic> json) {
    return LightingPlan(
      key: json['key']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      recommended: json['recommended'] == true,
      suggestedLightColor:
          json['suggested_light_color']?.toString() ?? 'natural',
      targetLumens:
          double.tryParse((json['target_lumens'] ?? 0).toString()) ?? 0,
      primaryLumens:
          double.tryParse((json['primary_lumens'] ?? 0).toString()) ?? 0,
      estimatedLux:
          double.tryParse((json['estimated_lux'] ?? 0).toString()) ?? 0,
      totalPowerW:
          double.tryParse((json['total_power_w'] ?? 0).toString()) ?? 0,
      products: (json['products'] as List? ?? [])
          .map(
              (e) => LightingProductPick.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      decorativeSuggestions: (json['decorative_suggestions'] as List? ?? [])
          .map(
              (e) => LightingProductPick.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      equipmentTotal: LightingMoney.fromJson(json['equipment_total'] is Map
          ? Map<String, dynamic>.from(json['equipment_total'])
          : null),
      distribution: LightingDistributionPlan.fromJson(
          json['distribution'] is Map
              ? Map<String, dynamic>.from(json['distribution'])
              : {}),
      adequacy: json['adequacy']?.toString() ?? 'adequate',
      reasoningAr: (json['reasoning_ar'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      warningsAr: (json['warnings_ar'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool get isEconomic => key == 'economic';

  bool get isBalanced => key == 'balanced';

  bool get isPremium => key == 'premium';
}

// ═══════════════════════════════════════════════════════════
// 9) Design Response
// ═══════════════════════════════════════════════════════════

class LightingDesignResponse {
  final bool ok;
  final String status;
  final String summaryAr;
  final String pricingTier;
  final String roomId;
  final String roomTypeKey;
  final String roomTitleAr;
  final int attemptNo;
  final double areaM2;
  final double targetLux;
  final double utilizationFactor;
  final double maintenanceFactor;
  final double requiredPrimaryLumens;
  final List<LightingPlan> plans;
  final List<LightingAssumption> assumptions;
  final List<String> warningsAr;
  final bool visualizationAvailable;

  LightingDesignResponse({
    required this.ok,
    required this.status,
    required this.summaryAr,
    required this.pricingTier,
    required this.roomId,
    required this.roomTypeKey,
    required this.roomTitleAr,
    required this.attemptNo,
    required this.areaM2,
    required this.targetLux,
    required this.utilizationFactor,
    required this.maintenanceFactor,
    required this.requiredPrimaryLumens,
    required this.plans,
    required this.assumptions,
    required this.warningsAr,
    required this.visualizationAvailable,
  });

  factory LightingDesignResponse.fromJson(Map<String, dynamic> json) {
    return LightingDesignResponse(
      ok: json['ok'] == true,
      status: json['status']?.toString() ?? 'complete',
      summaryAr: json['summary_ar']?.toString() ?? '',
      pricingTier: json['pricing_tier']?.toString() ?? 'retail',
      roomId: json['room_id']?.toString() ?? '',
      roomTypeKey: json['room_type_key']?.toString() ?? '',
      roomTitleAr: json['room_title_ar']?.toString() ?? '',
      attemptNo: int.tryParse((json['attempt_no'] ?? 1).toString()) ?? 1,
      areaM2: double.tryParse((json['area_m2'] ?? 0).toString()) ?? 0,
      targetLux: double.tryParse((json['target_lux'] ?? 0).toString()) ?? 0,
      utilizationFactor:
          double.tryParse((json['utilization_factor'] ?? 0).toString()) ?? 0,
      maintenanceFactor:
          double.tryParse((json['maintenance_factor'] ?? 0).toString()) ?? 0,
      requiredPrimaryLumens:
          double.tryParse((json['required_primary_lumens'] ?? 0).toString()) ??
              0,
      plans: (json['plans'] as List? ?? [])
          .map((e) => LightingPlan.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      assumptions: (json['assumptions'] as List? ?? [])
          .map((e) => LightingAssumption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      warningsAr: (json['warnings_ar'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      visualizationAvailable: json['visualization_available'] == true,
    );
  }

  LightingPlan? planFor(String key) {
    try {
      return plans.firstWhere((p) => p.key == key);
    } catch (_) {
      return null;
    }
  }

  LightingPlan? get recommendedPlan {
    try {
      return plans.firstWhere((p) => p.recommended);
    } catch (_) {
      return plans.isNotEmpty ? plans.first : null;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// 10) Recheck Response
// ═══════════════════════════════════════════════════════════

class LightingRecheckResponse {
  final bool ok;
  final String adequacy;
  final double targetLux;
  final double requiredPrimaryLumens;
  final double selectedPrimaryLumens;
  final double estimatedLux;
  final double totalPowerW;
  final LightingMoney equipmentTotal;
  final String messageAr;
  final List<String> warningsAr;

  LightingRecheckResponse({
    required this.ok,
    required this.adequacy,
    required this.targetLux,
    required this.requiredPrimaryLumens,
    required this.selectedPrimaryLumens,
    required this.estimatedLux,
    required this.totalPowerW,
    required this.equipmentTotal,
    required this.messageAr,
    required this.warningsAr,
  });

  factory LightingRecheckResponse.fromJson(Map<String, dynamic> json) {
    return LightingRecheckResponse(
      ok: json['ok'] == true,
      adequacy: json['adequacy']?.toString() ?? 'adequate',
      targetLux: double.tryParse((json['target_lux'] ?? 0).toString()) ?? 0,
      requiredPrimaryLumens:
          double.tryParse((json['required_primary_lumens'] ?? 0).toString()) ??
              0,
      selectedPrimaryLumens:
          double.tryParse((json['selected_primary_lumens'] ?? 0).toString()) ??
              0,
      estimatedLux:
          double.tryParse((json['estimated_lux'] ?? 0).toString()) ?? 0,
      totalPowerW:
          double.tryParse((json['total_power_w'] ?? 0).toString()) ?? 0,
      equipmentTotal: LightingMoney.fromJson(json['equipment_total'] is Map
          ? Map<String, dynamic>.from(json['equipment_total'])
          : null),
      messageAr: json['message_ar']?.toString() ?? '',
      warningsAr: (json['warnings_ar'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool get isAdequate => adequacy == 'adequate';

  bool get isLow => adequacy == 'low';

  bool get isExcessive => adequacy == 'excessive';
}

// ═══════════════════════════════════════════════════════════
// 11) Alternative Product
// ═══════════════════════════════════════════════════════════

class LightingAlternativeProduct {
  final String productId;
  final String titleAr;
  final String? fixtureType;
  final String? lightColor;
  final double lumens;
  final double watts;
  final LightingMoney unitPrice;

  LightingAlternativeProduct({
    required this.productId,
    required this.titleAr,
    this.fixtureType,
    this.lightColor,
    required this.lumens,
    required this.watts,
    required this.unitPrice,
  });

  factory LightingAlternativeProduct.fromJson(Map<String, dynamic> json) {
    return LightingAlternativeProduct(
      productId: json['product_id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      fixtureType: json['fixture_type']?.toString(),
      lightColor: json['light_color']?.toString(),
      lumens: double.tryParse((json['lumens'] ?? 0).toString()) ?? 0,
      watts: double.tryParse((json['watts'] ?? 0).toString()) ?? 0,
      unitPrice: LightingMoney.fromJson(json['unit_price'] is Map
          ? Map<String, dynamic>.from(json['unit_price'])
          : null),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 12) Project
// ═══════════════════════════════════════════════════════════

class LightingProject {
  final int id;
  final String projectNumber;
  final String status;
  final int roomCount;
  final double totalPowerW;
  final LightingMoney equipmentTotal;
  final bool isSyp;
  final double? exchangeRate;
  final String? createdAt;

  LightingProject({
    required this.id,
    required this.projectNumber,
    required this.status,
    required this.roomCount,
    required this.totalPowerW,
    required this.equipmentTotal,
    this.isSyp = false,
    this.exchangeRate,
    this.createdAt,
  });

  factory LightingProject.fromJson(Map<String, dynamic> json) {
    return LightingProject(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      projectNumber: json['project_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      roomCount: int.tryParse((json['room_count'] ?? 0).toString()) ?? 0,
      totalPowerW:
          double.tryParse((json['total_power_w'] ?? 0).toString()) ?? 0,
      equipmentTotal: LightingMoney.fromJson(json['equipment_total'] is Map
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
      case 'ordered':
        return 'تم الطلب';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// 13) Confirm Attempt Response
// ═══════════════════════════════════════════════════════════

class LightingConfirmAttemptResponse {
  final int attemptId;
  final int roomIdDb;
  final int projectId;
  final int attemptNo;
  final String planKey;

  LightingConfirmAttemptResponse({
    required this.attemptId,
    required this.roomIdDb,
    required this.projectId,
    required this.attemptNo,
    required this.planKey,
  });

  factory LightingConfirmAttemptResponse.fromJson(Map<String, dynamic> json) {
    return LightingConfirmAttemptResponse(
      attemptId: int.tryParse((json['attempt_id'] ?? 0).toString()) ?? 0,
      roomIdDb: int.tryParse((json['room_id_db'] ?? 0).toString()) ?? 0,
      projectId: int.tryParse((json['project_id'] ?? 0).toString()) ?? 0,
      attemptNo: int.tryParse((json['attempt_no'] ?? 1).toString()) ?? 1,
      planKey: json['plan_key']?.toString() ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 14) Selected Design Item
// ═══════════════════════════════════════════════════════════

class LightingSelectedItem {
  String productId;
  int quantity;
  String role;

  LightingSelectedItem({
    required this.productId,
    required this.quantity,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'role': role,
      };

  factory LightingSelectedItem.fromJson(Map<String, dynamic> json) {
    return LightingSelectedItem(
      productId: json['product_id']?.toString() ?? '',
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      role: json['role']?.toString() ?? 'primary',
    );
  }

  LightingSelectedItem copyWith({int? quantity}) {
    return LightingSelectedItem(
      productId: productId,
      quantity: quantity ?? this.quantity,
      role: role,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 15) Helper
// ═══════════════════════════════════════════════════════════

extension LightingAdequacyAr on String {
  String get adequacyAr {
    switch (this) {
      case 'adequate':
        return 'مناسب';
      case 'low':
        return 'أقل من المطلوب';
      case 'excessive':
        return 'أعلى من الحاجة';
      default:
        return this;
    }
  }

  String get statusDesignAr {
    switch (this) {
      case 'complete':
        return '✅ مكتمل';
      case 'needs_review':
        return '⚠️ يحتاج مراجعة';
      case 'no_product_match':
        return '❌ لا توجد منتجات متوافقة';
      default:
        return this;
    }
  }

  String get lightColorAr {
    switch (this) {
      case 'warm':
        return 'دافئ';
      case 'natural':
        return 'طبيعي';
      case 'white':
        return 'أبيض';
      case 'auto':
        return 'تلقائي';
      default:
        return this;
    }
  }
}
