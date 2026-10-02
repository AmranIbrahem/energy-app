// lib/widgets/floating_chat_button.dart

import 'dart:ui';

import 'package:GeniusHouse/screens/appliances/appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_maintenance_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/appliances/appliance_schedule_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_compatibility_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_maintenance_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_savings_screen.dart';
import 'package:GeniusHouse/screens/appliances/guest_appliance_schedule_screen.dart';
import 'package:GeniusHouse/screens/chat/appliance_support_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_appliance_support_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_lighting_support_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_support_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/lighting_support_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/solar_chat_screen.dart';
import 'package:GeniusHouse/screens/chat/support_solar_chat_screen.dart';
import 'package:GeniusHouse/screens/lighting/lighting_projects_screen.dart';
import 'package:GeniusHouse/screens/solar/solar_projects_screen.dart';
import 'package:GeniusHouse/screens/solar/solar_wizard_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ✅ الموضع الآن nullable — سيُحسب ديناميكياً حسب الشاشة
  Offset? _position;
  bool _isDragging = false;
  bool _hasBeenDragged = false;

  // ثوابت الأحجام
  static const double _buttonSize = 60;
  static const double _margin = 16;
  static const double _navBarHeight = 90; // ارتفاع الشريط السفلي في home_screen

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ إذا لم يُحمَّل موضع محفوظ، احسب الموضع الافتراضي (أسفل يمين)
    if (_position == null) {
      _position = _calculateDefaultPosition();
    }
  }

  /// ✅ حساب الموضع الافتراضي: أسفل يمين الشاشة فوق شريط التنقل بقليل
  Offset _calculateDefaultPosition() {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // اليمين: عرض الشاشة - حجم الزر - الهامش
    final double x = screenSize.width - _buttonSize - _margin;

    // الأسفل: ارتفاع الشاشة - الشريط السفلي - حجم الزر - الهامش - الـ safe area
    final double y =
        screenSize.height - _navBarHeight - _buttonSize - _margin - bottomInset + 30;

    return Offset(x, y);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _savePosition() async {
    if (_position == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('chat_button_x', _position!.dx);
    await prefs.setDouble('chat_button_y', _position!.dy);
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble('chat_button_x');
    final y = prefs.getDouble('chat_button_y');
    if (x != null && y != null && mounted) {
      setState(() {
        _position = Offset(x, y);
        _hasBeenDragged = true;
      });
    }
  }

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
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

    // حماية: إذا لم يُحسب الموضع بعد
    if (_position == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      // ✅ استخدام _position كموضع فعلي للزر
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _hasBeenDragged = false;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            double newX = _position!.dx + details.delta.dx;
            double newY = _position!.dy + details.delta.dy;

            newX = newX.clamp(0, screenSize.width - _buttonSize);
            newY = newY.clamp(
                0, screenSize.height - _buttonSize - kToolbarHeight);

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
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryBlue, secondaryBlue, darkBlue],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: primaryBlue.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 4)),
                        BoxShadow(
                            color: secondaryBlue.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 2)),
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
                                    gradient: const LinearGradient(
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

class CategorySelectionSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const CategorySelectionSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<CategorySelectionSheet> createState() => _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<CategorySelectionSheet> {
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'خدمات الطاقة الشمسية',
      'subtitle': 'ابدأ التصميم وحساب الطاقة',
      'image': 'assets/images/solar.png',
      'gradient': [Color(0xFF1A5F9E), Color(0xFF4A90E2)],
    },
    {
      'title': 'خدمات الإنارة والديكور',
      'subtitle': 'صمم إنارة منزلك',
      'image': 'assets/images/lightingillustration.png',
      'gradient': [Color(0xFF4C2A85), Color(0xFF8E6BBE)],
    },
    {
      'title': 'خدمات الأجهزة الكهربائية',
      'subtitle': 'فحص التوافق وحاسبة التوفير',
      'image': 'assets/images/homeappliancesillustration.png',
      'gradient': [Color(0xFF047857), Color(0xFF10B981)],
    },
  ];

  final List<Map<String, dynamic>> _quickAccessItems = [
    {'title': 'مهندس المنظومات', 'icon': Icons.solar_power_rounded},
    {'title': 'المستشار الشمسي', 'icon': Icons.chat_rounded},
    {'title': 'الدعم البشري', 'icon': Icons.support_agent_rounded},
    {'title': 'حاسبة التوفير', 'icon': Icons.calculate_rounded},
    {'title': 'الصيانة الذكية', 'icon': Icons.build_rounded},
    {'title': 'فحص التوافق', 'icon': Icons.check_circle_rounded},
    {'title': 'مدير جدول التشغيل', 'icon': Icons.schedule_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'اختر مجالك',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      return _buildGradientCategoryCard(
                          _categories[index], index);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوصول السريع للخدمات المتخصصة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C3AED).withOpacity(0.1),
                              const Color(0xFF312E81).withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildQuickAccessItem(0)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildQuickAccessItem(2)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildQuickAccessItem(1)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildQuickAccessItem(4)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildQuickAccessItem(3)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildQuickAccessItem(5)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildQuickAccessItem(6)),
                                const SizedBox(width: 8),
                                const Expanded(child: SizedBox()),
                              ],
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

  Widget _buildGradientCategoryCard(Map<String, dynamic> category, int index) {
    final gradient = category['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => _handleCategoryTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ابدأ',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: gradient[0],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: gradient[0], size: 14),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['subtitle'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(category['image'] as String,
                    fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem(int index) {
    final item = _quickAccessItems[index];

    return GestureDetector(
      onTap: () => _handleQuickAccess(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(item['icon'] as IconData, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item['title'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryTap(int index) {
    Navigator.pop(context);
    if (index == 0) {
      _showSolarOptionsSheet();
    } else if (index == 1) {
      _showLightingOptionsSheet();
    } else if (index == 2) {
      _showApplianceOptionsSheet();
    }
  }

  void _handleQuickAccess(int index) {
    Navigator.pop(context);

    if (widget.isGuest) {
      final storageService =
          widget.authService?.storageService ?? StorageService();
      switch (index) {
        case 0:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestChatScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 1:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestSolarChatScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 2:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestSupportSolarChatScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 3:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceSavingsScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 4:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceMaintenanceScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 5:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceCompatibilityScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 6:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceScheduleScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
      }
    } else {
      switch (index) {
        case 0:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 1:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SolarChatScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 2:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SupportSolarChatScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 3:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceSavingsScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 4:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceMaintenanceScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 5:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceCompatibilityScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 6:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceScheduleScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
      }
    }
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

  void _showLightingOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LightingOptionsSheet(
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
}

class SolarOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const SolarOptionsSheet({super.key, this.authService, required this.isGuest});

  @override
  State<SolarOptionsSheet> createState() => _SolarOptionsSheetState();
}

class _SolarOptionsSheetState extends State<SolarOptionsSheet> {
  final List<Map<String, dynamic>> _solarOptions = [
    {
      'title': 'مهندس المنظومات',
      'subtitle': 'تصميم منظومة شمسية متكاملة خطوة بخطوة',
      'icon': Icons.solar_power_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      'buttonText': 'ابدأ التصميم'
    },
    {
      'title': 'مسودات التصميم',
      'subtitle': 'استعرض، قارن، وأكمل منظوماتك المحفوظة',
      'icon': Icons.bookmarks_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'استعرض'
    },
    {
      'title': 'المستشار الشمسي',
      'subtitle': 'استفسارات وأسئلة متخصصة حول الطاقة الشمسية',
      'icon': Icons.chat_rounded,
      'gradient': [Color(0xFF059669), Color(0xFF10B981)],
      'buttonText': 'ابدأ الاستشارة'
    },
    {
      'title': 'الدعم البشري',
      'subtitle': 'تحدث مباشرة مع فريق الدعم الفني المتخصص',
      'icon': Icons.support_agent_rounded,
      'gradient': [Color(0xFFB45309), Color(0xFFF59E0B)],
      'buttonText': 'ابدأ المحادثة'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.solar_power_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text('خدمات الطاقة الشمسية',
                          style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _solarOptions.length,
                    itemBuilder: (context, index) =>
                        _buildGradientOptionCard(_solarOptions[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOptionCard(Map<String, dynamic> option, int index) {
    final gradient = option['gradient'] as List<Color>;
    return GestureDetector(
      onTap: () => _handleSolarOptionTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(option['icon'] as IconData,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option['title'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(option['subtitle'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: gradient[0])),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSolarOptionTap(int index) {
    Navigator.pop(context);

    final storageService =
        widget.authService?.storageService ?? StorageService();
    final apiService = ApiService(storageService: storageService);

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolarWizardScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      return;
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SolarProjectsScreen(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      );
      return;
    }

    if (index == 2) {
      if (widget.isGuest) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuestSolarChatScreen(
              apiService: apiService,
              storageService: storageService,
              initialGovernorate: storageService.getGuestGovernorate(),
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SolarChatScreen(
              authService: widget.authService!,
              apiService: apiService,
            ),
          ),
        );
      }
      return;
    }

    if (widget.isGuest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuestSupportSolarChatScreen(
            apiService: apiService,
            storageService: storageService,
            initialGovernorate: storageService.getGuestGovernorate(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportSolarChatScreen(
            authService: widget.authService!,
            apiService: apiService,
          ),
        ),
      );
    }
  }
}

class LightingOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const LightingOptionsSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<LightingOptionsSheet> createState() => _LightingOptionsSheetState();
}

class _LightingOptionsSheetState extends State<LightingOptionsSheet> {
  final List<Map<String, dynamic>> _lightingOptions = [
    {
      'title': 'تصميم الإضاءة الذكية',
      'subtitle': 'احسب إنارة غرفتك واحصل على 3 اقتراحات من Nex',
      'icon': Icons.auto_fix_high_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'ابدأ التصميم',
      'enabled': true
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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.lightbulb_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text('خدمات الإنارة والديكور',
                          style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _lightingOptions.length,
                    itemBuilder: (context, index) => _buildGradientOptionCard(
                        _lightingOptions[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOptionCard(Map<String, dynamic> option, int index) {
    final gradient = option['gradient'] as List<Color>;
    final enabled = option['enabled'] as bool;
    return GestureDetector(
      onTap: () => _handleLightingOptionTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
              : null,
          color: enabled ? null : Colors.grey.shade800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: enabled
              ? [
            BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
                border: enabled
                    ? Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: Icon(option['icon'] as IconData,
                  color: enabled ? Colors.white : Colors.grey.shade500,
                  size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option['title'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                          enabled ? Colors.white : Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Text(option['subtitle'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: enabled
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey.shade500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: enabled ? Colors.white : Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(25)),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: enabled ? gradient[0] : Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLightingOptionTap(int index) {
    Navigator.pop(context);

    if (index == 0) {
      final storageService =
          widget.authService?.storageService ?? StorageService();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LightingProjectsScreen(
            apiService: ApiService(storageService: storageService),
            storageService: storageService,
          ),
        ),
      );
      return;
    }

    if (widget.isGuest) {
      final storageService =
          widget.authService?.storageService ?? StorageService();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GuestLightingSupportChatScreen(
                  apiService: ApiService(storageService: storageService),
                  storageService: storageService,
                  initialGovernorate: storageService.getGuestGovernorate())));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LightingSupportChatScreen(
                  authService: widget.authService!,
                  apiService: ApiService(
                      storageService: widget.authService!.storageService))));
    }
  }
}

class ApplianceOptionsSheet extends StatefulWidget {
  final AuthService? authService;
  final bool isGuest;

  const ApplianceOptionsSheet(
      {super.key, this.authService, required this.isGuest});

  @override
  State<ApplianceOptionsSheet> createState() => _ApplianceOptionsSheetState();
}

class _ApplianceOptionsSheetState extends State<ApplianceOptionsSheet> {
  final List<Map<String, dynamic>> _applianceOptions = [
    {
      'title': 'فحص التوافق',
      'subtitle': 'تحقق من توافق أجهزتك مع منظومتك الشمسية',
      'icon': Icons.check_circle_outline_rounded,
      'gradient': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      'buttonText': 'ابدأ الفحص'
    },
    {
      'title': 'حاسبة التوفير',
      'subtitle': 'قارن استهلاك الأجهزة العادية مع الإنفرتر',
      'icon': Icons.savings_rounded,
      'gradient': [Color(0xFF059669), Color(0xFF10B981)],
      'buttonText': 'ابدأ الحساب'
    },
    {
      'title': 'مدير جدول التشغيل',
      'subtitle': 'نظم تشغيل أجهزتك حسب قدرة منظومتك',
      'icon': Icons.schedule_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'ابدأ التنظيم'
    },
    {
      'title': 'الصيانة الذكية',
      'subtitle': 'صور العطل واحصل على تشخيص فوري',
      'icon': Icons.build_rounded,
      'gradient': [Color(0xFFB45309), Color(0xFFF59E0B)],
      'buttonText': 'ابدأ التشخيص'
    },
    {
      'title': 'دعم الأجهزة الكهربائية',
      'subtitle': 'تواصل مع فريق الدعم الفني المتخصص',
      'icon': Icons.support_agent_rounded,
      'gradient': [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      'buttonText': 'ابدأ المحادثة'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.electrical_services_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text('خدمات الأجهزة الكهربائية',
                          style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _applianceOptions.length,
                    itemBuilder: (context, index) => _buildGradientOptionCard(
                        _applianceOptions[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOptionCard(Map<String, dynamic> option, int index) {
    final gradient = option['gradient'] as List<Color>;
    return GestureDetector(
      onTap: () => _handleApplianceOptionTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(option['icon'] as IconData,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option['title'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(option['subtitle'] as String,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Text(option['buttonText'] as String,
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: gradient[0])),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApplianceOptionTap(int index) {
    Navigator.pop(context);

    if (widget.isGuest) {
      final storageService =
          widget.authService?.storageService ?? StorageService();
      switch (index) {
        case 0:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceCompatibilityScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 1:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceSavingsScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 2:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceScheduleScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 3:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceMaintenanceScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
        case 4:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GuestApplianceSupportChatScreen(
                      apiService: ApiService(storageService: storageService),
                      storageService: storageService,
                      initialGovernorate:
                      storageService.getGuestGovernorate())));
          break;
      }
    } else {
      switch (index) {
        case 0:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceCompatibilityScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 1:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceSavingsScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 2:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceScheduleScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 3:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceMaintenanceScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
        case 4:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ApplianceSupportChatScreen(
                      authService: widget.authService!,
                      apiService: ApiService(
                          storageService:
                          widget.authService!.storageService))));
          break;
      }
    }
  }
}