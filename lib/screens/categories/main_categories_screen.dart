import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:energy_store_app/services/api_service.dart';
import 'package:energy_store_app/screens/categories/subcategories_screen.dart';

class MainCategoriesScreen extends StatefulWidget {
  final List<dynamic> categories;
  final ApiService apiService;

  const MainCategoriesScreen({
    super.key,
    required this.categories,
    required this.apiService,
  });

  @override
  State<MainCategoriesScreen> createState() => _MainCategoriesScreenState();
}

class _MainCategoriesScreenState extends State<MainCategoriesScreen> {
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // فلترة الأقسام حسب البحث
    final filteredCategories = _searchQuery.isEmpty
        ? widget.categories
        : widget.categories.where((category) {
      final name = category['name_ar']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'الأقسام الرئيسية',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          // زر تبديل عرض الشبكة/القائمة
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن قسم...',
                hintStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
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
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: widget.categories.isEmpty
          ? _buildEmptyState()
          : filteredCategories.isEmpty
          ? _buildNoResultsState()
          : _isGridView
          ? _buildGridView(filteredCategories)
          : _buildListView(filteredCategories),
    );
  }

  /// عرض الشبكة (GridView)
  Widget _buildGridView(List<dynamic> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  /// عرض القائمة (ListView)
  Widget _buildListView(List<dynamic> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildCategoryListItem(category),
        );
      },
    );
  }

// ==================== كروت الأقسام المحسنة (GridView) ====================

  Widget _buildCategoryCard(dynamic category) {
    final int subCategoriesCount = category['number_sub_categories'] ?? 0;
    final int productsCount = category['number_products'] ?? 0;
    final String name = category['name_ar'] ?? '';
    final String description = category['description'] ?? '';
    final String imageUrl = category['image'] ?? '';

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubCategoriesScreen(
                      category: category,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // الخلفية مع الصورة
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
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

                      // طبقة داكنة فوق الصورة لتحسين ظهور النص
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
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
                            // اسم القسم
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
                            const SizedBox(height: 8),

                            // الوصف
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 12),

                            // الإحصائيات
                            Row(
                              children: [
                                _buildModernStatChip(
                                  icon: Icons.category_rounded,
                                  count: subCategoriesCount,
                                  label: 'قسم',
                                ),
                                const SizedBox(width: 8),
                                _buildModernStatChip(
                                  icon: Icons.shopping_bag_rounded,
                                  count: productsCount,
                                  label: 'منتج',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // شارة التصنيف (اختياري)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'رائج',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// ==================== عنصر القائمة المحسن (ListView) ====================

  Widget _buildCategoryListItem(dynamic category) {
    final int subCategoriesCount = category['number_sub_categories'] ?? 0;
    final int productsCount = category['number_products'] ?? 0;
    final String name = category['name_ar'] ?? '';
    final String description = category['description'] ?? '';
    final String imageUrl = category['image'] ?? '';

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubCategoriesScreen(
                      category: category,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubCategoriesScreen(
                              category: category,
                              apiService: widget.apiService,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // صورة القسم مع تأثير
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF10B981),
                                  const Color(0xFF059669),
                                ],
                              ),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Colors.white.withOpacity(0.7),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.category_rounded,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),

                          // المحتوى
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  if (description.isNotEmpty) ...[
                                    Text(
                                      description,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // الإحصائيات
                                  Row(
                                    children: [
                                      _buildCompactStatChip(
                                        icon: Icons.category_rounded,
                                        count: subCategoriesCount,
                                        label: 'قسم فرعي',
                                      ),
                                      const SizedBox(width: 10),
                                      _buildCompactStatChip(
                                        icon: Icons.shopping_bag_rounded,
                                        count: productsCount,
                                        label: 'منتج',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // سهم التوجيه مع تأثير
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// ==================== شريط إحصائيات متطور ====================

  Widget _buildModernStatChip({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

// ==================== شريط إحصائيات مدمج للقائمة ====================

  Widget _buildCompactStatChip({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  /// شريط إحصائيات
  Widget _buildStatChip({
    required IconData icon,
    required int count,
    required String label,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 12 : 14, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.cairo(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// حالة عدم وجود أقسام
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أقسام',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إضافة أقسام جديدة قريباً',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// حالة عدم وجود نتائج بحث
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم نجد أقساماً تطابق بحثك',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear),
            label: Text(
              'مسح البحث',
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