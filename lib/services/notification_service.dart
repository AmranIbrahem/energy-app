import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // تهيئة الإشعارات المحلية
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);

    // طلب إذن الإشعارات
    await FirebaseMessaging.instance.requestPermission();

    // الحصول على التوكن (أرسله للخادم لاحقاً)
    final token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token الخاص بك: $token');
    // TODO: سترسل هذا التوكن إلى الخادم

    // عندما يكون التطبيق مفتوحاً
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // عندما يضغط المستخدم على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('تم الضغط على الإشعار');
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'إشعار جديد',
      message.notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'energy_channel',
          'إشعارات متجر الطاقة',
          importance: Importance.high,
        ),
      ),
    );
  }
}