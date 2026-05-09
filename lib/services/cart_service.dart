// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:energy_store_app/models/cart_item_model.dart';
//
// class CartService {
//   static const String _cartKey = 'cart_items';
//   static CartService? _instance;
//   static CartService get instance {
//     _instance ??= CartService._();
//     return _instance!;
//   }
//
//   CartService._();
//
//   List<CartItemModel> _items = [];
//
//   Future<void> loadCart() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? cartJson = prefs.getString(_cartKey);
//     if (cartJson != null) {
//       final List<dynamic> decoded = jsonDecode(cartJson);
//       _items = decoded.map((e) => CartItemModel.fromJson(e)).toList();
//     } else {
//       _items = [];
//     }
//   }
//
//   Future<void> _saveCart() async {
//     final prefs = await SharedPreferences.getInstance();
//     final List<Map<String, dynamic>> jsonItems = _items.map((e) => e.toJson()).toList();
//     await prefs.setString(_cartKey, jsonEncode(jsonItems));
//   }
//
//   List<CartItemModel> get items => _items;
//
//   int get itemCount => _items.length;
//
//   int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
//
//   double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
//
//   void addItem(CartItemModel item) {
//     final existingIndex = _items.indexWhere((i) => i.id == item.id);
//     if (existingIndex != -1) {
//       _items[existingIndex].quantity += item.quantity;
//     } else {
//       _items.add(item);
//     }
//     _saveCart();
//   }
//
//   void removeItem(int productId) {
//     _items.removeWhere((item) => item.id == productId);
//     _saveCart();
//   }
//
//   void updateQuantity(int productId, int quantity) {
//     final index = _items.indexWhere((item) => item.id == productId);
//     if (index != -1) {
//       if (quantity <= 0) {
//         _items.removeAt(index);
//       } else {
//         _items[index].quantity = quantity;
//       }
//       _saveCart();
//     }
//   }
//
//   void clearCart() {
//     _items.clear();
//     _saveCart();
//   }
//
//   bool isInCart(int productId) {
//     return _items.any((item) => item.id == productId);
//   }
//
//   int getQuantity(int productId) {
//     final item = _items.firstWhere((i) => i.id == productId, orElse: () => CartItemModel(
//       id: 0,
//       name: '',
//       slug: '',
//       price: 0,
//       finalPrice: 0,
//       stock: 0,
//     ));
//     return item.quantity;
//   }
// }


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

  // إضافة منتج عادي
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

  // إضافة عرض
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

  // تحديث الكمية
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

  // حذف عنصر
  void removeItem(int id, {String itemType = 'product'}) {
    _items.removeWhere((i) => i.id == id && i.itemType == itemType);
    _saveCart();
  }

  // تفريغ السلة بالكامل
  void clearCart() {
    _items.clear();
    _saveCart();
  }

  // التحقق من وجود عنصر في السلة
  bool isInCart(int id, {String itemType = 'product'}) {
    return _items.any((i) => i.id == id && i.itemType == itemType);
  }

  // الحصول على كمية عنصر
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

  // الحصول على بيانات الطلب لإرسالها للـ API
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

  // الحصول على عدد العناصر في السلة (للمنتجات فقط)
  int get productsCount {
    return _items.where((i) => i.itemType == 'product').length;
  }

  // الحصول على عدد العروض في السلة
  int get offersCount {
    return _items.where((i) => i.itemType == 'offer').length;
  }
}