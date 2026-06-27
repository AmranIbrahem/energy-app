// lib/models/cart_item_model.dart
class CartItemModel {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double finalPrice;
  final String? image;
  final int stock;
  int quantity;
  final double? discountPercentage;


  final String itemType;
  final List<Map<String, dynamic>>? productsInOffer;
  final int? totalWattage;
  final int? totalCapacity;

  CartItemModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.finalPrice,
    this.image,
    required this.stock,
    this.quantity = 1,
    this.discountPercentage,
    this.itemType = 'product',
    this.productsInOffer,
    this.totalWattage,
    this.totalCapacity,
  });

  double get totalPrice => finalPrice * quantity;


  bool get isOffer => itemType == 'offer';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      'final_price': finalPrice,
      'image': image,
      'stock': stock,
      'quantity': quantity,
      'discount_percentage': discountPercentage,
      'item_type': itemType,
      'products_in_offer': productsInOffer,
      'total_wattage': totalWattage,
      'total_capacity': totalCapacity,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      price: json['price'].toDouble(),
      finalPrice: json['final_price'].toDouble(),
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
    );
  }


  factory CartItemModel.fromOffer(Map<String, dynamic> offer, {int quantity = 1}) {
    final double price = double.tryParse(offer['price']?.toString() ?? '0') ?? 0;
    final double finalPrice = double.tryParse(offer['final_price']?.toString() ?? '0') ?? 0;
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
      image: offer['cover_image']?.toString(),
      stock: stock > 0 ? stock : 999999,
      quantity: quantity,
      discountPercentage: offer['discount_percentage']?.toDouble(),
      itemType: 'offer',
      productsInOffer: productsInOffer,
      totalWattage: offer['total_wattage'],
      totalCapacity: offer['total_capacity'],
    );
  }


  factory CartItemModel.fromProduct(Map<String, dynamic> product, {int quantity = 1}) {
    final double price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final double finalPrice = double.tryParse(product['final_price']?.toString() ?? '0') ?? 0;
    final int stock = product['stock'] ?? 0;

    return CartItemModel(
      id: product['id'],
      name: product['name_ar'] ?? 'غير معروف',
      slug: product['slug'] ?? '',
      price: price,
      finalPrice: finalPrice,
      image: product['main_image']?.toString(),
      stock: stock,
      quantity: quantity,
      discountPercentage: product['discount_percentage']?.toDouble(),
      itemType: 'product',
    );
  }
}