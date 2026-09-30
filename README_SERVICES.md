# 🔧 Services - Flutter Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Service Layer for NEX Mobile Application**

</div>

---

## 📑 Table of Contents

| # | Category | Services |
|---|----------|----------|
| 1 | [Core HTTP](#1-️-core-http) | ApiService |
| 2 | [Authentication](#2-️-authentication) | AuthService |
| 3 | [Storage](#3-️-storage) | StorageService, OfflineStorageService |
| 4 | [Shopping](#4-️-shopping) | CartService, FavoritesService, ComparisonService |
| 5 | [Orders & Ratings](#5-️-orders--ratings) | OrderApiService, RatingApiService |
| 6 | [System Builder](#6-️-system-builder) | SystemBuilderService, SystemBuilderDraftService |
| 7 | [Solar](#7-️-solar) | SolarApiService, SolarSystemService |
| 8 | [Lighting](#8-️-lighting) | LightingApiService |
| 9 | [Diagnosis](#9-️-diagnosis) | DiagnosisApiService |
| 10 | [Notifications](#10-️-notifications) | NotificationService, LocalNotificationService |
| 11 | [Real-time](#11-️-real-time) | PusherService |
| 12 | [Permissions & Voice](#12-️-permissions--voice) | PermissionService, VoiceService |
| 13 | [UI Utilities](#13-️-ui-utilities) | FontScaleManager, TextAdService |

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
| `sendVoiceMessage()` | `POST /v1/user/chat/send-voice` | Voice (authenticated / guest) |
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
- `isTokenExpiringSoon()` → expiring within 5 days of expiration.
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
| `getInstallationPrice({isSyp})` | Installation price setting | `GET /setting/installation_almnthom` |
| `getMountingBasePrice({isSyp})` | Mounting price per panel | `GET /setting/solar_mounting_base_price_per_panel` |

#### 📤 Response Format

```dart
// createOrder / updateOrder
{
  'success': bool,
  'message': String,
  'data': {...},
  'compatibility': {...} | null   // compatibility check results
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

## 📝 Best Practices

1. **Always initialize in order:** `StorageService.init()` → `OfflineStorageService.init()` → `AuthService` → others.
2. **Use `CartService.instance`** — never construct directly.
3. **Call `loadCart()`, `loadFavorites()`, `loadDraft()`** on app startup.
4. **Handle `session_expired: true`** in API responses by redirecting to login.
5. **Prefer `handleTokenExpiry()`** from `AuthService` before authenticated requests.
6. **Cache home data** via `OfflineStorageService.saveHomeData` and check `shouldRefresh()` before refetching.
7. **Call `OfflineStorageService.clearCache()`** on logout only if required.
8. **Always check permission** via `PermissionService.requestMicrophone()` before voice recording.
9. **Subscribe to Pusher** only when the chat screen is mounted, and `unsubscribe` on dispose.
10. **Push notifications** require `NotificationService.init()` and `AuthService.sendFcmTokenToServer()` after login.

---

## 📊 Services Summary Table

| # | Service | Type | Purpose |
|---|---------|------|---------|
| 1 | ApiService | Instance | HTTP + token refresh |
| 2 | AuthService | ChangeNotifier | Authentication |
| 3 | StorageService | Instance | SharedPrefs wrapper |
| 4 | OfflineStorageService | Static (Hive) | Offline cache |
| 5 | CartService | Singleton | Shopping cart |
| 6 | FavoritesService | Singleton | Favorites |
| 7 | ComparisonService | Singleton | Compare (max 4) |
| 8 | OrderApiService | Instance | Orders |
| 9 | RatingApiService | Instance | Ratings |
| 10 | SystemBuilderService | Instance | System builder API |
| 11 | SystemBuilderDraftService | Singleton | Draft persistence |
| 12 | SolarApiService | Extension | Solar projects |
| 13 | SolarSystemService | Instance | Solar systems |
| 14 | LightingApiService | Extension | Lighting design |
| 15 | DiagnosisApiService | Instance | Diagnosis |
| 16 | NotificationService | Singleton | FCM + local |
| 17 | LocalNotificationService | Singleton | Local notif |
| 18 | PusherService | Singleton | Real-time chat |
| 19 | PermissionService | Static | Runtime permissions |
| 20 | VoiceService | Static | Voice recording |
| 21 | FontScaleManager | Static + Notifier | Font scaling |
| 22 | TextAdService | Instance | Text ads |
| 23 | showUnifiedReminderDialog | Function | Reminder dialog |
| 24 | MaintenanceServicesScreen | Widget | Maintenance UI |

---

<div align="center">

**🔧 NEX Mobile — Services Layer**

</div>

---

## END Services - Flutter Mobile App