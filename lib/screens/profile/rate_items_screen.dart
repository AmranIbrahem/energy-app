// lib/screens/profile/rate_items_screen.dart
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/rating_api_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/api_service.dart';

class RateItemsScreen extends StatefulWidget {
  final int invoiceId;
  final String invoiceNumber;
  final ApiService? apiService;
  final AuthService? authService;

  const RateItemsScreen({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    this.apiService,
    this.authService,
  });

  @override
  State<RateItemsScreen> createState() => _RateItemsScreenState();
}

class _RateItemsScreenState extends State<RateItemsScreen> {
  List<Map<String, dynamic>> _items = [];
  Map<int, int> _ratings = {};
  Map<int, TextEditingController> _reviews = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  late RatingApiService _ratingApiService;
  final String _baseUrl = 'https://nexsy.shop';

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _initApiService();
    _loadRateableItems();
  }

  void _initApiService() {
    final authService = widget.authService ??
        AuthService(storageService: StorageService()..init());
    _ratingApiService = RatingApiService(
      baseUrl: _baseUrl,
      authService: authService,
    );
  }

  Future<void> _loadRateableItems() async {
    setState(() => _isLoading = true);

    final result = await _ratingApiService.getRateableItems(widget.invoiceId);

    if (result['success']) {
      final items = List<Map<String, dynamic>>.from(result['data']['items']);
      setState(() {
        _items = items;
        for (var item in items) {
          final id = item['id'];
          _ratings[id] = 0;
          _reviews[id] = TextEditingController();
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'حدث خطأ', Colors.red);
    }
  }

  Future<void> _submitAllRatings() async {
    final unratedItems =
        _items.where((item) => _ratings[item['id']] == 0).toList();
    if (unratedItems.isNotEmpty) {
      _showSnackBar('يرجى تقييم جميع المنتجات قبل الإرسال', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    bool allSuccess = true;
    int successCount = 0;
    int failedCount = 0;

    for (var item in _items) {
      final result = await _ratingApiService.submitRating(
        invoiceId: widget.invoiceId,
        itemId: item['id'],
        itemType: item['type'],
        rating: _ratings[item['id']]!,
        review: _reviews[item['id']]?.text.trim().isEmpty ?? true
            ? null
            : _reviews[item['id']]?.text.trim(),
      );

      if (result['success']) {
        successCount++;
      } else {
        failedCount++;
        allSuccess = false;
      }
    }

    setState(() => _isSubmitting = false);

    if (allSuccess) {
      _showSnackBar('شكراً لك! تم إرسال جميع التقييمات بنجاح', primaryBlue);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(
          'تم إرسال $successCount تقييم، فشل $failedCount', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == primaryBlue
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: GoogleFonts.cairo(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _reviews.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'تقييم الطلب #${widget.invoiceNumber}',
          style: GoogleFonts.cairo(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _buildRatingCard(item);
                        },
                      ),
                    ),
                    _buildSubmitButton(),
                  ],
                ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> item) {
    final itemId = item['id'];
    final itemName = item['name'] ?? 'منتج';
    final itemImage = item['image'] ?? '';
    final itemType = item['type'] ?? 'product';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: itemImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: itemImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: primaryBlue, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: Icon(
                              itemType == 'offer'
                                  ? Icons.local_offer
                                  : Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(
                            itemType == 'offer'
                                ? Icons.local_offer
                                : Icons.shopping_bag,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              itemName,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ),
                          if (itemType == 'offer')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryBlue.withOpacity(0.12),
                                    secondaryBlue.withOpacity(0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: primaryBlue.withOpacity(0.2)),
                              ),
                              child: Text(
                                'عرض',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item['details'] != null)
                        Text(
                          itemType == 'product'
                              ? '${item['details']['brand'] ?? ''} ${item['details']['model'] ?? ''}'
                              : '${item['details']['total_wattage'] ?? 0} واط - ${item['details']['total_capacity'] ?? 0} واط/س',
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: mediumGray),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييمك',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: RatingBar(
                    initialRating: _ratings[itemId]?.toDouble() ?? 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 40,
                    ratingWidget: RatingWidget(
                      full: const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 40),
                      half: const Icon(Icons.star_half_rounded,
                          color: Colors.amber, size: 40),
                      empty: const Icon(Icons.star_outline_rounded,
                          color: Colors.amber, size: 40),
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _ratings[itemId] = rating.toInt();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviews[itemId],
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(fontSize: 14, color: darkColor),
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقك (اختياري)',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: lightGray,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAllRatings,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: primaryBlue.withOpacity(0.5),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'إرسال التقييمات',
                      style: GoogleFonts.cairo(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 250,
          decoration: BoxDecoration(
              color: cardWhite, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(Icons.star_outline_rounded,
                size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'جميع المنتجات مقيمة',
            style: GoogleFonts.cairo(
                fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
          ),
          const SizedBox(height: 8),
          Text(
            'لقد قمت بتقييم جميع منتجات هذا الطلب مسبقاً',
            style: GoogleFonts.cairo(fontSize: 14, color: mediumGray),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text('رجوع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class RatingBar extends StatelessWidget {
  final double initialRating;
  final double minRating;
  final Axis direction;
  final bool allowHalfRating;
  final int itemCount;
  final double itemSize;
  final RatingWidget ratingWidget;
  final ValueChanged<double> onRatingUpdate;

  const RatingBar({
    super.key,
    required this.initialRating,
    required this.minRating,
    required this.direction,
    required this.allowHalfRating,
    required this.itemCount,
    required this.itemSize,
    required this.ratingWidget,
    required this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        return GestureDetector(
          onTap: () => onRatingUpdate((index + 1).toDouble()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: index + 1 <= initialRating
                ? ratingWidget.full
                : ratingWidget.empty,
          ),
        );
      }),
    );
  }
}

class RatingWidget {
  final Widget full;
  final Widget half;
  final Widget empty;

  const RatingWidget({
    required this.full,
    required this.half,
    required this.empty,
  });
}
