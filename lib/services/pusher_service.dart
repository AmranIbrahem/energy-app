import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter/material.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter? _pusher;
  bool _isConnected = false;

  static const String _appKey = '485d3f2ec7b88393203b';
  static const String _cluster = 'eu';

  /// ✅ تهيئة Pusher
  Future<void> init() async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: _appKey,
        cluster: _cluster,
      );
      await _pusher!.connect();
    } catch (e) {
      debugPrint('❌ Pusher init error: $e');
    }
  }

  /// ✅ الاشتراك في قناة محادثة
  Future<void> subscribeToConversation(int conversationId, Function(Map<String, dynamic>) onMessage) async {
    try {
      final channelName = 'support-conversation.$conversationId';
      await _pusher!.subscribe(channelName: channelName);

      debugPrint('✅ Subscribed to: $channelName');
    } catch (e) {
      debugPrint('❌ Subscribe error: $e');
    }
  }

  /// ✅ الاستماع لحدث معين
  void bindEvent(String eventName, Function(Map<String, dynamic>) onMessage) {
    _pusher!.onEvent = (PusherEvent event) {
      if (event.eventName == eventName) {
        final data = event.data;
        try {
          if (data is Map) {
            onMessage(Map<String, dynamic>.from(data));
          } else if (data is String) {
            onMessage({'message': data});
          }
        } catch (e) {
          debugPrint('❌ Event parse error: $e');
        }
      }
    };
  }

  /// ✅ إلغاء الاشتراك
  Future<void> unsubscribe(String channelName) async {
    try {
      await _pusher!.unsubscribe(channelName: channelName);
    } catch (e) {
      debugPrint('❌ Unsubscribe error: $e');
    }
  }

  /// ✅ قطع الاتصال
  Future<void> disconnect() async {
    try {
      await _pusher!.disconnect();
    } catch (e) {
      debugPrint('❌ Disconnect error: $e');
    }
  }
}