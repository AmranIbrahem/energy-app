// lib/services/voice_service.dart

import 'package:flutter/services.dart';

class VoiceService {
  static const MethodChannel _channel = MethodChannel('com.nex.app/voice');

  static Future<bool> startRecording() async {
    try {
      final result = await _channel.invokeMethod('startRecording');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final result = await _channel.invokeMethod('stopRecording');
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> playAudio(String url) async {
    try {
      await _channel.invokeMethod('playAudio', {'url': url});
    } catch (e) {
      //
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _channel.invokeMethod('stopAudio');
    } catch (e) {
      //
    }
  }
}
