import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );

    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  
  static Future<void> showSOSNotification(bool isMalay) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel_id', 
      'Emergency Alerts', 
      channelDescription: 'Notifications for SOS alerts',
      importance: Importance.max, 
      priority: Priority.high,
      enableVibration: true, 
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: isMalay ? '🚨 SOS DIAKTIFKAN!' : '🚨 SOS ACTIVATED!',
      body: isMalay
          ? 'Lokasi anda telah dihantar kepada kenalan kecemasan.'
          : 'Your location has been sent to emergency contacts.',
      notificationDetails: platformDetails,
    );
  }
}