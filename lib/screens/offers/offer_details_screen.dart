// lib/screens/offers/offer_details_screen.dart
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
import 'package:energy_store_app/screens/products/product_details_screen.dart';
import 'package:energy_store_app/screens/cart/cart_screen.dart';
import 'package:energy_store_app/widgets/offer_card.dart';
import 'package:energy_store_app/widgets/product_card.dart';

class OfferDetailsScreen extends StatefulWidget {
  final String offerSlug;
  final ApiService apiService;
  final AuthService? authService;

  const OfferDetailsScreen({
    super.key,
    required this.offerSlug,
    required this.apiService,
    this.authService,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final FavoritesService _favoritesService = FavoritesService.instance;

  Map<String, dynamic>? _offer;
  List<dynamic> _similarOffers = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;
  bool _isAddingToCart = false;
  String? _errorMessage;
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchOfferDetails();
  }

  Future<void> _fetchOfferDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String endpoint;

      if (widget.authService?.isAuthenticated == true) {
        endpoint = '/v1/user/offers/${widget.offerSlug}/show';
      } else {
        final governorate = widget.authService != null
            ? await widget.authService!.storageService.getGovernorate()
            : 'دمشق';
        endpoint = '/v1/user/public/offers/${widget.offerSlug}/show/$governorate';
      }

      final response = await widget.apiService.get(
        endpoint,
        requiresAuth: widget.authService?.isAuthenticated ?? false,
      );

      if (response.containsKey('data') && mounted) {
        setState(() {
          _offer = response['data']['offer'];
          _similarOffers = response['data']['similar_offers'] ?? [];
          // استخدام الخدمة المحلية للتحقق من حالة المفضلة
          _isFavorite = _favoritesService.isOfferFavorite(_offer?['id']);
          _isLoading = false;
          _quantity = 1;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'حدث خطأ في تحميل العرض';
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
      final offerId = _offer!['id'];

      if (_isFavorite) {
        // إزالة من المفضلة المحلية
        await _favoritesService.removeOffer(offerId);
        setState(() {
          _isFavorite = false;
        });
        _showSnackBar('تم إزالة العرض من المفضلة', Colors.orange);
      } else {
        // إضافة إلى المفضلة المحلية
        final offerData = {
          'id': _offer!['id'],
          'name_ar': _offer!['name_ar'],
          'slug': _offer!['slug'],
          'price': _offer!['price'],
          'final_price': _offer!['final_price'],
          'cover_image': _offer!['cover_image'],
          'discount_percentage': _offer!['discount_percentage'],
          'total_wattage': _offer!['total_wattage'],
          'total_capacity': _offer!['total_capacity'],
          'rate': _offer!['rate'],
        };
        await _favoritesService.addOffer(offerData);
        setState(() {
          _isFavorite = true;
        });
        _showSnackBar('تم إضافة العرض إلى المفضلة', Colors.green);
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

  void _shareOffer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('مشاركة العرض'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم التواصل مع الدعم الفني'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addOfferToCart() {
    final int stock = _offer?['stock'] ?? -1;

    if (stock > 0 && _quantity > stock) {
      _showSnackBar('الكمية المتاحة: $stock فقط', Colors.orange);
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    final cartService = CartService.instance;

    final existingQuantity = cartService.getItemQuantity(
      _offer!['id'],
      itemType: 'offer',
    );

    final bool isExisting = existingQuantity > 0;

    final cartItem = CartItemModel.fromOffer(
      _offer!,
      quantity: _quantity,
    );

    cartService.addOffer(cartItem);

    setState(() {
      _isAddingToCart = false;
    });

    if (isExisting) {
      _showSnackBar(
        '✅ تم تحديث كمية العرض: ${_offer!['name_ar']}\nالكمية الجديدة: ${existingQuantity + _quantity}',
        Colors.green,
      );
    } else {
      _showSnackBar(
        '✅ تم إضافة $_quantity × ${_offer!['name_ar']} إلى السلة',
        Colors.green,
      );
    }

    _showGoToCartDialog();
  }

  void _showGoToCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              'تمت الإضافة بنجاح',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'تم إضافة العرض إلى سلة المشتريات. هل تريد الذهاب إلى السلة الآن؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'مواصلة التسوق',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ).then((_) {
                // تحديث حالة المفضلة عند العودة من السلة (إذا لزم الأمر)
                setState(() {
                  _isFavorite = _favoritesService.isOfferFavorite(_offer?['id']);
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'الذهاب إلى السلة',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildOfferContent(),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildOfferContent() {
    final bool hasDiscount = (_offer?['discount_percentage'] ?? 0) > 0;
    final double finalPrice = double.tryParse(_offer?['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice = double.tryParse(_offer?['price']?.toString() ?? '0') ?? 0;
    final int totalWattage = _offer?['total_wattage'] ?? 0;
    final int totalCapacity = _offer?['total_capacity'] ?? 0;
    final double installationPrice = double.tryParse(_offer?['installation_price']?.toString() ?? '0') ?? 0;
    final int views = _offer?['views'] ?? 0;
    final double rate = double.tryParse(_offer?['rate']?.toString() ?? '0') ?? 0;

    return CustomScrollView(
      slivers: [
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
              onPressed: _shareOffer,
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
                Text(
                  _offer?['name_ar'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (totalWattage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '$totalWattage واط',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (totalCapacity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.battery_std, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '$totalCapacity واط/ساعة',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (installationPrice > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.build, size: 16, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              'تركيب: ${Helpers.formatPrice(installationPrice)}',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
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
                      Row(
                        children: [
                          Text(
                            Helpers.formatPrice(finalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'خصم ${(_offer?['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            Helpers.formatPrice(finalPrice * _quantity),
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
                if (_offer?['description_ar'] != null &&
                    _offer!['description_ar'].isNotEmpty) ...[
                  Text(
                    'وصف العرض',
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
                      _offer!['description_ar'],
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_offer?['specifications'] != null &&
                    (_offer!['specifications'] as List).isNotEmpty) ...[
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
                      itemCount: (_offer!['specifications'] as List).length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final spec = _offer!['specifications'][index];
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
                if (_offer?['components'] != null &&
                    (_offer!['components'] as List).isNotEmpty) ...[
                  Text(
                    'المكونات',
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
                      itemCount: (_offer!['components'] as List).length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final component = _offer!['components'][index];
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
                                  component['key'] ?? '',
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
                                  component['value'] ?? '',
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
                if (_offer?['products_in_offer'] != null &&
                    (_offer!['products_in_offer'] as List).isNotEmpty) ...[
                  Text(
                    'المنتجات المشمولة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (_offer!['products_in_offer'] as List).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = _offer!['products_in_offer'][index];
                      return _buildProductInOfferCard(product);
                    },
                  ),
                ],
                const SizedBox(height: 20),
                if (_similarOffers.isNotEmpty) ...[
                  Text(
                    'عروض مشابهة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _similarOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _similarOffers[index];
                        return OfferCard(
                          offer: offer,
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

  Widget _buildProductInOfferCard(dynamic product) {
    final int quantity = product['quantity'] ?? 1;
    final String name = product['name_ar'] ?? '';
    final String imageUrl = product['main_image'] ?? '';
    final String unit = product['unit'] ?? 'piece';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productSlug: product['slug'],
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          // تحديث حالة المفضلة عند العودة (إذا لزم الأمر)
          setState(() {
            _isFavorite = _favoritesService.isOfferFavorite(_offer?['id']);
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'الكمية: $quantity $unit',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    List<String> images = [];

    if (_offer?['cover_image'] != null) {
      images.add(_offer!['cover_image']);
    }

    if (_offer?['additional_images'] != null) {
      images.addAll(List<String>.from(_offer!['additional_images']));
    }

    if (images.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, size: 80),
      );
    }

    return Stack(
      children: [
        PhotoViewGallery.builder(
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
          pageController: PageController(initialPage: _selectedImageIndex),
          onPageChanged: (index) {
            setState(() {
              _selectedImageIndex = index;
            });
          },
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedImageIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final double finalPrice = double.tryParse(_offer?['final_price']?.toString() ?? '0') ?? 0;

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
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent, size: 28, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isAddingToCart ? null : _addOfferToCart,
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
                        Helpers.formatPrice(finalPrice * _quantity),
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
            onPressed: _fetchOfferDetails,
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