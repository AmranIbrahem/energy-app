// lib/models/cart_item_model.dart

import 'dart:convert';

class CartItemModel {
  final int id;
  final String name;
  final String slug;

  final double price;
  final double finalPrice;

  final double? priceSyp;
  final double? finalPriceSyp;

  final String? image;
  final int stock;
  int quantity;
  final double? discountPercentage;

  final String itemType;
  final List<Map<String, dynamic>>? productsInOffer;
  final int? totalWattage;
  final int? totalCapacity;

  final List<Map<String, dynamic>>? shippingCities;

  CartItemModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.finalPrice,
    this.priceSyp,
    this.finalPriceSyp,
    this.image,
    required this.stock,
    this.quantity = 1,
    this.discountPercentage,
    this.itemType = 'product',
    this.productsInOffer,
    this.totalWattage,
    this.totalCapacity,
    this.shippingCities,
  });

  // ============================================================
  // ============================================================

  double displayPrice({required bool isSyp}) {
    if (isSyp && priceSyp != null && priceSyp! > 0) return priceSyp!;
    return price;
  }

  double displayFinalPrice({required bool isSyp}) {
    if (isSyp && finalPriceSyp != null && finalPriceSyp! > 0) {
      return finalPriceSyp!;
    }
    return finalPrice;
  }

  double displayTotalPrice({required bool isSyp}) =>
      displayFinalPrice(isSyp: isSyp) * quantity;

  double get totalPrice => finalPrice * quantity;

  bool get isOffer => itemType == 'offer';

  bool get hasSypPrices =>
      priceSyp != null &&
      priceSyp! > 0 &&
      finalPriceSyp != null &&
      finalPriceSyp! > 0;

  // ============================================================
  // ============================================================

  double? getShippingCostForCity(String? governorate) {
    if (governorate == null ||
        shippingCities == null ||
        shippingCities!.isEmpty) {
      return null;
    }

    for (var cityData in shippingCities!) {
      final city = cityData['city']?.toString() ?? '';
      if (city == governorate) {
        final cost = cityData['cost']?.toString();
        if (cost == null || cost.isEmpty) return null;
        return double.tryParse(cost);
      }
    }
    return null;
  }

  bool get hasShippingInfo =>
      shippingCities != null && shippingCities!.isNotEmpty;

  bool isFreeShippingForCity(String? governorate) {
    final cost = getShippingCostForCity(governorate);
    return cost != null && cost == 0;
  }

  bool isShippingPendingForCity(String? governorate) {
    if (governorate == null || !hasShippingInfo) return false;
    final cost = getShippingCostForCity(governorate);
    return cost == null;
  }

  bool isShippingCalculatedForCity(String? governorate) {
    final cost = getShippingCostForCity(governorate);
    return cost != null && cost > 0;
  }

  // ============================================================
  // ✅ Serialization
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      'final_price': finalPrice,
      'price_syp': priceSyp,
      'final_price_syp': finalPriceSyp,
      'image': image,
      'stock': stock,
      'quantity': quantity,
      'discount_percentage': discountPercentage,
      'item_type': itemType,
      'products_in_offer': productsInOffer,
      'total_wattage': totalWattage,
      'total_capacity': totalCapacity,
      'shipping_cities': shippingCities,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      price: (json['price'] as num).toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
      priceSyp: json['price_syp'] != null
          ? (json['price_syp'] as num).toDouble()
          : null,
      finalPriceSyp: json['final_price_syp'] != null
          ? (json['final_price_syp'] as num).toDouble()
          : null,
      image: json['image'],
      stock: json['stock'],
      quantity: json['quantity'] ?? 1,
      discountPercentage: json['discount_percentage']?.toDouble(),
      itemType: json['item_type'] ?? 'product',
      productsInOffer: json['products_in_offer'] != null
          ? List<Map<String, dynamic>>.from(json['products_in_offer'])
          : null,
      totalWattage: json['total_wattage'],
      totalCapacity: json['total_capacity'],
      shippingCities: json['shipping_cities'] != null
          ? List<Map<String, dynamic>>.from(json['shipping_cities'])
          : null,
    );
  }

  // ============================================================
  // ============================================================

  static List<Map<String, dynamic>>? _parseShippingCities(dynamic rawCities) {
    if (rawCities == null) return null;

    List<dynamic> citiesData = [];
    if (rawCities is List) {
      citiesData = rawCities;
    } else if (rawCities is String) {
      try {
        citiesData = jsonDecode(rawCities) as List;
      } catch (_) {
        return null;
      }
    }

    return citiesData.map((cityData) {
      if (cityData is String) {
        return {'city': cityData, 'cost': null};
      }
      if (cityData is Map) {
        return {
          'city': cityData['city']?.toString() ?? '',
          'cost': cityData['cost']?.toString(),
        };
      }
      return {'city': '', 'cost': null};
    }).toList();
  }

  // ============================================================
  // ============================================================

  factory CartItemModel.fromOffer(Map<String, dynamic> offer,
      {int quantity = 1}) {
    final double price =
        double.tryParse(offer['price']?.toString() ?? '0') ?? 0;
    final double finalPrice =
        double.tryParse(offer['final_price']?.toString() ?? '0') ?? 0;

    final double? priceSyp =
        double.tryParse(offer['price_syp']?.toString() ?? '0');
    final double? finalPriceSyp =
        double.tryParse(offer['final_price_syp']?.toString() ?? '0');

    final int stock = offer['stock'] ?? -1;

    List<Map<String, dynamic>> productsInOffer = [];
    if (offer['products_in_offer'] != null) {
      productsInOffer = List<Map<String, dynamic>>.from(
        (offer['products_in_offer'] as List).map((product) => {
              'id': product['id'],
              'name': product['name_ar'],
              'slug': product['slug'],
              'quantity': product['quantity'],
              'price': product['price'],
              'price_syp': product['price_syp'],
              'image': product['main_image'],
            }),
      );
    }

    return CartItemModel(
      id: offer['id'],
      name: offer['name_ar'] ?? 'غير معروف',
      slug: offer['slug'] ?? '',
      price: price,
      finalPrice: finalPrice,
      priceSyp: priceSyp,
      finalPriceSyp: finalPriceSyp,
      image: offer['cover_image']?.toString(),
      stock: stock > 0 ? stock : 999999,
      quantity: quantity,
      discountPercentage: offer['discount_percentage']?.toDouble(),
      itemType: 'offer',
      productsInOffer: productsInOffer,
      totalWattage: offer['total_wattage'],
      totalCapacity: offer['total_capacity'],
      shippingCities: _parseShippingCities(offer['shipping_cities']),
    );
  }

  // ============================================================
  // ============================================================

  factory CartItemModel.fromProduct(Map<String, dynamic> product,
      {int quantity = 1}) {
    final double price =
        double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final double finalPrice =
        double.tryParse(product['final_price']?.toString() ?? '0') ?? 0;

    final double? priceSyp =
        double.tryParse(product['price_syp']?.toString() ?? '0');
    final double? finalPriceSyp =
        double.tryParse(product['final_price_syp']?.toString() ?? '0');

    final int stock = product['stock'] ?? 0;

    return CartItemModel(
      id: product['id'],
      name: product['name_ar'] ?? 'غير معروف',
      slug: product['slug'] ?? '',
      price: price,
      finalPrice: finalPrice,
      priceSyp: priceSyp,
      finalPriceSyp: finalPriceSyp,
      image: product['main_image']?.toString(),
      stock: stock,
      quantity: quantity,
      discountPercentage: product['discount_percentage']?.toDouble(),
      itemType: 'product',
      shippingCities: _parseShippingCities(product['shipping_cities']),
    );
  }
}
