// lib/widgets/no_internet_wrapper.dart
import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoInternetWrapper extends StatefulWidget {
  final Widget child;
  final bool showAppBar;

  const NoInternetWrapper({
    super.key,
    required this.child,
    this.showAppBar = true,
  });

  @override
  State<NoInternetWrapper> createState() => _NoInternetWrapperState();
}

class _NoInternetWrapperState extends State<NoInternetWrapper>
    with SingleTickerProviderStateMixin {
  bool _isConnected = true;
  bool _isCheckingConnection = true;

  // ⚠️ تعديل مهم للإصدار 5: استخدام ConnectivityResult بدل List<ConnectivityResult>
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  late AnimationController _animationController;

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkConnectivity();

    // ⚠️ تعديل للإصدار 5: الاستماع يستقبل ConnectivityResult مباشرة
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {  // بدون List
        _handleConnectivityChange(result);
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isCheckingConnection = true);
    try {
      // ⚠️ تعديل للإصدار 5: ترجع ConnectivityResult مباشرة
      final result = await Connectivity().checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isCheckingConnection = false;
        });
      }
    }
  }

  // ⚠️ تعديل للإصدار 5: الدالة تستقبل ConnectivityResult مباشرة
  void _handleConnectivityChange(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;

    if (mounted) {
      setState(() {
        _isConnected = hasConnection;
        _isCheckingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) {
      return _buildLoadingScreen();
    }

    if (!_isConnected) {
      return _buildNoConnectionScreen();
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.1),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.yellow,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'NEX',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: widget.showAppBar
          ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'NEX',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأنيميشن
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final angle = _animationController.value * 2 * pi;
                  return Transform.rotate(
                    angle: angle,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (index) {
                          final circleAngle = angle + (index * 2.094);
                          return Positioned(
                            left: 30 * cos(circleAngle),
                            top: 30 * sin(circleAngle),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryBlue.withOpacity(0.3 + (index * 0.2)),
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade50,
                                Colors.red.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 50,
                                color: Colors.red.shade400,
                              ),
                              Icon(
                                Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
                                size: 25,
                                color: Colors.red.shade300,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              Text(
                'لا يوجد اتصال بالإنترنت',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'يرجى التحقق من اتصالك بالإنترنت',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تأكد من تشغيل Wi-Fi أو بيانات الجوال\nثم اضغط على زر إعادة المحاولة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final scale = 1.0 + (_animationController.value * 0.03);
                  return Transform.scale(
                    scale: scale,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isCheckingConnection = true);
                        _checkConnectivity();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 24),
                      label: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: primaryBlue.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'سيتم إعادة المحاولة تلقائياً عند عودة الاتصال',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}