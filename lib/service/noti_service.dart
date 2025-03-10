import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vhks/utility/function_support.dart';

class NotiService{
    final notificationPlugin = FlutterLocalNotificationsPlugin();

    bool _isInitialized = false;

    bool get isInitialized => _isInitialized;

    // Khoi tao
    Future<void> initNotification() async {
        if(_isInitialized) return;

        // Yêu cầu quyền trên Android 13+
        if (await Permission.notification.isDenied) {
            await Permission.notification.request();
        }

        // khoi tao cai dat cho thong bao android
        const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

        // khoi tao cai dat cho thong bao ios
        const initSettingsIos = DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

        // khoi tao cai dat
        const initSettings = InitializationSettings(
            android: initSettingsAndroid,
            iOS: initSettingsIos,
        );

        await notificationPlugin.initialize(initSettings);
    }

    // Noi dung thong bao
    NotificationDetails notificationDetails(){
        return const NotificationDetails(
            android: AndroidNotificationDetails(
                'channelId',
                'Notifications',
                channelDescription: "description",
                importance: Importance.max,
                priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails()
        );
    }

    // Hien thi thong bao
    Future<void> showNotification(BuildContext context, {int id = 0, String? title, String? body}) async {
        if (await Permission.notification.isGranted) {
            await notificationPlugin.show(id, title, body, notificationDetails());
        } else {
            print("Chưa có quyền hiển thị thông báo.");
            FunctionSupport().showSnackbar(context, "Vui lòng cấp quyền thông báo!", Colors.orangeAccent);
        }
    }

}