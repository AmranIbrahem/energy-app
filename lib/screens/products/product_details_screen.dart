// lib/screens/products/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/services.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/cart_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/models/cart_item_model.dart';
import 'package:GeniusHouse/widgets/product_card.dart';
import 'package:GeniusHouse/screens/auth/login_screen.dart';
import '../../services/comparison_service.dart';

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

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService.instance;

  Map<String, dynamic>? _product;
  List<dynamic> _similarProducts = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  String? _errorMessage;
  bool _isAnalyzing = false;
  bool _isInComparison = false;

  
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _heartAnimationController;
  late AnimationController _cartAnimationController;

  int _quantity = 1;
  bool _isAddingToCart = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fetchProductDetails();
    _checkIfInComparison();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _heartAnimationController.dispose();
    _cartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _askAIAboutProduct() async {
    final productId = _product?['id'];
    if (productId == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final endpoint = '/v1/user/public/ai/products/$productId/analyze';
      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: false,
      );

      if (response['success'] == true && mounted) {
        final analysis = response['data']['analysis'];
        _showAIAnalysisDialog(analysis);
      } else {
        _showSnackBar(
          response['message'] ?? 'عذراً، لم نتمكن من تحليل المنتج حالياً',
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      _showSnackBar('حدث خطأ في الاتصال بخدمة التحليل', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _checkIfInComparison() {
    final productId = _product?['id'];
    if (productId != null) {
      setState(() {
        _isInComparison = ComparisonService.instance.isProductInComparison(productId);
      });
    }
  }

  void _addToComparison() async {
    if (_product == null) return;

    final added = await ComparisonService.instance.addProduct(_product!);
    if (added) {
      setState(() => _isInComparison = true);
      _showSnackBar('تم إضافة المنتج للمقارنة', primaryBlue);
    } else {
      _showSnackBar('لا يمكن إضافة أكثر من 4 منتجات للمقارنة', Colors.orange);
    }
  }

  void _removeFromComparison() async {
    await ComparisonService.instance.removeProduct(_product!['id']);
    setState(() => _isInComparison = false);
    _showSnackBar('تم إزالة المنتج من المقارنة', Colors.orange);
  }

  void _showAIAnalysisDialog(String analysis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseAnimationController.value * 0.1),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.15),
                              secondaryBlue.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: primaryBlue, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'تحليل الذكاء الاصطناعي',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, thickness: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      analysis,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        height: 1.7,
                        color: mediumGray,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
          _isFavorite = _favoritesService.isProductFavorite(_product?['id']);
          _isLoading = false;
          _quantity = 1;
        });
        _fadeAnimationController.forward(from: 0.0);
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
    setState(() => _isUpdatingFavorite = true);

    try {
      final productId = _product!['id'];

      if (_isFavorite) {
        await _favoritesService.removeProduct(productId);
        setState(() => _isFavorite = false);
        _heartAnimationController.reverse();
        _showSnackBar('تم إزالة المنتج من المفضلة', Colors.orange);
      } else {
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
        setState(() => _isFavorite = true);
        _heartAnimationController.forward();
        _showSnackBar('تم إضافة المنتج إلى المفضلة', primaryBlue);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ، حاول مرة أخرى', Colors.red);
    } finally {
      setState(() => _isUpdatingFavorite = false);
    }
  }

  void _addToCart() {
    final int stock = _product?['stock'] ?? 0;

    if (_quantity > stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }

    setState(() => _isAddingToCart = true);
    _cartAnimationController.forward();

    final cartService = CartService.instance;

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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        _cartAnimationController.reset();
        HapticFeedback.heavyImpact();
      }
    });

    if (isExisting) {
      _showSnackBar(
        'تم تحديث الكمية: ${_product!['name_ar']}\nالكمية: $oldQuantity → ${oldQuantity + _quantity}',
        primaryBlue,
      );
    } else {
      _showSnackBar(
        'تم إضافة $_quantity × ${_product!['name_ar']} إلى السلة',
        primaryBlue,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        elevation: 5,
      ));
  }

  void _increaseQuantity() {
    final int stock = _product?['stock'] ?? 0;
    if (_quantity < stock) {
      setState(() => _quantity++);
      HapticFeedback.lightImpact();
    } else {
      _showSnackBar('لا يمكن زيادة الكمية عن المتوفر ($stock)', Colors.orange);
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
      HapticFeedback.lightImpact();
    }
  }

  void _openImageGallery(int initialIndex) {
    List<String> images = [];
    if (_product?['main_image'] != null) {
      images.add(_product!['main_image']);
    }
    if (_product?['additional_images'] != null) {
      images.addAll(List<String>.from(_product!['additional_images']));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildProductContent(),
      bottomNavigationBar: _isLoading || _errorMessage != null ? null : _buildBottomBar(),
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

    List<String> images = [];
    if (_product?['main_image'] != null) {
      images.add(_product!['main_image']);
    }
    if (_product?['additional_images'] != null) {
      images.addAll(List<String>.from(_product!['additional_images']));
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350,
          pinned: true,
          backgroundColor: cardWhite,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: darkColor, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _openImageGallery(_currentImageIndex),
                  child: Hero(
                    tag: _product!['main_image'] ?? 'product_image',
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? primaryBlue
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _currentImageIndex == index
                                ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.5),
                                blurRadius: 5,
                              ),
                            ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimationController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _fadeAnimationController,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.06),
                      blurRadius: 25,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Row(
                      children: [
                        if (rate > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade100,
                                  Colors.amber.shade200,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  rate.toStringAsFixed(1),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                Helpers.formatNumber(views),
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.discount_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'خصم ${_product!['discount_percentage']}%',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _product?['name_ar'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_product?['brand'] != null || _product?['model'] != null)
                      Row(
                        children: [
                          if (_product?['brand'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryBlue.withOpacity(0.1),
                                    secondaryBlue.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: primaryBlue.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _product!['brand'],
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                          if (_product?['model'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                _product!['model'],
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_product?['warranty'] != null)
                          _buildInfoTag(
                            icon: Icons.security_rounded,
                            label: 'ضمان ${_product!['warranty']}',
                            color: Colors.blue,
                          ),
                        if (_product?['unit'] != null)
                          _buildInfoTag(
                            icon: Icons.straighten_rounded,
                            label: 'الوحدة: ${_product!['unit']}',
                            color: Colors.purple,
                          ),
                        _buildInfoTag(
                          icon: inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          label: inStock ? 'متوفر ($stock قطعة)' : 'غير متوفر',
                          color: inStock ? successGreen : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryBlue.withOpacity(0.08),
                            secondaryBlue.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: primaryBlue.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السعر',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: mediumGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (hasDiscount) ...[
                            Text(
                              Helpers.formatPrice(originalPrice),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            Helpers.formatPrice(finalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الكمية:',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryBlue.withOpacity(0.08),
                                  secondaryBlue.withOpacity(0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    onTap: _decreaseQuantity,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.remove_rounded,
                                        size: 22,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: Text(
                                      '$_quantity',
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    onTap: _increaseQuantity,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 22,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
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
                                  color: mediumGray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Helpers.formatPrice(totalPrice),
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_product?['description_ar'] != null && _product!['description_ar'].isNotEmpty) ...[
                      _buildSectionTitle('الوصف', Icons.description_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _product!['description_ar'],
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            height: 1.6,
                            color: mediumGray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_product?['specifications'] != null && (_product!['specifications'] as List).isNotEmpty) ...[
                      _buildSectionTitle('المواصفات', Icons.list_alt_rounded),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (_product!['specifications'] as List).length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                          ),
                          itemBuilder: (context, index) {
                            final spec = _product!['specifications'][index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      spec['key'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: mediumGray,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      spec['value'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: darkColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_similarProducts.isNotEmpty) ...[
                      _buildSectionTitle('منتجات مشابهة', Icons.recommend_rounded),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _similarProducts.length,
                          itemBuilder: (context, index) {
                            final product = _similarProducts[index];
                            return TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ProductCard(
                                  product: product,
                                  apiService: widget.apiService,
                                  authService: widget.authService,
                                ),
                              ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryBlue.withOpacity(0.12),
                secondaryBlue.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: primaryBlue),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'analyze') {
                  _askAIAboutProduct();
                } else if (value == 'compare') {
                  if (_isInComparison) {
                    _removeFromComparison();
                  } else {
                    _addToComparison();
                  }
                }
              },
              offset: const Offset(0, -120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardWhite,
              elevation: 10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.08),
                      secondaryBlue.withOpacity(0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 28,
                  color: primaryBlue,
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'analyze',
                  child: Row(
                    children: [
                      _isAnalyzing
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryBlue,
                        ),
                      )
                          : Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isAnalyzing ? 'جاري التحليل...' : 'تحليل بالذكاء الاصطناعي',
                        style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isInComparison
                              ? primaryBlue.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: _isInComparison ? primaryBlue : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isInComparison ? 'إزالة من المقارنة' : 'إضافة للمقارنة',
                        style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isFavorite
                      ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                      : [Colors.grey.shade100, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isFavorite ? Colors.red.withOpacity(0.3) : Colors.grey.shade300,
                ),
              ),
              child: IconButton(
                onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
                icon: _isUpdatingFavorite
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
                    : AnimatedBuilder(
                  animation: _heartAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_heartAnimationController.value * 0.3),
                      child: child,
                    );
                  },
                  child: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.red : Colors.grey,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: _cartAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 - (_cartAnimationController.value * 0.05),
                    child: child,
                  );
                },
                child: ElevatedButton(
                  onPressed: (inStock && !_isAddingToCart) ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inStock ? primaryBlue : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: inStock ? 5 : 0,
                    shadowColor: inStock ? primaryBlue.withOpacity(0.5) : Colors.transparent,
                  ),
                  child: _isAddingToCart
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'جاري الإضافة...',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        inStock ? 'أضف إلى السلة' : 'غير متوفر',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (inStock) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
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
                    ],
                  ),
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
            height: 350,
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
                  width: 120,
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
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
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
                    borderRadius: BorderRadius.circular(20),
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
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.error_outline_rounded, size: 50, color: Colors.red.shade300),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProductDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                shadowColor: primaryBlue.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}