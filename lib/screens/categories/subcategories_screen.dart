import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/services/auth_service.dart';
import 'package:energy_store_app/screens/products/products_list_screen.dart';

import '../../services/storage_service.dart';

class SubCategoriesScreen extends StatefulWidget {
  final dynamic category;
  final ApiService apiService;
  final AuthService? authService;
  final StorageService? storageService;


  const SubCategoriesScreen({
    super.key,
    required this.category,
    required this.apiService,
    this.authService,
    this.storageService,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  List<dynamic> _subCategories = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _searchQuery = '';
  String? _errorMessage;
  int? _zoomedCardIndex;

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final slug = widget.category['slug'];
      final response = await widget.apiService.get(
        '/v1/user/public/categories/main/$slug/sub',
        requiresAuth: false,
      );

      if (response.containsKey('data') && mounted) {
        setState(() {
          _subCategories = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لا توجد أقسام فرعية';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في تحميل الأقسام الفرعية';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _searchQuery.isEmpty
        ? _subCategories
        : _subCategories.where((category) {
      final name = category['name_ar']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.category['name_ar'] ?? 'الأقسام الفرعية',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
                _zoomedCardIndex = null;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _zoomedCardIndex = null;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن قسم...',
                  hintStyle:
                  GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF9E9E9E)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9E9E9E)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _subCategories.isEmpty
          ? _buildEmptyWidget()
          : filteredCategories.isEmpty
          ? _buildNoResultsWidget()
          : _isGridView
          ? _buildGridView(filteredCategories)
          : _buildListView(filteredCategories),
    );
  }

  Widget _buildGridView(List<dynamic> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return FadeInCard(
          delay: Duration(milliseconds: index * 50),
          child: _buildCategoryCard(category, index),
        );
      },
    );
  }

  Widget _buildListView(List<dynamic> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return FadeInCard(
          delay: Duration(milliseconds: index * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryListItem(category, index),
          ),
        );
      },
    );
  }

  // ==================== كروت الشبكة - صورة ممتلئة مع Zoom بسيط ====================
  Widget _buildCategoryCard(dynamic subCategory, int index) {
    final int productsCount = subCategory['number_products'] ?? 0;
    final String name = subCategory['name_ar'] ?? '';
    final String description = subCategory['description'] ?? '';
    final String imageUrl = subCategory['image'] ?? '';
    final bool isZoomed = _zoomedCardIndex == index;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _zoomedCardIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _zoomedCardIndex = null;
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProductsListScreen(
                title: name,
                subcategorySlug: subCategory['slug'],
                apiService: widget.apiService,
                authService: widget.authService,
                storageService: widget.storageService,
                isSubCategory: true,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        });
      },
      onTapCancel: () {
        setState(() {
          _zoomedCardIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isZoomed ? 0.95 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isZoomed ? 0.12 : 0.08),
                blurRadius: isZoomed ? 18 : 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // صورة ممتلئة بالكامل
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover, // صورة ممتلئة بالكامل
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      child: const Icon(
                        Icons.category_rounded,
                        size: 60,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                // تدرج داكن
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0x33000000), // أسود شفاف 20%
                          Color(0xBF000000), // أسود شفاف 75%
                        ],
                      ),
                    ),
                  ),
                ),
                // المحتوى
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$productsCount منتج',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== كروت القائمة - صورة ممتلئة مع Zoom بسيط ====================
  Widget _buildCategoryListItem(dynamic subCategory, int index) {
    final int productsCount = subCategory['number_products'] ?? 0;
    final String name = subCategory['name_ar'] ?? '';
    final String description = subCategory['description'] ?? '';
    final String imageUrl = subCategory['image'] ?? '';
    final bool isZoomed = _zoomedCardIndex == index;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _zoomedCardIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _zoomedCardIndex = null;
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProductsListScreen(
                title: name,
                subcategorySlug: subCategory['slug'],
                apiService: widget.apiService,
                authService: widget.authService,
                storageService: widget.storageService,
                isSubCategory: true,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        });
      },
      onTapCancel: () {
        setState(() {
          _zoomedCardIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isZoomed ? 0.98 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isZoomed ? 0.1 : 0.05),
                blurRadius: isZoomed ? 12 : 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // صورة ممتلئة في المساحة المخصصة
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover, // صورة ممتلئة
                    placeholder: (_, __) => Container(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      child: const Center(
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      child: const Icon(
                        Icons.category_rounded,
                        size: 40,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF757575),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag_rounded,
                              size: 12,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$productsCount منتج',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(isZoomed ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE0E0E0),
          highlightColor: const Color(0xFFF5F5F5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF757575)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSubCategories,
            icon: const Icon(Icons.refresh),
            label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined, size: 50, color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد أقسام فرعية',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هذا القسم لا يحتوي على أقسام فرعية حالياً',
            style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 50, color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم نجد أقساماً تطابق بحثك',
            style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _searchQuery = ''),
            icon: const Icon(Icons.clear),
            label: Text('مسح البحث', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInCard extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const FadeInCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}