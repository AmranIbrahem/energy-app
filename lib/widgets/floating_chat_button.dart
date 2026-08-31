import 'package:GeniusHouse/screens/appliances/appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/solar_chat_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/appliances/appliance_maintenance_screen.dart';
import '../screens/appliances/guest_appliance_maintenance_screen.dart';
import '../screens/appliances/appliance_schedule_screen.dart';
import '../screens/appliances/guest_appliance_schedule_screen.dart';
import '../screens/chat/guest_support_solar_chat_screen.dart';
import '../screens/chat/support_solar_chat_screen.dart';
import '../screens/chat/appliance_support_chat_screen.dart';
import '../screens/chat/guest_appliance_support_chat_screen.dart';
import '../screens/chat/lighting_support_chat_screen.dart';
import '../screens/chat/guest_lighting_support_chat_screen.dart';

class FloatingChatButton extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const FloatingChatButton({
    super.key,
    this.authService,
    required this.isGuest,
  });

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  bool _isHovering = false;

  Offset _position = const Offset(16, 80);
  bool _isDragging = false;
  bool _hasBeenDragged = false;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color darkBlue = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadPosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chat_button_x', _position.dx);
    await prefs.setDouble('chat_button_y', _position.dy);
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('chat_button_x');
    final y = prefs.getDouble('chat_button_y');
    if (x != null && y != null) {
      setState(() {
        _position = Offset(x, y);
      });
    }
  }

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CategorySelectionSheet(
        authService: widget.authService,
        isGuest: widget.isGuest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _hasBeenDragged = false;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            double newX = _position.dx + details.delta.dx;
            double newY = _position.dy + details.delta.dy;

            newX = newX.clamp(0, screenSize.width - 60);
            newY = newY.clamp(0, screenSize.height - 60 - kToolbarHeight);

            _position = Offset(newX, newY);
            _hasBeenDragged = true;
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          _savePosition();
        },
        onTap: _openCategorySheet,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    (_isDragging || _isHovering) ? 1.05 : _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value * (_isHovering ? 2 : 1),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryBlue, secondaryBlue, darkBlue],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: primaryBlue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 4)),
                        BoxShadow(
                            color: secondaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final delay = index * 0.3;
                              final value =
                                  (_animationController.value + delay) % 1.0;
                              return Opacity(
                                opacity: (1 - value) * 0.5,
                                child: Transform.scale(
                                  scale: 1 + (value * 0.5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: primaryBlue.withOpacity(0.4),
                                          width: 2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 28),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.8, end: 1.2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1),
                                  ),
                                  child: Text('AI',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ✅ شاشة اختيار المجال
class CategorySelectionSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const CategorySelectionSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<CategorySelectionSheet> createState() => _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<CategorySelectionSheet>
    with SingleTickerProviderStateMixin {
  static const Color buttonBlue = Color(0xFF2D5AA8);
  static const Color cardBorderColor = Color(0xFFD9DFE7);
  static const Color cardBgColor = Color(0xFFF7F8FA);

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'الطاقة الشمسية',
      'subtitle': 'ابدأ التصميم وحساب الطاقة',
      'image': 'assets/images/solar.png'
    },
    {
      'title': 'الإنارة والديكور',
      'subtitle': 'صمم إنارة منزلك',
      'image': 'assets/images/lightingillustration.png'
    },
    {
      'title': 'الأجهزة الكهربائية',
      'subtitle': 'جد أكثر الأجهزة توفيراً',
      'image': 'assets/images/homeappliancesillustration.png'
    },
  ];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Text('اختر مجالك لنبدأ',
                style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827))),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(index * 0.15, index * 0.15 + 0.6,
                        curve: Curves.easeOutBack),
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: CategoryCard(
                        category: category,
                        onTap: () => _handleCategoryTap(index)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('إلغاء',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCategoryTap(int index) {
    Navigator.pop(context);

    if (index == 0) {
      _showSolarOptionsSheet();
    } else if (index == 1) {
      // ✅ الإنارة والديكور
      _showLightingOptionsSheet();
    } else if (index == 2) {
      // ✅ الأجهزة الكهربائية
      _showApplianceOptionsSheet();
    }
  }

  void _showLightingOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LightingOptionsSheet(
          authService: widget.authService, isGuest: widget.isGuest),
    );
  }
  void _showSolarOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SolarOptionsSheet(
          authService: widget.authService, isGuest: widget.isGuest),
    );
  }

  void _showApplianceOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ApplianceOptionsSheet(
          authService: widget.authService, isGuest: widget.isGuest),
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('هذا القسم قيد التطوير، سيتم إطلاقه قريباً!',
            style: GoogleFonts.cairo(fontSize: 14)),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


