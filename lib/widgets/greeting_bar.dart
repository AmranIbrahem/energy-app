import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingBar extends StatefulWidget {
  final String userName;
  final String governorate;

  const GreetingBar({
    super.key,
    required this.userName,
    required this.governorate,
  });

  @override
  State<GreetingBar> createState() => _GreetingBarState();
}

class _GreetingBarState extends State<GreetingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _weatherController;
  late Animation<double> _weatherAnimation;

  @override
  void initState() {
    super.initState();
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _weatherAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _weatherController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _weatherController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  Color _getTimeColor() {
    final hour = DateTime.now().hour;
    if (hour < 12) return const Color(0xFFFF9800);
    if (hour < 17) return const Color(0xFF2196F3);
    return const Color(0xFF1A237E);
  }

  Map<String, dynamic> _getWeatherData() {
    final weatherData = {
      'دمشق': {
        'temp': '28°',
        'icon': Icons.wb_sunny_rounded,
        'condition': 'مشمس'
      },
      'حلب': {
        'temp': '30°',
        'icon': Icons.wb_sunny_rounded,
        'condition': 'مشمس جزئياً'
      },
      'حمص': {
        'temp': '26°',
        'icon': Icons.wb_cloudy_rounded,
        'condition': 'غائم'
      },
      'اللاذقية': {
        'temp': '25°',
        'icon': Icons.water_drop_rounded,
        'condition': 'رطب'
      },
      'طرطوس': {
        'temp': '24°',
        'icon': Icons.water_drop_rounded,
        'condition': 'رطب'
      },
      'حماة': {
        'temp': '29°',
        'icon': Icons.wb_sunny_rounded,
        'condition': 'مشمس'
      },
      'درعا': {
        'temp': '31°',
        'icon': Icons.wb_sunny_rounded,
        'condition': 'حار'
      },
      'السويداء': {
        'temp': '27°',
        'icon': Icons.wb_cloudy_rounded,
        'condition': 'معتدل'
      },
    };
    return weatherData[widget.governorate] ??
        {'temp': '25°', 'icon': Icons.wb_sunny_rounded, 'condition': 'معتدل'};
  }

  @override
  Widget build(BuildContext context) {
    final weather = _getWeatherData();
    final greeting = _getGreeting();
    final timeIcon = _getTimeIcon();
    final timeColor = _getTimeColor();
    final hour = DateTime.now().hour;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            timeColor.withOpacity(0.1),
            timeColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: timeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: timeColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _weatherAnimation,
            builder: (context, child) => Transform.scale(
              scale: _weatherAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      timeColor.withOpacity(0.2),
                      timeColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: timeColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  timeIcon,
                  color: timeColor,
                  size: 28,
                ),
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
                    Text(
                      greeting,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    if (hour < 12)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Image.asset(
                          'assets/emojis/sun.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.emoji_emotions,
                                  color: Colors.amber, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A4A68),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: timeColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  weather['icon'],
                  color: timeColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather['temp'],
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      weather['condition'],
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
