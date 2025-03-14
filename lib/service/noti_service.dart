import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vhks/utility/function_support.dart';

class NotiService {
    final notificationPlugin = FlutterLocalNotificationsPlugin();
    bool _isInitialized = false;
    bool get isInitialized => _isInitialized;

    Future<void> initNotification() async {
        if (_isInitialized) return;

        if (await Permission.notification.isDenied) {
            await Permission.notification.request();
        }

        const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettingsIos = DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
        );

        const initSettings = InitializationSettings(
            android: initSettingsAndroid,
            iOS: initSettingsIos,
        );

        await notificationPlugin.initialize(initSettings);
        _isInitialized = true;
    }

    NotificationDetails notificationDetails() {
        return const NotificationDetails(
            android: AndroidNotificationDetails(
                'channelId',
                'Notifications',
                channelDescription: "description",
                importance: Importance.max,
                priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
        );
    }

    // Sử dụng timestamp để tránh trùng ID
    Future<void> showNotification(BuildContext context, {String? title, String? body}) async {
        if (await Permission.notification.isGranted) {
            int id = DateTime.now().millisecondsSinceEpoch.remainder(100000); // Tạo ID duy nhất
            await notificationPlugin.show(id, title, body, notificationDetails());
        } else {
            print("Chưa có quyền hiển thị thông báo.");
            FunctionSupport().showSnackbar(context, "Vui lòng cấp quyền thông báo!", Colors.orangeAccent);
        }
    }
}
