import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static FavoritesService get instance => _instance;

  FavoritesService._internal();

  List<Map<String, dynamic>> _favoriteProducts = [];
  List<Map<String, dynamic>> _favoriteOffers = [];

  List<Map<String, dynamic>> get favoriteProducts => List.unmodifiable(_favoriteProducts);
  List<Map<String, dynamic>> get favoriteOffers => List.unmodifiable(_favoriteOffers);

  int get productsCount => _favoriteProducts.length;
  int get offersCount => _favoriteOffers.length;
  int get totalCount => _favoriteProducts.length + _favoriteOffers.length;

  // تحميل المفضلة من التخزين المحلي
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final productsJson = prefs.getString('favorite_products');
    if (productsJson != null && productsJson.isNotEmpty) {
      final List<dynamic> decoded = json.decode(productsJson);
      _favoriteProducts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _favoriteProducts = [];
    }

    final offersJson = prefs.getString('favorite_offers');
    if (offersJson != null && offersJson.isNotEmpty) {
      final List<dynamic> decoded = json.decode(offersJson);
      _favoriteOffers = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _favoriteOffers = [];
    }
  }

  // حفظ المفضلة إلى التخزين المحلي
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_products', json.encode(_favoriteProducts));
    await prefs.setString('favorite_offers', json.encode(_favoriteOffers));
  }

  // إضافة منتج إلى المفضلة
  Future<bool> addProduct(Map<String, dynamic> product) async {
    final productId = product['id'];
    if (productId == null) return false;

    final exists = _favoriteProducts.any((p) => p['id'] == productId);
    if (!exists) {
      final simplifiedProduct = {
        'id': productId,
        'name': product['name'] ?? product['name_ar'] ?? product['name_en'] ?? 'غير معروف',
        'name_ar': product['name_ar'] ?? product['name'] ?? 'غير معروف',
        'name_en': product['name_en'] ?? product['name'] ?? '',
        'slug': product['slug'] ?? '',
        'price': product['price'] ?? 0,
        // ✅ إصلاح: تخزين discount_price بشكل صحيح
        'discount_price': product['discount_price'] ?? product['final_price'] ?? 0,
        'final_price': product['final_price'] ?? product['discount_price'] ?? product['price'] ?? 0,
        'main_image': product['main_image'] ?? product['cover_image'] ?? product['image'] ?? '',
        'cover_image': product['cover_image'] ?? product['main_image'] ?? '',
        'discount_percentage': product['discount_percentage'] ?? 0,
        'rate': product['rate'] ?? 0,
        // ✅ إضافة حقل للتأكد من وجود خصم
        'has_discount': (product['discount_price'] != null && product['discount_price'] > 0) ||
            (product['discount_percentage'] != null && product['discount_percentage'] > 0),
      };
      _favoriteProducts.add(simplifiedProduct);
      await _saveFavorites();
      return true;
    }
    return false;
  }

  // إضافة عرض إلى المفضلة
  Future<bool> addOffer(Map<String, dynamic> offer) async {
    final offerId = offer['id'];
    if (offerId == null) return false;

    final exists = _favoriteOffers.any((o) => o['id'] == offerId);
    if (!exists) {
      final simplifiedOffer = {
        'id': offerId,
        'name': offer['name'] ?? offer['name_ar'] ?? offer['name_en'] ?? 'غير معروف',
        'name_ar': offer['name_ar'] ?? offer['name'] ?? 'غير معروف',
        'name_en': offer['name_en'] ?? offer['name'] ?? '',
        'slug': offer['slug'] ?? '',
        'price': offer['price'] ?? 0,
        // ✅ إصلاح: تخزين discount_price بشكل صحيح
        'discount_price': offer['discount_price'] ?? offer['final_price'] ?? 0,
        'final_price': offer['final_price'] ?? offer['discount_price'] ?? offer['price'] ?? 0,
        'cover_image': offer['cover_image'] ?? offer['main_image'] ?? offer['image'] ?? '',
        'main_image': offer['main_image'] ?? offer['cover_image'] ?? '',
        'discount_percentage': offer['discount_percentage'] ?? 0,
        'total_wattage': offer['total_wattage'] ?? 0,
        'total_capacity': offer['total_capacity'] ?? 0,
        'rate': offer['rate'] ?? 0,
        // ✅ إضافة حقل للتأكد من وجود خصم
        'has_discount': (offer['discount_price'] != null && offer['discount_price'] > 0) ||
            (offer['discount_percentage'] != null && offer['discount_percentage'] > 0),
      };
      _favoriteOffers.add(simplifiedOffer);
      await _saveFavorites();
      return true;
    }
    return false;
  }

  // حذف منتج من المفضلة
  Future<bool> removeProduct(int productId) async {
    final beforeCount = _favoriteProducts.length;
    _favoriteProducts.removeWhere((p) => p['id'] == productId);
    final afterCount = _favoriteProducts.length;

    if (beforeCount > afterCount) {
      await _saveFavorites();
      return true;
    }
    return false;
  }

  // حذف عرض من المفضلة
  Future<bool> removeOffer(int offerId) async {
    final beforeCount = _favoriteOffers.length;
    _favoriteOffers.removeWhere((o) => o['id'] == offerId);
    final afterCount = _favoriteOffers.length;

    if (beforeCount > afterCount) {
      await _saveFavorites();
      return true;
    }
    return false;
  }

  // التحقق إذا كان المنتج في المفضلة
  bool isProductFavorite(int productId) {
    return _favoriteProducts.any((p) => p['id'] == productId);
  }

  // التحقق إذا كان العرض في المفضلة
  bool isOfferFavorite(int offerId) {
    return _favoriteOffers.any((o) => o['id'] == offerId);
  }

  // مسح جميع المفضلة
  Future<void> clearAll() async {
    _favoriteProducts.clear();
    _favoriteOffers.clear();
    await _saveFavorites();
  }

  // دالة مؤقتة لمسح البيانات القديمة
  Future<void> clearOldData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorite_products');
    await prefs.remove('favorite_offers');
    _favoriteProducts = [];
    _favoriteOffers = [];
  }
}