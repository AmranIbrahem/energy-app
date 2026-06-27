// lib/services/font_scale_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScaleManager {
  static const double _minScale = 0.7;
  static const double _maxScale = 2.0;
  static const double _defaultScale = 0.8;
  static const String _key = 'app_font_scale';

  static double _currentScale = _defaultScale;

  static double get currentScale => _currentScale;

  // تحميل القيمة المحفوظة
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentScale = prefs.getDouble(_key) ?? _defaultScale;
  }

  // تغيير القيمة وحفظها
  static Future<void> setScale(double scale) async {
    _currentScale = scale.clamp(_minScale, _maxScale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, _currentScale);
  }

  // إعادة التعيين
  static Future<void> reset() async {
    await setScale(_defaultScale);
  }
}

// ✅ ChangeNotifier لتحديث واجهة المستخدم فوراً
class FontScaleNotifier extends ChangeNotifier {
  double _scale = FontScaleManager.currentScale;

  double get scale => _scale;

  double get percentage => _scale * 100;

  String get label {
    if (_scale <= 0.8) return 'صغير';
    if (_scale <= 1.1) return 'عادي';
    if (_scale <= 1.5) return 'كبير';
    return 'كبير جداً';
  }

  Future<void> setScale(double newScale) async {
    _scale = newScale.clamp(0.7, 2.0);
    await FontScaleManager.setScale(_scale);
    notifyListeners();
  }

  Future<void> reset() async {
    _scale = 0.8;
    await FontScaleManager.reset();
    notifyListeners();
  }
}