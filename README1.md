# 📚 NEX Mobile — Documentation Master Index

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Complete Reference for the NEX Mobile Application**

</div>

---

## 📖 How to Use This Document

This documentation is organized into **9 self-contained parts**. Each part is fully independent and can be read, shared, or merged separately. The full set covers:

| # | Part | Contents |
|---|------|----------|
| **0** | **Master Index** (this file) | Overview, architecture, conventions |
| **1** | [📦 Models](#part-1) | 5 model files — data layer |
| **2** | [🔧 Services](#part-2) | 24 services — service layer |
| **3** | [🧩 Widgets](#part-3) | 17 reusable UI components |
| **4** | [📱 Core Screens](#part-4) | Splash, Onboarding, Auth, Home, Search, Settings |
| **5** | [🛒 Commerce Screens](#part-5) | Cart, Checkout, Categories, Favorites, Offers, Products |
| **6** | [👤 Profile & Account Screens](#part-6) | Profile, Orders, Workshop, Notifications, Legal, Comparison |
| **7** | [☀️ Solar & System Builder](#part-7) | System Builder, Solar Systems, Solar Design, Maintenance |
| **8** | [🤖 AI & Diagnosis Screens](#part-8) | Appliances, Chats, Diagnosis, Engineer, Lighting |
| **9** | [🏢 Company Screens](#part-9) | Company dashboard, Products, Offers, Orders, Commission |

> 💡 **Tip:** Since this file is very long, use `Ctrl+F` with the numbered sections (e.g. `PART 2`) to jump around.

---

## 🏗️ High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
├──────────────────────────────────────────────────────────────┤
│  Screens (UI)  │  Widgets (Reusable UI)  │  Providers         │
├──────────────────────────────────────────────────────────────┤
│                    Service Layer (24 svc)                    │
│   Auth · Cart · Orders · Solar · Lighting · Diagnosis · …    │
├──────────────────────────────────────────────────────────────┤
│            ApiService (HTTP + Auto Token Refresh)            │
├──────────────────────────────────────────────────────────────┤
│  StorageService (SharedPrefs)  │  OfflineStorageService (Hive)│
├──────────────────────────────────────────────────────────────┤
│         Models (Cart · Diagnosis · Lighting · Solar · Notif) │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎨 Global Design Tokens

### 🎨 Color Palette (used across all screens)

| Token | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Blue** | `#60A5FA` | Highlights |
| **Dark Blue** | `#1E40AF` | Gradients |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success Green** | `#10B981` | Success / Appliances |
| **Emerald** | `#059669` | Wholesale |
| **Danger Red** | `#EF4444` / `#DC2626` | Errors / Danger |
| **Warning Amber** | `#F59E0B` | Warnings / Solar |
| **Purple** | `#7C3AED` / `#8B5CF6` | Wholesale / AI / Lighting |
| **Battery Green** | `#059669` | Batteries |
| **Cable Brown** | `#8B4513` | Cables |
| **Lighting Amber** | `#D97706` | Lighting |
| **SYP Amber** | `#D97706` | SYP prices |
| **Gold** | `#B45309` | Commission |
| **Day** | `#F59E0B` | Day hours |
| **Night** | `#6366F1` | Night hours |

### 🔤 Typography

- **Font:** Google Fonts **Cairo** (Arabic-first) — used everywhere
- **Poppins:** Logo / brand text (`NEX`)
- **Weights:** `w600` / `bold` most common
- **Sizes:** `9 – 36` (cards use `11 – 15`)

### 🧊 Common Design Patterns

| Pattern | Description |
|---------|-------------|
| **Glassmorphism** | `BackdropFilter(blur: 15)` + translucent overlays in bottom sheets |
| **Curved AppBar** | `ClipPath` + `_BottomCurveClipper` |
| **Gradient backgrounds** | `LinearGradient` on cards, headers, buttons |
| **Rounded corners** | `12 – 30` radius |
| **Shimmer placeholders** | While images load |
| **Hero animations** | Product/Offer image transitions (tag pattern: `{type}_{id}`) |
| **Squeeze animations** | `ScaleTransition` (`1.0 → 0.95`) on tap |
| **Pulse animations** | Weather icon, chat button, header icons |
| **Staggered entrances** | `flutter_staggered_animations` |
| **Floating SnackBars** | `SnackBarBehavior.floating` |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200 ms | Press scale (squeeze) |
| 300 ms | Wizard step transition / card entry |
| 400 ms | Dialog scale-in |
| 500 – 600 ms | Page fade-in |
| 700 – 800 ms | Large entrances |
| 1000 ms | Choice card scale |
| 1500 – 2000 ms | Pulse loops (reverse) |
| 4000 ms | Particle motion |
| 30 000 ms | Background rotation |

---

## 📐 Naming Conventions

### Models

| Pattern | Example | Meaning |
|---------|---------|---------|
| `XxxModel` | `CartItemModel`, `NotificationModel` | Standard model |
| `XxxResponse` | `DiagnosisSessionResponse` | API response wrapper |
| `XxxMoney` | `LightingMoney`, `SolarMoney` | Currency value object |
| `XxxPlan` | `LightingPlan` | Design plan |
| `XxxPick` | `LightingProductPick` | Selected items |
| `XxxInput` | `LightingRoomInput` | Request payload |
| `XxxInfo` | `DeviceInfo` | Metadata |
| `XxxTree` | `DeviceTree` | Hierarchical structure |

### Widgets

| Pattern | Example | Meaning |
|---------|---------|---------|
| `XxxCard` | `ProductCard`, `OfferCard` | Grid/list item card |
| `HomeXxxCard` | `HomeProductCard` | Home-specific card |
| `XxxOverlay` | `ChatOverlay` | Stack wrapper |
| `XxxBadge` | `CartBadge` | Small indicator |
| `XxxBar` | `GreetingBar` | Horizontal bar |
| `XxxCarousel` | `TextAdsCarousel` | Auto-rotating view |
| `XxxSheet` | `SolarOptionsSheet` | Bottom sheet |
| `showXxxDialog` | `showUnifiedReminderDialog` | Dialog function |
| `XxxBorder` | `AnimatedGradientBorder` | Decoration wrapper |

### Services

| Pattern | Example | Meaning |
|---------|---------|---------|
| **Singleton** | `CartService.instance` | Global single instance |
| **Static** | `PermissionService.requestMicrophone()` | Static methods only |
| **ChangeNotifier** | `AuthService`, `CartService` | Reactive state |
| **Extension** | `SolarApiService` (on `ApiService`) | Adds methods |
| **Instance-based** | `OrderApiService`, `RatingApiService` | Constructed with deps |

---

## 📦 App-Wide Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Networking & storage
  http: ^latest
  shared_preferences: ^latest
  hive: ^latest
  hive_flutter: ^latest

  # UI
  google_fonts: ^latest            # Cairo font
  cached_network_image: ^latest
  shimmer: ^latest
  lottie: ^latest
  smooth_page_indicator: ^latest
  carousel_slider: ^latest
  photo_view: ^latest
  fl_chart: ^latest
  flutter_staggered_animations: ^latest
  flutter_markdown: ^latest

  # Input / voice
  image_picker: ^latest
  speech_to_text: ^latest
  permission_handler: ^latest
  flutter_sound: ^latest
  audioplayers: ^latest

  # Maps & location
  flutter_map: ^latest
  latlong2: ^latest
  geocoding: ^latest
  geolocator: ^latest

  # Real-time & notifications
  pusher_channels_flutter: ^latest
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest

  # Utilities
  intl: ^latest
  share_plus: ^latest
  path_provider: ^latest
  url_launcher: ^latest
  provider: ^latest
```

---

## 🧭 Global Navigation Flow (High Level)

```
SplashScreen (2.8s)
    │
    ├─ Not seen onboarding? → OnboardingScreen → LoginScreen
    │
    ├─ Authenticated OR (Guest + governorate)?
    │     ├─ isAlwaysShowHub? → EntryHubScreen
    │     └─ else              → HomeScreen
    │
    └─ else → GovernorateSelectionScreen → HomeScreen

HomeScreen
    ├─ Commerce:  Categories → SubCategories → ProductsList → ProductDetails
    │             Offers → OfferDetails
    │             Cart → Checkout → Order confirmation
    │             Favorites · Comparison
    │
    ├─ Services:  MaintenanceServices → Diagnosis | Workshop | Engineer
    │             SystemBuilder · SolarWizard · SolarProjects
    │             LightingProjects · Appliance screens
    │
    ├─ Profile:   Profile → Orders | WorkshopHistory | Notifications
    │             → Company (if company_owner)
    │
    └─ AI Chats:  ChatScreen · SolarChat · SupportSolar · ApplianceSupport · LightingSupport
```

---

## ✅ Global Best Practices

1. **Initialize in order:** `StorageService.init()` → `OfflineStorageService.init()` → `AuthService` → others.
2. **Always use `fromJson` factories** — never parse JSON manually.
3. **Handle `session_expired: true`** in API responses by redirecting to login.
4. **Prefer `handleTokenExpiry()`** before authenticated requests.
5. **Use singletons** (`CartService.instance`, `FavoritesService.instance`, …) — never construct directly.
6. **Call `loadCart()`, `loadFavorites()`, `loadDraft()`** on app startup.
7. **Wrap in `Directionality(textDirection: TextDirection.rtl)`** for Arabic.
8. **Use `HapticFeedback`** on interactions for premium feel.
9. **Hero tags must be unique** — use `{type}_{id}` pattern.
10. **Use `_BottomCurveClipper`** for consistent header design.
11. **Handle guest mode** — most screens support guest submissions via `public/*` endpoints.
12. **Show shimmer loading** for all list screens.
13. **Empty + Error states** are mandatory for every network-driven list.
14. **Confirm dialogs** for destructive actions (delete, cancel, clear).
15. **Cache home data** via `OfflineStorageService.saveHomeData()` + `shouldRefresh()` (> 24h).

---

<div align="center">

**📚 End of Master Index — Parts 1-9 follow below**

</div>

---
---

# <a id="part-1"></a>📦 PART 1 — Models

**Location:** `lib/models/`

**Purpose:** Data models for the NEX Mobile Application. All models are pure Dart (no external packages — only `dart:convert` and `dart:core`).

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

## 📑 Model Files Overview

| # | File | Models | Purpose |
|---|------|--------|---------|
| 1 | `cart_item_model.dart` | `CartItemModel` | سلة التسوق (products + offers) |
| 2 | `diagnosis_models.dart` | 8 models + 1 map | نظام التشخيص والأعطال |
| 3 | `lighting_design_models.dart` | 15 models + 1 extension | تصميم الإضاءة |
| 4 | `notification_model.dart` | `NotificationModel` | الإشعارات |
| 5 | `solar_design_models.dart` | `SolarMoney`, `SolarProject` | تصميم الأنظمة الشمسية |

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
| `displayPrice()` | `{bool isSyp}` | `double` | Price by currency |
| `displayFinalPrice()` | `{bool isSyp}` | `double` | Final price by currency |
| `displayTotalPrice()` | `{bool isSyp}` | `double` | Total = finalPrice × quantity |
| `getShippingCostForCity()` | `String? governorate` | `double?` | Shipping cost |
| `isFreeShippingForCity()` | `String? governorate` | `bool` | Free shipping? |
| `isShippingPendingForCity()` | `String? governorate` | `bool` | Cost not yet set? |
| `isShippingCalculatedForCity()` | `String? governorate` | `bool` | Cost calculated? |

### 🏭 Factory Constructors

**`CartItemModel.fromProduct(Map<String, dynamic> product, {int quantity = 1})`**
Creates a cart item from a product API response. Default `itemType = 'product'`.

**`CartItemModel.fromOffer(Map<String, dynamic> offer, {int quantity = 1})`**
Creates a cart item from an offer, extracting nested `products_in_offer`. Default `itemType = 'offer'`. Stock defaults to `999999` if unlimited.

**`CartItemModel.fromJson(Map<String, dynamic> json)`** — Standard JSON deserialization (snake_case).

### 📤 Serialization

`Map<String, dynamic> toJson()` produces:

`id`, `name`, `slug`, `price`, `final_price`, `price_syp`, `final_price_syp`, `image`, `stock`, `quantity`, `discount_percentage`, `item_type`, `products_in_offer`, `total_wattage`, `total_capacity`, `shipping_cities`.

### 🔒 Private Helpers

```dart
static List<Map<String, dynamic>>? _parseShippingCities(dynamic rawCities)
```

Safely parses shipping cities from either a `List`, JSON `String`, or mixed types. Each city is normalized to `{'city': String, 'cost': String?}`.

---

## 2️⃣ Diagnosis Models

**File:** `lib/models/diagnosis_models.dart`

**Purpose:** Models for the **AI-powered diagnosis system** — device tree, fault detection, inverter error codes, session state.

### 📦 Models

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

**Getter:** `severityAr` → `'عادي'` / `'عاجل'` / `'خطر'`.

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
> 💡 `fromJson` automatically unwraps the `data` field if present.

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

- **`SearchResult`** — single fault search result with `toFault()` converter.
- **`SearchResponse`** — contains `query`, `count`, `results: List<SearchResult>`.

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

**Purpose:** Complete model set for the **AI-powered lighting design system** — room profiling, plans, product picks, distribution, projects.

### 📦 Models (15 + 1 extension)

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

Request payload for a room design attempt. Supports `copyWith`.

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
| `productType`, `slug`, `image`, `price`, `finalPrice`, `discountPercentage`, `stock`, `brand`, `model`, `hasShipping`, `shippingCities` | (extra ordering fields) |

### 🔹 LightingDistributionPlan

| Field | Type |
|-------|------|
| `layoutType` | `String` |
| `rows`, `columns` | `int?` |
| `spacingXM`, `spacingYM` | `double?` |
| `wallOffsetXM`, `wallOffsetYM` | `double?` |
| `messageAr` | `String` |

### 🔹 LightingPlan

Full design plan (economic / balanced / premium).

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

Result of re-checking a modified selection. **Getters:** `isAdequate`, `isLow`, `isExcessive`.

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
`NotificationModel.fromJson(Map<String, dynamic> json)` — parses `read_at` and `created_at` as `DateTime`.

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

## 🔄 Models — Common Patterns

### 🏭 Factory Constructors
All models provide `fromJson(Map<String, dynamic> json)` for safe deserialization.

### 🛡️ Safe Parsing
```dart
double.tryParse((json['field'] ?? 0).toString()) ?? 0
int.tryParse((json['field'] ?? 0).toString()) ?? 0
(json['field'] ?? '').toString()
```

### 💰 Dual Currency Support
`CartItemModel`, `LightingMoney`, `SolarMoney` support both **USD** and **SYP**.

### 🌍 Arabic Labels
`severityAr`, `statusAr`, `planKeyAr`, `adequacyAr`, `lightColorAr`, `statusDesignAr` — extension methods.

### 🏙️ Shipping Cities
```dart
[
  {'city': 'دمشق', 'cost': '10.00'},
  {'city': 'حلب', 'cost': '15.00'},
]
```
Handled by `_parseShippingCities()`:
- Accepts `List`, `String` (JSON), or mixed types.
- Normalizes to `{'city': String, 'cost': String?}`.

---

## 📊 Model Feature Comparison

| Feature | CartItem | Diagnosis | Lighting | Notification | Solar |
|---------|:--------:|:---------:|:--------:|:------------:|:-----:|
| `fromJson` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `toJson` | ✅ | ❌ | Partial | ❌ | ❌ |
| `copyWith` | ❌ | ❌ | ✅ | ❌ | ❌ |
| Dual currency | ✅ | ❌ | ✅ | ❌ | ✅ |
| Arabic labels | ❌ | ✅ | ✅ | ✅ | ✅ |
| Factory from API | ✅ | ❌ | ❌ | ❌ | ❌ |
| Extension helpers | ❌ | ❌ | ✅ | ❌ | ❌ |
| Enums / State | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## 📝 Models — Best Practices

1. **Always use `fromJson` factories** — never parse JSON manually.
2. **Null-safe parsing** — use `tryParse` with defaults.
3. **Dual currency** — check `hasSypPrices` before displaying SYP.
4. **State detection** — use `DiagnosisSessionResponse` getters, not raw strings.
5. **Room profiles** — prefer `LightingConfig.profileFor(key)` over direct lookups.
6. **Shipping cost** — always call `isShippingPendingForCity` before showing zero.
7. **Arabic formatting** — use extension methods (`.statusAr`, `.lightColorAr`).

---

## 🔗 Models — Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  # No external packages — all models use only dart:convert and dart:core
```

| Import | Used By |
|--------|---------|
| `dart:convert` | `CartItemModel` (`jsonDecode`) |
| `package:flutter/foundation.dart` | `LightingDesignResponse` (implicit) |

---

<div align="center">

**📦 End of Part 1 — Models**

</div>

---

# <a id="part-2"></a>🔧 PART 2 — Services

**Location:** `lib/services/`

**Purpose:** Service layer for the NEX Mobile Application — HTTP, auth, storage, shopping, orders, solar, lighting, diagnosis, notifications, real-time, permissions, voice, UI utilities.

---

## 📑 Services Overview

| # | Category | Services |
|---|----------|----------|
| 1 | Core HTTP | `ApiService` |
| 2 | Authentication | `AuthService` |
| 3 | Storage | `StorageService`, `OfflineStorageService` |
| 4 | Shopping | `CartService`, `FavoritesService`, `ComparisonService` |
| 5 | Orders & Ratings | `OrderApiService`, `RatingApiService` |
| 6 | System Builder | `SystemBuilderService`, `SystemBuilderDraftService` |
| 7 | Solar | `SolarApiService`, `SolarSystemService` |
| 8 | Lighting | `LightingApiService` |
| 9 | Diagnosis | `DiagnosisApiService` |
| 10 | Notifications | `NotificationService`, `LocalNotificationService` |
| 11 | Real-time | `PusherService` |
| 12 | Permissions & Voice | `PermissionService`, `VoiceService` |
| 13 | UI Utilities | `FontScaleManager`, `TextAdService` |

---

## 📁 File Structure

```
lib/services/
├── api_service.dart                       # Core HTTP client
├── auth_service.dart                      # Authentication
├── storage_service.dart                   # Local key-value storage
├── offline_storage_service.dart           # Hive-based offline cache
├── cart_service.dart                      # Shopping cart
├── favorites_service.dart                 # Favorites
├── comparison_service.dart                # Product/Offer comparison
├── order_api_service.dart                 # Orders API
├── rating_api_service.dart                # Ratings API
├── system_builder_service.dart            # System builder API
├── system_builder_draft_service.dart      # System builder draft
├── solar_api_service.dart                 # Solar design API
├── solar_system_service.dart              # Solar systems API
├── lighting_api_service.dart              # Lighting design API
├── diagnosis_api_service.dart             # Diagnosis API
├── notification_service.dart              # FCM + local notif
├── local_notification_service.dart        # Local notifications
├── pusher_service.dart                    # Pusher real-time
├── permission_service.dart                # Permissions
├── voice_service.dart                     # Voice recording
├── font_scale_manager.dart                # Font scale control
├── text_ad_service.dart                   # Text advertisements
├── showUnifiedReminderDialog.dart         # Reminder dialog UI
└── maintenance_services_screen.dart       # Maintenance screen UI
```

---

## 1️⃣ Core HTTP

### 🔹 ApiService

**File:** `lib/services/api_service.dart`

**Purpose:** Central HTTP client wrapping all API calls with token management, automatic token refresh on 401, and unified error handling.

#### 📋 Constructor
```dart
ApiService({required StorageService storageService})
```
Loads the stored token on initialization and exposes `setToken(String)` for updates.

#### 🌐 HTTP Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `(String endpoint, {bool requiresAuth = false, Map<String, dynamic>? queryParams})` | HTTP GET |
| `post` | `(String endpoint, {required Map<String, dynamic> data, bool requiresAuth = false, List<File>? files})` | HTTP POST (auto-multipart if files) |
| `put` | `(String endpoint, {required Map<String, dynamic> data, bool requiresAuth = false})` | HTTP PUT |
| `delete` | `(String endpoint, {bool requiresAuth = false, Map<String, dynamic>? data})` | HTTP DELETE |
| `uploadImage` | `(String endpoint, File imageFile, {bool requiresAuth = false})` | Upload `profile_image` |
| `_postMultipart` | (private) | Internal multipart handler |
| `_getHeaders` | (private) | Builds headers with `Bearer` token |
| `_getHeadersWithAuth` | (private) | Async headers with token lookup |
| `_handleResponse` | (private) | Centralized response parser |

#### 📤 Response Format
```dart
{
  // Success:
  "success": true,
  "message": "...",
  "data": { ... }

  // Error:
  "error": true,
  "message": "...",
  "statusCode": 4xx,
  "errors": {...},          // validation errors
  "session_expired": true,  // 401 without refresh
}
```

#### 🔄 Auto Token Refresh (401)
When a `401 Unauthorized` is received:
1. Reads `remember_token` from storage.
2. Calls `POST /v1/user/public/refresh-token` with the remember token.
3. On success → saves new `token`, `remember_token`, `token_created_at` and returns `{error: true, message: 'TOKEN_REFRESHED', statusCode: 401}`.
4. On failure → clears tokens and returns `session_expired: true`.

#### 📌 Domain-Specific Methods

**Chat (Authenticated + Guest)**

| Method | Endpoint | Description |
|--------|----------|-------------|
| `startGuestSession()` | `POST /v1/user/public/chat/start` | Guest chat session |
| `sendGuestMessage()` | `POST /v1/user/public/chat/send` | Send guest text |
| `getGuestChatHistory()` | `GET /v1/user/public/chat/history` | Guest history |
| `clearGuestChat()` | `POST /v1/user/public/chat/clear` | Clear guest |
| `updateGuestGovernorate()` | `POST /v1/user/public/chat/update-governorate` | Update governorate |
| `getCalculationResult()` | `GET /v1/user/public/chat/calculation-result` | Calculation result |
| `sendMessageWithImages()` | `POST /v1/user/chat/send-with-image` | Multi-image message |
| `sendVoiceMessage()` | `POST /v1/user/chat/send-voice` | Voice (auth / guest) |
| `sendImageWithVoice()` | `POST /v1/user/chat/send-image-with-voice` | Image + voice |
| `sendGuestMessageWithImage()` | `POST /v1/user/public/chat/send-with-image` | Guest image |

**Solar Chat**

| Method | Endpoint |
|--------|----------|
| `startGuestSolarSession()` | `POST /v1/user/public/solar-chat/start` |
| `sendSolarMessage()` | `POST .../solar-chat/send` |
| `sendSolarMessageWithImage()` | `POST .../solar-chat/send-with-image` |
| `sendSolarVoiceMessage()` | `POST .../solar-chat/send-voice` |
| `getSolarChatHistory()` | `GET .../solar-chat/history` |
| `clearSolarChat()` | `DELETE .../solar-chat/clear` |

**Support Solar Chat**

| Method | Endpoint |
|--------|----------|
| `startGuestSupportSession()` | `POST /v1/user/public/support-solar/start` |
| `sendSupportMessage()` | `POST .../support-solar/send` |
| `sendSupportMessageWithImage()` | `POST .../support-solar/send-with-image` |
| `sendSupportVoiceMessage()` | `POST .../support-solar/send-voice` |
| `getSupportChatHistory()` | `GET .../support-solar/history` |
| `closeSupportConversation()` | `POST .../support-solar/close` |
| `clearSupportConversation()` | `DELETE .../support-solar/clear` |

**Appliance**

| Method | Endpoint |
|--------|----------|
| `checkApplianceCompatibility()` | `POST .../appliance-compatibility/check` |
| `getCompatibilityHistory()` | `GET .../appliance-compatibility/history` |
| `calculateApplianceSavings()` | `POST .../appliance-savings/calculate` |
| `generateApplianceSchedule()` | `POST .../appliance-schedule/generate` |
| `startGuestMaintenanceSession()` | `POST .../appliance-maintenance/start` |
| `sendMaintenanceMessage()` | `POST .../appliance-maintenance/send` |
| `sendMaintenanceImage()` | `POST .../appliance-maintenance/send-image` |
| `sendMaintenanceVoice()` | `POST .../appliance-maintenance/send-voice` |
| `getMaintenanceHistory()` | `GET .../appliance-maintenance/history` |
| `clearMaintenanceConversation()` | `DELETE .../appliance-maintenance/clear` |
| `startGuestApplianceSupportSession()` | `POST .../appliance-support/start` |
| `sendApplianceSupportMessage()` | `POST .../appliance-support/send` |
| `sendApplianceSupportImage()` | `POST .../appliance-support/send-image` |
| `sendApplianceSupportVoice()` | `POST .../appliance-support/send-voice` |
| `getApplianceSupportHistory()` | `GET .../appliance-support/history` |
| `clearApplianceSupportConversation()` | `DELETE .../appliance-support/clear` |
| `getInverterAppliances()` | `GET /v1/user/public/inverter-appliances` |

**Lighting Support Chat**

| Method | Endpoint |
|--------|----------|
| `startGuestLightingSupportSession()` | `POST .../lighting-support/start` |
| `sendLightingSupportMessage()` | `POST .../lighting-support/send` |
| `sendLightingSupportImage()` | `POST .../lighting-support/send-image` |
| `sendLightingSupportVoice()` | `POST .../lighting-support/send-voice` |
| `getLightingSupportHistory()` | `GET .../lighting-support/history` |
| `clearLightingSupportConversation()` | `DELETE .../lighting-support/clear` |

**Notifications**

| Method | Endpoint |
|--------|----------|
| `getUnreadNotificationsCount()` | `GET /v1/user/notifications/count/unread` |
| `getAllNotifications()` | `GET /v1/user/notifications?page=&per_page=` |
| `getUnreadNotifications()` | `GET /v1/user/notifications/unread` |
| `getNotification(id)` | `GET /v1/user/notifications/{id}` |
| `markAsRead(id)` | `PUT /v1/user/notifications/{id}/read` |
| `markAllAsRead()` | `PUT /v1/user/notifications/read-all` |
| `deleteNotification(id)` | `DELETE /v1/user/notifications/{id}` |
| `deleteAllNotifications()` | `DELETE /v1/user/notifications` |
| `sendFcmToken(token)` | `POST /v1/user/fcm-token` |

**Maintenance**

| Method | Endpoint |
|--------|----------|
| `sendMaintenanceRequest()` | `POST /v1/user/public/maintenance` (multipart) |
| `fetchMaintenanceRequests()` | `GET /v1/user/public/maintenance/my-requests` |

---

## 2️⃣ Authentication

### 🔹 AuthService

**File:** `lib/services/auth_service.dart`

**Purpose:** Extends `ChangeNotifier` — full authentication lifecycle manager (login, register, verify, reset, guest, biometrics).

#### 📋 Constructor
```dart
AuthService({required StorageService storageService})
```
Automatically loads auth state on construction. Wraps an internal `ApiService`.

#### 🔧 Public Getters
```dart
String? get token
bool get isAuthenticated
bool get isGuest
```

#### 📋 Public Methods

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `refreshAuthState()` | — | `Future<void>` | Reload from storage + notify |
| `login()` | `email, password` | `Map` | Login |
| `register()` | `name, email, phone, password, passwordConfirmation, governorate, district, address, userType, [referralCode]` | `Map` | Register |
| `verifyEmail()` | `email, code` | `Map` | Verify email |
| `resendVerificationCode()` | `email` | `Map` | Resend code |
| `sendPasswordResetCode()` | `email` | `Map` | Send reset code |
| `verifyPasswordResetCode()` | `email, code` | `Map` | Verify reset code |
| `resetPassword()` | `email, password, passwordConfirmation` | `Map` | Reset password |
| `continueAsGuest()` | — | `Future<void>` | Enter guest mode |
| `logout()` | — | `Future<void>` | Logout & clear |
| `setGuestGovernorate()` | `governorate` | `Future<void>` | Save guest gov. |
| `sendFcmTokenToServer()` | — | `Future<void>` | Send FCM token |
| `getUserData()` | — | `Map?` | Fetch cached user |
| `validateToken()` | — | `Future<bool>` | Check token exists |
| `refreshToken()` | — | `Future<bool>` | Refresh via remember_token |
| `handleTokenExpiry()` | — | `Future<bool>` | Smart expiry handler |
| `refreshTokenDirectly()` | `rememberToken` | `Future<bool>` | Direct refresh |

#### 🔐 Login Response Handling
```dart
// Success
{
  'success': true,
  'data': { userType, name, governorate, ... },
  'user_type': 'customer',
  'token': '...',
}

// Email verification required
{
  'success': false,
  'message': 'يجب تأكيد البريد الإلكتروني أولاً',
  'data': { 'email_verification_required': true, 'email': email },
}
```

#### 🔄 Token Lifecycle
- **30-day** lifespan stored as `token_created_at`.
- `isTokenExpired()` → expired after 30 days.
- `isTokenExpiringSoon()` → expiring within 5 days.
- Both handled automatically via `handleTokenExpiry()`.

---

## 3️⃣ Storage

### 🔹 StorageService

**File:** `lib/services/storage_service.dart`

**Purpose:** Wrapper over `SharedPreferences` for all app-level key-value storage.

#### 📋 Init
```dart
Future<void> init()  // Must be called once at startup
```

#### 🔑 Auth & User

| Key | Methods |
|-----|---------|
| `token` | `saveToken`, `getToken`, `removeToken` |
| `remember_token` | `saveRememberToken`, `getRememberToken`, `removeRememberToken` |
| `token_created_at` | `saveTokenCreatedAt`, `getTokenCreatedAt`, `isTokenExpired`, `isTokenExpiringSoon` |
| `user_data` | `saveUserData`, `getUserData` |
| `user_data_map` | `saveUserDataMap`, `getUserDataMap` |
| `user_name` | `saveUserName`, `getUserName` |
| `governorate` | `saveGovernorate`, `getGovernorate` |
| `guest_mode` | `setGuestMode`, `isGuestMode` |

#### 💱 Currency

| Key | Methods |
|-----|---------|
| `preferred_currency` | `savePreferredCurrency`, `getPreferredCurrency`, `isSypPreferred`, `isUsdPreferred` |

**Constants:** `currencyUsd` = `'usd'`, `currencySyp` = `'syp'`.

#### 💬 Chat Session IDs

| Session | Save | Get | Clear |
|---------|------|-----|-------|
| Solar Guest | `saveGuestSolarSessionId` | `getGuestSolarSessionId` | `clearGuestSolarSessionId` |
| Guest Chat | `saveGuestSessionId` | `getGuestSessionId` | — |
| Support Solar | `saveGuestSupportSessionId` | `getGuestSupportSessionId` | `clearGuestSupportSessionId` |
| Maintenance | `saveGuestMaintenanceSessionId` | `getGuestMaintenanceSessionId` | `clearGuestMaintenanceSessionId` |
| Appliance Support | `saveGuestApplianceSupportSessionId` | `getGuestApplianceSupportSessionId` | `clearGuestApplianceSupportSessionId` |
| Lighting Support | `saveGuestLightingSupportSessionId` | `getGuestLightingSupportSessionId` | `clearGuestLightingSupportSessionId` |
| Lighting | `saveLightingSessionId` | `getLightingSessionId` | `removeLightingSessionId` |

#### 🎛️ UI Preferences

| Key | Methods |
|-----|---------|
| `onboarding_seen` | `setOnboardingSeen`, `isOnboardingSeen` |
| `custom_quick_actions` | `saveCustomQuickActions`, `getCustomQuickActions` |
| `quick_actions_expanded` | `saveQuickActionsExpanded`, `isQuickActionsExpanded` |
| `always_show_hub` | `saveAlwaysShowHub`, `isAlwaysShowHub` |
| `show_unified_reminder` | `saveShowUnifiedReminder`, `isShowUnifiedReminder` |

#### 🧹 Reset
```dart
Future<void> clearAll()  // Clears ALL preferences
```

---

### 🔹 OfflineStorageService

**File:** `lib/services/offline_storage_service.dart`

**Purpose:** Static Hive-based offline cache for home screen data, category listings, product/offer details, notifications, and user orders.

#### 📋 Init
```dart
static Future<void> init()   // Hive.initFlutter + open 'home_data_cache'
```

#### 📦 Home Screen Data
```dart
static Future<void> saveHomeData({
  required List mainCategories,
  required List mostViewedProducts,
  required List topRatedProducts,
  required List latestProducts,
  required List randomProducts,
  required List featuredOffers,
  required List latestOffers,
  required List cheapestOffers,
  required List highestPowerOffers,
  required List electricalAppliances,
  required List electricalExtensions,
  required List homeLighting,
  List advertisements = const [],
  List textAds = const [],
})

static Map<String, dynamic> getHomeData()
static bool hasCachedData()
static DateTime? getLastUpdated()
static bool shouldRefresh()   // true if >24h old
static Future<void> clearCache()
```

#### 📂 Categories

| Method | Description |
|--------|-------------|
| `saveMainCategories(List)` / `getMainCategories()` | Main categories |
| `saveSubCategories({categoryKey, subCategories})` / `getSubCategories(key)` | Per-category sub-categories |

#### 🏷️ Product / Offer Details

| Method | Description |
|--------|-------------|
| `saveOfferDetails({offerSlug, offer, similarOffers})` / `getOfferDetails(slug)` | Offer details cache |
| `saveProductDetails({productSlug, product, similarProducts})` / `getProductDetails(slug)` | Product details cache |
| `saveProductsList({key, products})` / `getProductsList(key)` | Arbitrary product lists |
| `saveOffersList({filterKey, offers})` / `getOffersList(filterKey)` | Filtered offer lists |

#### 🔔 Notifications & Orders

| Method | Description |
|--------|-------------|
| `saveNotifications(List)` / `getNotifications()` | Notification cache |
| `saveUserProfile(Map)` / `getUserProfile()` | User profile cache |
| `saveOrders(List)` / `getOrders()` | User orders cache |

#### 🔒 Private Helpers
```dart
static List<dynamic> _decodeList(dynamic data)  // Safe JSON list parser
```

---

## 4️⃣ Shopping

### 🔹 CartService

**File:** `lib/services/cart_service.dart`

**Purpose:** Singleton (`ChangeNotifier`) for shopping cart management — supports products, offers, dual currency, and per-city shipping.

#### 🏭 Access
```dart
CartService.instance
```

#### 📊 Getters

| Getter | Type | Description |
|--------|------|-------------|
| `items` | `List<CartItemModel>` | Immutable list |
| `itemCount` | `int` | Number of items |
| `totalQuantity` | `int` | Sum of quantities |
| `totalPrice` | `double` | Sum of final prices |
| `originalTotalPrice` | `double` | Sum of original prices |
| `totalDiscount` | `double` | `originalTotalPrice - totalPrice` |
| `calculatedShippingCost` | `double` | Total shipping for governorate |
| `totalPriceWithShipping` | `double` | `totalPrice + shippingCost` |
| `pendingShippingItemsCount` | `int` | Items without calculated shipping |
| `freeShippingItemsCount` | `int` | Items with free shipping |
| `calculatedShippingItemsCount` | `int` | Items with shipping cost |
| `hasPendingShipping` | `bool` | If any pending shipping |
| `productsCount` | `int` | Number of products |
| `offersCount` | `int` | Number of offers |

#### 🔧 Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `loadCart()` | — | Load from SharedPreferences |
| `addItem(item)` | `CartItemModel` | Add product (increments if exists) |
| `addOffer(offer)` | `CartItemModel` | Add offer |
| `updateQuantity(id, qty, {itemType})` | — | Update quantity (removes if ≤ 0) |
| `removeItem(id, {itemType})` | — | Remove item |
| `clearCart()` | — | Empty cart |
| `isInCart(id, {itemType})` | — | Check presence |
| `getItemQuantity(id, {itemType})` | — | Get quantity |
| `getOrderData()` | — | Build `{products: [...], offers: [...]}` payload |

#### 💾 Persistence
Auto-saved to `SharedPreferences` under key `'cart_items'` on every mutation.

#### 🌍 Governorate
```dart
String? userGovernorate;  // set externally for shipping calc
```

---

### 🔹 FavoritesService

**File:** `lib/services/favorites_service.dart`

**Purpose:** Singleton for persisting favorite products and offers locally.

#### 🏭 Access
```dart
FavoritesService.instance
```

#### 📊 Getters
```dart
List<Map<String, dynamic>> get favoriteProducts
List<Map<String, dynamic>> get favoriteOffers
int get productsCount
int get offersCount
int get totalCount
```

#### 🔧 Methods

| Method | Parameters | Returns |
|--------|-----------|---------|
| `loadFavorites()` | — | `Future<void>` |
| `addProduct(product)` | `Map` | `Future<bool>` (false if already exists) |
| `addOffer(offer)` | `Map` | `Future<bool>` |
| `removeProduct(id)` | `int` | `Future<bool>` |
| `removeOffer(id)` | `int` | `Future<bool>` |
| `isProductFavorite(id)` | `int` | `bool` |
| `isOfferFavorite(id)` | `int` | `bool` |
| `clearAll()` | — | `Future<void>` |
| `clearOldData()` | — | `Future<void>` |

#### 🗄️ Storage Keys
`'favorite_products'`, `'favorite_offers'` — JSON arrays in SharedPreferences.

#### 🧩 Data Normalization
On add, both products and offers are normalized to include: `id`, `name`, `name_ar`, `name_en`, `slug`, `price`, `discount_price`, `final_price`, `price_syp`, `discount_price_syp`, `final_price_syp`, `main_image`/`cover_image`, `discount_percentage`, `rate`, `has_discount`, plus offer-specific `total_wattage` and `total_capacity`.

---

### 🔹 ComparisonService

**File:** `lib/services/comparison_service.dart`

**Purpose:** Singleton for managing up to **4 products** and **4 offers** side-by-side comparison.

#### 🏭 Access
```dart
ComparisonService.instance
```

#### 📊 Getters
```dart
List<Map<String, dynamic>> get products   // max 4
List<Map<String, dynamic>> get offers     // max 4
int get productsCount
int get offersCount
```

#### 🔧 Methods

| Method | Returns | Notes |
|--------|---------|-------|
| `loadComparisonData()` | `Future<void>` | Load from prefs |
| `addProduct(product)` | `Future<bool>` | false if exists or ≥ 4 |
| `addOffer(offer)` | `Future<bool>` | false if exists or ≥ 4 |
| `removeProduct(id)` | `Future<void>` | — |
| `removeOffer(id)` | `Future<void>` | — |
| `clearProducts()` / `clearOffers()` / `clearAll()` | `Future<void>` | — |
| `isProductInComparison(id)` / `isOfferInComparison(id)` | `bool` | — |

#### 🗄️ Storage Keys
`'comparison_products'`, `'comparison_offers'`.

---

## 5️⃣ Orders & Ratings

### 🔹 OrderApiService

**File:** `lib/services/order_api_service.dart`

**Purpose:** Handles order creation, retrieval, cancellation, coupon validation, and statistics.

#### 📋 Constructor
```dart
OrderApiService({required String baseUrl, required AuthService authService})
```
Base URL is prefixed with `$baseUrl/api/nex/...`.

#### 🔧 Methods

| Method | Parameters | Endpoint |
|--------|-----------|----------|
| `createOrder()` | `firstName, lastName, phone, shippingAddress, paymentMethod, items, [couponCode, userNotes, isPrepaid, isSyp, governorate]` | `POST /orders/create` |
| `getUserOrders()` | `[page = 1, status]` | `GET /orders/my-orders` |
| `getOrderDetails(invoiceId)` | `int` | `GET /orders/{invoiceId}` |
| `cancelOrder(invoiceId)` | `int` | `POST /orders/{invoiceId}/cancel` |
| `validateCoupon(code, subtotal)` | `String, double` | `POST /orders/validate-coupon` |
| `getOrderStats()` | — | `GET /orders/stats` |

#### 📤 Response Format
```dart
// Success
{
  'success': true,
  'data': { invoice: {...}, items: [...], customer: {...} }
}

// Error
{
  'success': false,
  'message': '...',
  'errors': {...}
}
```

---

### 🔹 RatingApiService

**File:** `lib/services/rating_api_service.dart`

**Purpose:** Manage product/offer ratings for completed invoices.

#### 📋 Constructor
```dart
RatingApiService({required String baseUrl, required AuthService authService})
```

#### 🔧 Methods

| Method | Parameters | Endpoint |
|--------|-----------|----------|
| `getRateableItems(invoiceId)` | `int` | `GET /ratings/invoice/{invoiceId}/items` |
| `submitRating()` | `invoiceId, itemId, itemType, rating, [review]` | `POST /ratings/store` |

---

## 6️⃣ System Builder

### 🔹 SystemBuilderService

**File:** `lib/services/system_builder_service.dart`

**Purpose:** Full API for the solar system builder (products, orders, analysis, auto-design, human design requests, pricing settings).

#### 📋 Constructor
```dart
SystemBuilderService({required AuthService authService})
```

#### 🔧 Methods

| Method | Description | Endpoint |
|--------|-------------|----------|
| `getProducts(type, {search, page})` | Product listing by type | `GET /system-builder/products` |
| `getPrepaidPercentage()` | Prepaid discount % | `GET /setting/aldfaa_almsbk` |
| `createOrder()` | Create system order | `POST /system-builder/order` |
| `updateOrder()` | Update order | `PUT /system-builder/orders/{id}` |
| `cancelOrder(orderId)` | Cancel order | `POST /system-builder/orders/{id}/cancel` |
| `getMyOrders()` | User orders | `GET /system-builder/my-orders` |
| `analyzeSystem()` | Compatibility analysis | `POST /system-builder/analyze` |
| `autoDesign()` | AI auto design | `POST /system-builder/auto-design` |
| `requestHumanDesign()` | Human designer request | `POST /system-builder/request-human-design` |
| `getInstallationPrice({isSyp})` | Installation price | `GET /setting/installation_almnthom` |
| `getMountingBasePrice({isSyp})` | Mounting price per panel | `GET /setting/solar_mounting_base_price_per_panel` |

#### 📤 Response Format
```dart
// createOrder / updateOrder
{
  'success': bool,
  'message': String,
  'data': {...},
  'compatibility': {...} | null
}

// analyzeSystem
{
  'success': true,
  'data': {
    'components': {...},
    'statistics': {...},
    'compatibility': {score, summary, issues, warnings},
    'ai_analysis': '...',
  }
}
```

---

### 🔹 SystemBuilderDraftService

**File:** `lib/services/system_builder_draft_service.dart`

**Purpose:** Singleton (`ChangeNotifier`) persisting an in-progress system builder draft across sessions.

#### 🏭 Access
```dart
SystemBuilderDraftService.instance
```

#### 📊 Getters
```dart
List<Map<String, dynamic>> get panels
List<Map<String, dynamic>> get inverters
List<Map<String, dynamic>> get batteries
List<Map<String, dynamic>> get cables
List<Map<String, dynamic>> get panelBoards
bool get hasDraft
int get totalItems   // Sum of quantities across all categories
```

#### 🔧 Methods

| Method | Parameters |
|--------|-----------|
| `loadDraft()` | — |
| `saveDraft({panels, inverters, batteries, cables, panelBoards})` | Lists |
| `clearDraft()` | — |

#### 🗄️ Storage Key
`'system_builder_draft'` — JSON object with all five component arrays.

---

## 7️⃣ Solar

### 🔹 SolarApiService (Extension)

**File:** `lib/services/solar_api_service.dart`

**Purpose:** `extension` on `ApiService` for **solar design projects** (draft, projects, compare, duplicate).

#### 🔧 Methods

| Method | Endpoint |
|--------|----------|
| `solarSaveDraft({sessionId, [planKey, isSyp, requiresAuth]})` | `POST /solar-design/save-draft` |
| `solarMyProjects({[sessionId, requiresAuth]})` | `GET /solar-design/projects` |
| `solarShowProject({projectId, [sessionId, requiresAuth]})` | `GET /solar-design/projects/{id}` |
| `solarDeleteProject({projectId, [sessionId, requiresAuth]})` | `DELETE /solar-design/projects/{id}` |
| `solarDuplicateProject({projectId, [sessionId, requiresAuth]})` | `POST /solar-design/projects/{id}/duplicate` |
| `solarCompareProjects({projectIds, [sessionId, requiresAuth]})` | `POST /solar-design/projects/compare` |

#### 🔐 Auth Toggle
All methods accept `requiresAuth` — swaps between:
- `/v1/user/solar-design` (authenticated)
- `/v1/user/public/solar-design` (guest)

Guest calls require a `session_id` query param.

---

### 🔹 SolarSystemService

**File:** `lib/services/solar_system_service.dart`

**Purpose:** Manages user-owned solar systems (CRUD).

#### 📋 Constructor
```dart
SolarSystemService({required String baseUrl, required AuthService authService})
```

#### 🔧 Methods

| Method | Description |
|--------|-------------|
| `getUserSolarSystems({page = 1})` | List systems |
| `getSolarSystemDetails(systemId)` | System details |
| `addSolarSystem({...})` | Add with multipart image upload |
| `deleteSolarSystem(systemId)` | Delete system |

#### 📤 `addSolarSystem` Parameters
**Required:** `installationDate`, `isNew`, `panelsCount`, `panelWattage`, `inverterPower`, `inverterCount`, `batteriesCount`, `batteryCapacity`

**Optional:** `previousIssues`, `notes`, `panelBrand`, `panelImage` (File), `inverterType`, `inverterBrand`, `inverterImage` (File), `batteryType`, `batteryBrand`, `batteryImage` (File), `detailsNotes`

#### 🖼️ Multipart Fields
Images use keys: `panel_image`, `inverter_image`, `battery_image`.

---

## 8️⃣ Lighting

### 🔹 LightingApiService (Extension)

**File:** `lib/services/lighting_api_service.dart`

**Purpose:** `extension` on `ApiService` for the AI-powered lighting design system.

#### 🔧 Methods

| # | Method | Endpoint |
|---|--------|----------|
| 1 | `lightingDesignConfig({[requiresAuth]})` | `GET .../config` |
| 2 | `lightingDesignStart({[governorate, requiresAuth]})` | `POST .../start` |
| 3 | `lightingUploadRoomPhoto({sessionId, photo, [requiresAuth]})` | `POST .../upload-photo` (multipart) |
| 4 | `lightingDesign({room, [sessionId, projectId, governorate, withAi, isSyp, requiresAuth]})` | `POST .../design` |
| 5 | `lightingRecheck({room, items, [isSyp, requiresAuth]})` | `POST .../recheck` |
| 6 | `lightingAlternatives({room, role, [fixtureType, requiresAuth]})` | `POST .../alternatives` |
| 7 | `lightingReplaceUnavailable({room, unavailableItem, [requiresAuth]})` | `POST .../replace-unavailable` |
| 8 | `lightingCompareAttempts({room, first, second, [requiresAuth]})` | `POST .../compare-attempts` |
| 9 | `lightingProjectSummary({projectId, rooms, [requiresAuth]})` | `POST .../project-summary` |
| 10 | `lightingVisualizationPayload({room, confirmedItems, distribution, [requiresAuth]})` | `POST .../visualization-payload` |
| 11 | `lightingConfirmAttempt({...})` | `POST .../confirm-attempt` |
| 11b | `lightingGenerateRoomImage({sessionId, roomIdDb, attemptId, confirmedItems, distribution, [projectId, aspectRatio, requiresAuth]})` | `POST .../generate-room-image` |
| 12 | `lightingMyProjects({[sessionId, requiresAuth]})` | `GET .../projects` |
| 13 | `lightingShowProject({projectId, [sessionId, requiresAuth]})` | `GET .../projects/{id}` |
| 14 | `lightingSessionHistory({sessionId, [requiresAuth]})` | `GET .../sessions/{id}/history` |
| 15 | `lightingDeleteProject({projectId, [sessionId, requiresAuth]})` | `DELETE .../projects/{id}` |
| 16 | `lightingConfirmProject({projectId, [sessionId, requiresAuth]})` | `POST .../projects/{id}/confirm` |

#### 🔐 Base Path Switcher
```dart
String _lightingBase({required bool auth}) =>
  auth ? '/v1/user/lighting-design' : '/v1/user/public/lighting-design';
```

#### ⚠️ Note
`lightingUploadRoomPhoto` implements its own multipart logic using `http.MultipartRequest` with the field name `photo` and reads token via `storageService.getToken()`.

---

## 9️⃣ Diagnosis

### 🔹 DiagnosisApiService

**File:** `lib/services/diagnosis_api_service.dart`

**Purpose:** AI-powered fault diagnosis — fault list, device tree, sessions, inverter code lookup, search.

#### 📋 Constructor
```dart
DiagnosisApiService({required ApiService api})
```

#### 🔧 Methods

| Method | Parameters | Endpoint |
|--------|-----------|----------|
| `listFaults()` | `[category, device]` | `GET /diagnosis/faults` |
| `startSession()` | `mode, [description, category, manufacturer, familyId, code, faultId, sessionId]` | `POST /diagnosis/sessions` |
| `answer()` | `sessionId, questionIndex, answer` | `POST /diagnosis/sessions/{id}/answers` |
| `completeStep()` | `sessionId, stepIndex, [outcome]` | `POST /diagnosis/sessions/{id}/steps/{stepIndex}/complete` |
| `recordOutcome()` | `sessionId, outcome` | `POST /diagnosis/sessions/{id}/outcome` |
| `lookupCode()` | `manufacturer, familyId, code` | `POST /inverter-code-lookups` |
| `listFamilies()` | `manufacturer` | `GET /inverter-families` |
| `showSession()` | `sessionId` | `GET /diagnosis/sessions/{id}` |
| `deviceTree()` | `category` | `GET /diagnosis/device-tree` |
| `search()` | `query, [category]` | `GET /diagnosis/search` |

#### 🌐 Public Endpoints
All diagnosis endpoints are **public** (`requiresAuth: false`).

#### 🎭 Diagnosis Modes
- `symptom` — User describes a symptom
- `code` — User provides an error code
- `fault_id` — Direct fault navigation from the device tree

---

## 🔟 Notifications

### 🔹 NotificationService

**File:** `lib/services/notification_service.dart`

**Purpose:** Singleton Firebase Cloud Messaging + local notifications handler.

#### 🏭 Access
```dart
NotificationService()
```

#### 🔧 Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize local notifications + request FCM permission + register `onMessage` / `onMessageOpenedApp` listeners |

#### 📢 Channel
- **Android:** `'energy_channel'` — "إشعارات متجر الطاقة"
- **Importance:** High

---

### 🔹 LocalNotificationService

**File:** `lib/services/local_notification_service.dart`

**Purpose:** Singleton for **local-only** notifications (e.g., cart reminders).

#### 🏭 Access
```dart
LocalNotificationService.instance
```

#### 🔧 Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `init()` | — | Initialize plugin with Android + iOS settings |
| `showCartReminderNotification({title, body})` | `title, body` | Show cart reminder (ID = 0) |

#### 📢 Channel
- **Android:** `'cart_reminder_channel'` — "تذكير بالسلة"
- **Importance:** High · **Priority:** High

---

## 1️⃣1️⃣ Real-time

### 🔹 PusherService

**File:** `lib/services/pusher_service.dart`

**Purpose:** Singleton for Pusher Channels integration — real-time support chat updates.

#### 🏭 Access
```dart
PusherService()
```

#### ⚙️ Configuration

| Setting | Value |
|---------|-------|
| **App Key** | `485d3f2ec7b88393203b` |
| **Cluster** | `eu` |

#### 🔧 Methods

| Method | Parameters | Description |
|--------|-----------|-------------|
| `init()` | — | Initialize & connect |
| `subscribeToConversation(id, callback)` | `int, Function(Map)` | Subscribe to `support-conversation.{id}` |
| `bindEvent(name, callback)` | `String, Function(Map)` | Bind global event handler |
| `unsubscribe(channelName)` | `String` | Unsubscribe from channel |
| `disconnect()` | — | Disconnect Pusher |

#### 📌 Channel Naming
```
support-conversation.{conversationId}
```

---

## 1️⃣2️⃣ Permissions & Voice

### 🔹 PermissionService

**File:** `lib/services/permission_service.dart`

**Purpose:** Static utility for requesting runtime permissions with a native MethodChannel fallback.

#### 📡 MethodChannel
```dart
MethodChannel('com.nex.app/permissions')
```

#### 🔧 Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `requestMicrophone()` | `Future<bool>` | Request mic (with channel fallback) |
| `checkMicrophone()` | `Future<bool>` | Check mic status |
| `isMicrophonePermanentlyDenied()` | `Future<bool>` | Whether permanently denied |
| `openAppSettings()` | `Future<void>` | Open app settings |
| `requestCamera()` | `Future<bool>` | Request camera |
| `requestPhotos()` | `Future<bool>` | Request photo library |
| `requestNotifications()` | `Future<bool>` | Request notification permission |

#### 🛡️ Fallback Strategy
For microphone permissions, if `permission_handler` fails or returns `permanentlyDenied`, the service tries the native channel `requestMicrophone` / `checkMicrophone` / `openAppSettings`.

---

### 🔹 VoiceService

**File:** `lib/services/voice_service.dart`

**Purpose:** Static bridge to native voice recording / playback via MethodChannel.

#### 📡 MethodChannel
```dart
MethodChannel('com.nex.app/voice')
```

#### 🔧 Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `startRecording()` | `Future<bool>` | Start voice recording |
| `stopRecording()` | `Future<String?>` | Stop & return audio file path |
| `playAudio(url)` | `Future<void>` | Play audio from URL |
| `stopAudio()` | `Future<void>` | Stop audio playback |

---

## 1️⃣3️⃣ UI Utilities

### 🔹 FontScaleManager

**File:** `lib/services/font_scale_manager.dart`

**Purpose:** Static + notifier class for app-wide font scaling (accessibility).

#### 🔢 Constants

| Constant | Value |
|----------|-------|
| `_minScale` | `0.7` |
| `_maxScale` | `2.0` |
| `_defaultScale` | `0.8` |
| `_key` | `'app_font_scale'` |

#### 🔧 Static Methods

| Method | Description |
|--------|-------------|
| `load()` | Load saved scale from prefs |
| `setScale(scale)` | Save clamped scale |
| `reset()` | Reset to default `0.8` |
| `currentScale` | Getter |

#### 🔔 FontScaleNotifier (`ChangeNotifier`)

| Member | Type | Description |
|--------|------|-------------|
| `scale` | `double` | Current scale |
| `percentage` | `double` | `scale × 100` |
| `label` | `String` | `'صغير'` / `'عادي'` / `'كبير'` / `'كبير جداً'` |
| `setScale(newScale)` | `Future<void>` | Update & notify |
| `reset()` | `Future<void>` | Reset to 0.8 |

---

### 🔹 TextAdService

**File:** `lib/services/text_ad_service.dart`

**Purpose:** Fetch scrolling text advertisements.

#### 📋 Constructor
```dart
TextAdService({required String baseUrl, required AuthService authService})
```

#### 🔧 Methods

| Method | Returns | Endpoint |
|--------|---------|----------|
| `getActiveTextAds()` | `Future<List<Map>>` | `GET /v1/user/public/text-ads` |
| `getCarouselTextAds({limit = 5})` | `Future<List<Map>>` | `GET /v1/user/public/text-ads/carousel?limit=N` |

Both return an empty list on failure.

---

### 🔹 showUnifiedReminderDialog

**File:** `lib/services/showUnifiedReminderDialog.dart`

**Purpose:** Helper function that shows an animated dialog reminding the user of incomplete cart items and/or system builder drafts.

#### 📞 Signature
```dart
Future<void> showUnifiedReminderDialog(BuildContext context)
```

#### 🎯 Behavior
1. Loads `CartService.instance` and `SystemBuilderDraftService.instance`.
2. If both are empty → returns silently.
3. Otherwise shows a scaled animated dialog with:
    - Cart summary (item count + total price) → navigates to `CartScreen`
    - Draft summary (item count) → navigates to `SystemBuilderScreen`
    - "Continue browsing" dismiss button
4. Triggers `HapticFeedback.mediumImpact()`.

#### 🎨 Styling
- Gradient `#1E3A8A → #3B82F6`
- Bounce + elastic animations
- Google Fonts: Cairo

---

### 🔹 MaintenanceServicesScreen

**File:** `lib/services/maintenance_services_screen.dart`

**Purpose:** Entry screen for maintenance services — routes users to Diagnosis or Workshop requests.

#### 📋 Constructor
```dart
MaintenanceServicesScreen({required ApiService apiService, AuthService? authService})
```

#### 🎨 UI Structure
- **Header:** Gradient curve clip + back button + construction icon
- **Intro:** Support agent card
- **Service Cards:**
    1. **تشخيص العطل** → `DiagnosisFlowScreen(mode: 'symptom')`
    2. **طلب ورشة** → `WorkshopRequestScreen(apiService, authService)`
- **Info Boxes:** Safety tip + when-to-use guidance

#### 🎨 Color Palette

| Color | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `darkColor` | `#111827` |
| `mediumGray` | `#4B5563` |
| `lightGray` | `#F3F4F6` |

---

## 🔄 Service Dependency Diagram

```
                       ┌───────────────────┐
                       │   StorageService  │◄──── SharedPreferences
                       └─────────┬─────────┘
                                 │
                                 ▼
                       ┌───────────────────┐
                       │    ApiService     │◄──── Auto Token Refresh (401)
                       └─────────┬─────────┘
                                 │
              ┌──────────────────┼─────────────────────┐
              ▼                  ▼                     ▼
     ┌────────────────┐  ┌───────────────┐   ┌──────────────────┐
     │  AuthService   │  │  Extensions   │   │  Domain Services │
     │  (ChangeNotif) │  │ Solar/Lighting│   │  Order / Rating  │
     └────────┬───────┘  └───────────────┘   └──────────────────┘
              │
              ▼
       ┌──────────────────┐
       │  System Builder  │
       │  Solar System    │
       │  Text Ad         │
       └──────────────────┘

     ┌─────────────────┐   ┌─────────────────┐   ┌────────────────┐
     │  CartService    │   │ FavoritesService│   │ComparisonServ. │
     │  (Singleton)    │   │  (Singleton)    │   │  (Singleton)   │
     └─────────────────┘   └─────────────────┘   └────────────────┘

     ┌─────────────────┐   ┌─────────────────┐   ┌────────────────┐
     │ OfflineStorage  │   │ PusherService   │   │NotificationServ│
     │  (Hive static)  │   │  (Singleton)    │   │  + Local       │
     └─────────────────┘   └─────────────────┘   └────────────────┘

     ┌─────────────────┐   ┌─────────────────┐   ┌────────────────┐
     │PermissionService│   │  VoiceService   │   │FontScaleManager│
     │  (Static + MC)  │   │  (Static + MC)  │   │  (Static)      │
     └─────────────────┘   └─────────────────┘   └────────────────┘
```

---

## 🏷️ Service Patterns

| Pattern | Examples | Description |
|---------|----------|-------------|
| **Singleton** | `CartService.instance`, `FavoritesService.instance`, `ComparisonService.instance`, `SystemBuilderDraftService.instance`, `PusherService()`, `NotificationService()`, `LocalNotificationService.instance` | Global single instance |
| **Static** | `OfflineStorageService`, `PermissionService`, `VoiceService`, `FontScaleManager` | Static methods only |
| **ChangeNotifier** | `AuthService`, `CartService`, `SystemBuilderDraftService`, `FontScaleNotifier` | Reactive state |
| **Extension** | `SolarApiService`, `LightingApiService` | Adds methods to `ApiService` |
| **Instance-based** | `OrderApiService`, `RatingApiService`, `SystemBuilderService`, `SolarSystemService`, `TextAdService`, `DiagnosisApiService` | Constructed with deps |

---

## 🔐 Authentication in Services

| Service | Auth Handling |
|---------|---------------|
| `ApiService` | Manual `setToken()` + auto refresh on 401 |
| `AuthService` | Manages token lifecycle & remembers token |
| `OrderApiService` | `_getToken()` via `authService.refreshAuthState()` |
| `RatingApiService` | Same as `OrderApiService` |
| `SystemBuilderService` | Same pattern |
| `SolarSystemService` | Same pattern |
| `SolarApiService` / `LightingApiService` | `requiresAuth` toggle for guest vs. user |
| `TextAdService` | No auth (public) |

---

## 📊 Services Summary Table

| # | Service | Type | Purpose |
|---|---------|------|---------|
| 1 | `ApiService` | Instance | HTTP + token refresh |
| 2 | `AuthService` | ChangeNotifier | Authentication |
| 3 | `StorageService` | Instance | SharedPrefs wrapper |
| 4 | `OfflineStorageService` | Static (Hive) | Offline cache |
| 5 | `CartService` | Singleton | Shopping cart |
| 6 | `FavoritesService` | Singleton | Favorites |
| 7 | `ComparisonService` | Singleton | Compare (max 4) |
| 8 | `OrderApiService` | Instance | Orders |
| 9 | `RatingApiService` | Instance | Ratings |
| 10 | `SystemBuilderService` | Instance | System builder API |
| 11 | `SystemBuilderDraftService` | Singleton | Draft persistence |
| 12 | `SolarApiService` | Extension | Solar projects |
| 13 | `SolarSystemService` | Instance | Solar systems |
| 14 | `LightingApiService` | Extension | Lighting design |
| 15 | `DiagnosisApiService` | Instance | Diagnosis |
| 16 | `NotificationService` | Singleton | FCM + local |
| 17 | `LocalNotificationService` | Singleton | Local notif |
| 18 | `PusherService` | Singleton | Real-time chat |
| 19 | `PermissionService` | Static | Runtime permissions |
| 20 | `VoiceService` | Static | Voice recording |
| 21 | `FontScaleManager` | Static + Notifier | Font scaling |
| 22 | `TextAdService` | Instance | Text ads |
| 23 | `showUnifiedReminderDialog` | Function | Reminder dialog |
| 24 | `MaintenanceServicesScreen` | Widget | Maintenance UI |

---

## 📝 Services — Best Practices

1. **Always initialize in order:** `StorageService.init()` → `OfflineStorageService.init()` → `AuthService` → others.
2. **Use `CartService.instance`** — never construct directly.
3. **Call `loadCart()`, `loadFavorites()`, `loadDraft()`** on app startup.
4. **Handle `session_expired: true`** by redirecting to login.
5. **Prefer `handleTokenExpiry()`** before authenticated requests.
6. **Cache home data** via `OfflineStorageService.saveHomeData` + check `shouldRefresh()`.
7. **Call `OfflineStorageService.clearCache()`** on logout only if required.
8. **Always check permission** via `PermissionService.requestMicrophone()` before voice recording.
9. **Subscribe to Pusher** only when the chat screen is mounted, and `unsubscribe` on dispose.
10. **Push notifications** require `NotificationService.init()` + `AuthService.sendFcmTokenToServer()` after login.

---

<div align="center">

**🔧 End of Part 2 — Services**

</div>

---

# <a id="part-3"></a>🧩 PART 3 — Widgets

**Location:** `lib/widgets/`

**Purpose:** Reusable UI components for the NEX Mobile Application — product/offer cards, cart badge, chat overlay, bottom sheets, home sections, category cards, decorations, dialogs.

---

## 📑 Widgets Overview

| # | Category | Widgets |
|---|----------|---------|
| 1 | Product & Offer Cards | `HomeProductCard`, `HomeOfferCard`, `ProductCard`, `OfferCard` |
| 2 | Cart | `CartBadge` |
| 3 | Chat & Floating UI | `ChatOverlay`, `FloatingChatButton` |
| 4 | Bottom Sheets | `CategorySelectionSheet`, `SolarOptionsSheet`, `LightingOptionsSheet`, `ApplianceOptionsSheet` |
| 5 | Home Sections | `GreetingBar`, `TextAdsCarousel` |
| 6 | Category | `CategoryCard` |
| 7 | Decorations | `AnimatedGradientBorder` |
| 8 | Dialogs | `showUnifiedReminderDialog` |
| 9 | Screens | `ApplianceCompatibilityScreen` |

---

## 📁 File Structure

```
lib/widgets/
├── animated_gradient_border.dart          # Animated border decoration
├── appliance_compatibility_screen.dart    # Appliance compatibility screen
├── cart_badge.dart                        # Cart item count badge
├── category_card.dart                     # Category circular card
├── chat_overlay.dart                      # Stack wrapper for floating chat
├── floating_chat_button.dart              # Draggable AI chat button
├── greeting_bar.dart                      # Time-based greeting + weather
├── HomeOfferCard.dart                     # Home offer card (horizontal)
├── HomeProductCard.dart                   # Home product card (horizontal)
├── offer_card.dart                        # Standard offer card (grid + list)
├── product_card.dart                      # Standard product card
├── text_ads_carousel.dart                 # Auto-rotating text ads
└── unified_reminder_dialog.dart           # Unified cart/draft reminder
```

---

## 1️⃣ Product & Offer Cards

### 🔹 HomeProductCard

**File:** `lib/widgets/HomeProductCard.dart`

**Purpose:** Horizontal-scroll product card for the home screen (width `175`). Includes **wholesale pricing** support, favorites, add-to-cart, and animations.

#### 📋 Constructor
```dart
HomeProductCard({
  required dynamic product,
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ Squeeze animation on tap (`scale 1.0 → 0.95`)
- ✅ **Hero animation** with tag `product_{id}`
- ✅ **Wholesale pricing** — only for company users
- ✅ Dual currency (USD / SYP)
- ✅ Discount badge + rating + governorate badge
- ✅ Favorite toggle (persisted via `FavoritesService`)
- ✅ Add-to-cart with haptic feedback + snackbar action
- ✅ Shimmer placeholder while image loads
- ✅ Cached network images

#### 🧩 Data Fields Read

| Field | Purpose |
|-------|---------|
| `id`, `name_ar`, `slug`, `main_image` | Basic info |
| `price`, `final_price`, `discount_percentage` | USD prices |
| `price_syp`, `final_price_syp` | SYP prices |
| `wholesale_price`, `wholesale_price_syp`, `wholesale_min_quantity` | Wholesale |
| `has_wholesale`, `has_wholesale_syp` | Wholesale flags |
| `brand`, `rate`, `stock`, `shipping_cities`, `governorate_product` | Meta |

#### 🎨 Layout
```
┌─────────────────────────┐
│  Image (135)            │
│  ├─ Discount % (top-R)  │
│  ├─ Rating (top-L)      │
│  ├─ Favorite (bot-L)    │
│  └─ Governorate (bot-R) │
├─────────────────────────┤
│  Brand chip             │
│  Name (2 lines)         │
│  Price / Wholesale      │
├─────────────────────────┤
│  🛒 Add to Cart         │
└─────────────────────────┘
```

#### 🔒 Company Detection
The card auto-detects company users via `storageService.getUserDataMap()` / `getUserData()` — checks `user_type` and `company_id`. Wholesale prices are only shown when `_isCompanyUser == true` **and** `has_wholesale` flag is set.

---

### 🔹 HomeOfferCard

**File:** `lib/widgets/HomeOfferCard.dart`

**Purpose:** Horizontal-scroll offer card for the home screen (width `175`). Similar to `HomeProductCard` but tailored for offers.

#### 📋 Constructor
```dart
HomeOfferCard({
  required dynamic offer,
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Hero animation** with tag `offer_{id}`
- ✅ Squeeze animation on tap
- ✅ Discount %, rating, governorate badges
- ✅ Total wattage + total capacity mini-badges
- ✅ Favorite toggle (persisted)
- ✅ Add-to-cart with cart animation
- ✅ Cached network images + shimmer placeholder

#### 🧩 Data Fields Read

| Field | Purpose |
|-------|---------|
| `id`, `name_ar`, `slug`, `cover_image` | Basic info |
| `price`, `final_price`, `price_syp`, `final_price_syp` | Prices |
| `discount_percentage` | Discount |
| `total_wattage`, `total_capacity` | Technical specs |
| `rate`, `governorate_offer` | Meta |

#### 🎨 Layout
```
┌─────────────────────────┐
│  Image (135)            │
│  ├─ Discount % (top-R)  │
│  ├─ Rating (top-L)      │
│  ├─ Governorate (top-R) │
│  ├─ ⚡ Wattage (bot-L)   │
│  ├─ 🔋 Capacity (bot-L) │
│  └─ Favorite (bot-R)    │
├─────────────────────────┤
│  Name (2 lines)         │
│  Price / Original       │
├─────────────────────────┤
│  🛒 Add to Cart         │
└─────────────────────────┘
```

---

### 🔹 ProductCard

**File:** `lib/widgets/product_card.dart`

**Purpose:** Standard product card for grids and lists. Similar to `HomeProductCard` but with **circular action buttons** overlaid on the image (favorite + add-to-cart).

#### 📋 Constructor
```dart
ProductCard({
  required dynamic product,
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Differences from HomeProductCard

| Feature | HomeProductCard | ProductCard |
|---------|-----------------|-------------|
| Width | `175` | `170` |
| Add-to-cart button | Full-width at bottom | Circular icon (bottom-right of image) |
| Favorite button | Circular (bottom-left of image) | Circular (top-right of image) |
| Wholesale badge | Overlay on image (top-right) | Overlay on image (top-right, offset) |
| Layout height | Variable | Fixed layout |

#### 🎨 Layout
```
┌─────────────────────────┐
│  Image (130)            │
│  ├─ Discount % (top-L)  │
│  ├─ Wholesale (top-R)   │
│  ├─ Favorite (top-R)    │
│  ├─ Governorate (bot-L) │
│  └─ 🛒 Circular (bot-R) │
├─────────────────────────┤
│  Name                   │
│  Brand                  │
│  Price / Wholesale      │
└─────────────────────────┘
```

#### 🟣 Wholesale Button Color
- Wholesale: **Purple** (`#7C3AED`)
- Regular: **Green** (`#4CAF50`)

---

### 🔹 OfferCard

**File:** `lib/widgets/offer_card.dart`

**Purpose:** Standard offer card with **two layouts** (grid + list) selected via `isListView` flag.

#### 📋 Constructor
```dart
OfferCard({
  required dynamic offer,
  required ApiService apiService,
  AuthService? authService,
  bool isListView = false,
})
```

#### 🎯 Features
- ✅ Two layouts: grid (`isListView: false`) / list (`isListView: true`)
- ✅ Discount badge
- ✅ Rating + views indicator
- ✅ Governorate + wattage badges
- ✅ Favorite toggle with snackbar feedback
- ✅ Cached images with shimmer

#### 🎨 Grid Layout
```
┌─────────────────────────┐
│  Image (130)            │
│  ├─ Discount % (top-L)  │
│  ├─ Favorite (top-R)    │
│  └─ Governorate/Wattage │
├─────────────────────────┤
│  Name (2 lines)         │
│  Capacity               │
│  Price  ⭐ Rating  👁️  │
└─────────────────────────┘
```

#### 🎨 List Layout
```
┌──────┬──────────────────┐
│      │  ❤️ (top-right)  │
│      │  Name (2 lines)  │
│ Image│  Capacity        │
│ 100x │  Price  ⭐ 👁️    │
│ 125  │                  │
└──────┴──────────────────┘
```

#### 🎨 Favicon Colors
- Green accent: `#4CAF50`
- Purple badge: `#7C3AED`
- Rating: `Colors.amber`

---

## 2️⃣ Cart

### 🔹 CartBadge

**File:** `lib/widgets/cart_badge.dart`

**Purpose:** Wraps any child widget with a **red circular badge** showing the total cart quantity.

#### 📋 Constructor
```dart
CartBadge({required Widget child})
```

#### 🎯 Features
- ✅ Auto-loads cart on `initState`
- ✅ Only shows badge when `_itemCount > 0`
- ✅ Positioned at top-right (`-4, -4`)
- ✅ Red circle with white text

#### 📊 Data Source
Reads `CartService.instance.totalQuantity` after `loadCart()`.

#### 🎨 Layout
```
      ┌───┐
      │ 3 │ ← red badge
      └───┘
   ┌─────────┐
   │  child  │
   └─────────┘
```

---

## 3️⃣ Chat & Floating UI

### 🔹 ChatOverlay

**File:** `lib/widgets/chat_overlay.dart`

**Purpose:** Simple `Stack` wrapper that overlays a `FloatingChatButton` on top of any child widget.

#### 📋 Constructor
```dart
ChatOverlay({
  required Widget child,
  AuthService? authService,
  required bool isGuest,
})
```

#### 🎯 Usage
```dart
ChatOverlay(
  authService: authService,
  isGuest: false,
  child: Scaffold(body: ...),
)
```

---

### 🔹 FloatingChatButton

**File:** `lib/widgets/floating_chat_button.dart`

**Purpose:** **Draggable, pulsing AI chat button** anchored to any position on screen. Opens a bottom sheet with 3 service categories.

#### 📋 Constructor
```dart
FloatingChatButton({
  AuthService? authService,
  required bool isGuest,
})
```

#### 🎯 Features
- ✅ **Draggable** with position persistence (`SharedPreferences` keys: `chat_button_x`, `chat_button_y`)
- ✅ **Pulsing** animation (scale 1.0 → 1.15)
- ✅ **Rotating** AI glow
- ✅ **Ripple rings** (3 animated circles)
- ✅ **`AI` badge** with gradient
- ✅ Clamped to screen bounds
- ✅ Gradient: `#1E3A8A → #3B82F6 → #1E40AF`

#### 🌐 Service Categories (via `CategorySelectionSheet`)

| Category | Gradient | Purpose |
|----------|----------|---------|
| خدمات الطاقة الشمسية | Blue | Solar services |
| خدمات الإنارة والديكور | Purple | Lighting |
| خدمات الأجهزة الكهربائية | Green | Appliances |

#### 🎯 Quick Access Items

| Icon | Title | Guest Screen | Auth Screen |
|------|-------|--------------|-------------|
| ☀️ | مهندس المنظومات | GuestChatScreen | ChatScreen |
| 💬 | المستشار الشمسي | GuestSolarChatScreen | SolarChatScreen |
| 🎧 | الدعم البشري | GuestSupportSolarChatScreen | SupportSolarChatScreen |
| 🧮 | حاسبة التوفير | GuestApplianceSavingsScreen | ApplianceSavingsScreen |
| 🔧 | الصيانة الذكية | GuestApplianceMaintenanceScreen | ApplianceMaintenanceScreen |
| ✅ | فحص التوافق | GuestApplianceCompatibilityScreen | ApplianceCompatibilityScreen |
| 📅 | مدير جدول التشغيل | GuestApplianceScheduleScreen | ApplianceScheduleScreen |

---

## 4️⃣ Bottom Sheets

All bottom sheets share a **glassmorphism** design:
- `BackdropFilter(blur: 15)`
- Semi-transparent grey background (`Colors.grey.withOpacity(0.15)`)
- Rounded top corners (30)
- White translucent content layer (`0.05`)
- White-tinted borders

### 🔹 CategorySelectionSheet

**Purpose:** Main entry bottom sheet showing 3 gradient categories + quick access grid.

#### 📊 Height: **95% of screen**

#### 🎨 Category Cards
Each category card has:
- Gradient background
- "ابدأ →" white pill button
- Title + subtitle
- Asset image (`assets/images/solar.png`, etc.)

---

### 🔹 SolarOptionsSheet

**Purpose:** Bottom sheet for solar services.

#### 📊 Height: **85% of screen**

#### 🎯 Options

| # | Title | Gradient | Action |
|---|-------|----------|--------|
| 0 | مهندس المنظومات | Blue | `SolarWizardScreen` |
| 1 | مسودات التصميم | Purple | `SolarProjectsScreen` |
| 2 | المستشار الشمسي | Green | `SolarChatScreen` / `GuestSolarChatScreen` |
| 3 | الدعم البشري | Amber | `SupportSolarChatScreen` / `GuestSupportSolarChatScreen` |

---

### 🔹 LightingOptionsSheet

**Purpose:** Bottom sheet for lighting services.

#### 📊 Height: **55% of screen**

#### 🎯 Options

| # | Title | Gradient | Action |
|---|-------|----------|--------|
| 0 | تصميم الإضاءة الذكية | Purple | `LightingProjectsScreen` |
| 1 | الدعم التقني للإنارة | Blue | `LightingSupportChatScreen` / `GuestLightingSupportChatScreen` |

#### 🎨 Disabled State
Supports `enabled: false` — greyed out with reduced opacity.

---

### 🔹 ApplianceOptionsSheet

**Purpose:** Bottom sheet for appliance services.

#### 📊 Height: **85% of screen**

#### 🎯 Options

| # | Title | Gradient | Action |
|---|-------|----------|--------|
| 0 | فحص التوافق | Blue | `ApplianceCompatibilityScreen` |
| 1 | حاسبة التوفير | Green | `ApplianceSavingsScreen` |
| 2 | مدير جدول التشغيل | Purple | `ApplianceScheduleScreen` |
| 3 | الصيانة الذكية | Amber | `ApplianceMaintenanceScreen` |
| 4 | دعم الأجهزة الكهربائية | Purple | `ApplianceSupportChatScreen` |

---

## 5️⃣ Home Sections

### 🔹 GreetingBar

**File:** `lib/widgets/greeting_bar.dart`

**Purpose:** Time-aware greeting bar with **weather simulation** per governorate.

#### 📋 Constructor
```dart
GreetingBar({
  required String userName,
  required String governorate,
})
```

#### 🎯 Features
- ✅ **Time-based greeting:**
    - `< 12` → **"صباح الخير"** (orange, `wb_sunny`)
    - `< 17` → **"مساء الخير"** (blue, `wb_cloudy`)
    - else → **"مساء النور"** (navy, `nights_stay`)
- ✅ **Weather data** per governorate (mock data)
- ✅ Pulsing weather icon (scale `0.8 ↔ 1.2`)
- ✅ Emoji asset (`assets/emojis/sun.png`) with fallback
- ✅ Themed gradient background by time of day

#### 🌤️ Weather Data (Governorates)

| Governorate | Temp | Icon | Condition |
|-------------|------|------|-----------|
| دمشق | 28° | ☀️ | مشمس |
| حلب | 30° | ☀️ | مشمس جزئياً |
| حمص | 26° | ☁️ | غائم |
| اللاذقية | 25° | 💧 | رطب |
| طرطوس | 24° | 💧 | رطب |
| حماة | 29° | ☀️ | مشمس |
| درعا | 31° | ☀️ | حار |
| السويداء | 27° | ☁️ | معتدل |
| **Default** | **25°** | ☀️ | معتدل |

---

### 🔹 TextAdsCarousel

**File:** `lib/widgets/text_ads_carousel.dart`

**Purpose:** Auto-rotating **text ad carousel** using `PageView`.

#### 📋 Constructor
```dart
TextAdsCarousel({
  required List<Map<String, dynamic>> ads,
  Duration interval = const Duration(seconds: 4),
})
```

#### 🎯 Features
- ✅ Auto-rotation every `interval` (default: 4s)
- ✅ Smooth `animateToPage` transitions (500ms)
- ✅ Graceful empty state (`SizedBox.shrink()`)
- ✅ Single-ad fallback (no timer)
- ✅ Height: **50px** with rounded corners (12)

#### 📊 Data Structure
```dart
[
  {'content': 'نص الإعلان الأول'},
  {'content': 'نص الإعلان الثاني'},
]
```

---

## 6️⃣ Category

### 🔹 CategoryCard

**File:** `lib/widgets/category_card.dart`

**Purpose:** Small circular category card for the horizontal categories row.

#### 📋 Constructor
```dart
CategoryCard({
  required dynamic category,
  required VoidCallback onTap,
})
```

#### 🎯 Features
- ✅ Circular image container (60x60) with green gradient
- ✅ Cached network image + shimmer placeholder
- ✅ Category icon fallback
- ✅ Fixed width: **80px**
- ✅ Name (2 lines max, ellipsis)
- ✅ Green accent: `#4CAF50`

#### 🎨 Layout
```
   ┌─────┐
   │ IMG │ ← 60x60 circle
   └─────┘
  Category
   Name
```

---

## 7️⃣ Decorations

### 🔹 AnimatedGradientBorder

**File:** `lib/widgets/animated_gradient_border.dart`

**Purpose:** Stateful widget that wraps a child with a **rotating gradient circular border**.

#### 📋 Constructor
```dart
AnimatedGradientBorder({
  required Widget child,
  double borderWidth = 3,
  Duration duration = const Duration(seconds: 3),
})
```

#### 🎯 Features
- ✅ Continuously rotating `SweepGradient`
- ✅ Custom painter (`_GradientBorderPainter`)
- ✅ Auto-repeating animation
- ✅ Configurable width + duration
- ✅ Always repaints (dynamic)

#### 🎨 Gradient Colors
```
#1E3A8A → #3B82F6 → #60A5FA → #F59E0B → #1E3A8A
(blue)   (blue)     (light)    (amber)   (loop)
```

#### ⚠️ Note
Only draws the **circle** — the child should be circular to match. Works well with avatars, circular badges, etc.

---

## 8️⃣ Dialogs

### 🔹 showUnifiedReminderDialog

**File:** `lib/widgets/unified_reminder_dialog.dart`

**Purpose:** Animated reminder dialog that shows **cart items** and/or **system builder drafts** to the user.

#### 📞 Signature
```dart
Future<void> showUnifiedReminderDialog(BuildContext context)
```

#### 🎯 Behavior
1. **Session guard** — `_hasShownInThisSession` prevents re-showing.
2. **Preference check** — Skips if `isShowUnifiedReminder() == false`.
3. Loads `CartService.instance` and `SystemBuilderDraftService.instance`.
4. Returns silently if both are empty.
5. Shows a scaling, bouncing dialog with:
    - Cart section (item count + total) → `CartScreen`
    - Draft section (item count) → `SystemBuilderScreen`
    - "Adjust in Settings" hint → `SettingsScreen`
    - "Continue browsing" dismiss button
6. Triggers `HapticFeedback.mediumImpact()`.

#### 🎨 Styling
- Gradient: `#1E3A8A → #3B82F6`
- Bounce (`Curves.elasticOut`) + scale animations
- Google Fonts: Cairo
- Shadow: blue glow

#### 🎯 Dynamic Icon

| Has Cart | Has Draft | Icon |
|----------|-----------|------|
| ✅ | ✅ | `shopping_bag_rounded` |
| ✅ | ❌ | `shopping_cart_rounded` |
| ❌ | ✅ | `design_services_rounded` |

#### 🆚 Comparison
There are **two** similar dialogs:

| File | Session Guard | Settings Hint | Persistent Toggle |
|------|--------------|---------------|-------------------|
| `showUnifiedReminderDialog.dart` | ❌ | ❌ | ❌ |
| `unified_reminder_dialog.dart` | ✅ | ✅ | ✅ |

The `unified_reminder_dialog.dart` version is the **newer, more feature-rich** implementation.

---

## 9️⃣ Screens

### 🔹 ApplianceCompatibilityScreen

**File:** `lib/widgets/appliance_compatibility_screen.dart`

> ⚠️ **Note:** This file is a **full screen** (not a small widget). It's included here because of its file location.

**Purpose:** 4-step wizard to check appliance compatibility with a solar system.

#### 📋 Constructor
```dart
ApplianceCompatibilityScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **4-step wizard** with progress dots
- ✅ Back / Next navigation
- ✅ Custom gradient AppBar
- ✅ Segmented results (compatible / warning / incompatible)
- ✅ Reset button for new checks
- ✅ Loading state during API call

#### 📊 Wizard Steps

| Step | Question | Type |
|------|----------|------|
| 0 | فولتية النظام | Select: 12 / 24 / 48 |
| 1 | قدرة الإنفرتر | Select: `< 1000W` / `1000-3000W` / `> 3000W` |
| 2 | نوع البطاريات | Select: أسيد / جل / ليثيوم |
| 3 | الأجهزة المراد فحصها | Multi-line text input |

#### 🔌 API Call
```
POST /v1/user/appliance-compatibility/check
{
  "system_voltage": "12",
  "inverter_power": "1000W - 3000W",
  "battery_type": "ليثيوم",
  "appliances": "براد 200W\nغسالة 500W\n..."
}
```

#### 📤 Response Structure
```json
{
  "status": "success",
  "data": {
    "compatible": [{"name": "...", "watts": 200, "note": "..."}],
    "warning": [...],
    "incompatible": [...],
    "summary": "..."
  }
}
```

#### 🎨 Colors

| Element | Color |
|---------|-------|
| Primary | `#1E3A8A` |
| Secondary | `#3B82F6` |
| Compatible | `Colors.green` |
| Warning | `Colors.orange` |
| Incompatible | `Colors.red` |
| Background | `#F3F4F6` |

---

## 🎨 Shared Design Tokens

### 🎨 Colors

| Token | Value | Usage |
|-------|-------|-------|
| **Primary Blue** | `#1E3A8A` | Main brand |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Dark Blue** | `#1E40AF` | Gradients |
| **Purple** | `#7C3AED` | Wholesale / Lighting |
| **Green** | `#059669` / `#10B981` | Success / Appliances |
| **Amber** | `#F59E0B` | Warnings / Solar |
| **Red** | `#EF4444` | Discounts / Danger |

### 🔤 Typography
- **Font:** Google Fonts **Cairo** (Arabic-first)
- **Weights:** `w600` / `bold` most common
- **Sizes:** `9–24` (cards use `11–15`)

### 🧊 Design Patterns

| Pattern | Description |
|---------|-------------|
| **Glassmorphism** | `BackdropFilter` + translucent overlays |
| **Gradient backgrounds** | `LinearGradient` on cards & buttons |
| **Rounded corners** | `12–30` radius |
| **Shimmer placeholders** | While images load |
| **Hero animations** | Product/Offer image transitions |
| **Squeeze animations** | `ScaleTransition` on tap |
| **Pulse animations** | Weather icon, chat button |

---

## 📦 External Dependencies

| Package | Used By |
|---------|---------|
| `cached_network_image` | All image cards |
| `shimmer` | Image placeholders |
| `google_fonts` | All widgets (Cairo) |
| `flutter/services` | Haptic feedback |
| `shared_preferences` | Chat button position |
| `dart:ui` | `ImageFilter.blur` (bottom sheets) |

---

## 🔗 Service Dependencies

| Widget | Depends On |
|--------|-----------|
| `HomeProductCard` / `ProductCard` | `CartService`, `FavoritesService`, `StorageService`, `ApiService`, `AuthService` |
| `HomeOfferCard` / `OfferCard` | Same as above |
| `CartBadge` | `CartService` |
| `FloatingChatButton` | `StorageService` |
| `showUnifiedReminderDialog` | `CartService`, `SystemBuilderDraftService`, `StorageService`, `AuthService` |
| `ApplianceCompatibilityScreen` | `ApiService`, `AuthService` |

---

## 🏷️ Widget Naming Conventions

| Pattern | Example | Meaning |
|---------|---------|---------|
| `XxxCard` | `ProductCard`, `OfferCard` | Grid/list item cards |
| `HomeXxxCard` | `HomeProductCard`, `HomeOfferCard` | Home-specific cards |
| `XxxOverlay` | `ChatOverlay` | Stack overlays |
| `XxxBadge` | `CartBadge` | Small indicator on top |
| `XxxBar` | `GreetingBar` | Horizontal bars |
| `XxxCarousel` | `TextAdsCarousel` | Auto-rotating view |
| `XxxSheet` | `CategorySelectionSheet`, `SolarOptionsSheet` | Bottom sheets |
| `showXxxDialog` | `showUnifiedReminderDialog` | Dialog functions |
| `XxxBorder` | `AnimatedGradientBorder` | Decoration wrappers |

---

## 📊 Widgets Summary Table

| # | Widget | Type | Stateful | Size | Purpose |
|---|--------|------|----------|------|---------|
| 1 | `HomeProductCard` | Card | ✅ | 175px | Home product |
| 2 | `HomeOfferCard` | Card | ✅ | 175px | Home offer |
| 3 | `ProductCard` | Card | ✅ | 170px | Grid product |
| 4 | `OfferCard` | Card | ✅ | Variable | Grid/List offer |
| 5 | `CartBadge` | Indicator | ✅ | Auto | Cart count |
| 6 | `ChatOverlay` | Stack | ❌ | Full | Wraps child |
| 7 | `FloatingChatButton` | FAB | ✅ | 60x60 | Draggable AI |
| 8 | `CategorySelectionSheet` | Bottom Sheet | ✅ | 95% | Main entry |
| 9 | `SolarOptionsSheet` | Bottom Sheet | ✅ | 85% | Solar |
| 10 | `LightingOptionsSheet` | Bottom Sheet | ✅ | 55% | Lighting |
| 11 | `ApplianceOptionsSheet` | Bottom Sheet | ✅ | 85% | Appliances |
| 12 | `GreetingBar` | Bar | ✅ | Full width | Greeting + weather |
| 13 | `TextAdsCarousel` | Carousel | ✅ | 50px | Rotating ads |
| 14 | `CategoryCard` | Card | ❌ | 80px | Category item |
| 15 | `AnimatedGradientBorder` | Decoration | ✅ | Child | Rotating border |
| 16 | `showUnifiedReminderDialog` | Function | — | Dialog | Cart/draft reminder |
| 17 | `ApplianceCompatibilityScreen` | Screen | ✅ | Full | Compatibility check |

---

## 💡 Usage Examples

### 🏠 Home Screen — Product Card
```dart
HomeProductCard(
  product: productData,
  apiService: apiService,
  authService: authService,
)
```

### 🛒 Cart Badge in App Bar
```dart
AppBar(
  actions: [
    CartBadge(
      child: IconButton(
        icon: Icon(Icons.shopping_cart),
        onPressed: () => Navigator.push(...),
      ),
    ),
  ],
)
```

### 💬 Chat Overlay on Home
```dart
ChatOverlay(
  authService: authService,
  isGuest: false,
  child: HomeScreen(),
)
```

### 🔔 Reminder Dialog on App Start
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showUnifiedReminderDialog(context);
  });
}
```

### 📢 Text Ad Carousel
```dart
TextAdsCarousel(
  ads: textAds,
  interval: Duration(seconds: 5),
)
```

### 🎨 Animated Border
```dart
AnimatedGradientBorder(
  borderWidth: 3,
  duration: Duration(seconds: 2),
  child: CircleAvatar(radius: 40),
)
```

---

## 📝 Widgets — Best Practices

1. **Always pass `apiService` + `authService`** to cards — they need them for favorites, cart, and details navigation.
2. **Use `HomeXxxCard`** for horizontal scrolling rows on the home screen.
3. **Use `XxxCard` (non-Home)** for grid / list views with fixed dimensions.
4. **Both card types read `storageService.isSypPreferred()`** — ensure `StorageService.init()` ran at app startup.
5. **Company users see wholesale prices** — this is automatic via `_isCompanyUser` detection.
6. **`FloatingChatButton` position is persisted** across sessions — don't reset `chat_button_x/y` unless needed.
7. **`showUnifiedReminderDialog`** should be called **after the first frame** — use `addPostFrameCallback`.
8. **Prefer `unified_reminder_dialog.dart`** (newer) over `showUnifiedReminderDialog.dart` (older).
9. **Bottom sheets use `showModalBottomSheet`** with `isScrollControlled: true` for full-height.
10. **Wrap child in `Material`** when using `AnimatedGradientBorder` if it has its own visual context.

---

<div align="center">

**🧩 End of Part 3 — Widgets**

</div>

---
# <a id="part-4"></a>📱 PART 4 — Core Screens

**Location:** `lib/screens/`

**Purpose:** Startup, authentication, guest onboarding, and main app screens.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | Startup | `SplashScreen`, `OnboardingScreen`, `EntryHubScreen` |
| 2 | Authentication | `LoginScreen`, `RegisterScreen`, `EmailVerificationScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen` |
| 3 | Guest Onboarding | `GovernorateSelectionScreen` |
| 4 | Main App | `HomeScreen`, `SearchScreen`, `SettingsScreen` |

---

## 📁 File Structure

```
lib/screens/
├── splash_screen.dart                     # App splash
├── onboarding_screen.dart                 # Onboarding carousel
├── entry_hub_screen.dart                  # Entry hub (4 main hubs)
├── governorate_selection_screen.dart      # Guest governorate picker
├── home_screen.dart                       # Main home
├── search_screen.dart                     # Product search + voice
├── settings_screen.dart                   # App settings
└── auth/
    ├── login_screen.dart                  # Login
    ├── register_screen.dart               # Registration (customer + company)
    ├── email_verification_screen.dart     # Email OTP verification
    ├── forgot_password_screen.dart        # Forgot password (email + code)
    └── reset_password_screen.dart         # Reset password
```

---

## 1️⃣ Startup

### 🔹 SplashScreen

**File:** `lib/screens/splash_screen.dart`

**Purpose:** Animated splash screen with **smart routing** based on auth state, onboarding status, and hub preference.

#### 📋 Constructor
```dart
SplashScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **4 concurrent animations:** entrance, pulse, rotation, particles
- ✅ 25 orbiting particles + 5 decorative rotating circles
- ✅ Logo with pulsing glow + rotation
- ✅ **Smart routing** based on:
    - Onboarding seen?
    - Authenticated / Guest with governorate?
    - `isAlwaysShowHub` setting
- ✅ **Token validation** on startup (`handleTokenExpiry()`)
- ✅ Auto-navigates after **2800ms**

#### 🔄 Routing Logic
```
Splash (2.8s)
   │
   ▼
refreshAuthState + handleTokenExpiry
   │
   ├─ Not seen onboarding? → OnboardingScreen
   │
   ├─ Authenticated OR (Guest + governorate)?
   │     │
   │     ├─ isAlwaysShowHub? → EntryHubScreen
   │     └─ else                → HomeScreen
   │
   └─ else → GovernorateSelectionScreen
```

#### 🎨 Colors

| Color | Value |
|-------|-------|
| Primary | `#1E3A8A` |
| Secondary | `#3B82F6` |
| Dark | `#111827` |

#### 📦 Assets
- `assets/images/app_nex_icon.jpg` (main logo, fallback `bolt_rounded`)

---

### 🔹 OnboardingScreen

**File:** `lib/screens/onboarding_screen.dart`

**Purpose:** 4-page animated onboarding carousel with **Lottie animations** + particles.

#### 📋 Constructor
```dart
OnboardingScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ 4 pages (Solar / Smart Home / Quality / Tech Support)
- ✅ **Lottie animations** per page
- ✅ **Smooth page indicator** (`smooth_page_indicator`)
- ✅ **Particle painter** with floating dots
- ✅ **Dynamic color transition** per page
- ✅ "Skip" button (jumps to last page)
- ✅ "Next" / "Get Started" / "Login" buttons

#### 📄 Pages Content

| # | Title | Subtitle | Animation |
|---|-------|----------|-----------|
| 0 | طاقة شمسية | لمنزلك | `solar-panel.json` |
| 1 | أجهزة منزلية | ذكية ومتطورة | `smart_home.json` |
| 2 | جودة معتمدة | وعالمية | `successful-food-delivery.json` |
| 3 | دعم فني | متكامل | `tech-support.json` |

#### 🔄 Navigation
- **Get Started** → Marks onboarding seen → `LoginScreen`
- **Skip** → Jumps to last page
- **Login** (only on last page) → `LoginScreen`

#### 🎨 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_animationController` | 1000ms | Page entrance |
| `_particleController` | 4000ms | Particle motion (loop) |
| `_colorTransitionController` | 600ms | Background color shift |
| `_floatingController` | 3000ms | Floating indicator |

#### 📦 Assets
- `assets/animations/solar-panel.json`
- `assets/animations/smart_home.json`
- `assets/animations/successful-food-delivery.json`
- `assets/animations/tech-support.json`

---

### 🔹 EntryHubScreen

**File:** `lib/screens/entry_hub_screen.dart`

**Purpose:** Premium **4-card entry hub** to route users to the main sections (Browse / Services / Solar / Lighting).

#### 📋 Constructor
```dart
EntryHubScreen({
  required AuthService authService,
  required StorageService storageService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Dark navy gradient background** with animated circles
- ✅ **12 floating light dots** (random-seeded)
- ✅ **Staggered row entrances** (5 items)
- ✅ Per-row pulsing icon + press-scale animation
- ✅ Settings hint card → `SettingsScreen`
- ✅ Footer hint "اختر صفاً للبدء"

#### 🎯 Hub Cards

| # | Title | Subtitle | Icon | Gradient | Route |
|---|-------|----------|------|----------|-------|
| 0 | تصفح التطبيق | اكتشف كل الميزات | `apps_rounded` | Blue | `HomeScreen` |
| 1 | خدمات الصيانة | تركيب وصيانة فورية | `home_repair_service` | Green | `MaintenanceServicesScreen` |
| 2 | منظومة شمسية | صمم نظامك خطوة بخطوة | `solar_power` | Amber | `SolarWizardScreen` |
| 3 | إنارة ذكية | ديكور وإضاءة منزلية | `lightbulb` | Purple | `LightingProjectsScreen` |

#### 🎨 Colors
```
Background gradient: #0F172A → #1E3A8A → #2563EB → #1E40AF
```

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_entranceController` | 2200ms | Staggered entry (5 items) |
| `_bgController` | 30000ms | Background rotation (loop) |
| `_pulseController` | 1800ms | Icon pulse (reverse loop) |

---

## 2️⃣ Authentication

### 🔹 LoginScreen

**File:** `lib/screens/auth/login_screen.dart`

**Purpose:** Animated login with **remember me**, guest mode, company routing, email verification redirect, and checkout integration.

#### 📋 Constructor
```dart
LoginScreen({
  required AuthService authService,
  required StorageService storageService,
  bool returnToCheckout = false,
})
```

#### 🎯 Features
- ✅ **Remember me** (email + password in SharedPreferences)
- ✅ **Guest mode** entry
- ✅ **Company user routing** (`company_owner` → `CompanyChoiceScreen`)
- ✅ **Email verification redirect** (auto-detect)
- ✅ **Checkout integration** (`returnToCheckout: true` → `Navigator.pop`)
- ✅ FCM token sync after login
- ✅ Custom animated logo (dual glow) + gradient form
- ✅ Staggered entrance animations

#### 🔐 Login Flow
```
Login
  │
  ▼
AuthService.login()
  │
  ├─ Success → saveCredentials + sendFcmToken
  │     │
  │     ├─ returnToCheckout? → Navigator.pop
  │     │
  │     ├─ user_type == 'company_owner'? → CompanyChoiceScreen
  │     │
  │     └─ else → HomeScreen
  │
  └─ Email verification required? → EmailVerificationScreen
     (isFromLogin: true)
```

#### 🔑 Stored Credentials

| Key | Value |
|-----|-------|
| `remember_me` | `bool` |
| `saved_email` | `String` |
| `saved_password` | `String` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `accentBlue` | `#60A5FA` |
| `darkColor` | `#111827` |
| `mediumGray` | `#4B5563` |
| `lightGray` | `#F3F4F6` |

---

### 🔹 RegisterScreen

**File:** `lib/screens/auth/register_screen.dart`

**Purpose:** Dual-mode registration screen — **customer** or **company** — with auto phone formatting, governorate picker, logo upload, and terms acceptance.

#### 📋 Constructor
```dart
RegisterScreen({
  required AuthService authService,
  required StorageService storageService,
  bool returnToCheckout = false,
})
```

#### 🎯 Features
- ✅ **Dual user type:** Customer / Company
- ✅ **Phone auto-formatting** (`+963...`)
- ✅ **Governorate dropdown** with "show more"
- ✅ **Referral code** support
- ✅ **Company logo upload** via `image_picker`
- ✅ **Terms & Privacy** acceptance with links
- ✅ **Multipart company request** submission

#### 📊 User Type Comparison

| Field | Customer | Company |
|-------|----------|---------|
| Name / Email / Phone | ✅ | ✅ |
| Governorate | ✅ | ✅ |
| Password | ✅ | ✅ |
| Referral Code | ✅ | ✅ |
| Company Name | ❌ | ✅ |
| Company Description | ❌ | ✅ |
| Company Phone | ❌ | ✅ |
| Company WhatsApp | ❌ | ✅ |
| Commercial Register | ❌ | ✅ |
| Map URL | ❌ | ✅ |
| Company Logo | ❌ | ✅ |

#### 🔌 Company Registration Endpoint
```
POST /v1/user/public/company-requests
  - name, email, phone, password, password_confirmation
  - governorate, referral_code (optional)
  - company_name_ar, company_description_ar
  - company_phone, company_whatsapp
  - company_governorate, company_commercial_register
  - company_map_url, company_logo (file)
```

#### 🔑 Phone Formatting
- Auto-strips leading `0`
- Auto-prepends `+963` if not present
- Validates: `+963` + 8+ digits

---

### 🔹 EmailVerificationScreen

**File:** `lib/screens/auth/email_verification_screen.dart`

**Purpose:** 6-digit OTP verification with auto-submit on completion and 60-second resend cooldown.

#### 📋 Constructor
```dart
EmailVerificationScreen({
  required AuthService authService,
  required StorageService storageService,
  required String email,
  String? token,
  bool isFromLogin = false,
  bool returnToCheckout = false,
})
```

#### 🎯 Features
- ✅ **6-box OTP input** with auto-focus advance
- ✅ **Auto-submit** on 6th digit
- ✅ **60-second countdown** for resend
- ✅ Animated email icon (elastic)
- ✅ Clear on error + refocus first box
- ✅ **Smart navigation:**
    - `returnToCheckout` → `Navigator.pop`
    - `isFromLogin` → `HomeScreen`
    - else → `LoginScreen`

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Verify | `POST /nex/verify-email` |
| Resend | `POST /nex/resend-verification-code` |

---

### 🔹 ForgotPasswordScreen

**File:** `lib/screens/auth/forgot_password_screen.dart`

**Purpose:** Two-phase forgot password — email → 6-digit code → reset.

#### 📋 Constructor
```dart
ForgotPasswordScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Two-phase UI** (email → code)
- ✅ Auto-submit when 6 digits entered
- ✅ Resend button
- ✅ Animated lock icon (elastic)
- ✅ Navigates to `ResetPasswordScreen` with email

#### 🔄 Flow
```
Email form → _sendResetCode()
   │
   ▼
Code form (auto-opens)
   │
   ├─ 6 digits entered → _verifyCode() auto
   │
   ▼
ResetPasswordScreen(email)
```

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Send code | `POST /nex/forgot-password` |
| Verify code | `POST /nex/verify-reset-code` |

---

### 🔹 ResetPasswordScreen

**File:** `lib/screens/auth/reset_password_screen.dart`

**Purpose:** Reset password form with confirmation, then redirects to login.

#### 📋 Constructor
```dart
ResetPasswordScreen({
  required AuthService authService,
  required StorageService storageService,
  required String email,
})
```

#### 🎯 Features
- ✅ Password + confirmation fields
- ✅ Show/hide password toggles
- ✅ Animated key icon
- ✅ On success → `LoginScreen` (after 2s)

#### 🔌 Endpoint
```
POST /nex/reset-password
{ email, password, password_confirmation }
```

---

## 3️⃣ Guest Onboarding

### 🔹 GovernorateSelectionScreen

**File:** `lib/screens/governorate_selection_screen.dart`

**Purpose:** Grid-based governorate picker for **guest mode** with two CTAs (Browse as Guest / Login).

#### 📋 Constructor
```dart
GovernorateSelectionScreen({
  required AuthService authService,
  required StorageService storageService,
  bool isFromOnboarding = false,
})
```

#### 🎯 Features
- ✅ Grid of all 14 Syrian governorates
- ✅ Selected state with gradient + checkmark
- ✅ Haptic feedback on selection
- ✅ Persists governorate to `StorageService`
- ✅ **Continue as Guest** → `HomeScreen`
- ✅ **Login** → `LoginScreen`
- ✅ "Back" button hidden when `isFromOnboarding: true`

#### 🎯 Actions

| Button | Action |
|--------|--------|
| تصفح كزائر | Saves governorate → `continueAsGuest()` → `HomeScreen` |
| تسجيل الدخول | `LoginScreen` |

#### 📦 Data Source
`AppConstants.syrianGovernorates` (14 governorates)

#### 🎨 Colors
- Primary: `#1E3A8A`
- Secondary: `#3B82F6`

---

## 4️⃣ Main App

### 🔹 HomeScreen

**File:** `lib/screens/home_screen.dart`

**Purpose:** Main home screen with **IndexedStack navigation**, quick actions, dynamic content sections, drawer, custom bottom nav, and unified reminder dialog.

#### 📋 Constructor
```dart
HomeScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **IndexedStack navigation** (6 tabs)
- ✅ **ChatOverlay** wrapper (draggable AI chat)
- ✅ **SliverAppBar** with curved clip + search bar
- ✅ **Greeting widget** with time-based emoji + subtitle
- ✅ **Active requests stats** (auth only)
- ✅ **Custom quick actions bar** (user-customizable)
- ✅ **Advertisements carousel** (full-screen viewer)
- ✅ **Text ads carousel**
- ✅ **Custom bottom nav** with floating home button
- ✅ **Drawer** with 15+ menu items
- ✅ **Scroll-to-top FAB**
- ✅ **Unified reminder dialog** (2s delay on init + app resume)

#### 📑 IndexedStack Tabs

| Index | Screen |
|-------|--------|
| 0 | Home body |
| 1 | `MainCategoriesScreen` |
| 2 | `FavoritesScreen` |
| 3 | `OffersListScreen` |
| 4 | `CartScreen` |
| 5 | `ProfileScreen` (or locked screen if guest) |

#### 📊 Data Loaded

| Section | Endpoint |
|---------|----------|
| Text Ads | `/v1/user/public/text-ads` |
| Advertisements | `/v1/user/public/advertisements` |
| Main Categories | `/v1/user/public/categories/main/random` |
| Electrical Appliances | `/v1/user/public/categories/main/7/subcategories` |
| Electrical Extensions | `/v1/user/public/categories/main/9/subcategories` |
| Home Lighting | `/v1/user/public/categories/main/10/subcategories` |
| Most Viewed | `/products/most-viewed` |
| Top Rated | `/products/top-rated` |
| Latest | `/products/latest` |
| Random | `/products/random` |
| Featured Offers | `/offers/featured` |
| Latest Offers | `/offers/latest` |
| Cheapest Offers | `/offers/cheapest` |
| Highest Power Offers | `/offers/highest-power` |
| Variety Offers | `/offers/variety` |
| All Offers | `/offers` |

> 🔀 **Auth-aware endpoints:** Authenticated requests use `/v1/user/...`, guests use `/v1/user/public/.../{governorate}`.

#### 🎯 Quick Actions (Customizable)

| ID | Title | Icon | Route |
|----|-------|------|-------|
| `maintenance_services` | خدمات الصيانة | `home_repair_service` | `MaintenanceServicesScreen` |
| `comparisons` | المقارنات | `compare_arrows` | `ComparisonScreen` |
| `system_builder` | تصميم منظومة | `design_services` | `SystemBuilderScreen` |
| `workshop` | طلب ورشة تركيب | `handyman` | `WorkshopRequestScreen` |
| `workshop_maintenance` | طلب ورشة صيانة | `build_circle` | `WorkshopRequestMaintenanceScreen` |
| `order_tracking` | تتبع طلباتي | `local_shipping` | `OrderTrackingScreen` *(auth only)* |
| `compatibility_check` | فحص توافق المكونات | `check_circle_outline` | Compatibility screen |
| `smart_maintenance` | الصيانة الذكية | `electrical_services` | Maintenance screen |
| `savings_calculator` | حاسبة توفير الإنفرتر | `calculate` | Savings screen |
| `appliance_schedule` | جدولة تشغيل الأجهزة | `schedule` | Schedule screen |
| `solar_support` | دعم بشري للطاقة | `support_agent` | Support chat |
| `solar_qa` | أسئلة واستفسارات | `help_outline` | Solar chat |

#### 📊 Active Requests Stats
**Endpoint:** `GET /v1/user/dashboard/active-requests-stats`

Returns:
- `summary.total_active_requests`
- `summary.pending_requests`
- `summary.processing_requests`
- `workshop_requests.total_active`
- `store_orders.total_active`
- `solar_system_orders.total_active`

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `accentBlue` | `#60A5FA` |
| `darkColor` | `#111827` |
| `mediumGray` | `#4B5563` |
| `successGreen` | `#10B981` |
| Background | `#F8F9FA` |

#### 🎯 Drawer Items
1. الرئيسية
2. التصنيفات
3. تصميم منظومة
4. المفضلة
5. العروض
6. السلة
7. حسابي *(auth only)*
8. المساعد الذكي
9. خدمات الصيانة والتركيب
10. منظوماتي *(auth only)*
11. صيانة
12. المقارنات
13. الإعدادات
14. لوحة تحكم الشركة *(company_owner only)*
15. تقديم شكوى
16. تسجيل خروج *(auth only)*

#### 🌐 Advertisement Actions

| Action | Handler |
|--------|---------|
| Link | `_openUrl()` — external browser |
| Phone | `_makePhoneCall()` — `tel:` |
| WhatsApp | `_openWhatsapp()` — `wa.me` |

---

### 🔹 SearchScreen

**File:** `lib/screens/search_screen.dart`

**Purpose:** Full-featured product search with **voice recognition**, filters (governorate / price / rating), sort options, and grid/list view toggle.

#### 📋 Constructor
```dart
SearchScreen({
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Voice search** via `speech_to_text` (Arabic `ar_SY`)
- ✅ **Microphone permission** handling
- ✅ **Recording indicator** with progress bar
- ✅ **Sort chips:** Latest / Rating / Views / Price
- ✅ **Filter sheet:** Governorate / Price / Rating
- ✅ **Grid / List view toggle**
- ✅ **Infinite scroll** with pagination
- ✅ **Animated entrance** for each card
- ✅ **Recent searches** (in-memory)
- ✅ Shimmer loading skeleton
- ✅ Error + Empty states

#### 🎤 Voice Search

| Aspect | Value |
|--------|-------|
| Locale | `ar_SY` |
| Mode | `stt.ListenMode.dictation` |
| Timeout | 15 seconds |
| Pause | 3 seconds |
| Partial results | ✅ |
| Cancel on error | ✅ |

#### 🎯 Sort Options

| Value | Label | Icon |
|-------|-------|------|
| `created_at` | الأحدث | `fiber_new` |
| `rate` | الأعلى تقييماً | `star` |
| `views` | الأكثر مشاهدة | `visibility` |
| `price` | السعر | `attach_money` |

#### ⭐ Rate Options

| Value | Label |
|-------|-------|
| 0 | الكل |
| 4 | 4 نجوم فما فوق |
| 3 | 3 نجوم فما فوق |
| 2 | نجمتان فما فوق |

#### 🔌 Search Endpoint
```
Auth:    GET /v1/user/products/search
Guest:   GET /v1/user/public/products/{governorate}/search

Query params:
  - name, min_price, max_price
  - governorate (comma-separated)
  - sort_by, sort_order, min_rate
  - page, per_page
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| `dangerRed` | `#EF4444` |
| `warningOrange` | `#F59E0B` |
| `purple` | `#7C3AED` |

---

### 🔹 SettingsScreen

**File:** `lib/screens/settings_screen.dart`

**Purpose:** App-wide settings — font scale, currency, entry hub preference, unified reminder, legal pages.

#### 📋 Constructor
```dart
SettingsScreen()
```

> ⚠️ **Requires** `Provider<StorageService>` and `Provider<FontScaleNotifier>` ancestors.

#### 🎯 Sections

| Section | Items |
|---------|-------|
| **المظهر** | Font size (slider + quick buttons) |
| **العملة** | Currency (USD / SYP) |
| **واجهة البداية** | Show hub vs. direct |
| **التذكيرات** | Unified reminder toggle |
| **قانوني** | Terms & Privacy |
| **معلومات** | Version + brand |

#### 🔤 Font Size Control

| Value | Label |
|-------|-------|
| 0.8 | صغير |
| 1.0 | عادي |
| 1.5 | كبير |
| 2.0 | كبير جداً |

**Range:** 0.7 → 2.0 (13 divisions)

#### 💱 Currency

| Option | Storage Constant |
|--------|-----------------|
| USD | `StorageService.currencyUsd` |
| SYP | `StorageService.currencySyp` |

#### 🏠 Entry Hub
- **عرض واجهة البداية دائماً** → `saveAlwaysShowHub(true)`
- **الدخول مباشرة إلى التطبيق** → `saveAlwaysShowHub(false)`

#### 🔔 Reminders
- **إظهار التذكير** → `saveShowUnifiedReminder(true)`
- **عدم إظهار التذكير** → `saveShowUnifiedReminder(false)`

#### 🎨 Colors
- Primary: `#1E3A8A`
- Secondary: `#3B82F6`
- Light: `#F3F4F6`

---

## 🎨 Shared Design System

### 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Blue** | `#60A5FA` | Highlights |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success |
| **Danger** | `#EF4444` | Errors |
| **Warning** | `#F59E0B` | Warnings |
| **Purple** | `#7C3AED` | Wholesale / Lighting |

### 🔤 Typography
- **Font:** Google Fonts **Cairo** (Arabic)
- **Poppins:** Used for logo/brand text (`NEX`)
- **Sizes:** 10–36

### 🎬 Animation Patterns

| Pattern | Used In |
|---------|---------|
| **Staggered entrance** (`flutter_staggered_animations`) | All auth screens |
| **Elastic scale** (`Curves.elasticOut`) | Logos, buttons |
| **Pulse** (reverse repeat) | Icons, badges |
| **Rotation** (loop) | Splash, hub backgrounds |
| **FadeInAnimation** (custom) | All screens |
| **Smooth page indicator** | Onboarding |
| **Shimmer** | Loading placeholders |

### 🧊 Design Patterns

| Pattern | Description |
|---------|-------------|
| **Curved AppBar** | `ClipPath` + `_BottomCurveClipper` |
| **Glassmorphism** | `BackdropFilter` in bottom sheets |
| **Radial gradient background** | All auth screens |
| **Rounded cards** | 18–30 radius |
| **Floating buttons** | Custom bottom nav |

---

## 🔄 Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                          Splash                              │
└──────────────────────┬──────────────────────────────────────┘
                       │ (2800ms)
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   Onboarding     EntryHub        HomeScreen
   (first time)   (auth/guest)    (direct)
        │              │
        │              ├─→ HomeScreen
        │              ├─→ MaintenanceServicesScreen
        │              ├─→ SolarWizardScreen
        │              └─→ LightingProjectsScreen
        │
        ▼
   LoginScreen ──→ RegisterScreen ──→ EmailVerificationScreen
        │                                     │
        │                                     ▼
        │                               HomeScreen
        │
        ├─→ ForgotPasswordScreen ──→ ResetPasswordScreen ──→ LoginScreen
        │
        └─→ GovernorateSelectionScreen (Guest) ──→ HomeScreen
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `flutter_staggered_animations` | All auth screens |
| `google_fonts` | All screens |
| `smooth_page_indicator` | Onboarding |
| `lottie` | Onboarding |
| `cached_network_image` | Home, Search |
| `carousel_slider` | Home |
| `shimmer` | Home, Search |
| `speech_to_text` | Search |
| `permission_handler` | Search |
| `image_picker` | Register |
| `provider` | Settings |
| `shared_preferences` | Login (remember me) |
| `url_launcher` | Home (ads) |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `SplashScreen` | `AuthService`, `StorageService`, `ApiService` |
| `OnboardingScreen` | `AuthService`, `StorageService` |
| `EntryHubScreen` | `AuthService`, `StorageService`, `ApiService` |
| `LoginScreen` | `AuthService`, `StorageService` |
| `RegisterScreen` | `AuthService`, `StorageService` |
| `EmailVerificationScreen` | `AuthService`, `StorageService` |
| `ForgotPasswordScreen` | `AuthService`, `StorageService` |
| `ResetPasswordScreen` | `AuthService`, `StorageService` |
| `GovernorateSelectionScreen` | `AuthService`, `StorageService` |
| `HomeScreen` | `AuthService`, `StorageService`, `ApiService`, `TextAdService`, `CartService`, `SystemBuilderDraftService`, `LocalNotificationService` |
| `SearchScreen` | `ApiService`, `AuthService` |
| `SettingsScreen` | `StorageService`, `FontScaleNotifier` |

---

## 📊 Screen Summary

| # | Screen | Type | Auth Required | Purpose |
|---|--------|------|:-------------:|---------|
| 1 | `SplashScreen` | Startup | ❌ | Animated splash + routing |
| 2 | `OnboardingScreen` | Startup | ❌ | 4-page intro |
| 3 | `EntryHubScreen` | Startup | ❌ | 4-hub entry |
| 4 | `LoginScreen` | Auth | ❌ | Login |
| 5 | `RegisterScreen` | Auth | ❌ | Register (customer/company) |
| 6 | `EmailVerificationScreen` | Auth | ❌ | 6-digit OTP |
| 7 | `ForgotPasswordScreen` | Auth | ❌ | 2-phase reset |
| 8 | `ResetPasswordScreen` | Auth | ❌ | New password |
| 9 | `GovernorateSelectionScreen` | Guest | ❌ | Governorate picker |
| 10 | `HomeScreen` | Main | Optional | Main app |
| 11 | `SearchScreen` | Main | Optional | Search + voice |
| 12 | `SettingsScreen` | Main | ❌ | App settings |

---

## 📝 Best Practices

1. **Always initialize `StorageService` first** — all screens depend on it.
2. **Use `returnToCheckout: true`** when routing to login/register from checkout flow.
3. **Check `isAuthenticated`** before calling authenticated endpoints — fall back to `public` versions.
4. **Provide `AuthService` + `StorageService`** to every screen constructor.
5. **Persist guest governorate** via `storageService.saveGovernorate()`.
6. **Handle `permanentlyDenied` mic permission** by opening app settings.
7. **Always wrap in `Directionality(textDirection: TextDirection.rtl)`** for Arabic layout.
8. **Use `HapticFeedback`** on button interactions for premium feel.
9. **Call `showUnifiedReminderDialog`** only after the first frame + on `AppLifecycleState.resumed`.
10. **Prefer `EntryHubScreen`** if `isAlwaysShowHub() == true` after login.

---

<div align="center">

**📱 End of Part 4 — Core Screens**

</div>

---

# <a id="part-5"></a>🛒 PART 5 — Commerce Screens

**Location:** `lib/screens/cart/`, `lib/screens/categories/`, `lib/screens/favorites/`, `lib/screens/offers/`, `lib/screens/products/`

**Purpose:** Commerce & shopping screens for the NEX Mobile Application — cart, checkout, categories, favorites, offers, and products.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | Cart & Checkout | `CartScreen`, `CheckoutScreen` |
| 2 | Categories | `MainCategoriesScreen`, `SubCategoriesScreen` |
| 3 | Favorites | `FavoritesScreen` |
| 4 | Offers | `OffersListScreen`, `OfferDetailsScreen` |
| 5 | Products | `ProductsListScreen`, `ProductDetailsScreen` |

---

## 📁 File Structure

```
lib/screens/
├── cart/
│   ├── cart_screen.dart                   # Shopping cart
│   └── checkout_screen.dart               # Order checkout
├── categories/
│   ├── main_categories_screen.dart        # Main categories
│   └── subcategories_screen.dart          # Subcategories
├── favorites/
│   └── favorites_screen.dart              # Favorites
├── offers/
│   ├── offers_list_screen.dart            # Offers listing
│   └── offer_details_screen.dart          # Offer details
└── products/
    ├── products_list_screen.dart          # Products listing
    └── product_details_screen.dart        # Product details
```

---

## 1️⃣ Cart & Checkout

### 🔹 CartScreen

**File:** `lib/screens/cart/cart_screen.dart`

**Purpose:** Full-featured shopping cart with per-item quantity control, per-city shipping calculation, animated bottom summary, and integration with checkout.

#### 📋 Constructor
```dart
CartScreen({
  ApiService? apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Auto-load cart** on init + on app resume (`WidgetsBindingObserver`)
- ✅ **Per-item quantity control** (text field + increment/decrement)
- ✅ **Stock validation** with toast messages
- ✅ **Dual currency** (USD / SYP)
- ✅ **Per-city shipping status** per item:
    - ✅ Free shipping (`isFreeShippingForCity`)
    - 🚚 Calculated shipping (`isShippingCalculatedForCity`)
    - ⏳ Pending shipping (`isShippingPendingForCity`)
    - 🚫 No shipping info
- ✅ **Low stock warning** (≤ 5 items)
- ✅ **Animated bottom summary** (slide + fade toggle)
- ✅ **Refresh indicator** + scroll-to-refresh
- ✅ **Item removal / clear cart** with animated confirm dialogs
- ✅ **Hero animation** for image transitions

#### 📊 Bottom Summary Breakdown

| Row | Description |
|-----|-------------|
| المجموع الفرعي | Subtotal (`totalPrice`) |
| رسوم الشحن المحسوبة | `calculatedShippingCost` |
| عناصر شحنها مجاني | `freeShippingItemsCount` |
| منتجات بدون سعر توصيل | `pendingShippingItemsCount` |
| الإجمالي | `totalPriceWithShipping` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| Background | `#EFF6FF → #F5F7FA` |

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_animationController` | 800ms | Fade-in |
| `_pulseAnimationController` | 2000ms | Cart icon pulse (reverse loop) |
| `_cartAnimationController` | 600ms | Checkout button press |

#### 🎯 Actions

| Action | Result |
|--------|--------|
| `_updateQuantity(item, qty)` | Increment/decrement |
| `_setQuantity(item, value)` | Text field update |
| `_removeItem(item)` | Delete single item with confirm |
| `_clearCart()` | Empty cart with confirm |
| `_checkout()` | Navigate to `CheckoutScreen` |
| `_navigateToProductDetails(item)` | Open product or offer details |

#### 📤 Order Data
Delegates to `CartService.instance`:
- `items`, `itemCount`, `totalQuantity`
- `totalPrice`, `originalTotalPrice`, `totalDiscount`
- `calculatedShippingCost`, `totalPriceWithShipping`

---

### 🔹 CheckoutScreen

**File:** `lib/screens/cart/checkout_screen.dart`

**Purpose:** Complete checkout with customer info, prepaid discount, coupons, payment methods (cash / bank transfer / wallet with company selection), shipping notes, and order confirmation dialog.

#### 📋 Constructor
```dart
CheckoutScreen({
  required List<CartItemModel> items,
  required double totalPrice,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Customer info** (auto-filled from logged-in user)
- ✅ **Prepaid discount** (`aldfaa_almsbk` setting) — auto-disables cash payment
- ✅ **Coupon validation** via `validateCoupon`
- ✅ **Payment methods:**
    - 💵 Cash on delivery
    - 🏦 Bank transfer (fetch companies + custom)
    - 📱 E-wallet (fetch companies + custom)
- ✅ **Payment method details modal** (recipient, city, phone, account, account image, share image)
- ✅ **Shipping notes builder** (pending / free / calculated items)
- ✅ **Order confirmation dialog** with:
    - Invoice number
    - Total (with currency)
    - Prepaid discount breakdown
    - "Go to my orders" / "Home" buttons

#### 📊 Payment Methods

| Value | Label | Icon | Color |
|-------|-------|------|-------|
| `cash` | الدفع عند الاستلام | `money` | Green |
| `bank_transfer` | تحويل بنكي | `account_balance` | Blue |
| `wallet` | المحفظة الإلكترونية | `account_balance_wallet` | Orange |

#### 🔌 Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /v1/user/public/payment-methods/type/bank_transfer` | Bank companies |
| `GET /v1/user/public/payment-methods/type/electronic_wallet` | Wallet companies |
| `GET /v1/user/public/setting/aldfaa_almsbk` | Prepaid discount % |

#### 💰 Price Calculation
```dart
_subtotal                 = widget.totalPrice
_discountAmount           = discount (from coupon)
_shippingAmount           = cartService.calculatedShippingCost
_taxAmount                = _tax
_prepaidDiscountAmount    = _subtotal × (_prepaidPercentage / 100)   // if prepaid
_grandTotal               = _subtotal - _discount + _shipping + _tax - _prepaidDiscount
```

#### 📋 Notes Builder
`_buildShippingNotes()` generates a structured note appended to `user_notes`:
```
⚠️ المنتجات التالية بدون رسوم شحن محددة:
- ... (الكمية: X)

✅ المنتجات التالية شحنها مجاني:
- ...

📦 المنتجات التالية لها رسوم شحن محسوبة:
- ... - الشحن: ...

تحويل بنكي عن طريق: <company>
محفظة إلكترونية: <wallet>
✅ دفع مسبق - خصم X%
📦 إجمالي رسوم الشحن المحسوبة: ...
✅ X عناصر شحنها مجاني
⚠️ X عناصر سيتم تحديد شحنها لاحقاً
```

#### 🎯 Validation Rules
1. Form fields required
2. Prepaid **cannot** combine with cash
3. Bank transfer requires company selection OR custom name
4. Wallet requires company selection OR custom name
5. Auth required — redirects to `LoginScreen(returnToCheckout: true)`

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |

#### 🔗 Base URL
```
https://nexsy.shop
```

---

## 2️⃣ Categories

### 🔹 MainCategoriesScreen

**File:** `lib/screens/categories/main_categories_screen.dart`

**Purpose:** Main categories listing with **grid / list toggle**, search, and route to subcategories.

#### 📋 Constructor
```dart
MainCategoriesScreen({
  required ApiService apiService,
  AuthService? authService,
  StorageService? storageService,
})
```

#### 🎯 Features
- ✅ Grid (2-col) / list view toggle
- ✅ Search bar with clear button
- ✅ **Hero animations** for category images
- ✅ Stats chips: subcategories + products counts
- ✅ Featured badge
- ✅ Shimmer loading
- ✅ Error / Empty / No results states

#### 🔌 Endpoint
```
GET /v1/user/public/categories/main
```

#### 📊 Category Card Fields

| Field | Description |
|-------|-------------|
| `id`, `name_ar`, `description`, `image`, `slug` | Basic |
| `number_sub_categories` | Subcategories count |
| `number_products` | Products count |

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_pulseAnimationController` | 2000ms | Header icon pulse |
| `_fadeAnimationController` | 800ms | Entrance fade |

#### 🎨 Colors
Same palette as Home (`#1E3A8A`, `#3B82F6`, `#60A5FA`).

---

### 🔹 SubCategoriesScreen

**File:** `lib/screens/categories/subcategories_screen.dart`

**Purpose:** Subcategories listing within a main category, with **press-scale animation** (tap-down zoom effect) and grid / list toggle.

#### 📋 Constructor
```dart
SubCategoriesScreen({
  required dynamic category,
  required ApiService apiService,
  AuthService? authService,
  StorageService? storageService,
})
```

#### 🎯 Features
- ✅ Grid (2-col) / list view toggle
- ✅ Search bar
- ✅ **Press-scale animation** (`_zoomedCardIndex`) — cards shrink to `0.95` / `0.98` on tap-down
- ✅ Hero animation
- ✅ Products count chips
- ✅ Featured badge
- ✅ Shimmer loading

#### 🔌 Endpoint
```
GET /v1/user/public/categories/main/{slug}/sub
```

#### 🎯 Navigation
Tap card → `ProductsListScreen(isSubCategory: true, subcategorySlug: ...)`

#### 🎬 Animation
- **Grid cards:** `Transform.scale(0.95)` on tap-down → restores on tap-up
- **List cards:** `Transform.scale(0.98)` on tap-down
- 120ms delay before navigation for visual feedback
- `FadeInCard` staggered entrance

---

## 3️⃣ Favorites

### 🔹 FavoritesScreen

**File:** `lib/screens/favorites/favorites_screen.dart`

**Purpose:** User favorites (products + offers) with section filter, stats banner, and inline remove.

#### 📋 Constructor
```dart
FavoritesScreen({
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Auto-refresh** on app resume
- ✅ Filter (popup menu):
    - 🗂️ All
    - 🛍️ Products only
    - 🏷️ Offers only
- ✅ **Stats banner** (total + per-type counts)
- ✅ **Inline remove** (favorite heart icon on each card)
- ✅ **Hero**-integrated product/offer cards
- ✅ Pull-to-refresh
- ✅ Empty / Shimmer loading states

#### 🔧 Actions

| Action | Result |
|--------|--------|
| `_loadFavorites()` | Load from `FavoritesService` |
| `_refreshFavoritesData()` | Refresh + animate |
| `_onRefresh()` | Pull-to-refresh |
| `_removeProduct(id)` | Remove + snackbar |
| `_removeOffer(id)` | Remove + snackbar |
| `_navigateToProduct` / `_navigateToOffer` | Open details + refresh on return |

#### 📊 Section Headers

| Section | Icon | Color |
|---------|------|-------|
| Products | `shopping_bag` | Primary blue |
| Offers | `local_offer` | Orange |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| Favorites Red | `Colors.red` |

---

## 4️⃣ Offers

### 🔹 OffersListScreen

**File:** `lib/screens/offers/offers_list_screen.dart`

**Purpose:** Offers listing with **filter chips**, **grid / list toggle**, infinite scroll pagination, and empty state variations per filter.

#### 📋 Constructor
```dart
OffersListScreen({
  required String title,
  List<dynamic>? offers,      // If provided, no fetch
  String? type,                // Predefined filter (e.g., 'featured')
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Filter chips:** All / Cheapest / Highest Power / Variety / Featured / Latest
- ✅ **Grid / list view toggle**
- ✅ **Infinite scroll** with pagination
- ✅ **Empty state** per selected filter (varied titles/messages/icons)
- ✅ **Loading more** indicator with pulse
- ✅ Shimmer loading
- ✅ Hero animation on cards

#### 📊 Filter Types

| Key | Name | Icon | Color |
|-----|------|------|-------|
| `all` | الكل | `apps` | Primary |
| `cheapest` | الأرخص | `savings` | Orange |
| `highest-power` | الأقوى | `bolt` | Amber |
| `variety` | متنوعة | `category` | Purple |
| `featured` | مميزة | `star` | Amber-700 |
| `latest` | الأحدث | `fiber_new` | Teal |

#### 🔌 Endpoints

**Auth:**
```
/v1/user/offers
/v1/user/offers/{type}
/v1/user/offers/{selectedFilter}
```

**Guest:**
```
/v1/user/public/offers/all/{governorate}
/v1/user/public/offers/{type}/{governorate}
/v1/user/public/offers/{selectedFilter}/{governorate}
```

#### 🎯 Empty State Examples

| Filter | Title | Icon |
|--------|-------|------|
| `cheapest` | لا توجد عروض رخيصة | `savings` |
| `highest-power` | لا توجد عروض قوية | `bolt` |
| `variety` | لا توجد عروض متنوعة | `category` |
| `featured` | لا توجد عروض مميزة | `star` |
| `latest` | لا توجد عروض جديدة | `fiber_new` |

---

### 🔹 OfferDetailsScreen

**File:** `lib/screens/offers/offer_details_screen.dart`

**Purpose:** Complete offer details with **image gallery**, **AI analysis bottom sheet**, favorites, comparison, per-city shipping, in-offer products, and similar offers.

#### 📋 Constructor
```dart
OfferDetailsScreen({
  required String offerSlug,
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **PhotoView image gallery** (zoom + swipe)
- ✅ **Quantity control** with stock limit
- ✅ **AI analysis bottom sheet** (`/ai/offers/{id}/analyze`)
- ✅ **Comparison service** toggle
- ✅ **Per-city shipping card** with price tiers:
    - 🏆 Free (green)
    - 🚚 Cheap (blue, ≤ 5000)
    - 🚚 Medium (orange, ≤ 15000)
    - 🚚 Expensive (red, > 15000)
- ✅ **In-offer products** with Hero animation
- ✅ **Similar offers** horizontal carousel
- ✅ **Description expansion tile**
- ✅ **Specifications list**
- ✅ **Components list**
- ✅ **Smart Arabic/English text direction** (`_getTextDirection`)
- ✅ **Smart rating color** by percentage

#### 🧠 AI Analysis Section

| Section | Icon | Detection |
|---------|------|-----------|
| Advantages | `check_circle` | 'مميزات', 'مزايا', 'pros' |
| Disadvantages | `warning_amber` | 'عيوب', 'ضعف', 'cons' |
| Recommendation | `lightbulb` | 'نصيحة', 'توصية', 'advice' |
| Usage | `tips_and_updates` | 'استفادة', 'كيفية', 'how to' |
| Overview | `analytics` | 'تقييم', 'عام', 'overview' |
| Quality | `insights` | 'جودة', 'أداء', 'quality' |
| Compare | `compare_arrows` | 'قارن', 'مقارنة', 'compare' |

#### 🔧 AI Score Cards

| Card | Max Score | Color |
|------|-----------|-------|
| الدرجة النهائية | 100 | Primary Blue |
| جودة المكونات | 35 | Info Blue |
| التوافق | 10 | Status |
| الضمان | 30 | Success Green |
| التركيب | 10 | Purple |
| القيمة | 15 | Warning Orange |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Fetch | `GET /v1/user/offers/{slug}/show` |
| Guest fetch | `GET /v1/user/public/offers/{slug}/show/{governorate}` |
| Analyze | `GET /v1/user/public/ai/offers/{id}/analyze` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| `infoBlue` | `#3B82F6` |
| `warningOrange` | `#F59E0B` |

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_pulseAnimationController` | 2000ms | Header icon pulse |
| `_fadeAnimationController` | 800ms | Content fade-in |
| `_heartAnimationController` | 600ms | Favorite heart pop |
| `_cartAnimationController` | 800ms | Add-to-cart press |

---

## 5️⃣ Products

### 🔹 ProductsListScreen

**File:** `lib/screens/products/products_list_screen.dart`

**Purpose:** Products listing with **sort chips**, search, grid / list toggle, and infinite scroll pagination.

#### 📋 Constructor
```dart
ProductsListScreen({
  required String title,
  List<dynamic>? products,          // If provided, no fetch
  String? categorySlug,
  String? subcategorySlug,
  required ApiService apiService,
  AuthService? authService,
  StorageService? storageService,
  bool isSubCategory = false,
})
```

#### 🎯 Features
- ✅ **Sort chips:**
    - 🕐 Latest
    - 💵 Price ascending
    - 💵 Price descending
    - ⭐ Top rated
    - 👁️ Most viewed
- ✅ **Grid / list toggle**
- ✅ **Search bar** with submit
- ✅ **Infinite scroll** pagination
- ✅ **Contextual empty state** (search vs subcategory vs category vs default)
- ✅ **Governorate-aware** (auto-detects from storage)
- ✅ Shimmer loading

#### 📊 Sort Options

| Value | Label | Order | Icon |
|-------|-------|-------|------|
| `created_at` | الأحدث | desc | `schedule` |
| `price` | الأقل سعراً | asc | `trending_up` |
| `price` | الأعلى سعراً | desc | `trending_down` |
| `rate` | الأعلى تقييماً | desc | `star` |
| `views` | الأكثر مشاهدة | desc | `visibility` |

#### 🔌 Endpoints

| Context | Auth | Endpoint |
|---------|------|----------|
| Subcategory | ✅ | `/v1/user/products/sub-category/{slug}` |
| Subcategory | ❌ | `/v1/user/public/products/sub-category/{slug}/{gov}` |
| Category | ✅ | `/v1/user/products/category/{slug}` |
| Category | ❌ | `/v1/user/public/products/category/{slug}/{gov}` |
| General | ✅ | `/v1/user/products/search` |
| General | ❌ | `/v1/user/public/products/{gov}/search` |

#### 📊 Query Params
```
page, per_page, sort_by, sort_order, [name]
```

#### 🎯 Contextual Empty States

| Scenario | Icon | Title |
|----------|------|-------|
| Search active | `search_off` | لا توجد نتائج |
| Subcategory | `inventory_2` | القسم فارغ |
| Category | `category` | القسم فارغ |
| Default | `shopping_bag` | لا توجد منتجات |

---

### 🔹 ProductDetailsScreen

**File:** `lib/screens/products/product_details_screen.dart`

**Purpose:** The **most feature-rich** screen — product details with wholesale pricing, AI analysis, comparison, chat integration, spec styling, and shipping.

#### 📋 Constructor
```dart
ProductDetailsScreen({
  required String productSlug,
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **PhotoView image gallery**
- ✅ **Wholesale pricing** auto-detection + activation at threshold
- ✅ **AI analysis** bottom sheet
- ✅ **Chat with AI about this product** (`_discussProductWithAI`)
- ✅ **Comparison service** toggle
- ✅ **Per-city shipping card**
- ✅ **Descriptions expansion tile**
- ✅ **Specifications list with 100+ custom icons per spec type**
- ✅ **Similar products carousel**
- ✅ **Quantity control** with wholesale threshold alerts
- ✅ **Share product** (copy link to clipboard)

#### 🧠 Wholesale Pricing Logic
```dart
final bool hasWholesale = _product?['has_wholesale'] == true;
final int wholesaleMinQty = _product?['wholesale_min_quantity'] ?? 0;

// When quantity >= wholesaleMinQty → wholesale price applied
// Toast on threshold reached OR threshold-1
```

#### 📊 Wholesale Card

| Element | Color |
|---------|-------|
| Gradient | `#22C55E → #16A34A` |
| Text | `#166534` |
| Border | `#86EFAC` |

#### 🎯 Spec Icon Mapping (`_getSpecStyle`)
The screen includes **100+ custom icon mappings** for specification keys, grouped by type:

| Category | Icon | Color |
|----------|------|-------|
| Solar | `solar_power` | Amber |
| Voltage | `electric_bolt` | Amber |
| Current | `electric_meter` | Orange |
| Power | `flash_on` | Amber |
| Phase | `tune` | Purple |
| Battery | `battery_charging_full` | Green |
| Lithium | `battery_charging_full` | Green |
| Dimensions | `straighten` | Brown |
| Weight | `scale` | Teal |
| Speed | `speed` | Blue |
| Efficiency | `speed` | Green |
| Cooling | `ac_unit` | Cyan |
| Heating | `whatshot` | Orange |
| Steam | `cloud` | Slate |
| Gas | `local_fire_department` | Red |
| Water | `water_drop` | Cyan |
| Filter | `filter_alt` | Green |
| Noise | `volume_up` | Slate |
| Warranty | `verified_user` | Blue |
| ...and 80+ more | | |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Fetch | `GET /v1/user/products/{slug}/show` |
| Guest fetch | `GET /v1/user/public/products/{slug}/show/{governorate}` |
| Analyze | `GET /v1/user/public/ai/products/{id}/analyze` |

#### 💬 AI Chat Integration
`_discussProductWithAI()` builds a structured message:
```
🛍️ **مناقشة منتج**

📦 **اسم المنتج:** ...
🏷️ **الماركة:** ...
🔧 **الموديل:** ...

💰 **السعر:** ...

📋 **المواصفات:**
  • key: value
  ...

📝 **الوصف:**
...

أريد مناقشة هذا المنتج ومعرفة المزيد من التفاصيل والتوصيات.
```

Then routes to:
- **Guest** → `GuestChatScreen(initialMessage: ...)`
- **Auth** → `ChatScreen(initialMessage: ...)`

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_pulseAnimationController` | 2000ms | Header icon pulse |
| `_fadeAnimationController` | 800ms | Content fade-in |
| `_heartAnimationController` | 600ms | Favorite heart pop |
| `_cartAnimationController` | 800ms | Add-to-cart press |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `wholesaleGreen` | `#16A34A` |
| `wholesaleLight` | `#22C55E` |
| `successGreen` | `#10B981` |
| `infoBlue` | `#3B82F6` |
| `warningOrange` | `#F59E0B` |

---

## 🎨 Shared Design System

### 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Blue** | `#60A5FA` | Highlights |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success |
| **Danger** | `#EF4444` | Errors |
| **Warning** | `#F59E0B` | Warnings |
| **Wholesale Green** | `#16A34A` | Wholesale pricing |

### 🧊 Shared Patterns

| Pattern | Used By |
|---------|---------|
| **Curved AppBar** (`_BottomCurveClipper`) | All list screens |
| **Shimmer loading** | All screens |
| **Hero animations** | Products, offers, cart items |
| **Staggered entrances** | Grid/List items |
| **Empty states** with pulse icon | All screens |
| **Snackbar with icon + floating** | All screens |
| **Animated confirm dialogs** | Cart removals |
| **Bilingual text detection** (`_getTextDirection`) | Offer/Product details |
| **Rating color by percentage** | Product details AI analysis |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200ms | Press scale (squeeze) |
| 300–400ms | Dialog scale-in |
| 500–600ms | Card entrance |
| 700–800ms | Page fade-in |
| 1500–2000ms | Pulse (loop) |

---

## 🔄 Navigation Flow

```
HomeScreen
    │
    ├─→ MainCategoriesScreen ──→ SubCategoriesScreen ──→ ProductsListScreen ──→ ProductDetailsScreen
    │                                                                              │
    │                                                                              ├─→ Add to cart → CartScreen
    │                                                                              ├─→ Chat with AI (ChatScreen / GuestChatScreen)
    │                                                                              └─→ Add to comparison
    │
    ├─→ OffersListScreen ──→ OfferDetailsScreen
    │                              │
    │                              ├─→ Add to cart → CartScreen
    │                              ├─→ AI analyze (bottom sheet)
    │                              └─→ Compare
    │
    ├─→ FavoritesScreen ──→ Product/Offer details
    │
    └─→ CartScreen ──→ CheckoutScreen ──→ Order confirmation dialog
                                            │
                                            ├─→ OrdersScreen
                                            └─→ HomeScreen
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `cached_network_image` | All screens |
| `google_fonts` | All screens |
| `shimmer` | All loading states |
| `photo_view` | Image galleries (details) |
| `http` | Checkout payment methods |
| `path_provider` | Image download for sharing |
| `share_plus` | Share account image |
| `flutter/services` | HapticFeedback + Clipboard |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `CartScreen` | `CartService`, `ApiService`, `AuthService` |
| `CheckoutScreen` | `OrderApiService`, `CartService`, `AuthService`, `StorageService` |
| `MainCategoriesScreen` | `ApiService`, `AuthService`, `StorageService` |
| `SubCategoriesScreen` | `ApiService`, `AuthService`, `StorageService` |
| `FavoritesScreen` | `FavoritesService`, `ApiService`, `AuthService` |
| `OffersListScreen` | `ApiService`, `AuthService` |
| `OfferDetailsScreen` | `CartService`, `FavoritesService`, `ComparisonService`, `ApiService`, `AuthService` |
| `ProductsListScreen` | `ApiService`, `AuthService`, `StorageService` |
| `ProductDetailsScreen` | `CartService`, `FavoritesService`, `ComparisonService`, `StorageService`, `ApiService`, `AuthService` |

---

## 📊 Screens Summary

| # | Screen | Type | Auth Required | Purpose |
|---|--------|------|:-------------:|---------|
| 1 | `CartScreen` | Commerce | Optional | Shopping cart |
| 2 | `CheckoutScreen` | Commerce | ✅ | Order checkout |
| 3 | `MainCategoriesScreen` | Catalog | ❌ | Main categories |
| 4 | `SubCategoriesScreen` | Catalog | ❌ | Subcategories |
| 5 | `FavoritesScreen` | Commerce | ❌ | User favorites |
| 6 | `OffersListScreen` | Catalog | Optional | Offers listing |
| 7 | `OfferDetailsScreen` | Catalog | Optional | Offer details |
| 8 | `ProductsListScreen` | Catalog | Optional | Products listing |
| 9 | `ProductDetailsScreen` | Catalog | Optional | Product details |

---

## 📝 Best Practices

1. **Set `CartService.userGovernorate`** in CartScreen init before shipping calculations.
2. **Always provide `apiService`** to detail screens — required for navigation.
3. **Handle 404 gracefully** — treat as empty list, not as error.
4. **Prefer `widget.products != null`** to skip network fetches (used by home sections).
5. **Wholesale pricing auto-applies** when `quantity >= wholesale_min_quantity` — don't duplicate logic.
6. **Use `_getTextDirection()`** for mixed Arabic/English strings in detail screens.
7. **Call `refreshFavoritesData()`** after returning from detail screens.
8. **Validate prepaid + cash combination** before submitting orders.
9. **Show payment method details modal** for bank/wallet before selection.
10. **Persist governorate** via `StorageService.getGovernorate()` — used for shipping endpoints.

---

<div align="center">

**🛒 End of Part 5 — Commerce Screens**

</div>

---

# <a id="part-6"></a>👤 PART 6 — Profile, Orders, Workshop & Misc Screens

**Location:** `lib/screens/profile/`, `lib/screens/workshop/`, `lib/screens/notifications/`, `lib/screens/legal/`, `lib/screens/complaints/`, `lib/screens/comparison/`

**Purpose:** Profile, orders, workshop requests, notifications, legal pages, complaints, and comparison screens.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | Profile & Account | `ProfileScreen`, `EditProfileScreen`, `ChangePasswordScreen` |
| 2 | Orders | `OrdersScreen`, `OrderTrackingScreen`, `RateItemsScreen` |
| 3 | Workshop Services | `WorkshopRequestScreen`, `WorkshopRequestMaintenanceScreen`, `WorkshopHistoryScreen`, `LocationPickerScreen` |
| 4 | Notifications | `NotificationsScreen` |
| 5 | Legal & Support | `PrivacyScreen`, `TermsScreen`, `AddComplaintScreen` |
| 6 | Comparison | `ComparisonScreen` |

---

## 📁 File Structure

```
lib/screens/
├── profile/
│   ├── profile_screen.dart                # Main profile
│   ├── edit_profile_screen.dart           # Edit profile
│   ├── change_password_screen.dart        # Change password
│   ├── orders_screen.dart                 # Orders list
│   ├── order_tracking_screen.dart         # Order tracking hub
│   └── rate_items_screen.dart             # Rate items
├── workshop/
│   ├── workshop_request_screen.dart       # Installation request
│   ├── workshop_request_maintenance_screen.dart # Maintenance request
│   ├── workshop_history_screen.dart       # History
│   └── location_picker_screen.dart        # Map picker
├── notifications/
│   └── notifications_screen.dart          # Notifications list
├── legal/
│   ├── privacy_screen.dart                # Privacy policy
│   └── terms_screen.dart                  # Terms & conditions
├── complaints/
│   └── add_complaint_screen.dart          # Add complaint
└── comparison/
    └── comparison_screen.dart             # Comparison screen
```

---

## 1️⃣ Profile & Account

### 🔹 ProfileScreen

**File:** `lib/screens/profile/profile_screen.dart`

**Purpose:** Main profile screen with **tabbed layout** (Personal Info / Settings), statistics cards, referral code sharing, image upload, and account management.

#### 📋 Constructor
```dart
ProfileScreen({
  required AuthService authService,
  required ApiService apiService,
  required VoidCallback onLogout,
})
```

#### 🎯 Features
- ✅ **Curved gradient header** with animated avatar
- ✅ **Tabbed section** (Personal Info + Settings)
- ✅ **Stats cards** (Favorites, Orders, Registration date)
- ✅ **Referral code card** (tap to copy)
- ✅ **Share referral** bottom sheet with gift icon
- ✅ **Image picker** (gallery / camera / delete)
- ✅ **Delete account** with password + confirmation
- ✅ **Logout confirmation**
- ✅ Company owner request navigation
- ✅ Pull-to-refresh (via `_fetchProfile`)

#### 📊 Stats Cards

| Card | Icon | Color |
|------|------|-------|
| Favorites | `favorite` | Red |
| Orders | `shopping_bag` | Blue |
| Registration date | `calendar_today` | Orange |

#### 🔌 Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /v1/user/profile` | User profile |
| `GET /v1/user/favorites` | Favorites count |
| `GET /v1/user/orders` | Orders count |
| `POST /v1/user/profile/profile-image` | Upload image |
| `DELETE /v1/user/profile/profile-image` | Delete image |
| `DELETE /v1/user/profile/account` | Delete account |

#### 🎯 Settings Tab Items

| Icon | Title | Destination |
|------|-------|-------------|
| `business` | طلب فتح حساب شركة | `RequestCompanyScreen` |
| `edit` | تعديل الملف الشخصي | `EditProfileScreen` |
| `lock` | تغيير كلمة المرور | `ChangePasswordScreen` |
| `shopping_bag` | طلباتي | `OrdersScreen` |
| `logout` | تسجيل خروج | Logout dialog |
| `delete_forever` | حذف الحساب | Delete dialog |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `accentBlue` | `#60A5FA` |

---

### 🔹 EditProfileScreen

**File:** `lib/screens/profile/edit_profile_screen.dart`

**Purpose:** Edit user profile (name, phone, governorate, district, address) with validation.

#### 📋 Constructor
```dart
EditProfileScreen({
  required Map<String, dynamic> userData,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Curved gradient header** with save in AppBar
- ✅ **Animated avatar** with camera badge
- ✅ **Section headers** (Personal Info + Address)
- ✅ **Governorate dropdown** (14 Syrian governorates)
- ✅ **Phone validation** (`+963...`)
- ✅ Bottom save button + AppBar save icon

#### 📊 Fields

| Field | Validation |
|-------|-----------|
| Name | Required, ≥ 3 chars |
| Phone | Valid Syrian phone |
| Governorate | Required dropdown |
| District | Required |
| Address | Required |

#### 🔌 Endpoint
```
PUT /v1/user/profile
{ name, phone, governorate, district, address }
```

---

### 🔹 ChangePasswordScreen

**File:** `lib/screens/profile/change_password_screen.dart`

**Purpose:** Change password with live **password requirements validation** (length, digit, uppercase).

#### 📋 Constructor
```dart
ChangePasswordScreen({
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Live validation tiles** for password requirements:
    - ≥ 6 characters
    - Contains digit
    - Contains uppercase letter
- ✅ **Show/hide toggles** for each field
- ✅ **Animated requirement icons** (check vs. radio)
- ✅ AppBar save + bottom button

#### 🔌 Endpoint
```
POST /v1/user/profile/change-password
{ current_password, new_password, new_password_confirmation }
```

#### 🎨 Requirement Tiles

| Requirement | Regex |
|-------------|-------|
| Length ≥ 6 | `text.length >= 6` |
| Has digit | `\d` |
| Has uppercase | `[A-Z]` |

---

## 2️⃣ Orders

### 🔹 OrdersScreen

**File:** `lib/screens/profile/orders_screen.dart`

**Purpose:** Full order management with **status tabs** (All / Pending / Completed / Cancelled), detail modal, cancel action, and rating integration.

#### 📋 Constructor
```dart
OrdersScreen({
  ApiService? apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **TabBar** with 4 statuses
- ✅ **Animated order cards** with status gradient
- ✅ **Payment method labels + icons** (cash, card, bank, wallet)
- ✅ **Order details bottom sheet** with items + invoice summary
- ✅ **Cancel pending orders** with confirm dialog
- ✅ **Rate completed orders** → `RateItemsScreen`
- ✅ **Hero animations** for status icon + item images
- ✅ Pull-to-refresh

#### 📊 Order Status Mapping

| Status | Text | Color | Icon |
|--------|------|-------|------|
| `pending` | قيد المعالجة | Orange | `pending_actions` |
| `processing` | جاري التجهيز | Blue | `engineering` |
| `completed` | مكتمل | Green | `verified` |
| `cancelled` | ملغي | Red | `cancel` |
| `refunded` | مسترد | Purple | `currency_exchange` |

#### 📊 Payment Methods

| Key | Label | Icon |
|-----|-------|------|
| `cash` | الدفع عند الاستلام | `money` |
| `card` | بطاقة ائتمان | `credit_card` |
| `bank_transfer` | تحويل بنكي | `account_balance` |
| `wallet` | المحفظة الإلكترونية | `account_balance_wallet` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/orders/my-orders?page=&status=` |
| Details | `GET /v1/user/orders/{id}` |
| Cancel | `POST /v1/user/orders/{id}/cancel` |

#### 🔗 Base URL
```
https://nexsy.shop
```

---

### 🔹 OrderTrackingScreen

**File:** `lib/screens/profile/order_tracking_screen.dart`

**Purpose:** Simple **hub screen** for order tracking — routes to purchase orders or solar system design orders.

#### 📋 Constructor
```dart
OrderTrackingScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Two tracking options** (Shop orders / Solar design)
- ✅ **Hero-tagged icons** for smooth navigation
- ✅ Info card with support message

#### 🎯 Options

| Option | Icon | Color | Destination |
|--------|------|-------|-------------|
| طلبات الشراء | `shopping_bag` | Primary Blue | `OrdersScreen` |
| تصميم منظومة شمسية | `solar_power` | `#F59E0B` | `OrderHistoryScreen` |

---

### 🔹 RateItemsScreen

**File:** `lib/screens/profile/rate_items_screen.dart`

**Purpose:** Rate items in a completed order with **star rating** and optional comment per item.

#### 📋 Constructor
```dart
RateItemsScreen({
  required int invoiceId,
  required String invoiceNumber,
  ApiService? apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Per-item rating cards** (image + name + type badge)
- ✅ **Custom RatingBar** widget (tap-to-select stars)
- ✅ **Comment TextField** per item (optional)
- ✅ **Bulk submit** with partial success handling
- ✅ Empty state for fully rated orders

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Fetch items | `GET /v1/user/ratings/invoice/{id}/items` |
| Submit | `POST /v1/user/ratings/store` |

#### 📊 Submit Payload
```json
{
  "invoice_id": 1,
  "item_id": 5,
  "item_type": "product" | "offer",
  "rating": 1-5,
  "review": "..." // optional
}
```

---

## 3️⃣ Workshop Services

### 🔹 WorkshopRequestScreen

**File:** `lib/screens/workshop/workshop_request_screen.dart`

**Purpose:** Workshop **installation** request form with workshop selector, worker picker, available time slots, urgency, images, and map location.

#### 📋 Constructor
```dart
WorkshopRequestScreen({
  AuthService? authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Customer info** section (name, phone, address)
- ✅ **Map location picker** (`LocationPickerScreen`)
- ✅ **Workshop type grid** (3 cols, icon-based)
- ✅ **Custom workshop** option
- ✅ **Worker picker** with ratings + times
- ✅ **Available time slots** bottom sheet
- ✅ **Custom date/time** fallback
- ✅ **Urgency level** (Normal / Urgent)
- ✅ **Images upload** (multi-image)
- ✅ **Guest / Auth aware** endpoint switch

#### 📊 Icon Mapping

| Icon Name | IconData |
|-----------|----------|
| `tools` | `handyman` |
| `wrench` | `build` |
| `bolt` | `bolt` |
| `plug` | `power` |
| `industry` | `factory` |
| `hammer` | `construction` |
| `screwdriver` | `hardware` |
| `house` | `home` |
| `solar-panel` | `solar_power` |
| `fan` | `wind_power` |
| `snowflake` | `ac_unit` |
| `lightbulb` | `lightbulb` |
| `fire` | `local_fire_department` |
| `water` | `water_drop` |
| `elevator` | `elevator` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Workshops | `GET /v1/user/public/workshops` |
| Workers | `GET /v1/user/public/workshops/workers?workshop_id=` |
| Times | `GET /v1/user/public/workers/available-times?worker_id=` |
| Ratings | `GET /v1/user/public/workers/ratings?worker_id=` |
| Submit (Auth) | `POST /v1/user/workshop-requests` |
| Submit (Guest) | `POST /v1/user/public/workshop-requests` |

---

### 🔹 WorkshopRequestMaintenanceScreen

**File:** `lib/screens/workshop/workshop_request_maintenance_screen.dart`

**Purpose:** Workshop **maintenance** request form — nearly identical to `WorkshopRequestScreen` but with `prefilledSummary` support.

#### 📋 Constructor
```dart
WorkshopRequestMaintenanceScreen({
  AuthService? authService,
  required ApiService apiService,
  String? prefilledSummary,
})
```

#### 🎯 Differences vs. Installation

| Feature | Installation | Maintenance |
|---------|--------------|-------------|
| Endpoint | `/workshops` | `/workshops/maintenance` |
| Prefilled summary | ❌ | ✅ (`prefilledSummary`) |
| Form fields | Same | Same |

---

### 🔹 WorkshopHistoryScreen

**File:** `lib/screens/workshop/workshop_history_screen.dart`

**Purpose:** Workshop request history with **status tabs**, cancel/rate actions, and detail modal.

#### 📋 Constructor
```dart
WorkshopHistoryScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **4 status tabs** (All / Pending / Completed / Cancelled)
- ✅ **Animated request cards**
- ✅ **Status badge** + urgency chip
- ✅ **Cancel pending** requests
- ✅ **Rate completed** with modal (star selector + comment)
- ✅ **Details bottom sheet**
- ✅ Hero animations

#### 📊 Status Mapping

| Status | Text | Color | Icon |
|--------|------|-------|------|
| `pending` | قيد الانتظار | Orange | `pending_actions` |
| `processing` | جاري المعالجة | Blue | `engineering` |
| `completed` | مكتمل | Green | `verified` |
| `cancelled` | ملغي | Red | `cancel` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/workshop-requests/my-requests` |
| Cancel | `POST /v1/user/workshop-requests/{id}/cancel` |
| Rate | `POST /v1/user/workshop-requests/{id}/rate` |

---

### 🔹 LocationPickerScreen

**File:** `lib/screens/workshop/location_picker_screen.dart`

**Purpose:** Interactive **OpenStreetMap** map picker with reverse geocoding and current location detection.

#### 📋 Constructor
```dart
LocationPickerScreen()
```

#### 🎯 Features
- ✅ **FlutterMap** with OpenStreetMap tiles
- ✅ **Pulsing marker** at selected location
- ✅ **Tap to select** location on map
- ✅ **Reverse geocoding** (`geocoding` package)
- ✅ **GPS permission** handling (`geolocator`)
- ✅ **Default location** = Damascus (33.5138, 36.2765)
- ✅ **Copy coordinates** to clipboard
- ✅ **Confirm button** returns `{latitude, longitude, address}`

#### 🎯 Return Value
```dart
{
  'latitude': 33.5138,
  'longitude': 36.2765,
  'address': 'دمشق - المزة - ...'
}
```

#### 🔧 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_map` | Map rendering |
| `latlong2` | LatLng coordinates |
| `geocoding` | Reverse geocoding |
| `geolocator` | GPS location |

---

## 4️⃣ Notifications

### 🔹 NotificationsScreen

**File:** `lib/screens/notifications/notifications_screen.dart`

**Purpose:** Notifications list with **pagination**, mark-as-read, delete, and details bottom sheet.

#### 📋 Constructor
```dart
NotificationsScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Paginated list** (20 items per page, infinite scroll)
- ✅ **Guest lock screen** (redirect to login)
- ✅ **Mark single as read** on tap
- ✅ **Mark all as read** (popup menu)
- ✅ **Delete single / delete all**
- ✅ **Details bottom sheet** with type badge
- ✅ **Notification type icons + colors**
- ✅ Unread counter badge in header

#### 📊 Notification Types

| Type | Icon | Color | Label |
|------|------|-------|-------|
| `welcome` | `celebration` | Purple | ترحيب |
| `tips` | `lightbulb` | Orange | نصائح |
| `order` | `shopping_bag` | Blue | طلب |
| `offer` | `local_offer` | Green | عرض |
| default | `notifications` | Grey | إشعار عام |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/notifications?page=&per_page=` |
| Count | `GET /v1/user/notifications/count/unread` |
| Mark read | `PUT /v1/user/notifications/{id}/read` |
| Mark all read | `PUT /v1/user/notifications/read-all` |
| Delete | `DELETE /v1/user/notifications/{id}` |
| Delete all | `DELETE /v1/user/notifications` |

---

## 5️⃣ Legal & Support

### 🔹 PrivacyScreen

**File:** `lib/screens/legal/privacy_screen.dart`

**Purpose:** Static privacy policy with **10 numbered sections**.

#### 📋 Constructor
```dart
PrivacyScreen()
```

#### 🎯 Sections
1. المعلومات التي نجمعها
2. كيفية استخدام المعلومات
3. مشاركة المعلومات
4. أمان المعلومات
5. ملفات تعريف الارتباط
6. حقوق المستخدم
7. الاحتفاظ بالبيانات
8. خصوصية الأطفال
9. التعديلات على سياسة الخصوصية
10. الاتصال بنا

**Contact:** `privacy@nexsy.com`

---

### 🔹 TermsScreen

**File:** `lib/screens/legal/terms_screen.dart`

**Purpose:** Static terms & conditions with **10 numbered sections**.

#### 📋 Constructor
```dart
TermsScreen()
```

#### 🎯 Sections
1. قبول الشروط
2. وصف الخدمة
3. التسجيل والحساب
4. المنتجات والأسعار
5. الطلبات والدفع
6. الشحن والتركيب
7. الضمان والصيانة
8. الخصوصية
9. التعديلات
10. الاتصال بنا

**Contact:** `support@nexsy.com`

---

### 🔹 AddComplaintScreen

**File:** `lib/screens/complaints/add_complaint_screen.dart`

**Purpose:** Submit a complaint/feedback with **optional user info** (auto-filled if authenticated).

#### 📋 Constructor
```dart
AddComplaintScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Auto-fill** name/email/phone if authenticated
- ✅ **Multi-line message** (≥ 10 chars)
- ✅ **Animated feedback icon** (pulse)
- ✅ **Success dialog** then pop
- ✅ Works for guests too

#### 🔌 Endpoint
```
POST /v1/user/public/complaints
{ message, name?, email?, phone? }
```

#### 📊 Validation
- Message: required, ≥ 10 chars
- Name / Email / Phone: optional

---

## 6️⃣ Comparison

### 🔹 ComparisonScreen

**File:** `lib/screens/comparison/comparison_screen.dart`

**Purpose:** Side-by-side comparison of **Products** and **Offers** (up to 4 items each) with **AI comparison** results.

#### 📋 Constructor
```dart
ComparisonScreen({
  ApiService? apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **TabBar** (Products / Offers)
- ✅ **Horizontal comparison cards** (max 4)
- ✅ **Header banner** with item count
- ✅ **AI comparison** button (when ≥ 2 items)
- ✅ **Formatted comparison result** (headers + bullets)
- ✅ **Remove item** individually or clear all
- ✅ **Empty states** with helpful hints
- ✅ **Back to items** button in result view

#### 📊 Card Information

| Field | Product | Offer |
|-------|:-------:|:-----:|
| Image | ✅ | ✅ |
| Name | ✅ | ✅ |
| Final price | ✅ | ✅ |
| Discount | ✅ | ✅ |
| Brand | ✅ | ❌ |
| Total wattage | ❌ | ✅ |
| Total capacity | ❌ | ✅ |
| Rating | ✅ | ✅ |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Compare products | `POST /v1/user/public/ai/products/compare-multiple` |
| Compare offers | `POST /v1/user/public/ai/offers/compare-multiple` |

#### 📊 Request Payloads
```json
// Products
{ "product_ids": [1, 2, 3, 4] }

// Offers
{ "offer_ids": [10, 11, 12] }
```

#### 🎯 Max Items
- **Products:** 4
- **Offers:** 4

---

## 🎨 Shared Design System

### 🎨 Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Blue** | `#60A5FA` | Highlights |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success |
| **Danger** | `#EF4444` | Errors / Delete |
| **Warning** | `#F59E0B` | Warnings |
| **Amber** | `#FFA726` | Rating / Points |

### 🧊 Shared Patterns

| Pattern | Applied To |
|---------|-----------|
| **Curved AppBar** (`_BottomCurveClipper`) | All screens |
| **Shimmer loading** | Orders, History, Notifications, Comparison |
| **Hero animations** | Order status, images, workshop requests |
| **Animated entrances** | All lists (fade + slide) |
| **Pulse animations** | Header icons, empty states |
| **Confirm dialogs** | Delete / Cancel / Clear actions |
| **SnackBar with icon + floating** | All screens |
| **Bottom sheets** | Details, pickers, share |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200ms | Press scale |
| 300–400ms | Dialog / card entry |
| 500–600ms | Page fade-in |
| 700–800ms | Large entrances |
| 1500–2000ms | Pulse loops |

---

## 🔄 Navigation Flow

```
ProfileScreen
    │
    ├─→ EditProfileScreen
    ├─→ ChangePasswordScreen
    ├─→ OrdersScreen ──→ RateItemsScreen
    ├─→ RequestCompanyScreen
    ├─→ OrderTrackingScreen
    │       ├─→ OrdersScreen
    │       └─→ OrderHistoryScreen
    └─→ Logout / Delete Account

WorkshopRequestScreen
    ├─→ LocationPickerScreen
    ├─→ Workshops/Workers picker (bottom sheets)
    └─→ Submit

WorkshopRequestMaintenanceScreen
    ├─→ LocationPickerScreen
    └─→ Submit

WorkshopHistoryScreen
    ├─→ Details bottom sheet
    ├─→ Cancel / Rate
    └─→ Submit

NotificationsScreen
    └─→ Details bottom sheet

ComparisonScreen
    ├─→ AI comparison result
    └─→ Remove / Clear items
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `google_fonts` | All screens |
| `shimmer` | Loading skeletons |
| `cached_network_image` | Profile / Orders / RateItems |
| `image_picker` | Profile / Workshop |
| `flutter_map` | LocationPickerScreen |
| `latlong2` | LocationPickerScreen |
| `geocoding` | LocationPickerScreen |
| `geolocator` | LocationPickerScreen |
| `intl` | Workshop (date formatting) |
| `http` | AddComplaint / Profile |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `ProfileScreen` | `AuthService`, `ApiService` |
| `EditProfileScreen` | `ApiService` |
| `ChangePasswordScreen` | `ApiService` |
| `OrdersScreen` | `OrderApiService`, `ApiService`, `AuthService` |
| `OrderTrackingScreen` | `AuthService`, `ApiService` |
| `RateItemsScreen` | `RatingApiService`, `AuthService` |
| `WorkshopRequestScreen` | `AuthService`, `ApiService` |
| `WorkshopRequestMaintenanceScreen` | `AuthService`, `ApiService` |
| `WorkshopHistoryScreen` | `AuthService`, `ApiService` |
| `LocationPickerScreen` | *(standalone)* |
| `NotificationsScreen` | `AuthService`, `ApiService` |
| `PrivacyScreen` | *(static)* |
| `TermsScreen` | *(static)* |
| `AddComplaintScreen` | `AuthService`, `StorageService` |
| `ComparisonScreen` | `ComparisonService`, `ApiService`, `AuthService` |

---

## 📊 Screens Summary

| # | Screen | Type | Auth Required | Purpose |
|---|--------|------|:-------------:|---------|
| 1 | `ProfileScreen` | Profile | ✅ | User profile hub |
| 2 | `EditProfileScreen` | Profile | ✅ | Edit profile |
| 3 | `ChangePasswordScreen` | Profile | ✅ | Change password |
| 4 | `OrdersScreen` | Orders | ✅ | Orders list |
| 5 | `OrderTrackingScreen` | Orders | ✅ | Order tracking hub |
| 6 | `RateItemsScreen` | Orders | ✅ | Rate items |
| 7 | `WorkshopRequestScreen` | Workshop | Optional | Installation request |
| 8 | `WorkshopRequestMaintenanceScreen` | Workshop | Optional | Maintenance request |
| 9 | `WorkshopHistoryScreen` | Workshop | ✅ | History |
| 10 | `LocationPickerScreen` | Workshop | ❌ | Map picker |
| 11 | `NotificationsScreen` | Notifications | Optional | Notifications |
| 12 | `PrivacyScreen` | Legal | ❌ | Privacy policy |
| 13 | `TermsScreen` | Legal | ❌ | Terms & conditions |
| 14 | `AddComplaintScreen` | Support | Optional | Submit complaint |
| 15 | `ComparisonScreen` | Comparison | Optional | Products/Offers comparison |

---

## 📝 Best Practices

1. **Always pass `AuthService` + `ApiService`** to authenticated screens.
2. **Handle guest mode** gracefully — many screens support guest submissions.
3. **Use `WidgetsBindingObserver`** for auto-refresh on resume (Orders, Profile).
4. **Hero tags must be unique** — use `{type}_{id}` pattern.
5. **Prefill user data** from `AuthService.getUserData()` where possible.
6. **Validate phone with `+963` prefix** in all forms.
7. **Use `_BottomCurveClipper`** for consistent header design.
8. **Reuse `_showSnackBar()` pattern** for uniform feedback.
9. **Reset form after submit** to prevent duplicate submissions.
10. **Persist location coordinates** as `double` for backend compatibility.

---

<div align="center">

**👤 End of Part 6 — Profile, Orders, Workshop & Misc Screens**

</div>

---

# <a id="part-7"></a>☀️ PART 7 — System Builder, Solar & Maintenance Screens

**Location:** `lib/screens/system_builder/`, `lib/screens/solar_systems/`, `lib/screens/solar/`, `lib/screens/services/`, `lib/screens/maintenance/`

**Purpose:** System builder, user solar systems, AI solar design wizard, and maintenance request screens.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | System Builder | `SystemBuilderScreen`, `EditSystemOrderScreen`, `OrderHistoryScreen` |
| 2 | Solar Systems | `SolarSystemsScreen`, `AddSolarSystemScreen` |
| 3 | Solar Design | `SolarWizardScreen`, `SolarProjectsScreen`, `SolarProjectSummaryScreen` |
| 4 | Maintenance Services | `MaintenanceServicesScreen`, `MaintenanceScreen` |

---

## 📁 File Structure

```
lib/screens/
├── system_builder/
│   ├── system_builder_screen.dart         # Main builder
│   ├── edit_system_order_screen.dart      # Edit order
│   └── order_history_screen.dart          # Order history
├── solar_systems/
│   ├── solar_systems_screen.dart          # User's systems
│   └── add_solar_system_screen.dart       # Add system
├── solar/
│   ├── solar_wizard_screen.dart           # Design wizard (6 steps)
│   ├── solar_projects_screen.dart         # Saved projects
│   └── solar_project_summary_screen.dart  # Project summary
├── services/
│   └── maintenance_services_screen.dart   # Services hub
└── maintenance/
    └── maintenance_screen.dart            # Maintenance request
```

---

## 1️⃣ System Builder

### 🔹 SystemBuilderScreen

**File:** `lib/screens/system_builder/system_builder_screen.dart`

**Purpose:** The **core system builder** — allows users to select components (panels, inverters, batteries, cables, panel boards), analyze compatibility with AI, calculate costs, apply prepaid discounts, choose payment methods, and submit orders.

#### 📋 Constructor
```dart
SystemBuilderScreen({required AuthService authService})
```

#### 🎯 Features
- ✅ **Component selection** (5 categories with individual pickers)
- ✅ **Live cost calculation** with installation + mounting base fees
- ✅ **AI compatibility analysis** (via `analyzeSystem`)
- ✅ **Standard fees card** (installation + panel mounting base)
- ✅ **Prepaid discount** with toggle
- ✅ **3 payment methods:** Cash / Bank transfer / Wallet
- ✅ **Dynamic company pickers** (bank + wallet from API)
- ✅ **Payment method details modal** (recipient / phone / account image with share)
- ✅ **Draft auto-save** (via `SystemBuilderDraftService`)
- ✅ **History navigation** to `OrderHistoryScreen`
- ✅ **4 animated dialogs** (success / error / incompatibility / warning)

#### 📊 Component Categories

| Category | Colors | Icon |
|----------|--------|------|
| الألواح الشمسية | Orange | `solar_power` |
| الانفرتر | Blue | `memory` |
| البطاريات | Green | `battery_charging_full` |
| الكابلات | Purple | `cable` |
| تابلو الحماية | Teal | `electrical_services` |

#### 💰 Price Calculation
```dart
_subtotal              = Σ(component_price × quantity)
_installationPriceNumeric = installation_alamnthom setting
_mountingBaseTotal     = solar_mounting_base_price_per_panel × total_panels
_standardFeesTotal     = installation + mounting base
_prepaidBaseAmount     = subtotal + installation
_prepaidDiscountAmount = prepaidBaseAmount × (prepaidPercentage / 100)
_prepaidAmount         = prepaidBaseAmount - prepaidDiscountAmount
```

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Products by type | `GET /v1/user/public/system-builder/products?type=&search=&page=` |
| Installation price | `GET /v1/user/public/setting/installation_almnthom` |
| Mounting base price | `GET /v1/user/public/setting/solar_mounting_base_price_per_panel` |
| Prepaid % | `GET /v1/user/public/setting/aldfaa_almsbk` |
| Bank companies | `GET /api/nex/v1/user/public/payment-methods/type/bank_transfer` |
| Wallet companies | `GET /api/nex/v1/user/public/payment-methods/type/electronic_wallet` |
| Analyze | `POST /v1/user/public/system-builder/analyze` |
| Create order | `POST /v1/user/system-builder/order` |

#### 📊 Payment Methods

| Value | Label | Icon | Color |
|-------|-------|------|-------|
| `cash` | الدفع عند الاستلام | `money` | Green |
| `bank_transfer` | تحويل بنكي | `account_balance` | Blue |
| `wallet` | المحفظة الإلكترونية | `account_balance_wallet` | Orange |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `gold` | `#FFD700` |
| `successGreen` | `#10B981` |

#### 🎬 Animation Controllers

| Controller | Duration | Purpose |
|-----------|----------|---------|
| `_pulseAnimationController` | 2000ms | Header icon pulse |
| `_fadeAnimationController` | 800ms | Content fade-in |
| `_slideAnimationController` | 600ms | Page slide |

#### ⚠️ Validation Flow
1. Guest check → Login required
2. At least 1 component
3. Prepaid ≠ cash
4. Missing essential components warning (panels/inverters/batteries)
5. Delivery info (name, phone, address)
6. Payment company selection

#### 🧠 Compatibility Result Handling

| Status | Dialog |
|--------|--------|
| Compatible (score ≥ 70) | Success dialog |
| Warnings only | Compatibility warning dialog |
| Incompatible | Incompatibility dialog with issues |

---

### 🔹 EditSystemOrderScreen

**File:** `lib/screens/system_builder/edit_system_order_screen.dart`

**Purpose:** Edit an existing **system builder order** — modify components, quantities, delivery info, payment method, and prepaid option.

#### 📋 Constructor
```dart
EditSystemOrderScreen({
  required AuthService authService,
  required Map<String, dynamic> order,
})
```

#### 🎯 Features
- ✅ **Loads existing order data** (auto-parse JSON components)
- ✅ **Editable component lists** (5 categories)
- ✅ **Inline quantity controls** with text field
- ✅ **Add new components** via `ProductPickerScreen`
- ✅ **Delivery info editing**
- ✅ **Payment method picker** (4 methods)
- ✅ **Prepaid toggle**
- ✅ **Live cost summary**
- ✅ **Missing components warning**
- ✅ **Incompatibility dialog** on submit fail

#### 📊 Payment Methods (4 options)

| Value | Label |
|-------|-------|
| `cash` | الدفع عند الاستلام |
| `bank_transfer` | تحويل بنكي |
| `card` | بطاقة ائتمان |
| `wallet` | المحفظة الإلكترونية |

#### 🔌 Endpoint
```
PUT /v1/user/system-builder/orders/{id}
```

#### 🎯 **ProductPickerScreen** (Nested)
**Inner widget in same file** — product selection screen.

- ✅ **Grid/list of products** by type
- ✅ **Search bar** with debounced load
- ✅ **Quantity dialog** with stock limit
- ✅ **Navigate to product details** on card tap

---

### 🔹 OrderHistoryScreen

**File:** `lib/screens/system_builder/order_history_screen.dart`

**Purpose:** Solar system order history with **4 status tabs**, detail modal, edit and cancel actions.

#### 📋 Constructor
```dart
OrderHistoryScreen({required AuthService authService})
```

#### 🎯 Features
- ✅ **4 status tabs:** All / Pending / Processing / Completed
- ✅ **Animated order cards** with component stat row
- ✅ **Order detail bottom sheet** with:
    - Delivery + payment info
    - Prepaid discount
    - Components (5 sections)
    - Cost summary
    - User/admin notes
    - Dates
- ✅ **Cancel pending orders** with confirmation
- ✅ **Edit pending orders** → `EditSystemOrderScreen`
- ✅ **Hero animations** for status icons
- ✅ Pull-to-refresh

#### 📊 Order Status Mapping

| Status | Text | Color | Icon |
|--------|------|-------|------|
| `pending` | قيد الانتظار | Orange | `pending_actions` |
| `processing` | جاري المعالجة | Blue | `engineering` |
| `completed` | مكتمل | Green | `verified` |
| `cancelled` | ملغي | Red | `cancel` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/system-builder/my-orders` |
| Cancel | `POST /v1/user/system-builder/orders/{id}/cancel` |
| Edit | `PUT /v1/user/system-builder/orders/{id}` |

#### 🎯 Stat Row (per card)

| Icon | Label |
|------|-------|
| `solar_power` | الألواح |
| `memory` | الانفرتر |
| `battery_charging_full` | البطاريات |
| `cable` | الكابلات |
| `electrical_services` | التابلو |
| `attach_money` | الإجمالي |

---

## 2️⃣ Solar Systems

### 🔹 SolarSystemsScreen

**File:** `lib/screens/solar_systems/solar_systems_screen.dart`

**Purpose:** List of user's registered solar systems with detailed inspection modal.

#### 📋 Constructor
```dart
SolarSystemsScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **System cards** with status badge + payment indicator
- ✅ **Detailed bottom sheet** with:
    - Header (system number + status)
    - Status banner
    - **Panel section** (with image, count, wattage, brand, total)
    - **Inverter section** (with image, type, power, count, brand)
    - **Battery section** (with image, count, capacity, type, brand, total)
    - **Statistics section** (total power, battery capacity, age, responses count, payment)
    - **Maintenance responses** (with type badge + human date)
- ✅ **Delete system** with confirmation dialog
- ✅ **Add new system** FAB → `AddSolarSystemScreen`
- ✅ **Hero + staggered animations**

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /api/nex/v1/user/solar-systems?page=` |
| Details | `GET /api/nex/v1/user/solar-systems/{id}` |
| Delete | `DELETE /api/nex/v1/user/solar-systems/{id}` |

#### 🔗 Base URL
```
https://nexsy.shop
```

---

### 🔹 AddSolarSystemScreen

**File:** `lib/screens/solar_systems/add_solar_system_screen.dart`

**Purpose:** 5-section form to register a new solar system with images + progress bar.

#### 📋 Constructor
```dart
AddSolarSystemScreen({required AuthService authService})
```

#### 🎯 Features
- ✅ **Form progress bar** (5 sections)
- ✅ **5 sections:**
    1. Basic info (installation date, new/old toggle, previous issues, notes)
    2. Solar panels (count, wattage, brand, image)
    3. Inverter (type, power, count, brand, image)
    4. Batteries (count, capacity, type, brand, image)
    5. Details notes
- ✅ **Date picker** with theme
- ✅ **Switch toggle** for new/old system
- ✅ **Image pickers** (camera / gallery)
- ✅ **Submit button** with pulse animation

#### 📊 Form Sections

| # | Section | Icon | Color |
|---|---------|------|-------|
| 0 | معلومات أساسية | `info_outline` | Blue |
| 1 | الألواح الشمسية | `solar_power` | Orange |
| 2 | الانفرتر | `memory` | Purple |
| 3 | البطاريات | `battery_charging_full` | Green |
| 4 | ملاحظات إضافية | `note_add` | Teal |

#### 🔌 Endpoint
```
POST /api/nex/v1/user/solar-systems/store
```

#### 📤 Multipart Fields
```
installation_date, is_new, previous_issues, notes,
panels_count, panel_wattage, panel_brand, panel_image,
inverter_type, inverter_power, inverter_count, inverter_brand, inverter_image,
batteries_count, battery_capacity, battery_type, battery_brand, battery_image,
details_notes
```

---

## 3️⃣ Solar Design

### 🔹 SolarWizardScreen

**File:** `lib/screens/solar/solar_wizard_screen.dart`

**Purpose:** The **6-step solar design wizard** — place type → location → devices → hours → simultaneity → results. This is the most feature-rich screen in the app.

#### 📋 Constructor
```dart
SolarWizardScreen({
  ApiService? apiService,
  StorageService? storageService,
})
```

#### 🎯 Features
- ✅ **6-step wizard** with stepper header
- ✅ **Step 0:** Place type (house / industrial / agricultural)
- ✅ **Step 1:** City + area + electrical supply (220V / 380V / unknown)
- ✅ **Step 2:** Device selection (grid by category + custom device dialog)
- ✅ **Step 3:** Hours per device (day/night with 24h limit + split hint)
- ✅ **Step 4:** Simultaneity (day/night tabs, per-heavy-load quantity)
- ✅ **Step 5:** Results (plans + AI analysis + budget assessment)
- ✅ **Auto session persistence** (`saveGuestSolarSessionId`)
- ✅ **Save draft** as project
- ✅ **Add plan to manual builder** (draft service)
- ✅ **Discuss plan with AI** (chat navigation)
- ✅ **Draft history navigation**

#### 📊 Stepper Labels

| Step | Label |
|------|-------|
| 0 | النوع |
| 1 | الموقع |
| 2 | الأجهزة |
| 3 | الساعات |
| 4 | التزامن |
| 5 | النتائج |

#### 🏠 Place Type

| Value | Title | Available |
|-------|-------|-----------|
| `house` | منزلي | ✅ |
| `industrial` | صناعي | ❌ (coming soon) |
| `agricultural` | زراعي | ❌ (coming soon) |

#### ⚡ Electrical Supply

| Value | Label |
|-------|-------|
| `single_220` | أحادي 220V |
| `three_380` | ثلاثي 380V |
| `unknown` | لا أعرف |

#### 🧩 Device Categories

| Category | Icon |
|----------|------|
| تكييف | `ac_unit` |
| مطبخ | `kitchen` |
| غسيل | `local_laundry_service` |
| تلفزيون | `tv` |
| كمبيوتر | `laptop` |
| إضاءة | `lightbulb` |
| إنترنت | `router` |
| هواتف | `phone_android` |
| مكاتب | `desktop_windows` |
| صوتيات | `speaker` |
| مراوح | `air` |
| تنظيف | `cleaning_services` |
| مايكروويف | `microwave` |
| مكواة | `iron` |
| ماء | `water_drop` |
| مرطبات | `water` |
| مراقبة | `videocam` |
| نقاط بيع | `point_of_sale` |
| طباعة | `print` |
| كراج | `garage` |
| قهوة | `coffee` |
| مطاعم | `restaurant` |
| سيرفر | `dns` |
| أدوات | `build` |
| مخصص | `settings` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Device templates | `GET /v1/user/public/device-templates/{placeType}/grouped` |
| Design (auth) | `POST /v1/user/solar-design/design` |
| Design (guest) | `POST /v1/user/public/solar-design/design` |
| Save draft | `POST /v1/user/solar-design/save-draft` |

#### 📤 Design Request Payload
```json
{
  "design_mode": "home",
  "electrical_supply": "single_220",
  "place_type": "house",
  "location": {
    "city_ar": "دمشق",
    "area_ar": "المزة"
  },
  "selected_loads": [
    {"row_id": "r-xxx", "load_id": 5, "quantity": 2, "day_hours": 4, "night_hours": 2}
  ],
  "custom_loads": [
    {"row_id": "c-xxx", "name_ar": "جهاز مخصص", "rated_power_w": 500, "quantity": 1, "day_hours": 2, "night_hours": 0}
  ],
  "daytime_simultaneous": [
    {"row_id": "r-xxx", "simultaneous_quantity": 2}
  ],
  "nighttime_simultaneous": [
    {"row_id": "r-yyy", "simultaneous_quantity": 1}
  ],
  "is_syp": false,
  "session_id": "solar_guest_abc123"
}
```

#### 📊 Response Structure
```json
{
  "success": true,
  "data": {
    "engine_result": {
      "daily_energy_wh": 5000,
      "daytime_energy_wh": 3000,
      "night_energy_wh": 2000,
      "design_continuous_w": 1500,
      "design_surge_w": 2200,
      "plans": [
        {
          "key": "balanced",
          "valid": true,
          "recommended": true,
          "title_ar": "متوازن",
          "products": [...],
          "standard_addons": [...],
          "equipment_total": {"amount": 1200, "currency": "USD"},
          "estimated_total": {"amount": 1450, "currency": "USD"},
          "compatibility": [...],
          "constraints_ar": [...]
        }
      ],
      "warnings_ar": [...],
      "assumptions": [...],
      "savings_scenarios": [...],
      "budget_assessment": {...}
    },
    "ai_explanation": "...",
    "session_id": "solar_session_xyz"
  }
}
```

#### 🎯 Special Features

**Split Device Feature:**
- When a device has quantity > 1, a "تقسيم" (split) button appears
- Splits the row so each row can have independent day/night hours

**Simultaneity Detection:**
- Heavy loads (`heavy: true`) trigger the simultaneity step
- Single heavy load → auto-selected
- Multiple heavy loads → checkbox + quantity picker

**Budget Assessment:**
- `below_minimum` → Red (budget too low)
- `within_need` → Green (good)
- `above_need` → Orange (over-budget)

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| `warningOrange` | `#F59E0B` |
| `purple` | `#8B5CF6` |

---

### 🔹 SolarProjectsScreen

**File:** `lib/screens/solar/solar_projects_screen.dart`

**Purpose:** List of saved solar projects with **multi-select comparison** and swipe-to-delete.

#### 📋 Constructor
```dart
SolarProjectsScreen({
  ApiService? apiService,
  StorageService? storageService,
})
```

#### 🎯 Features
- ✅ **Stats bar** (projects / total kWh / total cost)
- ✅ **Animated project cards**
- ✅ **Swipe-to-delete** (Dismissible)
- ✅ **Long-press to enter selection mode**
- ✅ **Multi-select up to 3 projects** for comparison
- ✅ **FAB**: New design / Compare (context-aware)
- ✅ **Currency badge** (SYP/USD)
- ✅ **Chosen plan badge**
- ✅ Guest / auth aware

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/solar-design/projects` |
| Guest list | `GET /v1/user/public/solar-design/projects?session_id=` |
| Compare | `POST /v1/user/solar-design/projects/compare` |
| Delete | `DELETE /v1/user/solar-design/projects/{id}` |

#### 📊 Compare Screen (Nested)
**`SolarCompareScreen`** — side-by-side comparison of up to 3 projects:

| Field | Description |
|-------|-------------|
| رقم المشروع | Project number |
| التاريخ | Date |
| المحافظة | Governorate |
| عدد الأجهزة | Loads count |
| الاستهلاك اليومي (kWh) | Daily energy |
| الحمل المتزامن (kW) | Continuous load |
| الخطة | Plan |
| الألواح | Panels |
| البطاريات | Batteries |
| العاكس (W) | Inverter power |
| مصفوفة PV (W) | PV array |
| الإجمالي | Total (highlighted) |

---

### 🔹 SolarProjectSummaryScreen

**File:** `lib/screens/solar/solar_project_summary_screen.dart`

**Purpose:** Read-only summary of a saved solar project with detailed plan and loads.

#### 📋 Constructor
```dart
SolarProjectSummaryScreen({
  required ApiService apiService,
  required StorageService storageService,
  required int projectId,
  String? sessionId,
})
```

#### 🎯 Features
- ✅ **Header card** (project number + status + total)
- ✅ **Chosen plan section:**
    - Specs chips (panels, batteries, inverter, PV array, battery capacity, strings)
    - Products list with images
- ✅ **Loads section** with:
    - Device name, quantity, power
    - Day hours badge (amber)
    - Night hours badge (indigo)
    - Heavy load indicator 🔥
- ✅ **Duplicate project** button (AppBar)
- ✅ **Add to manual builder** (draft service)

#### 🔌 Endpoint
```
GET /v1/user/solar-design/projects/{id}
```

---

## 4️⃣ Maintenance Services

### 🔹 MaintenanceServicesScreen

**File:** `lib/screens/services/maintenance_services_screen.dart`

**Purpose:** Hub screen with **4 service cards** for diagnosis, installation, maintenance, and engineer consultation.

#### 📋 Constructor
```dart
MaintenanceServicesScreen({
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Features
- ✅ **Curved gradient header**
- ✅ **Intro card** with support agent icon
- ✅ **4 service cards** with tags
- ✅ **Info boxes** (safety tip + when to use)
- ✅ **History card** (auth only)
- ✅ **Colored gradients per service**

#### 🎯 Service Cards

| # | Title | Colors | Route |
|---|-------|--------|-------|
| 1 | تشخيص العطل | Blue (`#1E3A8A → #3B82F6`) | `DiagnosisHomeScreen` |
| 2 | خدمات الصيانة | Green (`#10B981 → #059669`) | `WorkshopRequestMaintenanceScreen` |
| 3 | خدمات التركيب | Amber (`#F59E0B → #F97316`) | `WorkshopRequestScreen` |
| 4 | استشارة مهندس | Purple (`#8B5CF6 → #7C3AED`) | `EngineerConsultationScreen` |

#### 🏷️ Tags per Card

| Card | Tags |
|------|------|
| Diagnosis | رمز الشاشة · وصف المشكلة · خطوات آمنة |
| Maintenance | صيانة الأعطال · فني متخصص · أوقات متاحة |
| Installation | فني متخصص · تحديد الموقع · أوقات متاحة |
| Engineer | مهندس متخصص · كهرباء / شمسي / إنارة · استشارة مباشرة |

---

### 🔹 MaintenanceScreen

**File:** `lib/screens/maintenance/maintenance_screen.dart`

**Purpose:** Full maintenance request screen with **AI / Team** support selector and past request history.

#### 📋 Constructor
```dart
MaintenanceScreen({
  required AuthService authService,
  required ApiService apiService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Contact info form** (name, phone, email — auto-filled)
- ✅ **Message textarea** (required)
- ✅ **Image attachment** (camera / gallery)
- ✅ **Support type selector:** Team 👨‍💼 / AI 🧠
- ✅ **AI solution dialog** (when AI resolves)
- ✅ **Previous requests list** (with type + status badges)
- ✅ Shimmer loading

#### 📊 Support Types

| Type | Icon | Color | Description |
|------|------|-------|-------------|
| `team` | `support_agent` | Primary | Human support team |
| `ai` | `psychology` | Purple | AI-powered instant resolution |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Submit | `POST /v1/user/public/maintenance` (multipart) |
| List | `GET /v1/user/public/maintenance/my-requests` |

#### 📤 Submit Payload
```
message, type (team/ai), name?, phone?, email?, image (file)
```

#### 📊 Request Status

| Status | Text | Color |
|--------|------|-------|
| `pending` | قيد المعالجة | Orange |
| `resolved` | تم الحل | Green |

#### 🧠 AI Solution Dialog
When `type == 'ai'` and `ai_solution` is returned:
- Custom dialog with purple gradient header
- Solution content in purple-tinted card
- Info box for escalation to team
- "New issue" button

---

## 🎨 Shared Design System

### 🎨 Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Blue** | `#60A5FA` | Highlights |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success / Batteries |
| **Danger** | `#EF4444` | Errors |
| **Warning** | `#F59E0B` | Warnings / Panels |
| **Purple** | `#8B5CF6` | AI / Wallets |
| **Gold** | `#FFD700` | Header icons |
| **Teal** | `#14B8A6` | Panel boards |

### 🧊 Shared Patterns

| Pattern | Applied To |
|---------|-----------|
| **Curved AppBar** (`_BottomCurveClipper`) | All screens |
| **Shimmer loading** | System builder, Projects, Solar systems |
| **Hero animations** | Orders, products, project cards |
| **Animated entrances** | All lists (fade + slide) |
| **Pulse animations** | Header icons, empty states |
| **Confirm dialogs** | Delete / Cancel actions |
| **SnackBar with icon** | All screens |
| **Bottom sheets** | Details, pickers, image source |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200ms | Press scale |
| 300–400ms | Card entry, dialog |
| 500–600ms | Page fade-in |
| 700–800ms | Large entrances |
| 1500–2000ms | Pulse loops |

---

## 🔄 Navigation Flow

```
HomeScreen
    │
    ├─→ SystemBuilderScreen
    │       ├─→ ProductPickerScreen
    │       ├─→ OrderHistoryScreen
    │       │       └─→ EditSystemOrderScreen
    │       ├─→ ChatScreen / GuestChatScreen
    │       └─→ SolarProjectsScreen (drafts)
    │
    ├─→ SolarWizardScreen
    │       ├─→ ChatScreen / GuestChatScreen
    │       ├─→ SolarProjectsScreen (drafts)
    │       └─→ ProductDetailsScreen (via product tap)
    │
    ├─→ SolarProjectsScreen
    │       ├─→ SolarProjectSummaryScreen
    │       ├─→ SolarWizardScreen (new design)
    │       └─→ SolarCompareScreen
    │
    ├─→ SolarSystemsScreen
    │       ├─→ AddSolarSystemScreen
    │       └─→ Details bottom sheet
    │
    └─→ MaintenanceServicesScreen
            ├─→ DiagnosisHomeScreen
            ├─→ WorkshopRequestScreen
            ├─→ WorkshopRequestMaintenanceScreen
            ├─→ EngineerConsultationScreen
            └─→ WorkshopHistoryScreen
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `google_fonts` | All screens |
| `shimmer` | Loading skeletons |
| `cached_network_image` | Product / system images |
| `image_picker` | Add system, Maintenance |
| `http` | Payment methods, Share image |
| `path_provider` | Share temp file |
| `share_plus` | Share payment account images |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `SystemBuilderScreen` | `SystemBuilderService`, `SystemBuilderDraftService`, `AuthService`, `ApiService` |
| `EditSystemOrderScreen` | `SystemBuilderService`, `AuthService` |
| `OrderHistoryScreen` | `SystemBuilderService`, `AuthService` |
| `SolarSystemsScreen` | `SolarSystemService`, `ApiService`, `AuthService` |
| `AddSolarSystemScreen` | `SolarSystemService`, `AuthService` |
| `SolarWizardScreen` | `ApiService`, `StorageService`, `SystemBuilderDraftService` |
| `SolarProjectsScreen` | `ApiService` (extension `SolarApiService`), `StorageService` |
| `SolarProjectSummaryScreen` | `ApiService` (extension), `StorageService`, `SystemBuilderDraftService` |
| `MaintenanceServicesScreen` | `ApiService`, `AuthService` |
| `MaintenanceScreen` | `ApiService`, `AuthService`, `StorageService` |

---

## 📊 Screens Summary

| # | Screen | Type | Auth Required | Purpose |
|---|--------|------|:-------------:|---------|
| 1 | `SystemBuilderScreen` | System Builder | ✅ | Build solar system |
| 2 | `EditSystemOrderScreen` | System Builder | ✅ | Edit order |
| 3 | `OrderHistoryScreen` | System Builder | ✅ | Order history |
| 4 | `ProductPickerScreen` | Nested | ✅ | Product selection |
| 5 | `SolarSystemsScreen` | Solar | ✅ | User's systems |
| 6 | `AddSolarSystemScreen` | Solar | ✅ | Add system |
| 7 | `SolarWizardScreen` | Solar Design | Optional | 6-step wizard |
| 8 | `SolarProjectsScreen` | Solar Design | Optional | Saved projects |
| 9 | `SolarCompareScreen` | Nested | Optional | Compare projects |
| 10 | `SolarProjectSummaryScreen` | Solar Design | Optional | Project summary |
| 11 | `MaintenanceServicesScreen` | Services | ❌ | Services hub |
| 12 | `MaintenanceScreen` | Maintenance | Optional | Maintenance request |

---

## 📝 Best Practices

1. **Always pass `AuthService`** to system builder & solar screens — required for auth-gated endpoints.
2. **Guest mode supported** in solar wizard & projects — use `guest_solar_session_id`.
3. **Auto-save drafts** — System builder uses `SystemBuilderDraftService`, solar uses server-side drafts.
4. **Payment methods from API** — never hardcode companies; always fetch by type.
5. **Prepaid ≠ cash** — validate before submitting.
6. **Missing components warning** — always show before final submit.
7. **Incompatibility dialog** — never silently fail; show issues + score.
8. **Hero tags must be unique** — use `{type}_{id}` pattern.
9. **Prefill user data** from `AuthService.getUserData()` where possible.
10. **Reset form after successful submit** to prevent duplicates.
11. **Image upload requires multipart** — `MultipartFile.fromPath()`.
12. **Handle 404 gracefully** — treat empty results as valid states.

---

<div align="center">

**☀️ End of Part 7 — System Builder, Solar & Maintenance Screens**


</div>

---

# <a id="part-8"></a>🤖 PART 8 — Appliance, Chat, Diagnosis, Engineer & Lighting Screens

**Location:** `lib/screens/appliances/`, `lib/screens/chat/`, `lib/screens/diagnosis/`, `lib/screens/engineer/`, `lib/screens/lighting/`

**Purpose:** Appliance services, chat system, AI diagnosis, engineer consultation, and lighting design screens.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | Appliance Screens | Compatibility, Maintenance, Savings, Schedule |
| 2 | Chat Screens | Main Chat, Solar, Support, Appliance Support, Lighting Support |
| 3 | Diagnosis Screens | Entry, Home, Device, Device Options, Faults List, Flow, Search |
| 4 | Engineer Screens | Chat, Confirmation, Consultation |
| 5 | Lighting Screens | Projects, Project Summary, Room Wizard, Visualization |
| 6 | Widgets | MessageBubble, MaintenanceMessageBubble, GovernoratePicker |

---

## 📁 File Structure

```
lib/screens/
├── appliances/
│   ├── appliance_compatibility_screen.dart              # فحص التوافق (auth)
│   ├── appliance_maintenance_screen.dart                # الصيانة الذكية (auth)
│   ├── appliance_savings_screen.dart                    # حاسبة التوفير (auth)
│   ├── appliance_schedule_screen.dart                   # مدير جدول التشغيل (auth)
│   ├── guest_appliance_compatibility_screen.dart        # فحص التوافق (guest)
│   ├── guest_appliance_maintenance_screen.dart          # الصيانة الذكية (guest)
│   ├── guest_appliance_savings_screen.dart              # حاسبة التوفير (guest)
│   ├── guest_appliance_schedule_screen.dart             # مدير جدول التشغيل (guest)
│   └── maintenance_message_bubble.dart                  # فقاعة رسالة الصيانة
│
├── chat/
│   ├── chat_screen.dart                                 # المساعد الذكي (auth)
│   ├── guest_chat_screen.dart                           # المساعد الذكي (guest)
│   ├── solar_chat_screen.dart                           # المستشار الشمسي (auth)
│   ├── guest_solar_chat_screen.dart                     # المستشار الشمسي (guest)
│   ├── support_solar_chat_screen.dart                   # الدعم الفني الشمسي (auth)
│   ├── guest_support_solar_chat_screen.dart             # الدعم الفني الشمسي (guest)
│   ├── appliance_support_chat_screen.dart               # دعم الأجهزة (auth)
│   ├── guest_appliance_support_chat_screen.dart         # دعم الأجهزة (guest)
│   ├── lighting_support_chat_screen.dart                # دعم الإنارة (auth)
│   ├── guest_lighting_support_chat_screen.dart          # دعم الإنارة (guest)
│   ├── message_bubble.dart                              # فقاعة رسالة عامة
│   └── governorate_picker.dart                          # منتقي المحافظة
│
├── diagnosis/
│   ├── diagnosis_entry_screen.dart                      # مدخل التشخيص
│   ├── diagnosis_home_screen.dart                       # الصفحة الرئيسية للتشخيص
│   ├── diagnosis_device_screen.dart                     # أجهزة القسم
│   ├── diagnosis_device_options_screen.dart             # خيارات الجهاز
│   ├── diagnosis_faults_list_screen.dart                # قائمة الأعطال
│   ├── diagnosis_flow_screen.dart                       # مسار التشخيص (12 حالة)
│   └── diagnosis_search_screen.dart                     # البحث في الأعطال
│
├── engineer/
│   ├── engineer_consultation_screen.dart                # اختيار مجال الاستشارة
│   ├── engineer_confirmation_screen.dart                # تأكيد الاستشارة
│   └── engineer_chat_screen.dart                        # محادثة المهندس
│
└── lighting/
    ├── lighting_projects_screen.dart                    # مشاريع الإنارة
    ├── lighting_project_summary_screen.dart             # ملخص المشروع
    ├── lighting_room_wizard_screen.dart                 # معالج تصميم الغرفة
    └── lighting_visualization_screen.dart               # المعاينة البصرية
```

---

## 1️⃣ Appliance Screens

### 🔹 ApplianceCompatibilityScreen

**File:** `lib/screens/appliances/appliance_compatibility_screen.dart`

**Purpose:** 5-step wizard to check appliance compatibility with solar system (authenticated version).

#### 📋 Constructor
```dart
ApplianceCompatibilityScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **5-step wizard** with progress dots
- ✅ **Step 0:** System voltage (12V / 24V / 48V)
- ✅ **Step 1:** Solar panels count + watts (with "أخرى" custom input)
- ✅ **Step 2:** Batteries count + Ah + type (acid / gel / lithium)
- ✅ **Step 3:** Inverter power (10 range options + manual)
- ✅ **Step 4:** Devices to check (multi-add with suggested devices + custom)
- ✅ **Suggested devices carousel** with icons
- ✅ **Day/night hours per device** (☀️/🌙)
- ✅ **Result segmentation:** compatible / warning / incompatible
- ✅ **Summary banner** with gradient

#### 📊 Wizard Steps

| Step | Title | Fields |
|------|-------|--------|
| 0 | الفولتية | System voltage |
| 1 | الألواح | Panels count + watts |
| 2 | البطاريات | Count + Ah + type |
| 3 | الإنفرتر | Power range |
| 4 | الأجهزة | Device list |

#### 🔌 Endpoint
```
POST /v1/user/appliance-compatibility/check
```

#### 📤 Payload
```json
{
  "system_voltage": "24",
  "inverter_power": "3000W - 4000W",
  "battery_type": "ليثيوم",
  "panel_count": 6,
  "panel_watts": 550,
  "battery_count": 4,
  "battery_ah": 200,
  "appliances": "مكيف 1500W - نهار 4h - ليل 2h\nبراد 200W - نهار 24h"
}
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `accentCyan` | `#06B6D4` |
| `dayColor` | `#F59E0B` |
| `nightColor` | `#6366F1` |
| `successGreen` | `#10B981` |

---

### 🔹 GuestApplianceCompatibilityScreen

**File:** `lib/screens/appliances/guest_appliance_compatibility_screen.dart`

**Purpose:** Guest version of compatibility check — **4 steps** (no panels step).

#### 📋 Constructor
```dart
GuestApplianceCompatibilityScreen({
  required ApiService apiService,
  required StorageService storageService,
  String? initialGovernorate,
})
```

#### 🎯 Differences vs Auth Version

| Feature | Auth | Guest |
|---------|:----:|:-----:|
| Steps | 5 (with panels) | 4 |
| Governorate | ❌ | ✅ |
| Session ID | ❌ | ✅ (guest session) |
| Endpoint | `/v1/user/...` | `/v1/user/public/...` |
| Panel count/watts | ✅ | ❌ |
| Battery count/Ah | ✅ | ❌ |

#### 🔌 Endpoint
```
POST /v1/user/public/appliance-compatibility/check
{ session_id, governorate, system_voltage, inverter_power, battery_type, appliances }
```

---

### 🔹 ApplianceMaintenanceScreen

**File:** `lib/screens/appliances/appliance_maintenance_screen.dart`

**Purpose:** AI-powered maintenance chat with voice/image/text support (authenticated).

#### 📋 Constructor
```dart
ApplianceMaintenanceScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Chat-based UI** with message bubbles
- ✅ **Text messages** with markdown rendering
- ✅ **Image uploads** (multi-image picker)
- ✅ **Voice recording** (long-press to record)
- ✅ **AI diagnosis card** (structured fault detection)
- ✅ **Typing indicator** (3 animated dots)
- ✅ **Quick example chips**
- ✅ **Clear chat** with confirmation
- ✅ **Support chat navigation**
- ✅ **Workshop request navigation**

#### 📊 AI Diagnosis Card Fields

| Field | Description |
|-------|-------------|
| `diagnosis` | Overall fault description |
| `severity` | بسيط / متوسط / خطير |
| `possible_causes` | List of causes with details |
| `recommendations` | Actionable steps |
| `needs_technician` | Boolean flag |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Start session | `POST /v1/user/public/appliance-maintenance/start` |
| Send text | `POST /v1/user/appliance-maintenance/send` |
| Send image | `POST /v1/user/appliance-maintenance/send-image` |
| Send voice | `POST /v1/user/appliance-maintenance/send-voice` |
| Get history | `GET /v1/user/appliance-maintenance/history` |
| Clear | `DELETE /v1/user/appliance-maintenance/clear` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `accentCyan` | `#06B6D4` |
| `successGreen` | `#10B981` |

---

### 🔹 GuestApplianceMaintenanceScreen

**File:** `lib/screens/appliances/guest_appliance_maintenance_screen.dart`

**Purpose:** Guest version — same as auth but with **guest session** and **governorate picker**.

#### 🎯 Features
- ✅ **Guest session** auto-created (`saveGuestMaintenanceSessionId`)
- ✅ **Governorate picker** in header
- ✅ **Guest mode indicator** in header
- ✅ **Workshop request** with null authService

#### 🔌 Endpoints
All endpoints are `public/*` with `session_id` and `governorate` params.

---

### 🔹 ApplianceSavingsScreen

**File:** `lib/screens/appliances/appliance_savings_screen.dart`

**Purpose:** 3-step savings calculator — appliance list → review → result.

#### 📋 Constructor
```dart
ApplianceSavingsScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **3-step wizard** (appliances → review → calculate)
- ✅ **Inverter appliances catalog** from API
- ✅ **Search filter** for appliances
- ✅ **Grid layout** with appliance cards
- ✅ **Bottom sheet** to add appliance with hours
- ✅ **Edit/remove** selected appliances
- ✅ **Result screen** with comparison bars
- ✅ **Monthly totals** (normal vs inverter)
- ✅ **AI recommendation** card

#### 📊 Appliance Card Data

| Field | Description |
|-------|-------------|
| `name_ar` | Appliance name |
| `normal_watts` | Normal power (W) |
| `inverter_watts` | Inverter power (W) |
| `default_hours_per_day` | Suggested hours |
| `savings_percentage` | Expected savings % |
| `icon` | Icon name |

#### 🔌 Endpoint
```
GET /v1/user/public/inverter-appliances
POST /v1/user/appliance-savings/calculate
```

#### 📤 Payload
```json
{
  "appliances": [
    {
      "name": "مكيف",
      "normal_watts": 1500,
      "inverter_watts": 900,
      "hours_per_day": 6
    }
  ]
}
```

#### 🎨 Result Screen Colors

| Element | Color |
|---------|-------|
| Total savings row | `Colors.amber` |
| Normal consumption | `Colors.red` |
| Inverter consumption | `successGreen` |

---

### 🔹 GuestApplianceSavingsScreen

**File:** `lib/screens/appliances/guest_appliance_savings_screen.dart`

**Purpose:** Guest version of savings calculator — same structure, guest session.

#### 🔌 Endpoint
```
POST /v1/user/public/appliance-savings/calculate
{ appliances, session_id, governorate }
```

---

### 🔹 ApplianceScheduleScreen

**File:** `lib/screens/appliances/appliance_schedule_screen.dart`

**Purpose:** 5-step schedule generator — voltage → panels → batteries → inverter → devices.

#### 📋 Constructor
```dart
ApplianceScheduleScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **5-step wizard** (same steps as compatibility + devices)
- ✅ **Device templates** from API
- ✅ **Day/night hours** per device
- ✅ **Schedule result** with time sections:
    - 🌅 **الصباح** (morning)
    - ☀️ **الظهر** (afternoon)
    - 🌇 **المساء** (evening)
    - 🌙 **الليل** (night)
- ✅ **Warnings section** (red)
- ✅ **Tips section** (green)

#### 📊 Schedule Result Structure
```json
{
  "morning": ["جهاز 1 (10:00 - 12:00)"],
  "afternoon": ["جهاز 2 (14:00 - 16:00)"],
  "evening": ["جهاز 3 (18:00 - 20:00)"],
  "night": ["جهاز 4 (22:00 - 02:00)"],
  "warnings": ["حمل كبير في وقت واحد"],
  "tips": ["وزّع الأحمال على مدار اليوم"]
}
```

#### 🔌 Endpoint
```
POST /v1/user/appliance-schedule/generate
{
  system_voltage, inverter_power, battery_type,
  panel_count, panel_watts, battery_count, battery_ah,
  appliances
}
```

---

### 🔹 GuestApplianceScheduleScreen

**File:** `lib/screens/appliances/guest_appliance_schedule_screen.dart`

**Purpose:** Guest version — same structure, but skips battery type step order.

#### 🎯 Differences

| Feature | Auth | Guest |
|---------|:----:|:-----:|
| Steps | 5 | 5 |
| Step order | Voltage → Panels → Batteries → Inverter → Devices | Same |
| Guest session | ❌ | ✅ |

---

## 2️⃣ Chat Screens

All chat screens share the **same visual structure**:
- **Curved gradient header** with domain icon
- **Message list** with bubbles
- **Input bar** (mic + image + text + send)
- **Typing indicator** (3 animated dots)
- **Pusher real-time** integration
- **Suggested questions** chips (when available)
- **Font scale** pinch-zoom (in some screens)

### 🔹 ChatScreen (Main AI Assistant)

**File:** `lib/screens/chat/chat_screen.dart`

**Purpose:** Main AI assistant for solar energy calculations and product recommendations.

#### 📋 Constructor
```dart
ChatScreen({
  required AuthService authService,
  required ApiService apiService,
  String? initialMessage,
})
```

#### 🎯 Features
- ✅ **Solar calculator integration** (polling for async results)
- ✅ **Pagination** for chat history (load more)
- ✅ **Product navigation** from AI responses
- ✅ **Offer navigation** from AI responses
- ✅ **Font scale** pinch-to-zoom (0.7 → 2.0)
- ✅ **Suggested questions** from AI
- ✅ **Voice/image/text** support

#### 📊 AI Response Data Structure

| Key | Description |
|-----|-------------|
| `requirements` | Engineering calculation results |
| `matches.system_options` | Economic/Standard/Premium plans |
| `matches.products` | Recommended products |
| `matches.comparisons` | Product comparisons |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| History | `GET /v1/user/chat/history?limit=&offset=` |
| Send | `POST /v1/user/chat/send` |
| Send with image | `POST /v1/user/chat/send-with-image` |
| Send voice | `POST /v1/user/chat/send-voice` |
| Calculation result | `GET /v1/user/chat/calculation-result?calculation_id=` |
| Clear | `DELETE /v1/user/chat/clear` |

---

### 🔹 GuestChatScreen

**File:** `lib/screens/chat/guest_chat_screen.dart`

**Purpose:** Guest version of main chat.

#### 🎯 Differences

| Feature | Auth | Guest |
|---------|:----:|:-----:|
| Guest session | ❌ | ✅ |
| Governorate picker | ❌ | ✅ |
| Governorate update | ❌ | ✅ (`updateGuestGovernorate`) |
| Session ID param | ❌ | ✅ |
| Auth service | ✅ | ❌ (null) |

#### 🔌 Endpoint
```
POST /v1/user/public/chat/start
POST /v1/user/public/chat/send
POST /v1/user/public/chat/send-with-image
GET  /v1/user/public/chat/history
POST /v1/user/public/chat/update-governorate
DELETE /v1/user/public/chat/clear
```

---

### 🔹 SolarChatScreen

**File:** `lib/screens/chat/solar_chat_screen.dart`

**Purpose:** Solar consultant chat (authenticated) — focused on solar advice.

#### 🎯 Features
- ✅ **Solar-focused** suggested questions
- ✅ **History pagination**
- ✅ **Voice/image/text** support
- ✅ **No product navigation** (advice-focused)

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| History | `GET /v1/user/solar-chat/history` |
| Send | `POST /v1/user/solar-chat/send` |
| Send with image | `POST /v1/user/solar-chat/send-with-image` |
| Send voice | `POST /v1/user/solar-chat/send-voice` |
| Clear | `DELETE /v1/user/solar-chat/clear` |

#### 🎨 Icon
`solar_power_rounded` in header

---

### 🔹 GuestSolarChatScreen

**File:** `lib/screens/chat/guest_solar_chat_screen.dart`

**Purpose:** Guest version of solar consultant.

#### 🔌 Endpoint
```
POST /v1/user/public/solar-chat/start
POST .../solar-chat/send
POST .../solar-chat/send-with-image
POST .../solar-chat/send-voice
GET  .../solar-chat/history
DELETE .../solar-chat/clear
```

---

### 🔹 SupportSolarChatScreen

**File:** `lib/screens/chat/support_solar_chat_screen.dart`

**Purpose:** Human support chat for solar (authenticated).

#### 🎯 Features
- ✅ **Pusher real-time** updates (`SupportMessageSent` event)
- ✅ **Conversation ID** tracking
- ✅ **Close conversation** action
- ✅ **Support agent** icon

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Start | `POST /v1/user/public/support-solar/start` |
| Send | `POST .../support-solar/send` |
| Send with image | `POST .../support-solar/send-with-image` |
| Send voice | `POST .../support-solar/send-voice` |
| History | `GET .../support-solar/history` |
| Close | `POST .../support-solar/close` |
| Clear | `DELETE .../support-solar/clear` |

---

### 🔹 GuestSupportSolarChatScreen

**File:** `lib/screens/chat/guest_support_solar_chat_screen.dart`

**Purpose:** Guest version of solar support.

#### 🎯 Features
- ✅ **Governorate picker** in header
- ✅ **Guest mode indicator**
- ✅ **Pusher integration**

---

### 🔹 ApplianceSupportChatScreen

**File:** `lib/screens/chat/appliance_support_chat_screen.dart`

**Purpose:** Human support chat for appliances (authenticated).

#### 🎨 Icon
`handyman_rounded` in header

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Start | `POST .../appliance-support/start` |
| Send | `POST .../appliance-support/send` |
| Send image | `POST .../appliance-support/send-image` |
| Send voice | `POST .../appliance-support/send-voice` |
| History | `GET .../appliance-support/history` |
| Clear | `DELETE .../appliance-support/clear` |

---

### 🔹 GuestApplianceSupportChatScreen

**File:** `lib/screens/chat/guest_appliance_support_chat_screen.dart`

**Purpose:** Guest version of appliance support.

#### 🎯 Features
- ✅ **Governorate picker**
- ✅ **Guest session** (`saveGuestApplianceSupportSessionId`)
- ✅ **Pusher real-time**

---

### 🔹 LightingSupportChatScreen

**File:** `lib/screens/chat/lighting_support_chat_screen.dart`

**Purpose:** Human support chat for lighting (authenticated).

#### 🎨 Icon
`lightbulb_rounded` in header

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Start | `POST .../lighting-support/start` |
| Send | `POST .../lighting-support/send` |
| Send image | `POST .../lighting-support/send-image` |
| Send voice | `POST .../lighting-support/send-voice` |
| History | `GET .../lighting-support/history` |
| Clear | `DELETE .../lighting-support/clear` |

---

### 🔹 GuestLightingSupportChatScreen

**File:** `lib/screens/chat/guest_lighting_support_chat_screen.dart`

**Purpose:** Guest version of lighting support.

#### 🎯 Features
- ✅ **Governorate picker**
- ✅ **Guest session** (`saveGuestLightingSupportSessionId`)

---

## 3️⃣ Diagnosis Screens

### 🔹 DiagnosisEntryScreen

**File:** `lib/screens/diagnosis/diagnosis_entry_screen.dart`

**Purpose:** Simple entry point — choose between code path or symptom path.

#### 📋 Constructor
```dart
DiagnosisEntryScreen({required ApiService apiService})
```

#### 🎯 Features
- ✅ **Safety banner** (smoke/spark warning)
- ✅ **Two path cards:**
    - 🏷️ **عندي رمز على شاشة المحول** → `mode: 'code'`
    - 📝 **ما عندي رمز** → `mode: 'symptom'`
- ✅ **Info card** (safety notes)
- ✅ **Curved header** with diagnosis icon

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `amber` | `#F59E0B` |
| `green` | `#10B981` |

---

### 🔹 DiagnosisHomeScreen

**File:** `lib/screens/diagnosis/diagnosis_home_screen.dart`

**Purpose:** Main diagnosis home with category selection + search.

#### 📋 Constructor
```dart
DiagnosisHomeScreen({required ApiService apiService})
```

#### 🎯 Features
- ✅ **Search bar** → `DiagnosisSearchScreen`
- ✅ **3 categories:**
    - ☀️ **طاقة شمسية** (محول، بطارية، ألواح) — gradient amber
    - ⚡ **كهرباء منزلية** (قاطع، مقبس، تمديد) — gradient blue
    - 💡 **إنارة** (لمبة، ديمر، حساس) — gradient purple
- ✅ **Info card** with safety warning

#### 🎯 Categories

| ID | Label | Subtitle | Color |
|----|-------|----------|-------|
| `solar` | طاقة شمسية | محول، بطارية، ألواح | `#F59E0B` |
| `electricity` | كهرباء منزلية | قاطع، مقبس، تمديد | `#3B82F6` |
| `lighting` | إنارة | لمبة، ديمر، حساس | `#8B5CF6` |

---

### 🔹 DiagnosisDeviceScreen

**File:** `lib/screens/diagnosis/diagnosis_device_screen.dart`

**Purpose:** List of devices in a selected category.

#### 📋 Constructor
```dart
DiagnosisDeviceScreen({
  required ApiService apiService,
  required String category,
  required String categoryLabel,
  required Color categoryColor,
})
```

#### 🎯 Features
- ✅ **Device tree** from API (`deviceTree()`)
- ✅ **Device cards** with icon, name, faults count
- ✅ **Badges** for `رموز` (has codes) and `خطر` (has danger)
- ✅ **Icon mapping** for 20+ icon names

#### 📊 Device Card Fields

| Field | Description |
|-------|-------------|
| `deviceName` | Arabic device name |
| `icon` | Icon name (mapped to IconData) |
| `faultsCount` | Number of registered faults |
| `hasCodes` | Has error codes |
| `hasDanger` | Has dangerous faults |

#### 🔌 Endpoint
```
GET /v1/user/public/diagnosis/device-tree?category={category}
```

---

### 🔹 DiagnosisDeviceOptionsScreen

**File:** `lib/screens/diagnosis/diagnosis_device_options_screen.dart`

**Purpose:** Two options for a specific device — code path or symptom path.

#### 📋 Constructor
```dart
DiagnosisDeviceOptionsScreen({
  required ApiService apiService,
  required String category,
  required DeviceInfo device,
  required Color categoryColor,
})
```

#### 🎯 Options

| Option | Title | Hint | Action |
|--------|-------|------|--------|
| 1 | عندي رمز على الشاشة | الأسرع والأدق | `DiagnosisFlowScreen(mode: 'code')` |
| 2 | عندي مشكلة بدون رمز | 3 أسئلة قصيرة | `DiagnosisFaultsListScreen` |

#### 🔒 Conditional
Option 1 only shows if `device.hasCodes == true`.

---

### 🔹 DiagnosisFaultsListScreen

**File:** `lib/screens/diagnosis/diagnosis_faults_list_screen.dart`

**Purpose:** List of faults for a specific device with search.

#### 📋 Constructor
```dart
DiagnosisFaultsListScreen({
  required ApiService apiService,
  required String category,
  required String device,
  required Color categoryColor,
})
```

#### 🎯 Features
- ✅ **Faults list** from API with local search
- ✅ **Search bar** (filters locally)
- ✅ **Severity color coding:**
    - 🔴 `danger` = red
    - 🟠 `urgent` = amber
    - 🟢 `normal` = green
- ✅ **Fault cards** with title + severity badge + fault ID
- ✅ **Header counter** showing faults count

#### 🔌 Endpoint
```
GET /v1/user/public/diagnosis/faults?category={category}&device={device}
```

---

### 🔹 DiagnosisFlowScreen (⭐ Core Screen)

**File:** `lib/screens/diagnosis/diagnosis_flow_screen.dart`

**Purpose:** The **12-state diagnosis state machine** — handles manufacturer → family → code OR symptom → question → step → ask → result → safety/solved/no_match/handoff.

#### 📋 Constructor
```dart
DiagnosisFlowScreen({
  required ApiService apiService,
  required String mode,  // 'code' or 'symptom'
  String? prefilledFaultId,
  String? prefilledFaultTitle,
  String? prefilledCategory,
})
```

#### 🎯 States

| State | Description |
|-------|-------------|
| `manufacturer` | Choose inverter manufacturer |
| `family` | Choose exact inverter family |
| `codeEntry` | Enter error code |
| `symptomEntry` | Describe problem in Arabic |
| `question` | Answer diagnostic question (yes/no/unknown) |
| `step` | Complete safe step (work? / need technician) |
| `askResolved` | Ask if problem is solved |
| `result` | Show diagnosis result |
| `safety` | 🚨 Safety stop |
| `solved` | ✅ Solved by Nex |
| `noMatch` | ❌ Couldn't match |
| `handoff` | 📋 Handoff to workshop |

#### 🏭 Manufacturers

| ID | Label | Icon |
|----|-------|------|
| `deye` | Deye | D |
| `voltronic` | Voltronic Axpert | V |
| `felicity` | Felicity | F |
| `usfull` | USFULL | U |
| `invt` | INVT | I |

#### 🎯 Categories (for symptom mode)

| ID | Label | Icon |
|----|-------|------|
| `solar` | طاقة شمسية | ش |
| `electricity` | كهرباء منزلية | ك |
| `lighting` | إنارة | إ |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List families | `GET /v1/user/public/inverter-families?manufacturer=` |
| Start session | `POST /v1/user/public/diagnosis/sessions` |
| Answer | `POST /v1/user/public/diagnosis/sessions/{id}/answers` |
| Complete step | `POST /v1/user/public/diagnosis/sessions/{id}/steps/{stepIndex}/complete` |
| Record outcome | `POST /v1/user/public/diagnosis/sessions/{id}/outcome` |

#### 📊 Modes
- `code` — User provides error code (manufacturer → family → code → result)
- `symptom` — User describes symptom (description → questions → steps → result)
- `fault_id` — Direct navigation from fault list (via `prefilledFaultId`)

#### 🎯 Answer Options

| Value | Label | Color |
|-------|-------|-------|
| `yes` | نعم | green |
| `no` | لا | red |
| `unknown` | لا أعرف | amber |

#### 🎯 Step Outcomes

| Value | Label | Next |
|-------|-------|------|
| `completed` | عملت هالخطوة | Continue steps |
| `unable` | ما بقدر / بدي فني | Handoff |

#### 🎯 Final Outcomes

| Value | Label | Next |
|-------|-------|------|
| `resolved` | نعم، انحل | Solved screen |
| `unresolved` | لا، ما انحل | Workshop request |

#### 🎨 Safety Flow
When `safety == 'danger'`:
1. Jump to `safety` state
2. Show red warning icon (pulsing)
3. Display matched keywords as chips
4. Show safety actions list
5. CTA: **اطلب فني عاجل** → `WorkshopRequestMaintenanceScreen`

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `amber` | `#F59E0B` |
| `green` | `#10B981` |
| `red` | `#DC2626` |
| `purple` | `#8B5CF6` |

#### 🎬 Special Features
- ✅ **PopScope** — intercepts back button with confirmation dialog
- ✅ **AnimatedSwitcher** for state transitions
- ✅ **Progress bars** for questions/steps
- ✅ **Prefilled fault** auto-start
- ✅ **Handoff summary** passed to workshop request

---

### 🔹 DiagnosisSearchScreen

**File:** `lib/screens/diagnosis/diagnosis_search_screen.dart`

**Purpose:** Global search across all faults.

#### 📋 Constructor
```dart
DiagnosisSearchScreen({required ApiService apiService})
```

#### 🎯 Features
- ✅ **Debounced search** (400ms)
- ✅ **Quick suggestions chips:** بطارية، شرر، ماء، دخان، حرارة، قاطع، لمبة، محول
- ✅ **Result cards** with severity color bar
- ✅ **Minimum 2 chars** to trigger search
- ✅ **Empty state** with suggestions
- ✅ **No results state** with hint

#### 🔌 Endpoint
```
GET /v1/user/public/diagnosis/search?query={query}
```

#### 📊 Quick Suggestions
```dart
['بطارية', 'شرر', 'ماء', 'دخان', 'حرارة', 'قاطع', 'لمبة', 'محول']
```

---

## 4️⃣ Engineer Screens

### 🔹 EngineerConsultationScreen

**File:** `lib/screens/engineer/engineer_consultation_screen.dart`

**Purpose:** Choose consultation domain — electricity / solar / lighting.

#### 📋 Constructor
```dart
EngineerConsultationScreen({
  required ApiService apiService,
  AuthService? authService,
})
```

#### 🎯 Domains

| Key | Label | Subtitle | Color |
|-----|-------|----------|-------|
| `electricity` | كهرباء | تمديدات، قواطع، أحمال | `#3B82F6` |
| `solar` | طاقة شمسية | محولات، بطاريات، ألواح | `#F59E0B` |
| `lighting` | إنارة | سبوت، ديمر، حساسات | `#8B5CF6` |

#### 🎨 Features
- ✅ **Intro card** with engineer icon
- ✅ **3 domain cards** with gradient icons
- ✅ **Info box** about consultation being preliminary
- ✅ Gradient background (`#EFF6FF → #F5F7FA`)

---

### 🔹 EngineerConfirmationScreen

**File:** `lib/screens/engineer/engineer_confirmation_screen.dart`

**Purpose:** Confirmation screen before starting engineer chat.

#### 📋 Constructor
```dart
EngineerConfirmationScreen({
  required ApiService apiService,
  AuthService? authService,
  required String domainKey,
  required String domainLabel,
  required Color domainColor,
  required IconData domainIcon,
})
```

#### 🎯 Features
- ✅ **Domain circle** with gradient + shadow
- ✅ **Notice card** (consultation may convert to maintenance)
- ✅ **Capabilities card:**
    - إرسال رسالة نصية
    - إرسال صورة
    - إرسال رسالة صوتية
    - رد المهندس خلال ساعات العمل
- ✅ **Start chat** button → `EngineerChatScreen`
- ✅ **Change domain** button → pop

---

### 🔹 EngineerChatScreen

**File:** `lib/screens/engineer/engineer_chat_screen.dart`

**Purpose:** Unified engineer chat that switches endpoints based on domain.

#### 📋 Constructor
```dart
EngineerChatScreen({
  required ApiService apiService,
  AuthService? authService,
  required String domainKey,
  required String domainLabel,
  required Color domainColor,
})
```

#### 🎯 Domain Routing
The screen uses `domainKey` to route to the correct support endpoint:

| Domain | Text Endpoint | Image Endpoint | Voice Endpoint |
|--------|---------------|----------------|----------------|
| `solar` | `sendSupportMessage` | `sendSupportMessageWithImage` | `sendSupportVoiceMessage` |
| `lighting` | `sendLightingSupportMessage` | `sendLightingSupportImage` | `sendLightingSupportVoice` |
| `electricity` | `sendApplianceSupportMessage` | `sendApplianceSupportImage` | `sendApplianceSupportVoice` |

#### 🔐 Auth-Aware
Uses `widget.authService?.isAuthenticated` to decide between `requiresAuth: true/false`.

#### 🎯 Features
- ✅ **Domain-specific icon** in AppBar
- ✅ **Curved header** with gradient
- ✅ **Voice/image/text** support
- ✅ **Empty state** with greeting message
- ✅ **Auto-cleanup** on exit

#### 🎨 Icons

| Domain | Icon |
|--------|------|
| `solar` | `solar_power_rounded` |
| `lighting` | `lightbulb_rounded` |
| `electricity` | `electrical_services_rounded` |

---

## 5️⃣ Lighting Screens

### 🔹 LightingProjectsScreen

**File:** `lib/screens/lighting/lighting_projects_screen.dart`

**Purpose:** List of lighting projects with filters, sort, swipe-to-delete.

#### 📋 Constructor
```dart
LightingProjectsScreen({
  ApiService? apiService,
  StorageService? storageService,
})
```

#### 🎯 Features
- ✅ **Filters bar:** الكل / مسودة / مؤكد
- ✅ **Sort options:** الأحدث / الأقدم / السعر تنازلي / السعر تصاعدي
- ✅ **Stats bar:** المشاريع / الغرف / الواط / الإجمالي
- ✅ **Swipe-to-delete** with confirm dialog
- ✅ **Draft indicator** (yellow badge)
- ✅ **Currency badge** (SYP)
- ✅ **FAB** → `LightingRoomWizardScreen`
- ✅ **Shimmer loading**
- ✅ **Empty state**

#### 📊 Stats Bar

| Stat | Formula |
|------|---------|
| Projects count | `_projects.length` |
| Total rooms | Σ `roomCount` |
| Total power | Σ `totalPowerW` |
| Total cost | Σ `equipmentTotal.amount` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/user/lighting-design/projects` |
| Guest list | `GET /v1/user/public/lighting-design/projects?session_id=` |
| Delete | `DELETE /v1/user/lighting-design/projects/{id}` |

#### 🎨 Status Colors

| Status | Color | Label |
|--------|-------|-------|
| `draft` | `#F59E0B` | مسودة |
| `confirmed` | `#10B981` | مؤكد |
| `ordered` | `#3B82F6` | تم الطلب |
| `cancelled` | red | ملغى |

---

### 🔹 LightingProjectSummaryScreen

**File:** `lib/screens/lighting/lighting_project_summary_screen.dart`

**Purpose:** Project details with rooms, products, and cart integration.

#### 📋 Constructor
```dart
LightingProjectSummaryScreen({
  required ApiService apiService,
  required StorageService storageService,
  required int projectId,
  String? sessionId,
})
```

#### 🎯 Features
- ✅ **Header card** with gradient (project number + status + total)
- ✅ **Stats:** rooms count + total power
- ✅ **Rooms list** with confirmed attempts
- ✅ **Product cards** (tappable → product details)
- ✅ **CTA buttons:**
    - **تأكيد المشروع** (draft only)
    - **إضافة المشروع للسلة** (confirmed only)
    - **مشاركة المشروع** (copy to clipboard)
- ✅ **Shimmer loading**

#### 🎯 Cart Integration
Adds confirmed products to `CartService.instance` with dual currency support.

#### 🎯 Share Feature
Builds a formatted text summary with:
- Project number
- Stats (rooms, power, total)
- Per-room breakdown
- Product list with quantities

Then copies to clipboard.

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Show | `GET /v1/user/lighting-design/projects/{id}` |
| Confirm | `POST /v1/user/lighting-design/projects/{id}/confirm` |

---

### 🔹 LightingRoomWizardScreen (⭐ Core Screen)

**File:** `lib/screens/lighting/lighting_room_wizard_screen.dart`

**Purpose:** 5-step room lighting design wizard.

#### 📋 Constructor
```dart
LightingRoomWizardScreen({
  ApiService? apiService,
  StorageService? storageService,
  String? initialSessionId,
})
```

#### 📊 Wizard Steps

| Step | Title | Content |
|------|-------|---------|
| 0 | النوع | Room type selection |
| 1 | الأبعاد | Length, width, height |
| 2 | الجبس | Cove ceiling + photo upload |
| 3 | النتائج | AI design results (3 plans) |
| 4 | الاعتماد | Edit quantities + confirm |

#### 🎯 Room Type Categories
**Residential (purple):** صالون، غرفة نوم، غرفة أطفال
**Service (blue):** مطبخ، حمام، ممر
**Work (green):** مكتب، محل، معرض
**Industrial (amber):** مستودع، ورشة
**Hospitality (pink):** مطعم، مقهى
**Custom (amber):** غير ذلك → custom input with resolved classification

#### 🎯 Three Plans

| Key | Title | Icon | Description |
|-----|-------|------|-------------|
| `economic` | اقتصادي | 💰 | Budget-friendly |
| `balanced` | متوازن | ⚡ | Recommended |
| `premium` | ممتاز | ⭐ | High performance |

#### 🎯 Cove Ceiling Options

| Value | Label |
|-------|-------|
| `yes` | نعم، يوجد جبس |
| `no` | لا يوجد |
| `unknown` | لا أعرف |

#### 🎯 Editable Items
- Primary products (edit quantity ±)
- Decorative suggestions (add/remove)
- Re-check adequacy button
- Total cost display

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Config | `GET /v1/user/public/lighting-design/config` |
| Start | `POST .../lighting-design/start` |
| Upload photo | `POST .../lighting-design/upload-photo` |
| Design | `POST .../lighting-design/design` |
| Recheck | `POST .../lighting-design/recheck` |
| Confirm attempt | `POST .../lighting-design/confirm-attempt` |

#### 📤 Design Payload
```json
{
  "room": {
    "room_id": "room-xxx",
    "room_type_key": "living_room",
    "custom_room_type_ar": null,
    "resolved_room_type_key": null,
    "length_m": 6.0,
    "width_m": 4.0,
    "height_m": 3.0,
    "cove_ceiling": "unknown",
    "photo_ref": null,
    "attempt_no": 1,
    "preferred_light_color": "auto"
  },
  "session_id": "...",
  "project_id": null,
  "with_ai": true,
  "is_syp": false
}
```

#### 🎯 Post-Confirmation Dialog
After successful confirmation, shows dialog with 3 options:
1. **توليد صورة الغرفة** (if photo + plan + attempts available)
2. **عرض ملخص المشروع** → `LightingProjectSummaryScreen`
3. **إضافة غرفة أخرى** → returns data to parent

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| `amber` | `#F59E0B` |
| `purple` | `#8B5CF6` |

---

### 🔹 LightingVisualizationScreen

**File:** `lib/screens/lighting/lighting_visualization_screen.dart`

**Purpose:** AI image generation of the designed room (max 2 attempts).

#### 📋 Constructor
```dart
LightingVisualizationScreen({
  required ApiService apiService,
  required LightingRoomInput room,
  required List<LightingSelectedItem> confirmedItems,
  required LightingDistributionPlan distribution,
  String? localImagePath,
  String? sessionId,
  int? projectId,
  int? roomIdDb,
  int? attemptId,
  bool isLoggedIn,
})
```

#### 🎯 Features
- ✅ **Original photo display** (local + remote)
- ✅ **AI image generation** (2 attempts max)
- ✅ **Attempt counter** badge
- ✅ **Missing images warning** (products without images)
- ✅ **Product references list**
- ✅ **Fullscreen viewer** (`PhotoView` with zoom)
- ✅ **Save/Share** via `share_plus`
- ✅ **Remaining attempts** tracking

#### 🎯 Generation Rules
Image can be generated only if ALL conditions met:
1. `sessionId` is set
2. `roomIdDb` is set (not 0)
3. `attemptId` is set (not 0)
4. `projectId` is set (not 0)
5. `remainingAttempts > 0`
6. `localImagePath` is set

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Payload | `POST /v1/user/lighting-design/visualization-payload` |
| Generate | `POST /v1/user/lighting-design/generate-room-image` |

#### 📤 Generation Payload
```json
{
  "session_id": "...",
  "project_id": 5,
  "room_id_db": 12,
  "attempt_id": 34,
  "confirmed_items": [...],
  "distribution": {...},
  "aspect_ratio": "4:3"
}
```

#### 📥 Response
```json
{
  "success": true,
  "data": {
    "design_image_ref": "path/to/image.jpg",
    "design_image_url": "https://...",
    "remaining_attempts": 1,
    "gen_count": 1,
    "missing_images": ["product1", "product2"]
  }
}
```

#### 🎨 Features
- ✅ **PhotoView fullscreen** with zoom
- ✅ **Save image** (download + share sheet)
- ✅ **Missing images warning** (amber card)
- ✅ **Product references** (compact list)
- ✅ **Attempts remaining** counter
- ✅ **Gradient CTA button**

---

## 6️⃣ Widgets

### 🔹 MessageBubble

**File:** `lib/screens/chat/message_bubble.dart`

**Purpose:** Universal chat message bubble for all chat screens.

#### 📋 Constructor
```dart
MessageBubble({
  required bool isUser,
  required String content,
  required String timestamp,
  dynamic data,
  String type = 'text',
  List<String> images = const [],
  String? audioUrl,
  required ApiService apiService,
  AuthService? authService,
  Function(String slug)? onProductTap,
  Function(String slug)? onOfferTap,
  VoidCallback? onCopyTap,
  double fontScale = 1.0,
})
```

#### 🎯 Features
- ✅ **Markdown rendering** (`flutter_markdown`)
- ✅ **Mixed Arabic/Latin spacing** auto-formatting
- ✅ **Audio player** button
- ✅ **Image gallery** (network + local)
- ✅ **Requirements section** (engineering calc results)
- ✅ **System options section** (economic/standard/premium)
- ✅ **Products carousel** (horizontal list)
- ✅ **Comparisons section** (products comparison cards)
- ✅ **Copy button** below each message
- ✅ **Font scale** support

#### 📊 Data Sections

| Section | Data Path | Description |
|---------|-----------|-------------|
| Requirements | `data['requirements']` | Engineering calc results |
| System Options | `data['matches']['system_options']` | Economic/Standard/Premium |
| Products | `data['matches']['products']` | Panels/Batteries/Inverters |
| Comparisons | `data['matches']['comparisons']` | Product comparisons |

#### 🎯 Requirements Fields

| Field | Description |
|-------|-------------|
| `total_watts` | Total power |
| `daily_wh` | Daily energy |
| `required_panel_watt` | Panel watts |
| `required_battery_ah` | Battery Ah |
| `required_inverter_watt` | Inverter watts |
| `system_voltage` | System voltage |
| `warnings` | Warning list |
| `recommendations` | Smart recommendations |

---

### 🔹 MaintenanceMessageBubble

**File:** `lib/screens/appliances/maintenance_message_bubble.dart`

**Purpose:** Specialized bubble for appliance maintenance with AI diagnosis card.

#### 📋 Constructor
```dart
MaintenanceMessageBubble({
  required bool isUser,
  required String content,
  String type = 'text',
  dynamic data,
  List<String> images = const [],
  String? audioUrl,
})
```

#### 🎯 Features
- ✅ **Markdown rendering**
- ✅ **Audio player**
- ✅ **Image gallery**
- ✅ **AI Diagnosis Card:**
    - Diagnosis text
    - Severity badge (بسيط / متوسط / خطير)
    - Possible causes (with nested details)
    - Recommendations
    - Technician needed flag

#### 🎯 Severity Colors

| Severity | Color | Icon |
|----------|-------|------|
| بسيط | green | `check_circle_rounded` |
| متوسط | orange | `warning_rounded` |
| خطير | red | `error_rounded` |

---

### 🔹 GovernoratePicker

**File:** `lib/screens/chat/governorate_picker.dart`

**Purpose:** Bottom sheet for selecting Syrian governorate.

#### 📋 Constructor
```dart
GovernoratePicker({
  String? selectedGovernorate,
  required Function(String) onSelected,
})
```

#### 🎯 Features
- ✅ **14 Syrian governorates**
- ✅ **FilterChip** grid layout
- ✅ **Selected state** (green accent)
- ✅ **Curved bottom sheet**

#### 📊 Governorates List
```dart
[
  'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية',
  'طرطوس', 'إدلب', 'دير الزور', 'الحسكة', 'الرقة',
  'درعا', 'السويداء', 'القنيطرة'
]
```

---

## 🎨 Shared Design System

### 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Accent Cyan** | `#06B6D4` | Gradients |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success |
| **Danger** | `#EF4444` / `#DC2626` | Errors |
| **Warning** | `#F59E0B` | Warnings |
| **Purple** | `#8B5CF6` | AI / Lighting |
| **Day** | `#F59E0B` | Day hours |
| **Night** | `#6366F1` | Night hours |

### 🧊 Shared Patterns

| Pattern | Applied To |
|---------|-----------|
| **Curved Header** (`_BottomCurveClipper`) | All screens |
| **Glassmorphism** | Bottom sheets |
| **Gradient backgrounds** | Headers, CTAs |
| **Typing indicator** | All chat screens |
| **Shimmer loading** | List screens |
| **Swipe actions** | Projects, appliance lists |
| **Hero animations** | Product navigation |
| **AnimatedSwitcher** | Wizard steps |
| **WillPopScope** | Wizard back handling |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200ms | Press scale |
| 300ms | Wizard step transition |
| 400ms | Dialog scale |
| 600ms | Typing dots |
| 1200ms | Typing loop |
| 2000ms | Pulse loops |

---

## 🔄 Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       Appliance Services                         │
└─────────────────────────────────────────────────────────────────┘

HomeScreen
   ├─→ ApplianceCompatibilityScreen ──→ Result screen
   ├─→ ApplianceMaintenanceScreen ──→ ApplianceSupportChatScreen
   │                              └─→ WorkshopRequestScreen
   ├─→ ApplianceSavingsScreen ──→ _SavingsResultScreen
   └─→ ApplianceScheduleScreen ──→ Schedule result view

┌─────────────────────────────────────────────────────────────────┐
│                          Chat System                             │
└─────────────────────────────────────────────────────────────────┘

HomeScreen / ChatOverlay
   ├─→ ChatScreen (auth)              / GuestChatScreen
   ├─→ SolarChatScreen (auth)         / GuestSolarChatScreen
   ├─→ SupportSolarChatScreen (auth)  / GuestSupportSolarChatScreen
   ├─→ ApplianceSupportChatScreen     / GuestApplianceSupportChatScreen
   └─→ LightingSupportChatScreen      / GuestLightingSupportChatScreen

┌─────────────────────────────────────────────────────────────────┐
│                       Diagnosis System                           │
└─────────────────────────────────────────────────────────────────┘

DiagnosisEntryScreen
   ├─→ DiagnosisFlowScreen(mode: 'code')
   └─→ DiagnosisFlowScreen(mode: 'symptom')

DiagnosisHomeScreen
   ├─→ Search → DiagnosisSearchScreen
   └─→ Category → DiagnosisDeviceScreen → DiagnosisDeviceOptionsScreen
                                          ├─→ DiagnosisFlowScreen(mode: 'code')
                                          └─→ DiagnosisFaultsListScreen → DiagnosisFlowScreen

┌─────────────────────────────────────────────────────────────────┐
│                       Engineer Consultation                      │
└─────────────────────────────────────────────────────────────────┘

EngineerConsultationScreen
   └─→ EngineerConfirmationScreen
          └─→ EngineerChatScreen (with domain routing)

┌─────────────────────────────────────────────────────────────────┐
│                     Lighting Design                              │
└─────────────────────────────────────────────────────────────────┘

LightingProjectsScreen
   ├─→ LightingRoomWizardScreen
   │       ├─→ 5-step wizard
   │       └─→ Post-confirm dialog
   │              ├─→ LightingVisualizationScreen
   │              ├─→ LightingProjectSummaryScreen
   │              └─→ Add another room
   └─→ LightingProjectSummaryScreen
          ├─→ Confirm project
          ├─→ Add to cart
          └─→ Share project
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `google_fonts` | All screens (Cairo) |
| `shimmer` | Loading skeletons |
| `cached_network_image` | Product/photo images |
| `image_picker` | Register / Maintenance / Lighting |
| `flutter_sound` | Voice recording (all chats) |
| `audioplayers` | Voice playback |
| `flutter_markdown` | Message rendering |
| `intl` | Date formatting |
| `pusher_channels_flutter` | Real-time support chat |
| `photo_view` | Fullscreen images |
| `share_plus` | Save/share generated images |
| `http` | Image download (visualization) |
| `path_provider` | Temp file storage |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `ApplianceCompatibilityScreen` | `AuthService`, `ApiService` |
| `GuestApplianceCompatibilityScreen` | `ApiService`, `StorageService` |
| `ApplianceMaintenanceScreen` | `AuthService`, `ApiService`, `PermissionService` |
| `GuestApplianceMaintenanceScreen` | `ApiService`, `StorageService`, `PermissionService` |
| `ApplianceSavingsScreen` | `AuthService`, `ApiService` |
| `ApplianceScheduleScreen` | `AuthService`, `ApiService` |
| `ChatScreen` | `AuthService`, `ApiService`, `PermissionService` |
| `GuestChatScreen` | `ApiService`, `StorageService`, `PermissionService` |
| `SolarChatScreen` | `AuthService`, `ApiService` |
| `GuestSolarChatScreen` | `ApiService`, `StorageService` |
| `SupportSolarChatScreen` | `AuthService`, `ApiService`, `PusherService` |
| `ApplianceSupportChatScreen` | `AuthService`, `ApiService`, `PusherService` |
| `LightingSupportChatScreen` | `AuthService`, `ApiService`, `PusherService` |
| `DiagnosisEntryScreen` | `ApiService` |
| `DiagnosisHomeScreen` | `ApiService` |
| `DiagnosisDeviceScreen` | `ApiService`, `DiagnosisApiService` |
| `DiagnosisFlowScreen` | `ApiService`, `DiagnosisApiService` |
| `DiagnosisSearchScreen` | `ApiService`, `DiagnosisApiService` |
| `EngineerConsultationScreen` | `ApiService`, `AuthService` |
| `EngineerChatScreen` | `ApiService`, `AuthService`, `PusherService` |
| `LightingProjectsScreen` | `ApiService`, `StorageService` |
| `LightingProjectSummaryScreen` | `ApiService`, `StorageService`, `CartService` |
| `LightingRoomWizardScreen` | `ApiService`, `StorageService` |
| `LightingVisualizationScreen` | `ApiService` |

---

## 📊 Screens Summary

| # | Screen | Category | Auth | Guest |
|---|--------|----------|:----:|:-----:|
| 1 | `ApplianceCompatibilityScreen` | Appliance | ✅ | ❌ |
| 2 | `GuestApplianceCompatibilityScreen` | Appliance | ❌ | ✅ |
| 3 | `ApplianceMaintenanceScreen` | Appliance | ✅ | ❌ |
| 4 | `GuestApplianceMaintenanceScreen` | Appliance | ❌ | ✅ |
| 5 | `ApplianceSavingsScreen` | Appliance | ✅ | ❌ |
| 6 | `GuestApplianceSavingsScreen` | Appliance | ❌ | ✅ |
| 7 | `ApplianceScheduleScreen` | Appliance | ✅ | ❌ |
| 8 | `GuestApplianceScheduleScreen` | Appliance | ❌ | ✅ |
| 9 | `ChatScreen` | Chat | ✅ | ❌ |
| 10 | `GuestChatScreen` | Chat | ❌ | ✅ |
| 11 | `SolarChatScreen` | Chat | ✅ | ❌ |
| 12 | `GuestSolarChatScreen` | Chat | ❌ | ✅ |
| 13 | `SupportSolarChatScreen` | Chat | ✅ | ❌ |
| 14 | `GuestSupportSolarChatScreen` | Chat | ❌ | ✅ |
| 15 | `ApplianceSupportChatScreen` | Chat | ✅ | ❌ |
| 16 | `GuestApplianceSupportChatScreen` | Chat | ❌ | ✅ |
| 17 | `LightingSupportChatScreen` | Chat | ✅ | ❌ |
| 18 | `GuestLightingSupportChatScreen` | Chat | ❌ | ✅ |
| 19 | `DiagnosisEntryScreen` | Diagnosis | ❌ | ✅ |
| 20 | `DiagnosisHomeScreen` | Diagnosis | ❌ | ✅ |
| 21 | `DiagnosisDeviceScreen` | Diagnosis | ❌ | ✅ |
| 22 | `DiagnosisDeviceOptionsScreen` | Diagnosis | ❌ | ✅ |
| 23 | `DiagnosisFaultsListScreen` | Diagnosis | ❌ | ✅ |
| 24 | `DiagnosisFlowScreen` | Diagnosis | ❌ | ✅ |
| 25 | `DiagnosisSearchScreen` | Diagnosis | ❌ | ✅ |
| 26 | `EngineerConsultationScreen` | Engineer | Optional | ✅ |
| 27 | `EngineerConfirmationScreen` | Engineer | Optional | ✅ |
| 28 | `EngineerChatScreen` | Engineer | Optional | ✅ |
| 29 | `LightingProjectsScreen` | Lighting | Optional | ✅ |
| 30 | `LightingProjectSummaryScreen` | Lighting | Optional | ✅ |
| 31 | `LightingRoomWizardScreen` | Lighting | Optional | ✅ |
| 32 | `LightingVisualizationScreen` | Lighting | Optional | ✅ |

---

## 📝 Best Practices

### 🏠 Appliance Screens
1. **Always provide `authService`** for auth versions — required for workshop request.
2. **Provide `storageService`** for guest versions — required for session management.
3. **Guest session** is auto-created on first visit.
4. **Governorate** is auto-loaded from storage, defaulting to `'دمشق'`.
5. **Suggested devices** are loaded from public endpoint.
6. **Voice recording** requires `PermissionService.requestMicrophone()`.
7. **Voice files** are stored in temp directory with timestamp.

### 💬 Chat Screens
8. **Always use `MessageBubble`** for consistency.
9. **Pusher subscribes** only when conversation ID is available.
10. **Disconnect Pusher** on dispose.
11. **Handle `initialMessage`** after first frame + session init.
12. **Font scale** pinch-zoom is available in main + guest chat only.
13. **Clear on exit** is implemented for main + guest chat.
14. **Suggested questions** come from AI response.

### 🔍 Diagnosis Screens
15. **All diagnosis endpoints are public** (`requiresAuth: false`).
16. **`prefilledFaultId`** skips directly to diagnosis session start.
17. **Safety state** takes precedence over all other states.
18. **PopScope** intercepts back navigation in `DiagnosisFlowScreen`.
19. **`fault_id` mode** is converted to `symptom` mode internally.
20. **Handoff summary** is passed to `WorkshopRequestMaintenanceScreen` via `prefilledSummary`.

### 👨‍🔧 Engineer Screens
21. **Domain routing** happens in `EngineerChatScreen` based on `domainKey`.
22. **Auth-aware** — uses `requiresAuth: widget.authService?.isAuthenticated ?? false`.
23. **Domain color** should match the corresponding category color.

### 💡 Lighting Screens
24. **Always ensure session** before any API call (`_ensureSession()`).
25. **Photo upload** requires session ID first.
26. **Confirm attempt** before visualization — stores `attemptId`, `roomIdDb`.
27. **Max 2 image generations** per attempt — track `remainingAttempts`.
28. **Cart integration** requires confirmed attempt.
29. **Dual currency** (USD/SYP) — check `isSypPreferred()` before display.
30. **Shimmer loading** for all list screens.

### 🎨 General
31. **Always wrap in `Directionality`** with `TextDirection.rtl`.
32. **Use `_BottomCurveClipper`** for consistent header design.
33. **Use `HapticFeedback`** on interactions.
34. **SnackBars** should use `SnackBarBehavior.floating`.
35. **Curved headers** use `ClipPath` + `Container` + `SafeArea`.

---

<div align="center">

**🤖 End of Part 8 — Appliance, Chat, Diagnosis, Engineer & Lighting Screens**

</div>

---

# <a id="part-9"></a>🏢 PART 9 — Company Screens

**Location:** `lib/screens/company/`

**Purpose:** Company management, products, offers, categories, orders, and commission screens for the NEX Mobile Application.

---

## 📑 Screens Overview

| # | Category | Screens |
|---|----------|---------|
| 1 | Company Entry & Dashboard | `CompanyChoiceScreen`, `CompanyDashboardScreen` |
| 2 | Categories Management | Main Categories, Sub Categories, Add Main Category, Add Sub Category |
| 3 | Products Management | `ProductsListScreen`, `ProductDetailScreen`, `EditProductScreen` |
| 4 | Add Products (8 Types) | General, Battery, Inverter, Cable, Circuit Breaker, Solar Panel, Lighting Unit, Home Appliance |
| 5 | Offers Management | `OffersListScreen`, `OfferDetailScreen`, `AddOfferScreen`, `EditOfferScreen` |
| 6 | Supplier Orders | `SupplierOrdersListScreen`, `SupplierOrderDetailScreen` |
| 7 | Commission & Account | `CompanyCommissionScreen`, `RequestCompanyScreen` |

---

## 📁 File Structure

```
lib/screens/company/
├── company_choice_screen.dart                 # اختيار نوع الحساب
├── company_dashboard_screen.dart              # لوحة تحكم الشركة
├── request_company_screen.dart                # طلب فتح حساب شركة
│
├── categories/
│   ├── main_categories_screen.dart            # التصنيفات الرئيسية
│   ├── sub_categories_screen.dart             # التصنيفات الفرعية
│   ├── add_main_category_screen.dart          # إضافة تصنيف رئيسي
│   └── add_sub_category_screen.dart           # إضافة تصنيف فرعي
│
├── products/
│   ├── products_list_screen.dart              # قائمة المنتجات
│   ├── product_detail_screen.dart             # تفاصيل المنتج
│   ├── edit_product_screen.dart               # تعديل المنتج (ديناميكي)
│   ├── add_product_screen.dart                # إضافة منتج عادي
│   ├── add_battery_screen.dart                # إضافة بطارية
│   ├── add_inverter_screen.dart               # إضافة عاكس
│   ├── add_cable_screen.dart                  # إضافة كابل
│   ├── add_circuit_breaker_screen.dart        # إضافة قاطع
│   ├── add_solar_panel_screen.dart            # إضافة لوح شمسي
│   ├── add_lighting_unit_screen.dart          # إضافة وحدة إنارة
│   └── add_home_appliance_screen.dart         # إضافة أداة منزلية
│
├── offers/
│   ├── offers_list_screen.dart                # قائمة العروض
│   ├── offer_detail_screen.dart               # تفاصيل العرض
│   ├── add_offer_screen.dart                  # إضافة عرض
│   └── edit_offer_screen.dart                 # تعديل العرض
│
├── supplier_orders/
│   ├── supplier_orders_list_screen.dart       # طلبات التوريد
│   └── supplier_order_detail_screen.dart      # تفاصيل طلب التوريد
│
└── commissions/
    └── company_commission_screen.dart         # عمولة المنصة
```

---

## 1️⃣ Company Entry & Dashboard

### 🔹 CompanyChoiceScreen

**File:** `lib/screens/company/company_choice_screen.dart`

**Purpose:** Entry point after login — lets company owners choose between dashboard or browsing the app as a regular user.

#### 📋 Constructor
```dart
CompanyChoiceScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Radial gradient background** with animated circles
- ✅ **Two choice cards** with elastic scale animation
- ✅ **Staggered entrance** (fade + scale)
- ✅ **Haptic feedback** on heavy actions
- ✅ **Custom transitions** (fade + slide)

#### 🎯 Choice Cards

| # | Title | Subtitle | Gradient | Route |
|---|-------|----------|----------|-------|
| 1 | لوحة تحكم الشركة | إدارة المنتجات، الإحصائيات | `#1E3A8A → #3B82F6` | `CompanyDashboardScreen` |
| 2 | تصفح التطبيق | عرض المنتجات والتسوق | `grey[600] → grey[800]` | `HomeScreen` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |

---

### 🔹 CompanyDashboardScreen

**File:** `lib/screens/company/company_dashboard_screen.dart`

**Purpose:** The **main company hub** with drawer navigation, statistics, charts, and quick actions.

#### 📋 Constructor
```dart
CompanyDashboardScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Drawer navigation** with 8+ sections
- ✅ **Welcome card** with company name
- ✅ **Advanced stats grid** (5 cards)
- ✅ **Charts:** Bar chart + Pie chart (`fl_chart`)
- ✅ **Active statistics** from `/dashboard/stats`

#### 📊 Drawer Items

| # | Icon | Title | Screen |
|---|------|-------|--------|
| 1 | `dashboard_rounded` | الداشبورد | Dashboard |
| 2 | `inventory_2_rounded` | المنتجات | `ProductsListScreen` |
| 3 | `category_rounded` | التصنيفات | `MainCategoriesScreen` |
| 4 | `local_offer_rounded` | العروض | `OffersListScreen` |
| 5 | `local_shipping_rounded` | طلبات التوريد | `SupplierOrdersListScreen` |
| 6 | `percent_rounded` | عمولة المنصة | `CompanyCommissionScreen` |
| 7 | `shopping_bag_rounded` | تصفح التطبيق | `HomeScreen` |
| 8 | `logout_rounded` | تسجيل الخروج | Logout |

#### 📊 Stats Cards

| Icon | Label | Field |
|------|-------|-------|
| `category_rounded` | تصنيفات رئيسية | `main_categories_count` |
| `layers_rounded` | تصنيفات فرعية | `sub_categories_count` |
| `inventory_2_rounded` | منتجاتك | `total_products` / `active_products` |
| `local_offer_rounded` | العروض | `total_offers` / `active_offers` |
| `local_shipping_rounded` | طلبات التوريد | `total_supplier_orders` / `pending_supplier_orders` |

#### 📈 Charts

| Chart | Library | Data |
|-------|---------|------|
| **Bar chart** | Custom | منتجاتك حسب التصنيف الرئيسي |
| **Pie chart** | `fl_chart` | توزيع منتجاتك حسب التصنيف الفرعي |

#### 🔌 Endpoint
```
GET /v1/company/dashboard/stats
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |
| `warningOrange` | `#F59E0B` |
| `dangerRed` | `#EF4444` |

---

## 2️⃣ Categories Management

### 🔹 MainCategoriesScreen

**File:** `lib/screens/company/categories/main_categories_screen.dart`

**Purpose:** Grid list of company main categories with sub-categories and products counts.

#### 📋 Constructor
```dart
MainCategoriesScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **2-column grid** layout
- ✅ **Gradient circular icon** per category
- ✅ **Stats chips** (sub-categories count + products count)
- ✅ **FAB** → `AddMainCategoryScreen`
- ✅ **Auto-refresh** after addition
- ✅ **Empty state**

#### 🔌 Endpoint
```
GET /v1/company/categories/main
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |
| `successGreen` | `#10B981` |

---

### 🔹 SubCategoriesScreen

**File:** `lib/screens/company/categories/sub_categories_screen.dart`

**Purpose:** Grid list of sub-categories within a main category (green theme).

#### 📋 Constructor
```dart
SubCategoriesScreen({
  required AuthService authService,
  required StorageService storageService,
  required int mainCategoryId,
  required String mainCategoryName,
})
```

#### 🎯 Features
- ✅ **Curved AppBar** with main category name
- ✅ **Green gradient** theme (successGreen → emeraldGreen)
- ✅ **Products count chip** per sub-category
- ✅ **Description** (2 lines ellipsis)
- ✅ **FAB** → `AddSubCategoryScreen`
- ✅ **Refresh in AppBar**

#### 🔌 Endpoint
```
GET /v1/company/categories/sub/{mainCategoryId}
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `successGreen` | `#10B981` |
| `emeraldGreen` | `#34D399` |

---

### 🔹 AddMainCategoryScreen

**File:** `lib/screens/company/categories/add_main_category_screen.dart`

**Purpose:** Form to add a new main category with image upload.

#### 📋 Constructor
```dart
AddMainCategoryScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Info banner** (approval required)
- ✅ **Name field** with Arabic validation
- ✅ **Description field** (optional)
- ✅ **Image picker** with camera/gallery
- ✅ **Multipart upload** with token
- ✅ **Smart text direction** (Arabic/Latin)

#### 🔌 Endpoint
```
POST /v1/company/categories/main/store
```

#### 📤 Payload
```
name_ar, description (optional), image (file)
```

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `secondaryBlue` | `#3B82F6` |

---

### 🔹 AddSubCategoryScreen

**File:** `lib/screens/company/categories/add_sub_category_screen.dart`

**Purpose:** Form to add a new sub-category within a main category (green theme).

#### 📋 Constructor
```dart
AddSubCategoryScreen({
  required AuthService authService,
  required StorageService storageService,
  required int mainCategoryId,
  required String mainCategoryName,
})
```

#### 🎯 Features
- ✅ **Info banner** (green)
- ✅ **Main category display** (read-only)
- ✅ **Name field** with validation
- ✅ **Description field** (optional)
- ✅ **Image picker**
- ✅ **Multipart upload** with main_category_id

#### 🔌 Endpoint
```
POST /v1/company/categories/sub/store
```

#### 📤 Payload
```
main_category_id, name_ar, description, image (file)
```

---

## 3️⃣ Products Management

### 🔹 ProductsListScreen

**File:** `lib/screens/company/products/products_list_screen.dart`

**Purpose:** Comprehensive product list with filters, search, sorting, grid/list toggle, and 8 product types to add.

#### 📋 Constructor
```dart
ProductsListScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Search bar** (name/SKU/brand)
- ✅ **Advanced filters** (expandable):
    - Sub-category, Status, Approval, Stock status
    - Sort (latest, oldest, price, name, views)
    - Price range (min/max)
- ✅ **Grid / List toggle**
- ✅ **Infinite scroll**
- ✅ **Toggle active status** (with switch)
- ✅ **Delete product** with confirm
- ✅ **Edit product** navigation
- ✅ **Approval badge** (✓ موافق / ⏳ مراجعة)

#### 🎯 Add Product Types (Bottom Sheet)

| # | Icon | Type | Color |
|---|------|------|-------|
| 1 | `inventory_2_rounded` | منتج عادي | Blue |
| 2 | `home_repair_service_rounded` | أداة منزلية | Green |
| 3 | `solar_power_rounded` | لوح طاقة شمسية | Amber |
| 4 | `electric_bolt_rounded` | عاكس (انفرفر) | Purple |
| 5 | `battery_full_rounded` | بطارية | Green |
| 6 | `cable_rounded` | كابل | Brown |
| 7 | `toggle_off_rounded` | قاطع كهربائي | Red |
| 8 | `lightbulb_rounded` | وحدة إنارة | Amber |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/company/products?page=&per_page=&search=&sub_category_id=&status=&stock_status=&approval_status=&min_price=&max_price=&sort=` |
| Create data | `GET /v1/company/products/create-data` |
| Toggle | `POST /v1/company/products/{id}/toggle-status` |
| Delete | `DELETE /v1/company/products/{id}` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `primaryBlue` | `#1E3A8A` |
| `successGreen` | `#10B981` |
| `warningColor` | `#F59E0B` |
| `dangerRed` | `#EF4444` |

---

### 🔹 ProductDetailScreen

**File:** `lib/screens/company/products/product_detail_screen.dart`

**Purpose:** Full product details with AI analysis, organized specifications, dual currency, and parallel connection info.

#### 📋 Constructor
```dart
ProductDetailScreen({
  required AuthService authService,
  required StorageService storageService,
  required int productId,
})
```

#### 🎯 Features
- ✅ **Image gallery** (PhotoView with zoom)
- ✅ **Header badges** (status, approval, stock, rate, views, discount, parallel)
- ✅ **Price cards** (USD + SYP)
- ✅ **Wholesale cards** (USD + SYP)
- ✅ **Parallel connection card** (for batteries/inverters) 🆕
- ✅ **Shipping card** (cities + costs)
- ✅ **Organized specifications** (typed with icons)
- ✅ **AI analysis** for owner
- ✅ **Share product**

#### 🆕 Parallel Connection Card
Only shown for **battery** and **inverter** products. Displays:
- ✅ Supported / Not supported badge
- 🔗 Max count for parallel connection
- ℹ️ Safety note per product type

#### 🧠 AI Owner Analysis
Fetches from `/v1/company/analyzeProduct/{id}` and shows:
- Current score / 100
- Potential score / 100
- Missing specs (with point impact)
- Suggestions for improvement

#### 📊 Spec Icons Mapping
The screen shows 100+ icons based on field types (voltage, current, power, capacity, dimensions, etc.)

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Fetch | `GET /v1/company/products/{id}` |
| Analyze | `GET /v1/company/analyzeProduct/{id}` |

---

### 🔹 EditProductScreen

**File:** `lib/screens/company/products/edit_product_screen.dart`

**Purpose:** **Dynamic product editing** — auto-loads fields based on product type.

#### 📋 Constructor
```dart
EditProductScreen({
  required AuthService authService,
  required StorageService storageService,
  required int productId,
})
```

#### 🎯 Features
- ✅ **Dynamic fields** per product type (8 types)
- ✅ **Parallel connection fields** (batteries/inverters) 🆕
- ✅ **Top-level `supports_parallel` field** for backend
- ✅ **`max_parallel_count` field** conditionally sent
- ✅ **Specifications editing** (structured + additional)
- ✅ **Image management** (replace, remove, add)
- ✅ **Dual currency editing**
- ✅ **Shipping cities management**

#### 🧩 `ProductSpecsDefinitions`
A helper class that defines spec fields per product type:

| Type | Fields Count | Examples |
|------|:------------:|----------|
| `battery` | 12 | نوع، جهد، سعة، دورات، تيار، **الربط على التوازي** |
| `inverter` | 14 | استطاعة، نوع، جهد، مداخل، **الربط على التوازي** |
| `cable` | 5 | مساحة المقطع، نوع الموصل، النواقل، طول الرول |
| `circuit_breaker` | 5 | التيار، قدرة القطع، الأقطاب، نوع التيار |
| `solar_panel` | 8 | استطاعة، كفاءة، Voc، Vmp، نوع اللوح |
| `lighting_unit` | 10 | نوع الموديل، استطاعة، لومن، IP، لون |
| Home appliances | 14 common + special | حسب النوع |

#### 🔌 Endpoint
```
POST /v1/company/products/{id} (with _method=PUT)
```

#### 🆕 Parallel Fields Payload
```json
{
  "supports_parallel": "1",
  "max_parallel_count": "4"
}
```

---

## 4️⃣ Add Products (8 Types)

All "Add Product" screens share the same structure:
- ✅ **Curved gradient AppBar** with product-type-specific color
- ✅ **Product-type-specific fields** (brand, power, voltage, etc.)
- ✅ **Basic info** (name, SKU, description, category)
- ✅ **Price & stock** (with wholesale)
- ✅ **SYP prices** (auto-fill from USD rate)
- ✅ **Images** (main + additional)
- ✅ **Specifications** (structured + additional)
- ✅ **Shipping cities** (14 Syrian governorates)
- ✅ **Toggle active**
- ✅ **Save button** with type-specific color

### 📊 Products Comparison

| # | Screen | Product Type | Theme Color | Special Fields |
|---|--------|--------------|-------------|----------------|
| 1 | `AddProductScreen` | `general` | `primaryBlue` | Basic (specifications) |
| 2 | `AddBatteryScreen` | `battery` | `batteryGreen` | نوع، جهد، سعة، دورات، عمق تفريغ، تيار، **الربط على التوازي** |
| 3 | `AddInverterScreen` | `inverter` | `inverterPurple` | استطاعة، نوع، جهد، مداخل، **الربط على التوازي**، تصنيف الاستخدام |
| 4 | `AddCableScreen` | `cable` | `cableBrown` | مساحة المقطع، نوع الموصل، عدد النواقل، طول الرول |
| 5 | `AddCircuitBreakerScreen` | `circuit_breaker` | `breakerRed` | التيار، قدرة القطع، عدد الأقطاب، نوع التيار |
| 6 | `AddSolarPanelScreen` | `solar_panel` | `solarOrange` | استطاعة، كفاءة، Voc، Vmp، نوع اللوح، الأبعاد |
| 7 | `AddLightingUnitScreen` | `lighting_unit` | `lightingAmber` | Dynamic 10+ types + shared fields |
| 8 | `AddHomeApplianceScreen` | 24 types | `specialGreen` | Dynamic per appliance type |

---

### 🔹 AddProductScreen (General)

**File:** `lib/screens/company/products/add_product_screen.dart`

**Purpose:** General product with basic fields + custom specifications.

#### 🎯 Features
- ✅ **Smart sub-category selector** with search
- ✅ **Quick access** to add main/sub categories
- ✅ **Custom units** (add new unit with dialog)
- ✅ **Custom specifications** (key/value pairs)
- ✅ **Wholesale pricing**

#### 🔌 Endpoint
```
POST /v1/company/products
```

---

### 🔹 AddBatteryScreen

**File:** `lib/screens/company/products/add_battery_screen.dart`

**Purpose:** Battery-specific product with parallel connection support.

#### 🎯 Special Fields

| Field | Type | Required |
|-------|------|:--------:|
| الماركة | Text | ✅ |
| نوع البطارية | Dropdown (Lead Acid/Lithium/Gel) | ✅ |
| الجهد | Dropdown (12V/24V/48V) | ✅ |
| السعة (kWh) | Number | ✅ |
| السعة (Ah) | Number | ❌ |
| عمق التفريغ | Number (%) | ✅ |
| عدد دورات الشحن | Number | ✅ |
| أقصى تيار تفريغ | Number (A) | ❌ |
| أقصى تيار شحن | Number (A) | ❌ |
| **يدعم الربط على التوازي** | Toggle | 🆕 |
| **أقصى عدد بطاريات على التوازي** | Number | 🆕 |

#### 🆕 Parallel Support Section
When `_supportsParallel == true`:
- Shows a `max_parallel_count` input
- Displays safety note about parallel connection rules

---

### 🔹 AddInverterScreen

**File:** `lib/screens/company/products/add_inverter_screen.dart`

**Purpose:** Inverter-specific product with parallel + usage classification.

#### 🎯 Special Fields

| Field | Type | Required |
|-------|------|:--------:|
| الماركة | Text | ✅ |
| استطاعة العاكس (W) | Number | ✅ |
| قدرة الإقلاع (W) | Number | ❌ |
| نوع العاكس | Dropdown (Hybrid/Off-Grid/On-Grid) | ✅ |
| جهد البطارية | Dropdown (12V/24V/48V) | ✅ |
| أدنى/أقصى جهد للألواح | Numbers (V) | ✅ |
| يدعم بطارية ليثيوم | Dropdown (نعم/لا) | ✅ |
| الطور | Dropdown (أحادي/ثلاثي) | ✅ |
| **يدعم الربط على التوازي** | Toggle | 🆕 |
| **أقصى عدد عواكس على التوازي** | Number | 🆕 |

#### 🎯 Extra Section
- **عدد المداخل الشمسية:** مدخل واحد / مدخلان
- **تصنيف استخدام المحول (multi-select):** منزلي / صناعي / زراعي
- **Summary card** showing selected options

---

### 🔹 AddCableScreen

**File:** `lib/screens/company/products/add_cable_screen.dart`

**Purpose:** Cable product with cross-section and material.

#### 🎯 Special Fields

| Field | Type | Required |
|-------|------|:--------:|
| الماركة | Text | ✅ |
| مساحة المقطع | Dropdown (2/2.5/6 مم) + custom | ✅ |
| نوع الموصل | Dropdown (نحاس/ألمنيوم) | ✅ |
| عدد النواقل | Dropdown (1,2,3,4,5+) | ✅ |
| طول الرول | Number (م) | ❌ |

---

### 🔹 AddCircuitBreakerScreen

**File:** `lib/screens/company/products/add_circuit_breaker_screen.dart`

**Purpose:** Circuit breaker product with current and poles.

#### 🎯 Special Fields

| Field | Type | Required |
|-------|------|:--------:|
| الماركة | Text | ✅ |
| التيار (A) | Number | ✅ |
| قدرة القطع (kA) | Number | ❌ |
| عدد الأقطاب | Dropdown (1/2/3/6) | ✅ |
| نوع التيار | Dropdown (DC/AC) | ✅ |

---

### 🔹 AddSolarPanelScreen

**File:** `lib/screens/company/products/add_solar_panel_screen.dart`

**Purpose:** Solar panel with detailed electrical specs.

#### 🎯 Special Fields

| Field | Type | Required |
|-------|------|:--------:|
| الماركة | Text | ✅ |
| استطاعة اللوح (W) | Number | ✅ |
| الكفاءة (%) | Number | ❌ |
| جهد الدارة المفتوحة (Voc) | Number (V) | ✅ |
| جهد التشغيل (Vmp) | Number (V) | ✅ |
| نوع اللوح | Dropdown (10 types) | ✅ |
| الأبعاد (L×W×T) | 3 Numbers | ❌ |

#### 🎯 Solar Panel Types (10)
Mono, Poly, Thin Film, Bifacial, PERC, HJT, TOPCon, Half-Cut, Shingled, Flexible

---

### 🔹 AddLightingUnitScreen

**File:** `lib/screens/company/products/add_lighting_unit_screen.dart`

**Purpose:** **The most complex** add-product screen — 11 lighting types with dynamic fields.

#### 🎯 Lighting Types (11)

| # | ID | Label AR | Special Fields |
|---|-----|----------|----------------|
| 1 | `bulb` | لمبة | القاعدة، الشكل |
| 2 | `strip_rope` | شريط أو حبل | وحدة البيع، W/m، Lumen/m، طول اللفة، العرض |
| 3 | `decorative` | ضوء زخرفي | نوع الزخرفة |
| 4 | `wall` | إنارة جدارية | اتجاه الضوء، الحركة |
| 5 | `garden_floor` | حدائق وأرضية | نوع التركيب، الاتجاه، الحساس |
| 6 | `floodlight` | كشاف | مكان التثبيت، الحساس، زاوية الانتشار |
| 7 | `track` | إنارة مسار | نوع المسار، الحركة، زاوية الانتشار |
| 8 | `recessed_spot` | سبوت مخفي | الشكل، الفتحة، الحجم، الحركة، الزاوية |
| 9 | `surface_spot` | سبوت سطحي | الشكل، الحركة، الزاوية |
| 10 | `panel` | بانل سقفي | طريقة التركيب، الشكل، المقاس، الفتحة |
| 11 | `chandelier` | ثريا | عدد اللمبات، القاعدة، مرفقة، التعليق |
| 12 | `solar_street` | شمسي/شوارع | مصدر الطاقة، مدة البطارية، الحساس |
| 13 | `emergency` | طوارئ | مدة الاحتياطي، طريقة العمل |

#### 🎯 Shared Fields (14)
`source_type`, `power`, `lumen`, `voltage`, `color_temperature`, `control_method`, `transformer`, `usage`, `ip_rating`, `body_color`, `body_material`, `dim_length`, `dim_width`, `dim_height`

#### 🎯 Special Features
- ✅ **Conditional visibility** (fields depend on other fields)
- ✅ **IP rating** shown only if usage is outdoor/wet
- ✅ **Eligibility flags** (for calculation & image generation)
- ✅ **Design image** (for AI visualization)
- ✅ **Save as draft**

---

### 🔹 AddHomeApplianceScreen

**File:** `lib/screens/company/products/add_home_appliance_screen.dart`

**Purpose:** Dynamic home appliance form — 24 appliance categories with specific fields.

#### 📦 Data Structures
- **`HomeApplianceCategory`** — Icon + AR label
- **`HomeApplianceField`** — Field definition with type + visibility conditions
- **`HomeApplianceData`** — Static data container

#### 🎯 24 Appliance Categories

| ID | Label | Icon |
|----|-------|------|
| `air_conditioners` | المكيفات | `ac_unit` |
| `fans` | المراوح | `toys` |
| `air_coolers` | مبردات الهواء | `air` |
| `heaters` | المدافئ | `local_fire_department` |
| `air_treatment` | تنقية وترطيب | `filter_alt` |
| `refrigerators` | الثلاجات | `kitchen` |
| `freezers` | المجمدات | `ac_unit` |
| `water_dispensers` | برادات المياه | `water_drop` |
| `washing_machines` | الغسالات | `local_laundry_service` |
| `dryers` | نشافات | `dry` |
| `dishwashers` | جلايات | `countertops` |
| `ovens_cookers` | الأفران | `outdoor_grill` |
| `microwaves` | مايكروويف | `microwave` |
| `kitchen_hoods` | شفاطات | `wind_power` |
| `small_cooking` | طبخ صغير | `blender` |
| `food_preparation` | خلاطات | `blender` |
| `juicers` | عصارات | `local_drink` |
| `mixers_kneaders` | عجانات | `bakery_dining` |
| `kettles` | غلايات | `coffee_maker` |
| `coffee_machines` | آلات قهوة | `coffee` |
| `irons` | مكاوي | `iron` |
| `vacuum_cleaners` | مكانس | `cleaning_services` |
| `water_heaters` | سخانات | `water` |
| `televisions` | تلفزيونات | `tv` |

#### 🎯 Common Fields (6)
`energy_source`, `rated_voltage`, `frequency`, `rated_input_power_w`, `startup_power_w`, `spec_source`

#### 🎯 Field Input Types

| Type | Behavior |
|------|----------|
| `text` | Simple text field |
| `number` | Numeric input (LTR) |
| `number_with_unit` | Number + dropdown unit |
| `single_select` | Dropdown single option |
| `multi_select` | Chips multi-select |
| `boolean` | Switch |
| `dimensions` | 3 inputs (L×W×H) |

#### 🎯 Conditional Visibility
Fields can be visible only when:
- A parent **boolean** is `true` (`visibleWhenField: 'has_dryer'`)
- A parent **select** has a specific value (`visibleWhenField: 'product_type', visibleWhenValues: ['منقي هواء']`)
- A parent **multi-select** includes a value

---

### 🔹 HomeApplianceTypeSelectorScreen

**File:** Same file as `AddHomeApplianceScreen`

**Purpose:** Intermediate screen to pick a category before adding.

#### 🎯 Features
- ✅ **Search bar** for appliance types
- ✅ **2-column grid** with icons
- ✅ **Auto-navigation** to `AddHomeApplianceScreen` with `initialCategoryId`

---

## 5️⃣ Offers Management

### 🔹 OffersListScreen

**File:** `lib/screens/company/offers/offers_list_screen.dart`

**Purpose:** Offers list with filters, grid/list toggle, and status management.

#### 📋 Constructor
```dart
OffersListScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Search bar** (name)
- ✅ **Stats chips** (All, Active, Inactive, Featured, Approved)
- ✅ **Filters:**
    - Status (active/inactive)
    - Featured (yes/no)
    - Approval (approved/pending)
    - Sort (latest/oldest/name/price/views)
- ✅ **Grid / List toggle**
- ✅ **Toggle active** inline
- ✅ **Toggle featured** inline
- ✅ **Delete** with confirm
- ✅ **FAB** → `AddOfferScreen`

#### 📊 Status Badges

| Badge | Color |
|-------|-------|
| ✓ موافق | `successGreen` |
| ⏳ مراجعة | `warningOrange` |
| -X% discount | `dangerRed` |
| ⭐ featured | `warningOrange` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/company/offers` |
| Stats | `GET /v1/company/offers/statistics` |
| Toggle status | `POST /v1/company/offers/{id}/toggle-status` |
| Toggle featured | `POST /v1/company/offers/{id}/toggle-featured` |
| Delete | `DELETE /v1/company/offers/{id}` |

---

### 🔹 OfferDetailScreen

**File:** `lib/screens/company/offers/offer_detail_screen.dart`

**Purpose:** Full offer details with gallery, components, specs, and products.

#### 📋 Constructor
```dart
OfferDetailScreen({
  required AuthService authService,
  required StorageService storageService,
  required int offerId,
})
```

#### 🎯 Features
- ✅ **Image gallery** (PhotoView)
- ✅ **Header badges** (status, approval, featured, products count, views)
- ✅ **Price card** (USD + SYP)
- ✅ **Installation price**
- ✅ **Wattage / Capacity cards**
- ✅ **Shipping card** (cities + costs)
- ✅ **Description card**
- ✅ **Components list**
- ✅ **Specifications list**
- ✅ **Products list** (with SYP support)

#### 🔌 Endpoint
```
GET /v1/company/offers/{id}
```

---

### 🔹 AddOfferScreen

**File:** `lib/screens/company/offers/add_offer_screen.dart`

**Purpose:** Form to add a new offer with products, components, specifications, and shipping.

#### 📋 Constructor
```dart
AddOfferScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Basic info** (name, description)
- ✅ **Price** (USD/SYP with auto-fill)
- ✅ **Installation price**
- ✅ **Solar energy section** (wattage + capacity)
- ✅ **Cover image + additional images**
- ✅ **Products picker** (with search + quantity)
- ✅ **Components** (dynamic key/value)
- ✅ **Specifications** (dynamic key/value)
- ✅ **Shipping cities** (14 governorates)
- ✅ **Toggles** (active, featured)

#### 🎯 Product Picker
- Search by name/SKU
- Quantity input
- Show already-added products (disabled)

#### 🔌 Endpoint
```
POST /v1/company/offers
```

#### 📤 Payload
```
name_ar, price, discount_price, installation_price,
total_wattage, total_capacity, description_ar,
is_active, is_featured, has_shipping,
price_syp, discount_price_syp, installation_price_syp,
shipping_cities (JSON),
components (JSON),
specifications (JSON),
products[0][id], products[0][quantity], ...,
cover_image (file), images[] (files)
```

---

### 🔹 EditOfferScreen

**File:** `lib/screens/company/offers/edit_offer_screen.dart`

**Purpose:** Edit existing offer — same as Add but pre-fills data + image management.

#### 📋 Constructor
```dart
EditOfferScreen({
  required AuthService authService,
  required StorageService storageService,
  required int offerId,
})
```

#### 🎯 Image Management
- ✅ **Current cover** with replace/remove buttons
- ✅ **Current additional images** with delete tracking
- ✅ **New images** (badge "جديد")
- ✅ **Undo remove cover**

#### 🔌 Endpoint
```
POST /v1/company/offers/{id} (with _method=PUT)
```

#### 📤 Extra Fields
```
remove_cover_image=1 (if removed)
delete_images[]={id} (per deleted image)
```

---

## 6️⃣ Supplier Orders

### 🔹 SupplierOrdersListScreen

**File:** `lib/screens/company/supplier_orders/supplier_orders_list_screen.dart`

**Purpose:** List of supplier orders with filters and stats.

#### 📋 Constructor
```dart
SupplierOrdersListScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Search by order number**
- ✅ **Stats chips** (All, Pending, Confirmed, Shipped, Delivered)
- ✅ **Filters:** Status + Sort (latest, oldest, total value)
- ✅ **Pagination** with load more
- ✅ **Order cards** with:
    - Order number
    - Status badge
    - Items preview (2 items + "+N")
    - Total amount
    - Date

#### 📊 Status Mapping

| Status | Text | Color |
|--------|------|-------|
| `pending` | قيد الانتظار | `warningOrange` |
| `confirmed` | تم التأكيد | `infoBlue` |
| `shipped` | تم الشحن | `purpleColor` |
| `delivered` | تم التسليم | `successGreen` |
| `cancelled` | ملغي | `dangerRed` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| List | `GET /v1/company/supplier-orders` |
| Stats | `GET /v1/company/supplier-orders/statistics` |

---

### 🔹 SupplierOrderDetailScreen

**File:** `lib/screens/company/supplier_orders/supplier_order_detail_screen.dart`

**Purpose:** Order details with status update and commission breakdown.

#### 📋 Constructor
```dart
SupplierOrderDetailScreen({
  required AuthService authService,
  required StorageService storageService,
  required int orderId,
})
```

#### 🎯 Features
- ✅ **Status update card:**
    - Dropdown (confirmed / shipped / delivered)
    - Notes field
    - Update button
- ✅ **Info cards** (order number, status, total, date)
- ✅ **Commission card** (with calculation):
    - Commission % (`percentage_alaamol_mn_alshrkat`)
    - Commission amount (`alaamol_mn_alshrkat`)
    - Net amount = total - commission
- ✅ **Products list** (name, quantity, unit price, total)

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Show | `GET /v1/company/supplier-orders/{id}` |
| Update status | `POST /v1/company/supplier-orders/{id}/update-status` |

#### 🎨 Commission Card
Gold gradient with:
- نسبة العمولة (gold)
- قيمة العمولة (red)
- صافي المبلغ المستلم (green)

---

## 7️⃣ Commission & Account

### 🔹 CompanyCommissionScreen

**File:** `lib/screens/company/commissions/company_commission_screen.dart`

**Purpose:** Display platform commission percentage and history.

#### 📋 Constructor
```dart
CompanyCommissionScreen({
  required AuthService authService,
  required StorageService storageService,
})
```

#### 🎯 Features
- ✅ **Gold gradient percentage card** (24 radius)
- ✅ **Stats grid** (4 cards):
    - عدد الطلبيات
    - عمولات معلقة
    - عمولات مدفوعة
    - إجمالي العمولة
- ✅ **Info alert** (about commission)
- ✅ **Commission history list** with status badges

#### 📊 Commission Status

| Status | Text | Color |
|--------|------|-------|
| `pending` | معلق | `warningOrange` |
| `partially_paid` | مدفوع جزئياً | `primaryBlue` |
| `paid` | مدفوع بالكامل | `successGreen` |

#### 🔌 Endpoints

| Action | Endpoint |
|--------|----------|
| Data | `GET /v1/company/commissions` |
| List | `GET /v1/company/commissions/list` |

#### 🎨 Colors

| Token | Value |
|-------|-------|
| `goldColor` | `#B45309` |
| Gold gradient | `#FBBF24 → #F59E0B` |

---

### 🔹 RequestCompanyScreen

**File:** `lib/screens/company/request_company_screen.dart`

**Purpose:** Form to request opening a company account (for customers).

#### 📋 Constructor
```dart
RequestCompanyScreen({
  required AuthService authService,
  required ApiService apiService,
})
```

#### 🎯 Features
- ✅ **Company info section**
- ✅ **Fields:**
    - Company name AR (required)
    - Company description
    - Company phone
    - Company WhatsApp
    - Company address
    - Governorate (dropdown)
    - District
    - Commercial register
    - Map URL
- ✅ **Logo picker**
- ✅ **Success dialog** with confirmation

#### 🔌 Endpoint
```
POST /v1/user/company-request
```

#### 📤 Payload
```
company_name_ar, company_description_ar,
company_phone, company_whatsapp, company_address,
company_governorate, company_district,
company_commercial_register, company_map_url,
company_logo (file)
```

---

## 🎨 Shared Design System

### 🎨 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#1E3A8A` | Brand primary |
| **Secondary Blue** | `#3B82F6` | Accents |
| **Dark** | `#111827` | Text |
| **Medium Gray** | `#4B5563` | Secondary text |
| **Light Gray** | `#F3F4F6` | Backgrounds |
| **Success** | `#10B981` | Success / Home appliances |
| **Danger** | `#EF4444` | Errors |
| **Warning** | `#F59E0B` | Warnings / Solar |
| **Purple** | `#7C3AED` / `#8B5CF6` | Inverters / Parallel |
| **Brown** | `#8B4513` | Cables |
| **Battery Green** | `#059669` | Batteries |
| **Lighting Amber** | `#D97706` | Lighting |
| **SYP Amber** | `#D97706` | SYP prices |
| **Gold** | `#B45309` | Commission |

### 🧊 Shared Patterns

| Pattern | Applied To |
|---------|-----------|
| **Curved AppBar** (`_BottomCurveClipper`) | All screens |
| **Gradient headers** | All screens |
| **Smart text direction** | All text inputs |
| **Dual currency** (USD/SYP) | Products, Offers |
| **Auto-fill SYP** | Products, Offers |
| **Image upload** | Categories, Products, Offers |
| **Shipping cities** | Products, Offers |
| **Custom unit picker** | Products |
| **Wholesale pricing** | Products, Offers |
| **Empty / Shimmer states** | All list screens |

### 🎬 Animation Durations

| Duration | Usage |
|----------|-------|
| 200ms | Toggle / Switch |
| 300ms | Card entrance |
| 500ms | Page transition |
| 800ms | Fade-in |
| 1000ms | Choice card scale |

---

## 🔄 Navigation Flow

```
Login
  │
  ▼
CompanyChoiceScreen
  ├─→ CompanyDashboardScreen
  │       ├─→ ProductsListScreen
  │       │       ├─→ ProductDetailScreen → EditProductScreen
  │       │       └─→ Add Product (8 types)
  │       ├─→ MainCategoriesScreen
  │       │       ├─→ SubCategoriesScreen
  │       │       │       └─→ AddSubCategoryScreen
  │       │       └─→ AddMainCategoryScreen
  │       ├─→ OffersListScreen
  │       │       ├─→ OfferDetailScreen → EditOfferScreen
  │       │       └─→ AddOfferScreen
  │       ├─→ SupplierOrdersListScreen
  │       │       └─→ SupplierOrderDetailScreen
  │       └─→ CompanyCommissionScreen
  │
  └─→ HomeScreen (customer view)

ProfileScreen
  └─→ RequestCompanyScreen (for customers)
```

---

## 📦 Dependencies

| Package | Used By |
|---------|---------|
| `google_fonts` | All screens (Cairo) |
| `cached_network_image` | Product/Offer/Category images |
| `image_picker` | All add/edit screens |
| `http` | Multipart uploads |
| `photo_view` | Image galleries |
| `fl_chart` | Dashboard charts |
| `shimmer` | Loading skeletons |

---

## 🔗 Service Dependencies

| Screen | Depends On |
|--------|-----------|
| `CompanyChoiceScreen` | `AuthService`, `StorageService` |
| `CompanyDashboardScreen` | `AuthService`, `StorageService`, `ApiService` |
| `MainCategoriesScreen` | `AuthService`, `StorageService`, `ApiService` |
| `SubCategoriesScreen` | `AuthService`, `StorageService`, `ApiService` |
| `AddMainCategoryScreen` | `AuthService`, `StorageService` |
| `AddSubCategoryScreen` | `AuthService`, `StorageService` |
| `ProductsListScreen` | `AuthService`, `StorageService`, `ApiService` |
| `ProductDetailScreen` | `AuthService`, `StorageService`, `ApiService` |
| `EditProductScreen` | `AuthService`, `StorageService`, `ApiService` |
| All Add Product screens | `AuthService`, `StorageService` |
| `OffersListScreen` | `AuthService`, `StorageService`, `ApiService` |
| `OfferDetailScreen` | `AuthService`, `StorageService`, `ApiService` |
| `AddOfferScreen` | `AuthService`, `StorageService` |
| `EditOfferScreen` | `AuthService`, `StorageService` |
| `SupplierOrdersListScreen` | `AuthService`, `StorageService`, `ApiService` |
| `SupplierOrderDetailScreen` | `AuthService`, `StorageService`, `ApiService` |
| `CompanyCommissionScreen` | `AuthService`, `StorageService`, `ApiService` |
| `RequestCompanyScreen` | `AuthService`, `ApiService` |

---

## 📊 Screens Summary

| # | Screen | Type | Purpose |
|---|--------|------|---------|
| 1 | `CompanyChoiceScreen` | Entry | Choose dashboard vs app |
| 2 | `CompanyDashboardScreen` | Hub | Company stats + navigation |
| 3 | `MainCategoriesScreen` | List | Main categories |
| 4 | `SubCategoriesScreen` | List | Sub-categories |
| 5 | `AddMainCategoryScreen` | Form | Add main category |
| 6 | `AddSubCategoryScreen` | Form | Add sub-category |
| 7 | `ProductsListScreen` | List | All products + filters |
| 8 | `ProductDetailScreen` | Detail | Product details + AI |
| 9 | `EditProductScreen` | Form | Dynamic edit (8 types) |
| 10 | `AddProductScreen` | Form | General product |
| 11 | `AddBatteryScreen` | Form | Battery (parallel support) |
| 12 | `AddInverterScreen` | Form | Inverter (parallel support) |
| 13 | `AddCableScreen` | Form | Cable |
| 14 | `AddCircuitBreakerScreen` | Form | Circuit breaker |
| 15 | `AddSolarPanelScreen` | Form | Solar panel |
| 16 | `AddLightingUnitScreen` | Form | Lighting (13 types) |
| 17 | `AddHomeApplianceScreen` | Form | Home appliances (24 types) |
| 18 | `HomeApplianceTypeSelectorScreen` | Selector | Appliance picker |
| 19 | `OffersListScreen` | List | All offers |
| 20 | `OfferDetailScreen` | Detail | Offer details |
| 21 | `AddOfferScreen` | Form | Add offer |
| 22 | `EditOfferScreen` | Form | Edit offer |
| 23 | `SupplierOrdersListScreen` | List | Supplier orders |
| 24 | `SupplierOrderDetailScreen` | Detail | Order details + commission |
| 25 | `CompanyCommissionScreen` | Detail | Platform commission |
| 26 | `RequestCompanyScreen` | Form | Request company account |

---

## 📝 Best Practices

### 🏢 Company Screens
1. **Always pass `authService` + `storageService`** to every screen.
2. **Token is auto-set** in `ApiService` on construction.
3. **Handle `company_owner`** user type specifically.
4. **Drawer navigation** is state-based (`_currentIndex`).

### 🗂️ Categories
5. **Categories need approval** before showing to customers.
6. **Always refresh** after add (using `Navigator.pop(context, true)`).
7. **Image upload** uses multipart with `image` field name.

### 📦 Products
8. **8 product types** with distinct endpoints.
9. **Dynamic fields** loaded per type via `ProductSpecsDefinitions`.
10. **Parallel connection** fields sent top-level for batteries/inverters.
11. **SYP prices** auto-filled via exchange rate API.
12. **Wholesale pricing** activated at threshold quantity.
13. **Design image** for lighting units supports AI generation.

### 🎁 Offers
14. **Products must be selected** (at least 1).
15. **Cover image required**.
16. **SYP prices optional** — auto-fill available.

### 📊 Supplier Orders
17. **Commission is pre-calculated** by backend.
18. **Net amount** = total - commission.
19. **Status updates** limited to confirmed/shipped/delivered.

### 🎨 General
20. **Always wrap in `Directionality`** with `TextDirection.rtl`.
21. **Use `_BottomCurveClipper`** for consistent header design.
22. **Apply HapticFeedback** on heavy interactions.
23. **Use SnackBars** with floating behavior.
24. **Show confirm dialogs** for delete operations.
25. **Provide empty + shimmer states** for all lists.

---

<div align="center">

**🏢 End of Part 9 — Company Screens**

</div>

---
