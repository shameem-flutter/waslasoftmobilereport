import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waslasoftreport/screens/homescreen.dart';
import 'package:waslasoftreport/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waslasoft Report',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen1(),
      routes: {
        "/home": (context) => Homescreen(),
        "/login": (context) => LoginScreen1(),
      },
    );
  }
}
