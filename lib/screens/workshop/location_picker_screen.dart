// lib/screens/workshop/location_picker_screen.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:GeniusHouse/services/permission_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with TickerProviderStateMixin {
  MapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _isGettingAddress = false;

  static const LatLng _defaultLocation = LatLng(33.5138, 36.2765);

  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color darkColor = Color(0xFF111827);
  static const Color mediumGray = Color(0xFF4B5563);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color cardWhite = Color(0xFFFFFFFF);

  late AnimationController _pulseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // ✅ استخدام PermissionService بدل Geolocator.requestPermission()
      final hasPermission = await PermissionService.requestLocation();

      if (!hasPermission) {
        final permanentlyDenied =
        await PermissionService.isLocationPermanentlyDenied();

        if (permanentlyDenied) {
          _showSnackBar(
            'الرجاء تفعيل إذن الموقع من الإعدادات',
            Colors.red,
          );
        } else {
          _showSnackBar('تم رفض إذن الموقع', Colors.red);
        }

        setState(() {
          _selectedLocation = _defaultLocation;
        });
        await _getAddressFromLatLng(_defaultLocation);
        return;
      }

      // ✅ الصلاحية ممنوحة — الآن نجيب الموقع
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        _mapController?.move(_selectedLocation!, 15);

        await _getAddressFromLatLng(_selectedLocation!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedLocation = _defaultLocation;
        });
        await _getAddressFromLatLng(_defaultLocation);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeAnimationController.forward(from: 0.0);
        _scaleAnimationController.forward(from: 0.0);
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isGettingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String?> addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).toList();

        setState(() {
          _selectedAddress = addressParts.join(' - ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
    } finally {
      setState(() => _isGettingAddress = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.cairo(fontSize: 14)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    bool bottomPanelVisible = _selectedLocation != null && !_isLoading;
    double bottomButtonOffset = bottomPanelVisible ? 300 : 20;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF6FF),
        body: Stack(
          children: [
            if (_selectedLocation != null)
              FlutterMap(
                mapController: _mapController!,
                options: MapOptions(
                  initialCenter: _selectedLocation!,
                  initialZoom: 13,
                  onTap: (tapPosition, point) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedLocation = point;
                    });
                    _getAddressFromLatLng(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.geniushouse',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 80,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 40 +
                                      (_pulseAnimationController.value * 30),
                                  height: 40 +
                                      (_pulseAnimationController.value * 30),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.2 -
                                        (_pulseAnimationController.value *
                                            0.15)),
                                  ),
                                ),
                                child!,
                              ],
                            );
                          },
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 45,
                            shadows: [
                              Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                            scale: 0.8 + (0.2 * value), child: child),
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                  scale: 1.0 +
                                      (_pulseAnimationController.value * 0.2),
                                  child: child);
                            },
                            child: const CircularProgressIndicator(
                                color: primaryBlue, strokeWidth: 3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'جاري تحديد الموقع...',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: mediumGray,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, secondaryBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                          scale: 1.0 +
                                              (_pulseAnimationController.value *
                                                  0.15),
                                          child: child);
                                    },
                                    child: const Icon(Icons.location_on_rounded,
                                        color: Colors.yellow, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'تحديد الموقع على الخريطة',
                                      style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: bottomButtonOffset,
              child: AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                      scale: 1.0 + (_pulseAnimationController.value * 0.08),
                      child: child);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: const Icon(Icons.my_location, color: primaryBlue),
                  ),
                ),
              ),
            ),
            if (bottomPanelVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)), child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, -5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [
                                      primaryBlue.withOpacity(0.1),
                                      secondaryBlue.withOpacity(0.05)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: primaryBlue.withOpacity(0.1),
                                    width: 1),
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: primaryBlue, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الموقع المحدد',
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: darkColor)),
                                  const SizedBox(height: 2),
                                  Text('اضغط على الخريطة لتغيير الموقع',
                                      style: GoogleFonts.cairo(
                                          fontSize: 11, color: mediumGray)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200, width: 1),
                          ),
                          child: _isGettingAddress
                              ? Row(
                                  children: [
                                    const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primaryBlue)),
                                    const SizedBox(width: 8),
                                    Text('جاري تحديد العنوان...',
                                        style: GoogleFonts.cairo(
                                            fontSize: 12, color: mediumGray)),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.article_rounded,
                                        size: 16,
                                        color: primaryBlue.withOpacity(0.7)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedAddress.isEmpty
                                            ? 'لا يوجد عنوان محدد'
                                            : _selectedAddress,
                                        style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            color: mediumGray,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: primaryBlue.withOpacity(0.08), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location_rounded,
                                  size: 14, color: primaryBlue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Clipboard.setData(ClipboardData(
                                      text:
                                          '${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'));
                                  _showSnackBar(
                                      'تم نسخ الإحداثيات', Colors.green);
                                },
                                child: Icon(Icons.copy_rounded,
                                    size: 14,
                                    color: primaryBlue.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              Navigator.pop(context, {
                                'latitude': _selectedLocation!.latitude,
                                'longitude': _selectedLocation!.longitude,
                                'address': _selectedAddress,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 8,
                              shadowColor: primaryBlue.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('تأكيد الموقع',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 15)),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomCurveClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(ui.Size size) {
    var path = ui.Path();
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
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => false;
}
