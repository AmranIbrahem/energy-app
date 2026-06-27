// ملف: widgets/offer_stories.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class OfferStories extends StatefulWidget {
  final List<dynamic> offers;
  final Function(Map<String, dynamic>) onOfferTap;

  const OfferStories({
    super.key,
    required this.offers,
    required this.onOfferTap,
  });

  @override
  State<OfferStories> createState() => _OfferStoriesState();
}

class _OfferStoriesState extends State<OfferStories>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  int _currentStoryIndex = 0;
  Timer? _storyTimer;
  bool _isStoryOpen = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _storyTimer?.cancel();
    super.dispose();
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _storyTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStoryIndex < widget.offers.length - 1) {
        setState(() => _currentStoryIndex++);
        _progressController.reset();
        _progressController.forward();
      } else {
        _closeStory();
      }
    });
  }

  void _openStory(int index) {
    setState(() {
      _currentStoryIndex = index;
      _isStoryOpen = true;
    });
    _progressController.reset();
    _progressController.forward();
    _startStoryTimer();
  }

  void _closeStory() {
    _storyTimer?.cancel();
    setState(() => _isStoryOpen = false);
    _progressController.reset();
  }

  void _goToNextStory() {
    if (_currentStoryIndex < widget.offers.length - 1) {
      setState(() => _currentStoryIndex++);
      _progressController.reset();
      _progressController.forward();
    } else {
      _closeStory();
    }
  }

  void _goToPreviousStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // صف دوائر الستوريز
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.offers.length + 1, // +1 لزر "عرض الكل"
            itemBuilder: (context, index) {
              if (index == widget.offers.length) {
                return _buildViewAllButton();
              }
              return _buildStoryCircle(index);
            },
          ),
        ),
        // نافذة الستوري المنبثقة
        if (_isStoryOpen) _buildStoryViewer(),
      ],
    );
  }

  Widget _buildStoryCircle(int index) {
    final offer = widget.offers[index];
    final isViewed = index < _currentStoryIndex && !_isStoryOpen;
    final isActive = index == _currentStoryIndex && _isStoryOpen;

    return GestureDetector(
      onTap: () => _openStory(index),
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // دائرة الستوري مع حدود متدرجة
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : isViewed
                    ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
                    : const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                    Color(0xFF60A5FA),
                    Color(0xFFF59E0B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
                    : null,
              ),
              child: Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: offer['image_path'] != null
                      ? CachedNetworkImage(
                    imageUrl: offer['image_path'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.grey[300]),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.local_offer,
                          color: Colors.grey, size: 30),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.local_offer,
                        color: Colors.grey, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // اسم العرض
            Text(
              offer['title'] ?? 'عرض',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (offer['discount'] != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${offer['discount']}%',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return GestureDetector(
      onTap: () {
        // التنقل إلى صفحة جميع العروض
        widget.onOfferTap({});
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.1),
                    const Color(0xFF3B82F6).withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF1E3A8A),
                size: 30,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'عرض الكل',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E3A8A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryViewer() {
    final currentOffer = widget.offers[_currentStoryIndex];

    return GestureDetector(
      onTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 2) {
          _goToPreviousStory();
        } else {
          _goToNextStory();
        }
      },
      child: Container(
        color: Colors.black87,
        child: Stack(
          children: [
            // صورة الستوري
            Center(
              child: Hero(
                tag: 'story_${currentOffer['id']}',
                child: CachedNetworkImage(
                  imageUrl: currentOffer['image_path'] ?? '',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.local_offer,
                        color: Colors.white, size: 100),
                  ),
                ),
              ),
            ),
            // شريط التقدم
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  widget.offers.length,
                      (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: index == _currentStoryIndex
                          ? AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: Colors.transparent,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          );
                        },
                      )
                          : index < _currentStoryIndex
                          ? Container(color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            // معلومات العرض
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentOffer['title'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentOffer['description'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (currentOffer['price'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${currentOffer['price']} ل.س',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // أزرار التحكم
                        Row(
                          children: [
                            _buildStoryButton(
                              icon: Icons.arrow_back_ios_rounded,
                              onTap: _goToPreviousStory,
                            ),
                            const SizedBox(width: 12),
                            _buildStoryButton(
                              icon: Icons.arrow_forward_ios_rounded,
                              onTap: _goToNextStory,
                            ),
                            const SizedBox(width: 12),
                            _buildStoryButton(
                              icon: Icons.close_rounded,
                              onTap: _closeStory,
                              isClose: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // زر الإغلاق العلوي
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30),
                onPressed: _closeStory,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isClose
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.2),
          border: Border.all(
            color: isClose ? Colors.red : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}