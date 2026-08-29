// lib/services/cart_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  static CartService get instance => _instance;

  CartService._internal();

  List<CartItemModel> _items = [];
  List<CartItemModel> get items => List.unmodifiable(_items);

  // ✅ محافظة المستخدم - يتم تعيينها من الخارج
  String? userGovernorate;

  int get itemCount => _items.length;

  int get totalQuantity {
    int total = 0;
    for (var item in _items) {
      total += item.quantity;
    }
    return total;
  }

  double get totalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  double get originalTotalPrice {
    double total = 0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get totalDiscount {
    return originalTotalPrice - totalPrice;
  }

  // ✅ إجمالي رسوم الشحن المحسوبة
  double get calculatedShippingCost {
    double total = 0;
    for (var item in _items) {
      final cost = item.getShippingCostForCity(userGovernorate);
      if (cost != null && cost > 0) {
        total += cost;
      }
    }
    return total;
  }

  // ✅ عدد العناصر التي رسوم شحنها غير محددة
  int get pendingShippingItemsCount {
    int count = 0;
    for (var item in _items) {
      if (item.isShippingPendingForCity(userGovernorate)) {
        count++;
      }
    }
    return count;
  }

  // ✅ عدد العناصر التي الشحن لها مجاني
  int get freeShippingItemsCount {
    int count = 0;
    for (var item in _items) {
      if (item.isFreeShippingForCity(userGovernorate)) {
        count++;
      }
    }
    return count;
  }

  // ✅ عدد العناصر التي الشحن لها محسوب
  int get calculatedShippingItemsCount {
    int count = 0;
    for (var item in _items) {
      if (item.isShippingCalculatedForCity(userGovernorate)) {
        count++;
      }
    }
    return count;
  }

  // ✅ الإجمالي النهائي مع الشحن
  double get totalPriceWithShipping {
    return totalPrice + calculatedShippingCost;
  }

  // ✅ هل يوجد أي عنصر بشحن غير محدد
  bool get hasPendingShipping {
    return pendingShippingItemsCount > 0;
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart_items');
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(cartJson);
        _items = decoded.map((item) => CartItemModel.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        print('Error loading cart: $e');
        _items = [];
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
    await prefs.setString('cart_items', cartJson);
    notifyListeners();
  }

  void addItem(CartItemModel item) {
    final existingIndex = _items.indexWhere(
          (i) => i.id == item.id && i.itemType == 'product',
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }

    _saveCart();
  }

  void addOffer(CartItemModel offer) {
    final existingIndex = _items.indexWhere(
          (i) => i.id == offer.id && i.itemType == 'offer',
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity += offer.quantity;
    } else {
      _items.add(offer);
    }

    _saveCart();
  }

  void updateQuantity(int id, int newQuantity, {String itemType = 'product'}) {
    final index = _items.indexWhere(
          (i) => i.id == id && i.itemType == itemType,
    );
    if (index != -1 && newQuantity > 0) {
      if (newQuantity <= _items[index].stock || _items[index].stock >= 999999) {
        _items[index].quantity = newQuantity;
        _saveCart();
      }
    } else if (newQuantity <= 0) {
      removeItem(id, itemType: itemType);
    }
  }

  void removeItem(int id, {String itemType = 'product'}) {
    _items.removeWhere((i) => i.id == id && i.itemType == itemType);
    _saveCart();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _saveCart();
  }

  bool isInCart(int id, {String itemType = 'product'}) {
    return _items.any((i) => i.id == id && i.itemType == itemType);
  }

  int getItemQuantity(int id, {String itemType = 'product'}) {
    final item = _items.firstWhere(
          (i) => i.id == id && i.itemType == itemType,
      orElse: () => CartItemModel(
        id: 0,
        name: '',
        slug: '',
        price: 0,
        finalPrice: 0,
        stock: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  Map<String, dynamic> getOrderData() {
    final List<Map<String, dynamic>> products = [];
    final List<Map<String, dynamic>> offers = [];

    for (var item in _items) {
      if (item.itemType == 'product') {
        products.add({
          'id': item.id,
          'quantity': item.quantity,
          'price': item.finalPrice,
        });
      } else if (item.itemType == 'offer') {
        offers.add({
          'id': item.id,
          'quantity': item.quantity,
          'price': item.finalPrice,
          'name': item.name,
          'products_in_offer': item.productsInOffer,
          'total_wattage': item.totalWattage,
          'total_capacity': item.totalCapacity,
        });
      }
    }

    return {
      'products': products,
      'offers': offers,
    };
  }

  int get productsCount {
    return _items.where((i) => i.itemType == 'product').length;
  }

  int get offersCount {
    return _items.where((i) => i.itemType == 'offer').length;
  }
}