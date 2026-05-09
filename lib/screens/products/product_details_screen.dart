import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:energy_store_app/utils/helpers.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/services/cart_service.dart';
import 'package:energy_store_app/services/favorites_service.dart';
import 'package:energy_store_app/models/cart_item_model.dart';
import 'package:energy_store_app/widgets/product_card.dart';
import 'package:energy_store_app/screens/auth/login_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productSlug;
  final ApiService apiService;
  final AuthService? authService;

  const ProductDetailsScreen({
    super.key,
    required this.productSlug,
    required this.apiService,
    this.authService,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FavoritesService _favoritesService = FavoritesService.instance;

  Map<String, dynamic>? _product;
  List<dynamic> _similarProducts = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  String? _errorMessage;

  // ✅ متغيرات الكمية
  int _quantity = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String endpoint;
      bool requiresAuth;

      if (widget.authService?.isAuthenticated == true) {
        endpoint = '/v1/user/products/${widget.productSlug}/show';
        requiresAuth = true;
      } else {
        final governorate = widget.authService?.storageService.getGovernorate() ?? 'دمشق';
        endpoint = '/v1/user/public/products/${widget.productSlug}/show/$governorate';
        requiresAuth = false;
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: requiresAuth,
      );

      if (response.containsKey('data') && mounted) {
        setState(() {
          _product = response['data']['product'];
          _similarProducts = response['data']['similar_products'] ?? [];
          // استخدام الخدمة المحلية للتحقق من حالة المفضلة
          _isFavorite = _favoritesService.isProductFavorite(_product?['id']);
          _isLoading = false;
          _quantity = 1;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل المنتج';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      final productId = _product!['id'];

      if (_isFavorite) {
        // إزالة من المفضلة المحلية
        await _favoritesService.removeProduct(productId);
        setState(() {
          _isFavorite = false;
        });
        _showSnackBar('تم إزالة المنتج من المفضلة', Colors.orange);
      } else {
        // إضافة إلى المفضلة المحلية
        final productData = {
          'id': _product!['id'],
          'name_ar': _product!['name_ar'],
          'slug': _product!['slug'],
          'price': _product!['price'],
          'final_price': _product!['final_price'],
          'main_image': _product!['main_image'],
          'discount_percentage': _product!['discount_percentage'],
          'brand': _product!['brand'],
          'rate': _product!['rate'],
        };
        await _favoritesService.addProduct(productData);
        setState(() {
          _isFavorite = true;
        });
        _showSnackBar('تم إضافة المنتج إلى المفضلة', Colors.green);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
      debugPrint('Error toggling favorite: $e');
    } finally {
      setState(() {
        _isUpdatingFavorite = false;
      });
    }
  }

  void _shareProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('مشاركة المنتج'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToCart() {
    final int stock = _product?['stock'] ?? 0;

    if (_quantity > stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    final cartService = CartService.instance;

    // ✅ التحقق إذا كان المنتج موجوداً مسبقاً في السلة
    final existingItem = cartService.items.firstWhere(
          (item) => item.id == _product!['id'],
      orElse: () => CartItemModel(
        id: 0,
        name: '',
        slug: '',
        price: 0,
        finalPrice: 0,
        stock: 0,
      ),
    );

    final bool isExisting = existingItem.id != 0;
    final int oldQuantity = isExisting ? existingItem.quantity : 0;

    final cartItem = CartItemModel(
      id: _product!['id'],
      name: _product!['name_ar'] ?? 'غير معروف',
      slug: _product!['slug'] ?? '',
      price: double.tryParse(_product!['price']?.toString() ?? '0') ?? 0,
      finalPrice: double.tryParse(_product!['final_price']?.toString() ?? '0') ?? 0,
      image: _product!['main_image']?.toString(),
      stock: stock,
      quantity: _quantity,
      discountPercentage: _product!['discount_percentage']?.toDouble(),
    );

    cartService.addItem(cartItem);

    setState(() {
      _isAddingToCart = false;
    });

    // ✅ رسالة مختلفة حسب الحالة
    if (isExisting) {
      _showSnackBar(
        '✅ تم تحديث الكمية: ${_product!['name_ar']}\nالكمية السابقة: $oldQuantity → الكمية الجديدة: ${oldQuantity + _quantity}',
        Colors.green,
      );
    } else {
      _showSnackBar(
        '✅ تم إضافة $_quantity × ${_product!['name_ar']} إلى السلة',
        Colors.green,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ دالة زيادة الكمية
  void _increaseQuantity() {
    final int stock = _product?['stock'] ?? 0;
    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
    } else {
      _showSnackBar('لا يمكن زيادة الكمية عن المتوفر ($stock)', Colors.orange);
    }
  }

  // ✅ دالة نقصان الكمية
  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildProductContent(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildProductContent() {
    final bool hasDiscount = (_product?['discount_percentage'] ?? 0) > 0;
    final double finalPrice = double.tryParse(_product?['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice = double.tryParse(_product?['price']?.toString() ?? '0') ?? 0;
    final int stock = _product?['stock'] ?? 0;
    final bool inStock = stock > 0;
    final double rate = double.tryParse(_product?['rate']?.toString() ?? '0') ?? 0;
    final int views = _product?['views'] ?? 0;
    final double totalPrice = finalPrice * _quantity;

    return CustomScrollView(
      slivers: [
        // App Bar with image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _shareProduct,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.share, color: Colors.black87),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(),
          ),
        ),

        // Product Details
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating & Views Row
                Row(
                  children: [
                    if (rate > 0) ...[
                      RatingBar.builder(
                        initialRating: rate,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 16,
                        ignoreGestures: true,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {},
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($rate)',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.formatNumber(views),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Name
                Text(
                  _product?['name_ar'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Brand & Model
                if (_product?['brand'] != null || _product?['model'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_product?['brand'] != null) ...[
                          Text(
                            _product!['brand'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_product?['model'] != null)
                            Text(
                              ' - ',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                        if (_product?['model'] != null)
                          Text(
                            _product!['model'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Warranty & Unit
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_product?['warranty'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.security, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'ضمان ${_product!['warranty']}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_product?['unit'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'الوحدة: ${_product!['unit']}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        inStock ? 'متوفر ($stock قطعة)' : 'غير متوفر',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: inStock ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.1),
                        const Color(0xFF4CAF50).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasDiscount) ...[
                        Text(
                          Helpers.formatPrice(originalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        Helpers.formatPrice(finalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Quantity Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الكمية:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _decreaseQuantity,
                              icon: const Icon(Icons.remove, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(
                              width: 50,
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _increaseQuantity,
                              icon: const Icon(Icons.add, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'الإجمالي',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            Helpers.formatPrice(totalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                if (_product?['description_ar'] != null &&
                    _product!['description_ar'].isNotEmpty) ...[
                  Text(
                    'الوصف',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _product!['description_ar'],
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Specifications
                if (_product?['specifications'] != null &&
                    (_product!['specifications'] as List).isNotEmpty) ...[
                  Text(
                    'المواصفات',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_product!['specifications'] as List).length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final spec = _product!['specifications'][index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  spec['key'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  spec['value'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Similar Products
                if (_similarProducts.isNotEmpty) ...[
                  Text(
                    'منتجات مشابهة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _similarProducts.length,
                      itemBuilder: (context, index) {
                        final product = _similarProducts[index];
                        return ProductCard(
                          product: product,
                          apiService: widget.apiService,
                          authService: widget.authService,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    List<String> images = [];

    if (_product?['main_image'] != null) {
      images.add(_product!['main_image']);
    }
    if (_product?['additional_images'] != null) {
      images.addAll(List<String>.from(_product!['additional_images']));
    }

    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, size: 80),
      );
    }

    return PhotoViewGallery.builder(
      itemCount: images.length,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(images[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
        );
      },
      scrollPhysics: const BouncingScrollPhysics(),
      backgroundDecoration: const BoxDecoration(color: Colors.white),
      pageController: PageController(),
    );
  }

  Widget _buildBottomBar() {
    final double finalPrice = double.tryParse(_product?['final_price']?.toString() ?? '0') ?? 0;
    final int stock = _product?['stock'] ?? 0;
    final bool inStock = stock > 0;
    final double totalPrice = finalPrice * _quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Favorite Button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
                icon: _isUpdatingFavorite
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey[700],
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ✅ Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: (inStock && !_isAddingToCart)
                    ? _addToCart
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'أضف إلى السلة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        Helpers.formatPrice(totalPrice),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 300,
            color: Colors.grey.shade300,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 20,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchProductDetails,
            icon: const Icon(Icons.refresh),
            label: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}