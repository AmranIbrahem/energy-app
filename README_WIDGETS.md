# 🧩 Widgets - Flutter Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Reusable UI Components for NEX Mobile Application**

</div>

---

## 📑 Table of Contents

| # | Category | Widgets |
|---|----------|---------|
| 1 | [Product & Offer Cards](#1-️-product--offer-cards) | HomeProductCard, HomeOfferCard, ProductCard, OfferCard |
| 2 | [Cart](#2-️-cart) | CartBadge |
| 3 | [Chat & Floating UI](#3-️-chat--floating-ui) | ChatOverlay, FloatingChatButton |
| 4 | [Bottom Sheets](#4-️-bottom-sheets) | CategorySelectionSheet, SolarOptionsSheet, LightingOptionsSheet, ApplianceOptionsSheet |
| 5 | [Home Sections](#5-️-home-sections) | GreetingBar, TextAdsCarousel |
| 6 | [Category](#6-️-category) | CategoryCard |
| 7 | [Decorations](#7-️-decorations) | AnimatedGradientBorder |
| 8 | [Dialogs](#8-️-dialogs) | showUnifiedReminderDialog |
| 9 | [Screens](#9-️-screens) | ApplianceCompatibilityScreen |

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

## 📝 Best Practices

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

**🧩 NEX Mobile — Widgets Library**

</div>

---

## END Widgets - Flutter Mobile App