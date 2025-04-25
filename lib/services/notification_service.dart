import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // iOS için izinleri yapılandır
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications'ı yapılandır
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    // iOS ve Android 13+ için bildirim izinlerini iste
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    bool isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
    
    // Sonucu SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bildirimler', isGranted);

    return isGranted;
  }

  Future<bool> getNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('bildirimler') ?? false;
  }

  Future<bool> setNotificationStatus(bool enabled) async {
    if (enabled) {
      bool granted = await requestPermission();
      if (!granted) {
        // İzin verilmediyse, false döndür
        debugPrint('Bildirim izni reddedildi');
        return false;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bildirimler', enabled);
    return true;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Varsayılan Kanal',
      channelDescription: 'Genel bildirimler için varsayılan kanal',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void onTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((token) {
      // Token'ı backend'e gönder
      debugPrint('FCM Token yenilendi: $token');
    });
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> openNotificationSettings() async {
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<AuthorizationStatus> checkPermissionStatus() async {
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<void> enableNotifications() async {
    await setNotificationStatus(true);
  }

  Future<void> disableNotifications() async {
    await setNotificationStatus(false);
  }
} 