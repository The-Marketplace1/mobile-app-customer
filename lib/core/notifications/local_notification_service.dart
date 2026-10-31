import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  void Function()? onNotificationTap;

  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => onNotificationTap?.call(),
    );
  }

  Future<bool> requestPermission() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  Future<void> showRealtimeNotification(Map<String, dynamic> event) async {
    final notification = event['notification'];
    final payload = notification is Map<String, dynamic> ? notification : event;
    final title = payload['title'] as String?;
    final body = payload['body'] as String?;
    if (title == null || title.isEmpty || body == null || body.isEmpty) return;

    await _plugin.show(
      (payload['id'] as String? ?? '$title:$body').hashCode & 0x7fffffff,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'marketplace_updates',
          'Marketplace updates',
          channelDescription: 'Booking, message, and account updates.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

