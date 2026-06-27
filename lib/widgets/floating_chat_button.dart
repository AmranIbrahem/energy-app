import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GeniusHouse/screens/chat/chat_screen.dart';
import 'package:GeniusHouse/screens/chat/guest_chat_screen.dart';
import 'package:GeniusHouse/services/api_service.dart';
import 'package:GeniusHouse/services/auth_service.dart';
import 'package:GeniusHouse/services/storage_service.dart';
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

  Offset _position = const Offset(16, 80);
  bool _isDragging = false;
  bool _hasBeenDragged = false;

  // ألوان الهوية الجديدة
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);

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

  void _openChat() {
    if (!_isDragging && !_hasBeenDragged) {
      if (widget.isGuest) {
        _openGuestChat();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              authService: widget.authService!,
              apiService: ApiService(storageService: widget.authService!.storageService),
            ),
          ),
        );
      }
    }
    _hasBeenDragged = false;
  }

  void _openGuestChat() {
    final storageService = widget.authService?.storageService ?? StorageService();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestChatScreen(
          apiService: ApiService(storageService: storageService),
          storageService: storageService,
          initialGovernorate: storageService.getGuestGovernorate(),
        ),
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
        onTap: _openChat,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: (_isDragging || _isHovering) ? 1.05 : _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value * (_isHovering ? 2 : 1),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue,
                          secondaryBlue,
                          Color(0xFF1E40AF),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: secondaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // تأثيرات النبض
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              final delay = index * 0.3;
                              final value = (_animationController.value + delay) % 1.0;
                              return Opacity(
                                opacity: (1 - value) * 0.5,
                                child: Transform.scale(
                                  scale: 1 + (value * 0.5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryBlue.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        // الأيقونة الرئيسية
                        Icon(
                          _isDragging ? Icons.drag_handle_rounded : Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        // شارة AI
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
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.amber, Colors.orange],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
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