import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:vhks/screens/home_screen.dart';
import 'package:vhks/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vhks/service/noti_service.dart';
import 'package:vhks/ui/fee_screen.dart';
import 'package:vhks/ui/gps_log_screen.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();

    // Khoi tao thong bao
    NotiService().initNotification();
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'VHK-S',

            supportedLocales: [
                Locale('vi'),
            ],
            localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
                primarySwatch: Colors.blue,
            ),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
        );
    }
}
