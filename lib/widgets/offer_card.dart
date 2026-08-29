import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:GeniusHouse/utils/helpers.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/favorites_service.dart';
import 'package:GeniusHouse/screens/offers/offer_details_screen.dart';

class OfferCard extends StatefulWidget {
  final dynamic offer;
  final ApiService apiService;
  final AuthService? authService;
  final bool isListView;

  const OfferCard({
    super.key,
    required this.offer,
    required this.apiService,
    this.authService,
    this.isListView = false,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  final FavoritesService _favoritesService = FavoritesService.instance;
  bool _isFavorite = false;
  bool _isUpdatingFavorite = false;

  @override
  void initState() {
    super.initState();

    _isFavorite = _favoritesService.isOfferFavorite(widget.offer['id']);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isUpdatingFavorite = true);

    try {
      if (_isFavorite) {
        await _favoritesService.removeOffer(widget.offer['id']);
        setState(() {
          _isFavorite = false;
        });
        _showSnackBar('تم إزالة العرض من المفضلة', Colors.orange);
      } else {
        final offerData = {
          'id': widget.offer['id'],
          'name_ar': widget.offer['name_ar'],
          'slug': widget.offer['slug'],
          'price': widget.offer['price'],
          'final_price': widget.offer['final_price'],
          'cover_image': widget.offer['cover_image'],
          'discount_percentage': widget.offer['discount_percentage'],
          'total_wattage': widget.offer['total_wattage'],
          'total_capacity': widget.offer['total_capacity'],
          'rate': widget.offer['rate'],
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
      if (mounted) setState(() => _isUpdatingFavorite = false);
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

  @override
  Widget build(BuildContext context) {
    return widget.isListView ? _buildListViewCard() : _buildGridViewCard();
  }

  Widget _buildGridViewCard() {
    final bool hasDiscount = (widget.offer['discount_percentage'] ?? 0) > 0;
    final double finalPrice =
        double.tryParse(widget.offer['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice =
        double.tryParse(widget.offer['price']?.toString() ?? '0') ?? 0;
    final int totalWattage = widget.offer['total_wattage'] ?? 0;
    final int totalCapacity = widget.offer['total_capacity'] ?? 0;
    final String name = widget.offer['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.offer['cover_image']?.toString() ?? '';
    final int views = widget.offer['views'] ?? 0;
    final double rate =
        double.tryParse(widget.offer['rate']?.toString() ?? '0') ?? 0;
    // ✅ استخراج اسم المحافظة للعرض
    final String governorate =
        widget.offer['governorate_offer']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferDetailsScreen(
              offerSlug: widget.offer['slug']?.toString() ?? '',
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          setState(() {
            _isFavorite = _favoritesService.isOfferFavorite(widget.offer['id']);
          });
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                          height: 130, color: Colors.grey.shade300),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 130,
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      child: const Icon(Icons.local_offer,
                          size: 40, color: Color(0xFF4CAF50)),
                    ),
                  )
                      : Container(
                    height: 130,
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    child: const Icon(Icons.local_offer,
                        size: 40, color: Color(0xFF4CAF50)),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer,
                              size: 10, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${(widget.offer['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 8)
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleFavorite,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: _isUpdatingFavorite
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF4CAF50)))
                              : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ✅ عرض الشبكة: المحافظة + الواط في الأسفل
                if (totalWattage > 0 || governorate.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ المحافظة في الأسفل يسار
                        if (governorate.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  governorate,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ✅ الواط في الأسفل يمين
                        if (totalWattage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on,
                                    size: 10, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text('$totalWattage واط',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 9)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  if (totalCapacity > 0)
                    Row(
                      children: [
                        Icon(Icons.battery_std,
                            size: 12, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$totalCapacity واط/ساعة',
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                Helpers.formatPrice(originalPrice),
                                style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              Helpers.formatPrice(finalPrice),
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4CAF50)),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (rate > 0) ...[
                              const Icon(Icons.star,
                                  size: 10, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(rate.toStringAsFixed(1),
                                  style: GoogleFonts.cairo(
                                      fontSize: 9, color: Colors.grey)),
                              const SizedBox(width: 4),
                            ],
                            if (views > 0) ...[
                              const Icon(Icons.visibility,
                                  size: 10, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(Helpers.formatNumber(views),
                                  style: GoogleFonts.cairo(
                                      fontSize: 9, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListViewCard() {
    final bool hasDiscount = (widget.offer['discount_percentage'] ?? 0) > 0;
    final double finalPrice =
        double.tryParse(widget.offer['final_price']?.toString() ?? '0') ?? 0;
    final double originalPrice =
        double.tryParse(widget.offer['price']?.toString() ?? '0') ?? 0;
    final int totalWattage = widget.offer['total_wattage'] ?? 0;
    final int totalCapacity = widget.offer['total_capacity'] ?? 0;
    final String name = widget.offer['name_ar']?.toString() ?? 'غير معروف';
    final String imageUrl = widget.offer['cover_image']?.toString() ?? '';
    final int views = widget.offer['views'] ?? 0;
    final double rate =
        double.tryParse(widget.offer['rate']?.toString() ?? '0') ?? 0;
    // ✅ استخراج اسم المحافظة للعرض
    final String governorate =
        widget.offer['governorate_offer']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfferDetailsScreen(
              offerSlug: widget.offer['slug']?.toString() ?? '',
              apiService: widget.apiService,
              authService: widget.authService,
            ),
          ),
        ).then((_) {
          setState(() {
            _isFavorite = _favoritesService.isOfferFavorite(widget.offer['id']);
          });
        });
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 100,
                    height: 125,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 100,
                      height: 125,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 100,
                      height: 125,
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      child: const Icon(Icons.local_offer,
                          size: 30, color: Color(0xFF4CAF50)),
                    ),
                  )
                      : Container(
                    width: 100,
                    height: 125,
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    child: const Icon(Icons.local_offer,
                        size: 30, color: Color(0xFF4CAF50)),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(widget.offer['discount_percentage'] ?? 0).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // ✅ عرض القائمة: المحافظة + الواط في الأسفل
                if (totalWattage > 0 || governorate.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ✅ المحافظة في الأسفل يسار
                        if (governorate.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 9,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  governorate,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // ✅ الواط في الأسفل يمين
                        if (totalWattage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on,
                                    size: 8, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '$totalWattage',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: _isUpdatingFavorite
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4CAF50),
                              ),
                            )
                                : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                              _isFavorite ? Colors.red : Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (totalCapacity > 0)
                      Row(
                        children: [
                          Icon(Icons.battery_std,
                              size: 11, color: Colors.blue.shade600),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '$totalCapacity واط/ساعة',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            Helpers.formatPrice(originalPrice),
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          Helpers.formatPrice(finalPrice),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const Spacer(),
                        if (rate > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 10, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  rate.toStringAsFixed(1),
                                  style: GoogleFonts.cairo(
                                      fontSize: 9, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        if (views > 0)
                          Row(
                            children: [
                              const Icon(Icons.visibility,
                                  size: 10, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                Helpers.formatNumber(views),
                                style: GoogleFonts.cairo(
                                    fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
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
}