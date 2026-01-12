import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
    _initialized = true;
  }

  Future<void> showChatNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await init();
    }
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat messages',
      channelDescription: 'Trip chat updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(id, title, body, details);
  }
}
