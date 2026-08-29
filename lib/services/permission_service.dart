// lib/services/permission_service.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.nex.app/permissions');

  /// ✅ طلب صلاحية الميكروفون
  static Future<bool> requestMicrophone() async {
    try {
      // ✅ استخدام permission_handler أولاً
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        return true;
      }

      // ✅ إذا رفض المستخدم، حاول عبر MethodChannel (للأجهزة القديمة)
      if (status.isPermanentlyDenied) {
        // الصلاحية مرفوضة نهائياً - يجب فتح الإعدادات
        return false;
      }

      // ✅ محاولة عبر MethodChannel كخطة بديلة
      try {
        final result = await _channel.invokeMethod('requestMicrophone');
        return result == true;
      } catch (e) {
        return false;
      }

    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');

      // ✅ محاولة عبر MethodChannel كخطة بديلة
      try {
        final result = await _channel.invokeMethod('requestMicrophone');
        return result == true;
      } catch (channelError) {
        debugPrint('❌ MethodChannel error: $channelError');
        return false;
      }
    }
  }

  /// ✅ التحقق من صلاحية الميكروفون
  static Future<bool> checkMicrophone() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking microphone permission: $e');

      // ✅ محاولة عبر MethodChannel
      try {
        final result = await _channel.invokeMethod('checkMicrophone');
        return result == true;
      } catch (channelError) {
        return false;
      }
    }
  }

  /// ✅ التحقق إذا كانت الصلاحية مرفوضة نهائياً
  static Future<bool> isMicrophonePermanentlyDenied() async {
    try {
      final status = await Permission.microphone.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// ✅ فتح إعدادات التطبيق
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');

      // ✅ محاولة عبر MethodChannel
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (channelError) {
        debugPrint('❌ MethodChannel error: $channelError');
      }
    }
  }

  /// ✅ طلب صلاحية الكاميرا (للاستخدام المستقبلي)
  static Future<bool> requestCamera() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting camera permission: $e');
      return false;
    }
  }

  /// ✅ طلب صلاحية الصور (للاستخدام المستقبلي)
  static Future<bool> requestPhotos() async {
    try {
      final status = await Permission.photos.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting photos permission: $e');
      return false;
    }
  }

  /// ✅ طلب صلاحية الإشعارات (للاستخدام المستقبلي)
  static Future<bool> requestNotifications() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }
}