// lib/screens/company/categories/sub_categories_screen.dart

import 'package:GeniusHouse/screens/company/categories/add_sub_category_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubCategoriesScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;
  final int mainCategoryId;
  final String mainCategoryName;

  const SubCategoriesScreen({
    super.key,
    required this.authService,
    required this.storageService,
    required this.mainCategoryId,
    required this.mainCategoryName,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color emeraldGreen = Color(0xFF34D399);

  late ApiService _apiService;
  List<dynamic> _subCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(storageService: widget.storageService);
    if (widget.authService.token != null) {
      _apiService.setToken(widget.authService.token!);
    }
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '/v1/company/categories/sub/${widget.mainCategoryId}',
        requiresAuth: true,
      );
      if (response['data'] != null && mounted) {
        setState(() {
          _subCategories = response['data']['sub_categories'] ?? [];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightGray,
        appBar: _buildAppBar(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSubCategoryScreen(
                  authService: widget.authService,
                  storageService: widget.storageService,
                  mainCategoryId: widget.mainCategoryId,
                  mainCategoryName: widget.mainCategoryName,
                ),
              ),
            );
            if (result == true) {
              _fetchSubCategories();
            }
          },
          backgroundColor: successGreen,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'إضافة قسم فرعي',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlue))
            : RefreshIndicator(
                onRefresh: _fetchSubCategories,
                color: primaryBlue,
                child: _subCategories.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) =>
                            _buildSubCategoryCard(_subCategories[index]),
                      ),
              ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التصنيفات الفرعية',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            widget.mainCategoryName,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchSubCategories,
        ),
      ],
      flexibleSpace: ClipPath(
        clipper: _BottomCurveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(dynamic subCategory) {
    final String name = subCategory['name_ar'] ?? '';
    final String? imageUrl = subCategory['image'];
    final int productCount = subCategory['products_count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: emeraldGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [successGreen, emeraldGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: successGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.category_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              name,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: successGreen.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_rounded, size: 14, color: successGreen),
                const SizedBox(width: 6),
                Text(
                  '$productCount منتج',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: successGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (subCategory['description'] != null &&
              subCategory['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                subCategory['description'],
                style: GoogleFonts.cairo(fontSize: 10, color: mediumGray),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.category_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد تصنيفات فرعية',
            style: GoogleFonts.cairo(fontSize: 16, color: mediumGray),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لإضافة قسم فرعي جديد',
            style: GoogleFonts.cairo(fontSize: 13, color: mediumGray),
          ),
        ],
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height);
    path.lineTo(size.width - 20, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
