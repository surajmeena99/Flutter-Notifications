import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';

class NotificationService {
  // Singleton instance of NotificationService
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize timezones and request permissions
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set India timezone

    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print("Notification payload: ${response.payload}");
          // Open the PDF file if the payload is a file path
          await _openDownloadedFile(response.payload!);
        }
      },
    );

    print("Notification Service initialized.");
    await scheduleDailyNotifications();
  }

  // Show progress notification for download
  Future<void> showDownloadProgressNotification(int progress) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel', // channelId
      'PDF Downloads', // channelName
      channelDescription: 'Shows progress of PDF downloads', // Properly labeled as channelDescription
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      onlyAlertOnce: true, // Only alert on the first notification update
      playSound: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Downloading PDF',
      '$progress% completed',
      platformChannelSpecifics,
    );
  }

// Show notification when download is complete, allowing the user to open the file
  Future<void> showDownloadCompleteNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel', // channelId
      'PDF Downloads', // channelName
      channelDescription: 'Notification for completed PDF downloads', // Properly labeled as channelDescription
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      'Tap to open PDF',
      platformChannelSpecifics,
      payload: filePath, // Pass the file path as payload
    );
  }

  // Open the downloaded file in the device's default PDF reader
  static Future<void> _openDownloadedFile(String filePath) async {
    if (filePath.isNotEmpty) {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        print("Error opening file: ${result.message}");
      }
    }
  }

  static Future<void> checkAndRequestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      print("Notification permission already granted.");
    } else {
      final result = await Permission.notification.request();

      if (result.isGranted) {
        print("Notification permission granted after request.");
      } else {
        _showPermissionDialog(context);
      }
    }
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enable Notifications"),
          content: Text("To receive notifications, please enable them in your app settings."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await openAppSettings(); // Open app settings
              },
              child: Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  Future<void> scheduleDailyNotifications() async {
    print("Scheduling daily notifications.");

    await _scheduleDailyNotificationAtTime(
      0,
      8,  // Morning notification at 08:00 IST
      0,
      'Good Morning',
      'This is your morning notification!',
    );
    await _scheduleDailyNotificationAtTime(
      1,
      14, // Afternoon notification at 12:00 IST
      0,
      'Good Afternoon',
      'This is your afternoon notification!',
    );
    await _scheduleDailyNotificationAtTime(
      2,
      18, // Evening notification at 18:00 IST
      0,
      'Good Evening',
      'This is your evening notification!',
    );

    print("Daily notifications scheduled at fixed times in IST.");
  }

  Future<void> _scheduleDailyNotificationAtTime(int id, int hour, int minute, String title, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("Scheduled notification for $scheduledDate with ID: $id, Title: $title");

    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      sound: 'notification_sound.wav',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("Notification scheduled for $scheduledDate with ID: $id, Title: $title");
  }

  // Basic Notification with Sound
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Sound file without extension
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      sound: 'notification_sound.wav',  // Include extension for iOS
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Scheduled Notification with Sound
  Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Request permission for notifications
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.notification.isGranted || await Permission.notification.isLimited) {
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      print("Scheduled time in TZ: $tzScheduledTime");

      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'), // Sound file without extension
      );

      const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        sound: 'notification_sound.wav', // Include extension for iOS
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("Notification scheduled successfully!");
    } else {
      print('Permission for notifications not granted.');
    }
  }

  // Periodic Notification with Sound
  Future<void> showPeriodicNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Sound file without extension
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      sound: 'notification_sound.wav', // Include extension for iOS
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.everyMinute, // You can customize this interval
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
