import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_notification/features/PushNotification/message_screen.dart';
import 'package:flutter_notification/features/PushNotification/order_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(BuildContext context) async {
    // Request permissions
    await _requestPermission();

    // Init local notifications
    await _initLocalNotifications(context);

    // Log token
    final token = await _firebaseMessaging.getToken();
    debugPrint('Device Token: $token');

    saveTokenToFirestore(token!);

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('Token Refreshed: $newToken');
    });

    // Handle foreground
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      print('🟢 Received foreground message: ${message.notification?.title}');
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageNavigation(context, message);
      print('🟠 App opened from background via notification: ${message.messageId}');
    });

    // Handle notification tap when app is terminated
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      _handleMessageNavigation(context, message);
      print('🟡 App opened from terminated state: ${message.messageId}');
    }

    // Foreground notification behavior for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

  }


  Future<void> _initLocalNotifications(BuildContext context) async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Register the notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'FlutterNotifications', // channel ID (must match usage)
      'FlutterNotifications', // channel name
      description: 'Channel Description',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleMessageNavigation(context, payload);
        }
      },
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'FlutterNotifications', // channel ID
      'FlutterNotifications', // channel name
      // message.notification?.android?.channelId ?? 'channel ID',
      // message.notification?.android?.channelId ?? 'channel name',
      channelDescription: 'Channel Description',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('jetsons_doorbell'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No body',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  void _handleMessageNavigation(BuildContext context, dynamic message) {
    Map<String, dynamic> data;

    if (message is RemoteMessage) {
      data = message.data;
    } else if (message is String) {
      data = Uri.splitQueryString(message);
    } else {
      return;
    }

    if (data['type'] == 'sun') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MessageScreen(id: data['id']),
        ),
      );
    }else if (data['type'] == 'order') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OrderScreen(), // Or pass the order ID if needed
        ),
      );
    }

  }

  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  void saveTokenToFirestore(String token) async {
    await FirebaseFirestore.instance.collection('users').doc('UserId_102').set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  } 

}
