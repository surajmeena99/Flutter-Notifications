import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification/features/LocalNotifications/notification_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // Initialize notifications and request permissions
  Future<void> _initializeNotifications() async {
    await NotificationService.checkAndRequestNotificationPermission(context);
  }

  // Show immediate notification
  void _showTestNotification() {
    NotificationService().showNotification(
      id: 0,
      title: 'Hello!',
      body: 'This is an immediate notification',
    );
  }

  // Show scheduled notification for a time in the future
  void _showScheduledNotification() {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    print("Scheduling notification for: $scheduledTime");
    NotificationService().showScheduledNotification(
      id: 1,
      title: 'Scheduled Notification',
      body: 'This notification is scheduled to appear after 5 seconds',
      scheduledTime: scheduledTime,
    );
  }

  // Show periodic notification
  void _showPeriodicNotification() {
    NotificationService().showPeriodicNotification(
      id: 2,
      title: 'Periodic Notification',
      body: 'This notification appears every minute',
    );
  }

  // Cancel specific notification
  void _cancelNotification() {
    NotificationService().cancelNotification(0);
  }

  // Cancel all notifications
  void _cancelAllNotifications() {
    NotificationService().cancelAllNotifications();
  }

  Future<void> writeOnPdf(pw.Document pdf) async {
    // Load the NotoSans font
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final notoSansFont = pw.Font.ttf(fontData);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(
              'My Diary Details',
              textScaleFactor: 2,
              style: pw.TextStyle(font: notoSansFont, fontSize: 24),
            ),
          ),
          pw.Header(
            level: 0,
            child: pw.Text(
              'Diary Description...',
              textScaleFactor: 1,
              style: pw.TextStyle(font: notoSansFont, fontSize: 20),
            ),
          ),

        ];
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notifications Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NotificationService.checkAndRequestNotificationPermission(context);
                _showTestNotification();
              },
              // onPressed: _showTestNotification,
              child: const Text('Show Notification'),
            ),
            ElevatedButton(
              onPressed: _showScheduledNotification,
              child: const Text('Show Scheduled Notification'),
            ),
            ElevatedButton(
              onPressed: _showPeriodicNotification,
              child: const Text('Show Periodic Notification'),
            ),
            ElevatedButton(
              onPressed: _cancelNotification,
              child: const Text('Cancel Notification'),
            ),
            ElevatedButton(
              onPressed: _cancelAllNotifications,
              child: const Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await downloadDiary();
        },
        label: Text(
          "Download PDF",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: Icon(
          Icons.download_rounded,
          color: Colors.white,
          size: 28,
        ),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),

    );
  }

  Future<void> downloadDiary() async {
    try {
      if (Platform.isAndroid) {
        bool hasPermission = await Permission.manageExternalStorage.isGranted;
        if (!hasPermission) {
          var permissionStatus = await Permission.manageExternalStorage.request();
          if (!permissionStatus.isGranted) {
            print('Storage permission is required.');
            return;
          }
        }
      }

      final pdf = pw.Document();
      await writeOnPdf(pdf);
      final Uint8List pdfData = await pdf.save();

      String path = "";
      if (Platform.isIOS) {
        Directory directory = await getApplicationDocumentsDirectory();
        path = directory.path;
      } else {
        String directoryPath = "/storage/emulated/0/Download";
        if (!await Directory(directoryPath).exists()) {
          directoryPath = "/storage/emulated/0/Downloads";
        }
        path = directoryPath;
      }

      if (path.isNotEmpty) {
        String fileName = 'my_diary.pdf';
        String filePath = '$path/$fileName';

        int counter = 1;
        while (await File(filePath).exists()) {
          fileName = 'my_diary($counter).pdf';
          filePath = '$path/$fileName';
          counter++;
        }

        final File file = File(filePath);

        for (int i = 1; i <= 100; i += 20) {
          await NotificationService().showDownloadProgressNotification(i);
          await Future.delayed(Duration(milliseconds: 1000)); // Simulate download time
        }

        await file.writeAsBytes(pdfData);

        if (await file.exists()) {
          await NotificationService().showDownloadCompleteNotification(filePath);
          Fluttertoast.showToast(msg: "File downloaded successfully.");
        }
      } else {
        print("Path not found");
      }
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

}