// ✅ شاشة خيارات الإنارة والديكور
class LightingOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const LightingOptionsSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<LightingOptionsSheet> createState() => _LightingOptionsSheetState();
}

class _LightingOptionsSheetState extends State<LightingOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _lightingOptions = [
    {
      'title': 'تصميم الإضاءة الذكية',
      'subtitle': 'صور غرفتك والذكاء يضيف الإضاءة الصحيحة',
      'icon': Icons.auto_fix_high_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'قريباً',
      'enabled': false
    },
    {
      'title': 'الدعم التقني للإنارة',
      'subtitle': 'تواصل مع فريق الدعم الفني المتخصص',
      'icon': Icons.support_agent_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      'buttonText': 'ابدأ المحادثة',
      'enabled': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.grey.shade700, size: 22)),
                ),
                const SizedBox(width: 12),
                Text('خدمات الإنارة والديكور',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _lightingOptions.length,
              itemBuilder: (context, index) {
                final option = _lightingOptions[index];
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(index * 0.15, index * 0.15 + 0.5,
                          curve: Curves.easeOut)),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0, 0.2), end: Offset.zero)
                        .animate(animation),
                    child: _buildLightingOptionCard(option, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingOptionCard(Map<String, dynamic> option, int index) {
    final gradient = option['gradient'] as List<Color>;
    final enabled = option['enabled'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? gradient
                      : [Colors.grey.shade300, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
            Icon(option['icon'] as IconData, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option['title'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(option['subtitle'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? () => _handleLightingOptionTap(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient)
                    : null,
                color: enabled ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.white : Colors.grey.shade500)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLightingOptionTap(int index) {
    Navigator.pop(context);

    switch (index) {
      case 0:
      // ✅ تصميم الإضاءة الذكية - قريباً
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هذه الميزة قادمة قريباً!', style: GoogleFonts.cairo()), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
        break;
      case 1:
      // ✅ الدعم التقني للإنارة
        if (widget.isGuest) {
          _openGuestLightingSupport();
        } else {
          _openLightingSupport();
        }
        break;
    }
  }

  void _openLightingSupport() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LightingSupportChatScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestLightingSupport() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestLightingSupportChatScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }
}

// ✅ شاشة خيارات الطاقة الشمسية
class SolarOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const SolarOptionsSheet({super.key, this.authService, required this.isGuest});

  @override
  State<SolarOptionsSheet> createState() => _SolarOptionsSheetState();
}

class _SolarOptionsSheetState extends State<SolarOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _solarOptions = [
    {
      'title': 'مهندس المنظومات',
      'subtitle': 'تصميم منظومة شمسية متكاملة خطوة بخطوة',
      'icon': Icons.solar_power_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      'buttonText': 'ابدأ التصميم',
      'enabled': true
    },
    {
      'title': 'المستشار الشمسي',
      'subtitle': 'استفسارات وأسئلة متخصصة حول الطاقة الشمسية',
      'icon': Icons.chat_rounded,
      'gradient': [Color(0xFF059669), Color(0xFF10B981)],
      'buttonText': 'ابدأ الاستشارة',
      'enabled': true
    },
    {
      'title': 'الدعم البشري',
      'subtitle': 'تحدث مباشرة مع فريق الدعم الفني المتخصص',
      'icon': Icons.support_agent_rounded,
      'gradient': [Color(0xFFB45309), Color(0xFFF59E0B)],
      'buttonText': 'ابدأ المحادثة',
      'enabled': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.grey.shade700, size: 22)),
                ),
                const SizedBox(width: 12),
                Text('خدمات الطاقة الشمسية',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _solarOptions.length,
              itemBuilder: (context, index) {
                final option = _solarOptions[index];
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(index * 0.15, index * 0.15 + 0.5,
                          curve: Curves.easeOut)),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.2), end: Offset.zero)
                        .animate(animation),
                    child:
                        _buildOptionCard(option, index, _handleSolarOptionTap),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      Map<String, dynamic> option, int index, Function(int) onTap) {
    final gradient = option['gradient'] as List<Color>;
    final enabled = option['enabled'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? gradient
                      : [Colors.grey.shade300, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(option['icon'] as IconData, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option['title'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(option['subtitle'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? () => onTap(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient)
                    : null,
                color: enabled ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.white : Colors.grey.shade500)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSolarOptionTap(int index) {
    Navigator.pop(context);

    switch (index) {
      case 0:
        if (widget.isGuest) {
          _openGuestChat();
        } else {
          _openRegularChat();
        }
        break;
      case 1:
        if (widget.isGuest) {
          _openGuestSolarChat();
        } else {
          _openSolarChat();
        }
        break;
      case 2:
        if (widget.isGuest) {
          _openGuestSupportChat();
        } else {
          _openSupportChat();
        }
        break;
    }
  }

  void _openSupportChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SupportSolarChatScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestSupportChat() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestSupportSolarChatScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }

  void _openRegularChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestChat() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestChatScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }

  void _openSolarChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SolarChatScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestSolarChat() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestSolarChatScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }
}

// ✅ شاشة خيارات الأجهزة الكهربائية
class ApplianceOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const ApplianceOptionsSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<ApplianceOptionsSheet> createState() => _ApplianceOptionsSheetState();
}

class _ApplianceOptionsSheetState extends State<ApplianceOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _applianceOptions = [
    {
      'title': 'فحص التوافق',
      'subtitle': 'تحقق من توافق أجهزتك مع منظومتك الشمسية',
      'icon': Icons.check_circle_outline_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      'buttonText': 'ابدأ الفحص',
      'enabled': true
    },
    {
      'title': 'حاسبة التوفير',
      'subtitle': 'قارن استهلاك الأجهزة العادية مع الإنفرتر',
      'icon': Icons.savings_rounded,
      'gradient': [Color(0xFF059669), Color(0xFF10B981)],
      'buttonText': 'ابدأ الحساب',
      'enabled': true
    },
    {'title': 'مدير جدول التشغيل', 'subtitle': 'نظم تشغيل أجهزتك حسب قدرة منظومتك', 'icon': Icons.schedule_rounded, 'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)], 'buttonText': 'ابدأ التنظيم', 'enabled': true},

    {
      'title': 'الصيانة الذكية',
      'subtitle': 'صور العطل واحصل على تشخيص فوري',
      'icon': Icons.build_rounded,
      'gradient': [Color(0xFFB45309), Color(0xFFF59E0B)],
      'buttonText': 'ابدأ التشخيص',
      'enabled': true
    },

    {
      'title': 'دعم الأجهزة الكهربائية',
      'subtitle': 'تواصل مع فريق الدعم الفني المتخصص',
      'icon': Icons.support_agent_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'ابدأ المحادثة',
      'enabled': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: Column(
        children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.arrow_back_rounded,
                          color: Colors.grey.shade700, size: 22)),
                ),
                const SizedBox(width: 12),
                Text('خدمات الأجهزة الكهربائية',
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _applianceOptions.length,
              itemBuilder: (context, index) {
                final option = _applianceOptions[index];
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(index * 0.15, index * 0.15 + 0.5,
                          curve: Curves.easeOut)),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.2), end: Offset.zero)
                        .animate(animation),
                    child: _buildApplianceOptionCard(option, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceOptionCard(Map<String, dynamic> option, int index) {
    final gradient = option['gradient'] as List<Color>;
    final enabled = option['enabled'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? gradient
                      : [Colors.grey.shade300, Colors.grey.shade400]),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(option['icon'] as IconData, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option['title'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(option['subtitle'] as String,
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? () => _handleApplianceOptionTap(index) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient)
                    : null,
                color: enabled ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.white : Colors.grey.shade500)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleApplianceOptionTap(int index) {
    Navigator.pop(context);

    switch (index) {
      case 0:
        if (widget.isGuest) {
          _openGuestCompatibilityCheck();
        } else {
          _openCompatibilityCheck();
        }
        break;
      case 1:
        if (widget.isGuest) {
          _openGuestSavingsCalculator();
        } else {
          _openSavingsCalculator();
        }
        break;
      case 2:
      // ✅ مدير جدول التشغيل
        if (widget.isGuest) {
          _openGuestScheduleManager();
        } else {
          _openScheduleManager();
        }
        break;
      case 3:
        if (widget.isGuest) {
          _openGuestMaintenance();
        } else {
          _openMaintenance();
        }
        break;
      case 4:
        if (widget.isGuest) {
          _openGuestApplianceSupport();
        } else {
          _openApplianceSupport();
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هذه الميزة قادمة قريباً!', style: GoogleFonts.cairo()), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
    }
  }

  void _openScheduleManager() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ApplianceScheduleScreen(authService: widget.authService!, apiService: ApiService(storageService: widget.authService!.storageService))));
  }

  void _openGuestScheduleManager() {
    final storageService = widget.authService?.storageService ?? StorageService();
    Navigator.push(context, MaterialPageRoute(builder: (context) => GuestApplianceScheduleScreen(apiService: ApiService(storageService: storageService), storageService: storageService, initialGovernorate: storageService.getGuestGovernorate())));
  }
  void _openMaintenance() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ApplianceMaintenanceScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }
  void _openApplianceSupport() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ApplianceSupportChatScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestApplianceSupport() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestApplianceSupportChatScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }
  void _openGuestMaintenance() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestApplianceMaintenanceScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }
  void _openCompatibilityCheck() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ApplianceCompatibilityScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openSavingsCalculator() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ApplianceSavingsScreen(
                authService: widget.authService!,
                apiService: ApiService(
                    storageService: widget.authService!.storageService))));
  }

  void _openGuestSavingsCalculator() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestApplianceSavingsScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }

  void _openGuestCompatibilityCheck() {
    final storageService =
        widget.authService?.storageService ?? StorageService();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GuestApplianceCompatibilityScreen(
                apiService: ApiService(storageService: storageService),
                storageService: storageService,
                initialGovernorate: storageService.getGuestGovernorate())));
  }
}

// ✅ بطاقة واحدة
class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _CategorySelectionSheetState.cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _CategorySelectionSheetState.cardBorderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Image.asset(category['image'],
                    width: 70, height: 70, fit: BoxFit.contain)),
            const SizedBox(height: 12),
            Text(category['title'],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text(category['subtitle'],
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                  color: _CategorySelectionSheetState.buttonBlue,
                  borderRadius: BorderRadius.circular(30)),
              child: Center(
                child: Text(
                  category['title'] == 'الطاقة الشمسية' ||
                      category['title'] == 'الأجهزة الكهربائية' ||
                      category['title'] == 'الإنارة والديكور'
                      ? 'ابدأ'
                      : 'قريباً',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
