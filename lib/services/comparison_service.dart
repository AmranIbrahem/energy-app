// lib/services/comparison_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';

class ComparisonService {
  static final ComparisonService _instance = ComparisonService._internal();
  static ComparisonService get instance => _instance;
  ComparisonService._internal();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _offers = [];

  List<Map<String, dynamic>> get products => List.unmodifiable(_products);
  List<Map<String, dynamic>> get offers => List.unmodifiable(_offers);

  int get productsCount => _products.length;
  int get offersCount => _offers.length;

  Future<void> loadComparisonData() async {
    final prefs = await SharedPreferences.getInstance();

    final productsJson = prefs.getString('comparison_products');
    if (productsJson != null && productsJson.isNotEmpty) {
      _products = List<Map<String, dynamic>>.from(jsonDecode(productsJson));
    }

    final offersJson = prefs.getString('comparison_offers');
    if (offersJson != null && offersJson.isNotEmpty) {
      _offers = List<Map<String, dynamic>>.from(jsonDecode(offersJson));
    }
  }

  Future<void> _saveComparisonData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comparison_products', jsonEncode(_products));
    await prefs.setString('comparison_offers', jsonEncode(_offers));
  }

  Future<bool> addProduct(Map<String, dynamic> product) async {
    if (_products.any((p) => p['id'] == product['id'])) {
      return false;
    }

    if (_products.length >= 4) {
      return false;
    }

    _products.add({
      'id': product['id'],
      'name': product['name_ar'],
      'slug': product['slug'],
      'price': product['price'],
      'final_price': product['final_price'],
      'image': product['main_image'],
      'brand': product['brand'],
      'model': product['model'],
      'warranty': product['warranty'],
      'rate': product['rate'],
      'specifications': product['specifications'],
    });

    await _saveComparisonData();
    return true;
  }

  Future<bool> addOffer(Map<String, dynamic> offer) async {
    if (_offers.any((o) => o['id'] == offer['id'])) {
      return false;
    }

    if (_offers.length >= 4) {
      return false;
    }

    _offers.add({
      'id': offer['id'],
      'name': offer['name_ar'],
      'slug': offer['slug'],
      'price': offer['price'],
      'final_price': offer['final_price'],
      'image': offer['cover_image'],
      'total_wattage': offer['total_wattage'],
      'total_capacity': offer['total_capacity'],
      'installation_price': offer['installation_price'],
      'rate': offer['rate'],
      'specifications': offer['specifications'],
      'components': offer['components'],
    });

    await _saveComparisonData();
    return true;
  }

  Future<void> removeProduct(int productId) async {
    _products.removeWhere((p) => p['id'] == productId);
    await _saveComparisonData();
  }

  Future<void> removeOffer(int offerId) async {
    _offers.removeWhere((o) => o['id'] == offerId);
    await _saveComparisonData();
  }

  Future<void> clearProducts() async {
    _products.clear();
    await _saveComparisonData();
  }

  Future<void> clearOffers() async {
    _offers.clear();
    await _saveComparisonData();
  }

  Future<void> clearAll() async {
    _products.clear();
    _offers.clear();
    await _saveComparisonData();
  }

  bool isProductInComparison(int productId) {
    return _products.any((p) => p['id'] == productId);
  }

  bool isOfferInComparison(int offerId) {
    return _offers.any((o) => o['id'] == offerId);
  }
}
