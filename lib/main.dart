
import 'package:flutter/material.dart';
import 'package:vhks/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vhks/service/noti_service.dart';

void main() async {
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
