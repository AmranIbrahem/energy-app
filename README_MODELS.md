# 📦 Models - Flutter Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Data Models for NexSys Mobile Application**

</div>

---

## 📑 Table of Contents

| # | Model | File | Description |
|---|-------|------|-------------|
| 1 | [CartItemModel](#1-️-cartitemmodel) | `cart_item_model.dart` | سلة التسوق |
| 2 | [Diagnosis Models](#2-️-diagnosis-models) | `diagnosis_models.dart` | نظام التشخيص والأعطال |
| 3 | [Lighting Design Models](#3-️-lighting-design-models) | `lighting_design_models.dart` | تصميم الإضاءة |
| 4 | [NotificationModel](#4-️-notificationmodel) | `notification_model.dart` | الإشعارات |
| 5 | [Solar Design Models](#5-️-solar-design-models) | `solar_design_models.dart` | تصميم الأنظمة الشمسية |

---

## 📁 File Structure

```
lib/models/
├── cart_item_model.dart              # Cart items
├── diagnosis_models.dart             # Diagnostic system models
├── lighting_design_models.dart       # Lighting design models
├── notification_model.dart           # Push notifications
└── solar_design_models.dart          # Solar system design models
```

---

## 1️⃣ CartItemModel

**File:** `lib/models/cart_item_model.dart`

**Purpose:** Represents a cart item — supports both **Products** and **Offers** with dual currency (USD/SYP) and per-city shipping costs.

### 📋 Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `int` | Item ID |
| `name` | `String` | Item name (Arabic) |
| `slug` | `String` | URL slug |
| `price` | `double` | Regular price (USD) |
| `finalPrice` | `double` | Final price after discount (USD) |
| `priceSyp` | `double?` | Regular price (SYP) |
| `finalPriceSyp` | `double?` | Final price (SYP) |
| `image` | `String?` | Main image |
| `stock` | `int` | Available stock |
| `quantity` | `int` | Cart quantity (mutable) |
| `discountPercentage` | `double?` | Discount percentage |
| `itemType` | `String` | `'product'` or `'offer'` |
| `productsInOffer` | `List<Map>?` | Products inside an offer |
| `totalWattage` | `int?` | Total wattage (offers) |
| `totalCapacity` | `int?` | Total capacity (offers) |
| `shippingCities` | `List<Map>?` | Shipping cities with costs |

### 🔧 Key Getters

```dart
bool get isOffer            // true if itemType == 'offer'
bool get hasSypPrices       // true if both SYP prices are valid
double get totalPrice       // finalPrice × quantity
bool get hasShippingInfo    // true if shippingCities is not empty
```

### 📐 Key Methods

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `displayPrice()` | `{bool isSyp}` | `double` | Price based on currency |
| `displayFinalPrice()` | `{bool isSyp}` | `double` | Final price based on currency |
| `displayTotalPrice()` | `{bool isSyp}` | `double` | Total = finalPrice × quantity |
| `getShippingCostForCity()` | `String? governorate` | `double?` | Shipping cost for a city |
| `isFreeShippingForCity()` | `String? governorate` | `bool` | Check if shipping is free |
| `isShippingPendingForCity()` | `String? governorate` | `bool` | Check if cost not yet set |
| `isShippingCalculatedForCity()` | `String? governorate` | `bool` | Check if cost is calculated |

### 🏭 Factory Constructors

#### `CartItemModel.fromProduct()`
```dart
factory CartItemModel.fromProduct(
Map<String, dynamic> product, {
int quantity = 1,
})
```
Creates a cart item from a product API response. Default `itemType = 'product'`.

#### `CartItemModel.fromOffer()`
```dart
factory CartItemModel.fromOffer(
Map<String, dynamic> offer, {
int quantity = 1,
})
```
Creates a cart item from an offer, extracting nested `products_in_offer`. Default `itemType = 'offer'`. Stock defaults to `999999` if unlimited.

#### `CartItemModel.fromJson()`
Standard JSON deserialization with snake_case keys.

### 📤 Serialization

```dart
Map<String, dynamic> toJson()
```

Produces a map with:
`id`, `name`, `slug`, `price`, `final_price`, `price_syp`, `final_price_syp`, `image`, `stock`, `quantity`, `discount_percentage`, `item_type`, `products_in_offer`, `total_wattage`, `total_capacity`, `shipping_cities`.

### 🔒 Private Helpers

```dart
static List<Map<String, dynamic>>? _parseShippingCities(dynamic rawCities)
```
Safely parses shipping cities from either a `List`, JSON `String`, or mixed types. Each city is normalized to `{'city': String, 'cost': String?}`.

---

## 2️⃣ Diagnosis Models

**File:** `lib/models/diagnosis_models.dart`

**Purpose:** Models for the **AI-powered diagnosis system** — device tree, fault detection, inverter error codes, and session state.

### 📦 Models in this File

| Model | Description |
|-------|-------------|
| `DiagnosticFault` | عطل تشخيصي |
| `InverterFamily` | عائلة إنفرتر |
| `InverterCodeResult` | نتيجة كود إنفرتر |
| `DiagnosisSessionResponse` | استجابة جلسة التشخيص |
| `DeviceInfo` | معلومات جهاز |
| `DeviceTree` | شجرة الأجهزة |
| `SearchResult` | نتيجة بحث |
| `SearchResponse` | استجابة بحث |
| `deviceIconCodePoints` | خريطة أيقونات الأجهزة |

### 🔹 DiagnosticFault

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Fault ID |
| `category` | `String` | Category |
| `device` | `String` | Device key |
| `title` | `String` | Fault title |
| `severity` | `String` | `normal` / `urgent` / `danger` |

**Getter:** `severityAr` → returns Arabic label (`'عادي'` / `'عاجل'` / `'خطر'`).

### 🔹 InverterFamily

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Family ID |
| `manufacturer` | `String` | Manufacturer key |
| `manufacturerLabel` | `String` | Manufacturer label |
| `label` | `String` | Family label |
| `models` | `List<String>` | Supported models |
| `sourceUrl` | `String?` | Source reference |

### 🔹 InverterCodeResult

| Field | Type | Description |
|-------|------|-------------|
| `manufacturer` | `String` | Manufacturer |
| `manufacturerLabel` | `String?` | Manufacturer label |
| `familyId` | `String` | Family ID |
| `familyLabel` | `String?` | Family label |
| `code` | `String` | Error code |
| `meaning` | `String` | Code meaning |
| `resolutionMode` | `String` | `maintenance` / `danger` / `direct` / `guided` |
| `userSteps` | `List<String>` | Step-by-step resolution |
| `sourceUrl` | `String?` | Source URL |
| `sourcePages` | `String?` | Source pages |
| `reviewStatus` | `String?` | Review status |

**Getters:**
```dart
bool get isDanger        // resolutionMode == 'danger'
bool get isMaintenance   // resolutionMode == 'maintenance'
bool get isDirect        // resolutionMode == 'direct'
bool get isGuided        // resolutionMode == 'guided'
```

### 🔹 DiagnosisSessionResponse

**Comprehensive response** for the diagnosis state machine.

| Group | Fields |
|-------|--------|
| **Session** | `success`, `sessionId`, `sessionDbId`, `state`, `safety`, `message` |
| **Code** | `code`, `meaning`, `manufacturerLabel`, `familyLabel`, `resolutionMode` |
| **Question** | `questionIndex`, `question`, `totalQuestions` |
| **Step** | `stepIndex`, `stepText`, `totalSteps`, `stepFinished`, `askResolved` |
| **Result** | `faultId`, `title`, `result`, `causes` |
| **Meta** | `matchedKeywords`, `actions`, `canRequestUrgent`, `canRequestMaintenance` |
| **Extra** | `handoff`, `snapshot`, `next` |

**State Getters:**
```dart
bool get isQuestion     // state == 'question'
bool get isStep         // state == 'step'
bool get isResult       // state == 'result'
bool get isSafetyStop   // state == 'safety_stop'
bool get isNoMatch      // state == 'no_match'
bool get isSolved       // state == 'solved'
bool get isHandoff      // state == 'handoff'
bool get isDanger       // safety == 'danger'
```

> 💡 The `fromJson` automatically unwraps `data` field if present.

### 🔹 DeviceInfo

| Field | Type | Description |
|-------|------|-------------|
| `deviceKey` | `String` | Device key |
| `deviceName` | `String` | Device name (Arabic) |
| `icon` | `String` | Icon name |
| `faultsCount` | `int` | Number of faults |
| `hasCodes` | `bool` | Has error codes |
| `hasDanger` | `bool` | Has danger faults |

### 🔹 DeviceTree

| Field | Type | Description |
|-------|------|-------------|
| `category` | `String` | Category key |
| `categoryLabel` | `String` | Category label |
| `devices` | `List<DeviceInfo>` | Devices in this category |

### 🔹 SearchResult & SearchResponse

**SearchResult** — single fault search result with `toFault()` converter.

**SearchResponse** — contains `query`, `count`, and `results: List<SearchResult>`.

### 🔹 Device Icon Code Points

```dart
const Map<String, int> deviceIconCodePoints = {
  'electrical_services': 0xe1b1,
  'battery_charging_full': 0xe1a3,
  'solar_power': 0xea93,
  'shield': 0xe32f,
  'swap_horiz': 0xe8d4,
  'power': 0xe8ac,
  'wifi': 0xe63e,
  'output': 0xebbe,
  'account_tree': 0xe97a,
  'power_off': 0xe8ad,
  'speed': 0xe9e4,
  'toggle_on': 0xec07,
  'cable': 0xe1b6,
  'shield_alert': 0xe32e,
  'warning': 0xe002,
  'lightbulb': 0xe0f0,
  'light': 0xe0f0,
  'tune': 0xe429,
  'visibility': 0xe8f4,
  'wb_twilight': 0xe1c6,
  'settings_input_component': 0xe8af,
  'devices': 0xe1b1,
};
```

---

## 3️⃣ Lighting Design Models

**File:** `lib/models/lighting_design_models.dart`

**Purpose:** Complete model set for the **AI-powered lighting design system** — room profiling, plans, product picks, distribution, and projects.

### 📦 Models in this File

| # | Model | Description |
|---|-------|-------------|
| 1 | `LightingMoney` | العملة |
| 2 | `LightingRoomProfile` | ملف الغرفة |
| 3 | `LightingConfig` | إعدادات النظام |
| 4 | `LightingPlanMeta` | بيانات خطة |
| 5 | `LightingRoomInput` | مدخلات الغرفة |
| 6 | `LightingAssumption` | افتراض |
| 7 | `LightingProductPick` | منتج مختار |
| 8 | `LightingDistributionPlan` | خطة التوزيع |
| 9 | `LightingPlan` | خطة الإضاءة |
| 10 | `LightingDesignResponse` | استجابة التصميم |
| 11 | `LightingRecheckResponse` | استجابة إعادة الفحص |
| 12 | `LightingAlternativeProduct` | منتج بديل |
| 13 | `LightingProject` | مشروع |
| 14 | `LightingConfirmAttemptResponse` | استجابة تأكيد محاولة |
| 15 | `LightingSelectedItem` | عنصر مختار |
| — | `LightingAdequacyAr` | Extension للترجمة |

### 🔹 LightingMoney

```dart
class LightingMoney {
  final double amount;
  final String currency; // 'USD' or 'SYP'
}
```

**Getters:** `isSyp`, `isUsd`, `formatted` (`'$X.XX'` or `'X.XX SYP'`).

### 🔹 LightingRoomProfile

| Field | Type | Description |
|-------|------|-------------|
| `key` | `String` | Room key |
| `titleAr` | `String` | Arabic title |
| `targetLux` | `double` | Target lux level |
| `recommendedPrimaryTypes` | `List<String>` | Recommended primary fixture types |
| `decorativeTypes` | `List<String>` | Decorative fixture types |
| `defaultLightColor` | `String` | Default light color |

### 🔹 LightingConfig

Configuration response from API.

| Field | Type |
|-------|------|
| `maxAttemptsPerRoom` | `int` |
| `plans` | `List<LightingPlanMeta>` |
| `visualizationRequiresPhoto` | `bool` |
| `visualizationRequiresConfirmedDesign` | `bool` |
| `roomTypes` | `List<LightingRoomProfile>` |
| `initialUserFields` | `List<String>` |
| `lightColorIsSuggestedByNex` | `bool` |

**Methods:**
- `knownRoomTypes` → rooms excluding `'other'`
- `profileFor(String key)` → finds a room profile by key

### 🔹 LightingRoomInput

**Request payload** for a room design attempt. Supports `copyWith`.

| Field | Type | Default |
|-------|------|---------|
| `roomId` | `String` | required |
| `roomTypeKey` | `String` | required |
| `customRoomTypeAr` | `String?` | — |
| `resolvedRoomTypeKey` | `String?` | — |
| `lengthM` | `double` | required |
| `widthM` | `double` | required |
| `heightM` | `double` | required |
| `coveCeiling` | `String` | `'unknown'` |
| `photoRef` | `String?` | — |
| `attemptNo` | `int` | `1` |
| `preferredLightColor` | `String` | `'auto'` |

### 🔹 LightingProductPick

Represents a recommended/picked lighting product.

| Field | Type |
|-------|------|
| `productId` | `String` |
| `titleAr` | `String` |
| `fixtureType` | `String?` |
| `role` | `String` (`primary` / `decorative`) |
| `quantity` | `int` |
| `unitPrice` | `LightingMoney` |
| `lineTotal` | `LightingMoney` |
| `lumensPerUnit` | `double?` |
| `wattsPerUnit` | `double?` |
| `noteAr` | `String?` |
| `productType`, `slug`, `image`, `price`, `finalPrice`, `discountPercentage`, `stock`, `brand`, `model`, `hasShipping`, `shippingCities` | (extra fields for ordering) |

### 🔹 LightingDistributionPlan

| Field | Type |
|-------|------|
| `layoutType` | `String` |
| `rows`, `columns` | `int?` |
| `spacingXM`, `spacingYM` | `double?` |
| `wallOffsetXM`, `wallOffsetYM` | `double?` |
| `messageAr` | `String` |

### 🔹 LightingPlan

Full design plan (economic/balanced/premium).

| Field | Type |
|-------|------|
| `key` | `String` |
| `titleAr` | `String` |
| `recommended` | `bool` |
| `suggestedLightColor` | `String` |
| `targetLumens`, `primaryLumens`, `estimatedLux`, `totalPowerW` | `double` |
| `products` | `List<LightingProductPick>` |
| `decorativeSuggestions` | `List<LightingProductPick>` |
| `equipmentTotal` | `LightingMoney` |
| `distribution` | `LightingDistributionPlan` |
| `adequacy` | `String` |
| `reasoningAr`, `warningsAr` | `List<String>` |

**Getters:** `isEconomic`, `isBalanced`, `isPremium`.

### 🔹 LightingDesignResponse

Main design response with `planFor(key)` and `recommendedPlan` helpers.

Includes: `ok`, `status`, `summaryAr`, `pricingTier`, `roomId`, `roomTypeKey`, `roomTitleAr`, `attemptNo`, `areaM2`, `targetLux`, `utilizationFactor`, `maintenanceFactor`, `requiredPrimaryLumens`, `plans`, `assumptions`, `warningsAr`, `visualizationAvailable`.

### 🔹 LightingRecheckResponse

Result of re-checking a modified selection.

**Getters:** `isAdequate`, `isLow`, `isExcessive`.

### 🔹 LightingProject

| Field | Type |
|-------|------|
| `id` | `int` |
| `projectNumber` | `String` |
| `status` | `String` (`draft` / `confirmed` / `ordered` / `cancelled`) |
| `roomCount` | `int` |
| `totalPowerW` | `double` |
| `equipmentTotal` | `LightingMoney` |
| `isSyp` | `bool` |
| `exchangeRate` | `double?` |
| `createdAt` | `String?` |

**Getter:** `statusAr` → Arabic status.

### 🔹 LightingSelectedItem

Mutable selected item with `toJson`, `fromJson`, `copyWith({int? quantity})`.

### 🔹 String Extension: `LightingAdequacyAr`

```dart
extension LightingAdequacyAr on String {
  String get adequacyAr;      // 'مناسب' / 'أقل من المطلوب' / 'أعلى من الحاجة'
  String get statusDesignAr;  // '✅ مكتمل' / '⚠️ يحتاج مراجعة' / '❌ لا توجد منتجات'
  String get lightColorAr;    // 'دافئ' / 'طبيعي' / 'أبيض' / 'تلقائي'
}
```

---

## 4️⃣ NotificationModel

**File:** `lib/models/notification_model.dart`

**Purpose:** Simple model for push notifications.

### 📋 Properties

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Notification ID |
| `title` | `String` | Title |
| `body` | `String` | Body text |
| `type` | `String` | Type (default `'general'`) |
| `readAt` | `DateTime?` | Read timestamp |
| `createdAt` | `DateTime` | Creation timestamp |

### 🔧 Getters

```dart
bool get isRead                 // readAt != null
String get formattedDate        // 'الآن' / 'منذ X دقيقة' / 'منذ X يوم' / 'DD/MM/YYYY'
```

### 🏭 Factory

```dart
factory NotificationModel.fromJson(Map<String, dynamic> json)
```

Parses `read_at` and `created_at` as `DateTime`.

---

## 5️⃣ Solar Design Models

**File:** `lib/models/solar_design_models.dart`

**Purpose:** Lightweight models for **solar system projects** (used in "My Projects" listings).

### 📦 Models

| Model | Description |
|-------|-------------|
| `SolarMoney` | العملة |
| `SolarProject` | مشروع شمسي |

### 🔹 SolarMoney

```dart
class SolarMoney {
  final double amount;
  final String currency; // 'USD' or 'SYP'
}
```

**Getters:** `isSyp`, `isUsd`.

### 🔹 SolarProject

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Project ID |
| `projectNumber` | `String` | Project number |
| `status` | `String` | Status |
| `governorate` | `String?` | Governorate |
| `loadsCount` | `int` | Number of loads |
| `dailyEnergyWh` | `double` | Daily energy (Wh) |
| `designContinuousW` | `double` | Continuous power (W) |
| `chosenPlanKey` | `String?` | Chosen plan |
| `panelUnits` | `int` | Panel count |
| `batteryUnits` | `int` | Battery count |
| `inverterRatedW` | `double` | Inverter rated power |
| `pvArrayW` | `double` | PV array total |
| `equipmentTotal` | `SolarMoney` | Total equipment cost |
| `isSyp` | `bool` | SYP flag |
| `exchangeRate` | `double?` | Exchange rate |
| `createdAt` | `String?` | Creation date |

### 🔧 Getters

```dart
String get statusAr          // 'مسودة' / 'مؤكد' / 'ملغى'
String get planKeyAr         // 'اقتصادي' / 'متوازن' / 'ممتاز'
double get dailyEnergyKwh    // dailyEnergyWh / 1000
double get continuousKw      // designContinuousW / 1000
```

---

## 🔄 Common Patterns

### 🏭 Factory Constructors

All models provide a `fromJson(Map<String, dynamic> json)` factory for safe deserialization from API responses.

### 🛡️ Safe Parsing

Every model uses defensive parsing:
```dart
double.tryParse((json['field'] ?? 0).toString()) ?? 0
int.tryParse((json['field'] ?? 0).toString()) ?? 0
(json['field'] ?? '').toString()
```

### 💰 Dual Currency Support

`CartItemModel`, `LightingMoney`, and `SolarMoney` support both **USD** and **SYP** with helper getters and display methods.

### 🌍 Arabic Labels

- `severityAr`, `statusAr`, `planKeyAr`, `adequacyAr`, `lightColorAr`, `statusDesignAr`
- Extension methods for locale-specific string labels.

### 🏙️ Shipping Cities

`CartItemModel` and `LightingProductPick` share a common `shippingCities` structure:
```dart
[
{'city': 'دمشق', 'cost': '10.00'},
{'city': 'حلب', 'cost': '15.00'},
]
```

Handled by the internal `_parseShippingCities()` helper, which:
- Accepts `List`, `String` (JSON), or mixed types.
- Normalizes to `{'city': String, 'cost': String?}`.

---

## 📊 Model Comparison

| Feature | CartItem | Diagnosis | Lighting | Notification | Solar |
|---------|:--------:|:---------:|:--------:|:------------:|:-----:|
| `fromJson` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `toJson` | ✅ | ❌ | Partial | ❌ | ❌ |
| `copyWith` | ❌ | ❌ | ✅ | ❌ | ❌ |
| Dual currency | ✅ | ❌ | ✅ | ❌ | ✅ |
| Arabic labels | ❌ | ✅ | ✅ | ✅ | ✅ |
| Factory from API | ✅ (Product/Offer) | ❌ | ❌ | ❌ | ❌ |
| Extension helpers | ❌ | ❌ | ✅ | ❌ | ❌ |
| Enums / State | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## 📌 Naming Conventions

| Pattern | Example | Description |
|---------|---------|-------------|
| `XxxModel` | `CartItemModel`, `NotificationModel` | Standard models |
| `XxxResponse` | `DiagnosisSessionResponse`, `LightingDesignResponse` | API response wrappers |
| `XxxMoney` | `LightingMoney`, `SolarMoney` | Currency value objects |
| `XxxPlan` | `LightingPlan`, `LightingPlanMeta` | Design plans |
| `XxxPick` | `LightingProductPick` | Selected items |
| `XxxInput` | `LightingRoomInput` | Request payloads |
| `XxxInfo` | `DeviceInfo` | Metadata objects |
| `XxxTree` | `DeviceTree` | Hierarchical structures |

---

## 🔗 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  # No external packages required — all models use only dart:convert and dart:core
```

| Import | Used By |
|--------|---------|
| `dart:convert` | `CartItemModel` (`jsonDecode`) |
| `package:flutter/foundation.dart` | `LightingDesignResponse` (implicit) |

---

## 📝 Best Practices

1. **Always use `fromJson` factories** — never parse JSON manually.
2. **Null-safe parsing** — all models use `tryParse` with defaults.
3. **Dual currency** — check `hasSypPrices` before displaying SYP values.
4. **State detection** — use `DiagnosisSessionResponse` getters, not raw strings.
5. **Room profiles** — prefer `LightingConfig.profileFor(key)` over direct lookups.
6. **Shipping cost** — always call `isShippingPendingForCity` before showing zero.
7. **Arabic formatting** — use extension methods (`.statusAr`, `.lightColorAr`).

---

<div align="center">

**📦 NexSys Mobile Models**

</div>

---

## END Models - Flutter Mobile App