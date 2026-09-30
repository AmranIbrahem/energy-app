# 🏢 Company Screens - Flutter Mobile App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

**Company Management, Products, Offers, Categories & Orders Screens for NEX Mobile Application**

</div>

---

## 📑 Table of Contents

| # | Category | Screens |
|---|----------|---------|
| 1 | [Company Entry & Dashboard](#1-️-company-entry--dashboard) | CompanyChoiceScreen, CompanyDashboardScreen |
| 2 | [Categories Management](#2-️-categories-management) | MainCategoriesScreen, SubCategoriesScreen, AddMainCategoryScreen, AddSubCategoryScreen |
| 3 | [Products Management](#3-️-products-management) | ProductsListScreen, ProductDetailScreen, EditProductScreen |
| 4 | [Add Products (8 Types)](#4-️-add-products-8-types) | AddProductScreen, AddBatteryScreen, AddInverterScreen, AddCableScreen, AddCircuitBreakerScreen, AddSolarPanelScreen, AddLightingUnitScreen, AddHomeApplianceScreen |
| 5 | [Offers Management](#5-️-offers-management) | OffersListScreen, OfferDetailScreen, AddOfferScreen, EditOfferScreen |
| 6 | [Supplier Orders](#6-️-supplier-orders) | SupplierOrdersListScreen, SupplierOrderDetailScreen |
| 7 | [Commission & Account](#7-️-commission--account) | CompanyCommissionScreen, RequestCompanyScreen |

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

**`HomeApplianceCategory`** — Icon + AR label
**`HomeApplianceField`** — Field definition with type + visibility conditions
**`HomeApplianceData`** — Static data container

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

**🏢 NEX — Company Screens**

</div>

---

## END Company Screens - Flutter Mobile App