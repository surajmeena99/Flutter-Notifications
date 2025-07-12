import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification/features/LocalNotifications/notification_screen.dart';
import 'package:flutter_notification/features/PushNotification/notification_services.dart';
import 'package:flutter_notification/features/PushNotification/order_screen.dart';
import 'package:flutter_notification/features/ticket/views/admin/admin_user_list_screen.dart';
import 'package:flutter_notification/features/ticket/views/user/ticket_dashboard_screen.dart';

import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    NotificationService().init(context);
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Notifications App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async{
                  await sendNotifications();
                },
                child: Text('Send Notifications')
              ),
              ElevatedButton(
                  onPressed: () async{
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => OrderScreen()));
                  },
                  child: Text('Order List')
              ),
              ElevatedButton(
                  onPressed: () async{
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => NotificationScreen()));
                  },
                  child: Text('Local Notification Screen')
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () async{
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserListScreen()));
                      },
                      child: Text('Admin')
                  ),
                  ElevatedButton(
                      onPressed: () async{
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDashboardScreen(userId: 'Sun1999',)));
                      },
                      child: Text('User')
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> sendNotifications() async {
    // send notification from one device to another
    NotificationService().getDeviceToken().then((value)async{

      var data = {
        'to' : value.toString(),
        'notification' : {
          'title' : 'Suraj' ,
          'body' : 'Hello Meena' ,
          "sound": "jetsons_doorbell.mp3"
        },
        'android': {
          'notification': {
            'notification_count': 10,
          },
        },
        'data' : {
          'type' : 'sun' ,
          'id' : '99'
        }
      };

      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          body: jsonEncode(data) ,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization' : 'key=AAAAp9pXDFM:APA91bGhBeMCUABE2PXjl9UqodAZ2WdV_UI6PoiwdCzYaT8KeZmBKZszc01CD1GgN0OAJ1w3sNw9IVISyKhrrxQLASHizenGJUr2hjzoPjbjFu0HAx1CTk0l8Ut95ZENAQyRKm6hrltV'
          }
      ).then((value){
        if (kDebugMode) {
          print(value.body.toString());
        }
      }).onError((error, stackTrace){
        if (kDebugMode) {
          print(error);
        }
      });
    });
  }
  
}