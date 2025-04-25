import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotifications {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> setup() async {
    // Firebase'i başlat
    await Firebase.initializeApp();
    // Bildirim kanallarını oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Kanal ID'si
      'High Importance Notifications', // Kanal adı
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Firebase Messaging izinlerini talep et
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await messaging.subscribeToTopic('bilbakalim');

    // Arka planda bildirimleri yönet
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();

    if (kDebugMode) {
      print("Background message: ${message.messageId}");
      print('Data: ${message.data}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    }
  }
}
