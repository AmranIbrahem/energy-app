// lib/services/permission_service.dart

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  static const MethodChannel _channel =
  MethodChannel('com.nex.app/permissions');

  static Future<bool> requestMicrophone() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      try {
        final result = await _channel.invokeMethod('requestMicrophone');
        return result == true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      try {
        final result = await _channel.invokeMethod('requestMicrophone');
        return result == true;
      } catch (channelError) {
        return false;
      }
    }
  }

  static Future<bool> checkMicrophone() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      try {
        final result = await _channel.invokeMethod('checkMicrophone');
        return result == true;
      } catch (channelError) {
        return false;
      }
    }
  }

  static Future<bool> isMicrophonePermanentlyDenied() async {
    try {
      final status = await Permission.microphone.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestLocation() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkLocation() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isLocationPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestCamera() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestPhotos() async {
    try {
      final status = await Permission.photos.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestNotifications() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      try {
        await _channel.invokeMethod('openAppSettings');
      } catch (channelError) {
        // ignore
      }
    }
  }
}