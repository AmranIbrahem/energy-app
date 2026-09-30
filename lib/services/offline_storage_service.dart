// lib/services/offline_storage_service.dart

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class OfflineStorageService {
  static late Box _homeDataBox;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _homeDataBox = await Hive.openBox('home_data_cache');
    _isInitialized = true;
  }

  static Future<void> saveHomeData({
    required List<dynamic> mainCategories,
    required List<dynamic> mostViewedProducts,
    required List<dynamic> topRatedProducts,
    required List<dynamic> latestProducts,
    required List<dynamic> randomProducts,
    required List<dynamic> featuredOffers,
    required List<dynamic> latestOffers,
    required List<dynamic> cheapestOffers,
    required List<dynamic> highestPowerOffers,
    required List<dynamic> electricalAppliances,
    required List<dynamic> electricalExtensions,
    required List<dynamic> homeLighting,
    List<dynamic> advertisements = const [],
    List<dynamic> textAds = const [],
  }) async {
    try {
      await _homeDataBox.put('main_categories', jsonEncode(mainCategories));
      await _homeDataBox.put(
          'most_viewed_products', jsonEncode(mostViewedProducts));
      await _homeDataBox.put(
          'top_rated_products', jsonEncode(topRatedProducts));
      await _homeDataBox.put('latest_products', jsonEncode(latestProducts));
      await _homeDataBox.put('random_products', jsonEncode(randomProducts));
      await _homeDataBox.put('featured_offers', jsonEncode(featuredOffers));
      await _homeDataBox.put('latest_offers', jsonEncode(latestOffers));
      await _homeDataBox.put('cheapest_offers', jsonEncode(cheapestOffers));
      await _homeDataBox.put(
          'highest_power_offers', jsonEncode(highestPowerOffers));
      await _homeDataBox.put(
          'electrical_appliances', jsonEncode(electricalAppliances));
      await _homeDataBox.put(
          'electrical_extensions', jsonEncode(electricalExtensions));
      await _homeDataBox.put('home_lighting', jsonEncode(homeLighting));

      await _homeDataBox.put('advertisements', jsonEncode(advertisements));
      await _homeDataBox.put('text_ads', jsonEncode(textAds));

      await _homeDataBox.put('last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      //
    }
  }

  static Map<String, dynamic> getHomeData() {
    try {
      return {
        'main_categories': _decodeList(_homeDataBox.get('main_categories')),
        'most_viewed_products':
            _decodeList(_homeDataBox.get('most_viewed_products')),
        'top_rated_products':
            _decodeList(_homeDataBox.get('top_rated_products')),
        'latest_products': _decodeList(_homeDataBox.get('latest_products')),
        'random_products': _decodeList(_homeDataBox.get('random_products')),
        'featured_offers': _decodeList(_homeDataBox.get('featured_offers')),
        'latest_offers': _decodeList(_homeDataBox.get('latest_offers')),
        'cheapest_offers': _decodeList(_homeDataBox.get('cheapest_offers')),
        'highest_power_offers':
            _decodeList(_homeDataBox.get('highest_power_offers')),
        'electrical_appliances':
            _decodeList(_homeDataBox.get('electrical_appliances')),
        'electrical_extensions':
            _decodeList(_homeDataBox.get('electrical_extensions')),
        'home_lighting': _decodeList(_homeDataBox.get('home_lighting')),
        'advertisements': _decodeList(_homeDataBox.get('advertisements')),
        'text_ads': _decodeList(_homeDataBox.get('text_ads')),
        'last_updated': _homeDataBox.get('last_updated'),
      };
    } catch (e) {
      return {};
    }
  }

  static bool hasCachedData() {
    try {
      final data = _homeDataBox.get('main_categories');
      return data != null && data.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static DateTime? getLastUpdated() {
    try {
      final data = _homeDataBox.get('last_updated');
      if (data != null) {
        return DateTime.tryParse(data.toString());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static bool shouldRefresh() {
    final lastUpdated = getLastUpdated();
    if (lastUpdated == null) return true;

    final difference = DateTime.now().difference(lastUpdated);
    return difference.inHours >= 24;
  }

  static Future<void> clearCache() async {
    try {
      await _homeDataBox.clear();
    } catch (e) {
      //
    }
  }

  static List<dynamic> _decodeList(dynamic data) {
    if (data == null || data.toString().isEmpty) return [];
    try {
      return jsonDecode(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMainCategories(List<dynamic> categories) async {
    try {
      await _homeDataBox.put('all_main_categories', jsonEncode(categories));
    } catch (e) {
      //
    }
  }

  static List<dynamic> getMainCategories() {
    try {
      final data = _homeDataBox.get('all_main_categories');
      if (data == null || data.toString().isEmpty) return [];
      return jsonDecode(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSubCategories({
    required String categoryKey,
    required List<dynamic> subCategories,
  }) async {
    try {
      await _homeDataBox.put(categoryKey, jsonEncode(subCategories));
      // print(
      //     '✅ Sub categories saved for $categoryKey (${subCategories.length})');
    } catch (e) {
      // print('❌ Error saving sub categories: $e');
    }
  }

  static List<dynamic> getSubCategories(String categoryKey) {
    try {
      final data = _homeDataBox.get(categoryKey);
      if (data == null || data.toString().isEmpty) return [];
      return jsonDecode(data);
    } catch (e) {
      // print('❌ Error reading sub categories: $e');
      return [];
    }
  }

  static Future<void> saveNotifications(
      List<Map<String, dynamic>> notifications) async {
    try {
      await _homeDataBox.put('notifications', jsonEncode(notifications));
      // print('✅ Notifications saved (${notifications.length})');
    } catch (e) {
      // print('❌ Error saving notifications: $e');
    }
  }

  static List<dynamic> getNotifications() {
    try {
      final data = _homeDataBox.get('notifications');
      if (data == null || data.toString().isEmpty) return [];
      return jsonDecode(data);
    } catch (e) {
      // print('❌ Error reading notifications: $e');
      return [];
    }
  }

  static Future<void> saveOffersList({
    required String filterKey,
    required List<dynamic> offers,
  }) async {
    try {
      await _homeDataBox.put('offers_$filterKey', jsonEncode(offers));
      // print('✅ Offers saved for $filterKey (${offers.length})');
    } catch (e) {
      // print('❌ Error saving offers: $e');
    }
  }

  static List<dynamic> getOffersList(String filterKey) {
    try {
      final data = _homeDataBox.get('offers_$filterKey');
      if (data == null || data.toString().isEmpty) return [];
      return jsonDecode(data);
    } catch (e) {
      // print('❌ Error reading offers: $e');
      return [];
    }
  }

  static Future<void> saveOfferDetails({
    required String offerSlug,
    required Map<String, dynamic> offer,
    required List<dynamic> similarOffers,
  }) async {
    try {
      final data = jsonEncode({
        'offer': offer,
        'similar_offers': similarOffers,
        'saved_at': DateTime.now().toIso8601String(),
      });
      await _homeDataBox.put('offer_details_$offerSlug', data);
      // print('✅ Offer details saved for $offerSlug');
    } catch (e) {
      // print('❌ Error saving offer details: $e');
    }
  }

  static Map<String, dynamic>? getOfferDetails(String offerSlug) {
    try {
      final data = _homeDataBox.get('offer_details_$offerSlug');
      if (data == null || data.toString().isEmpty) return null;
      final decoded = jsonDecode(data);
      return {
        'offer': decoded['offer'],
        'similar_offers': decoded['similar_offers'] ?? [],
      };
    } catch (e) {
      // print('❌ Error reading offer details: $e');
      return null;
    }
  }

  static Future<void> saveProductDetails({
    required String productSlug,
    required Map<String, dynamic> product,
    required List<dynamic> similarProducts,
  }) async {
    try {
      final data = jsonEncode({
        'product': product,
        'similar_products': similarProducts,
        'saved_at': DateTime.now().toIso8601String(),
      });
      await _homeDataBox.put('product_details_$productSlug', data);
      // print('✅ Product details saved for $productSlug');
    } catch (e) {
      // print('❌ Error saving product details: $e');
    }
  }

  static Map<String, dynamic>? getProductDetails(String productSlug) {
    try {
      final data = _homeDataBox.get('product_details_$productSlug');
      if (data == null || data.toString().isEmpty) return null;
      final decoded = jsonDecode(data);
      return {
        'product': decoded['product'],
        'similar_products': decoded['similar_products'] ?? [],
      };
    } catch (e) {
      // print('❌ Error reading product details: $e');
      return null;
    }
  }

  static Future<void> saveProductsList({
    required String key,
    required List<dynamic> products,
  }) async {
    try {
      await _homeDataBox.put('products_list_$key', jsonEncode(products));
      // print('✅ Products list saved for $key (${products.length})');
    } catch (e) {
      // print('❌ Error saving products list: $e');
    }
  }

  static List<dynamic> getProductsList(String key) {
    try {
      final data = _homeDataBox.get('products_list_$key');
      if (data == null || data.toString().isEmpty) return [];
      return jsonDecode(data);
    } catch (e) {
      // print('❌ Error reading products list: $e');
      return [];
    }
  }

  static Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    try {
      await _homeDataBox.put('user_profile', jsonEncode(userData));
      // print('✅ User profile saved');
    } catch (e) {
      // print('❌ Error saving user profile: $e');
    }
  }

  static Map<String, dynamic>? getUserProfile() {
    try {
      final data = _homeDataBox.get('user_profile');
      if (data == null || data.toString().isEmpty) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      // print('❌ Error reading user profile: $e');
      return null;
    }
  }

  static Future<void> saveOrders(List<dynamic> orders) async {
    try {
      await _homeDataBox.put('user_orders', jsonEncode(orders));
      // print('✅ Orders saved (${orders.length})');
    } catch (e) {
      // print('❌ Error saving orders: $e');
    }
  }

  static List<dynamic> getOrders() {
    try {
      final data = _homeDataBox.get('user_orders');
      if (data == null || data.toString().isEmpty) return [];
      final decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      // print('❌ Error reading orders: $e');
      return [];
    }
  }
}
