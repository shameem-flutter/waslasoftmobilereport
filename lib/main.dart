import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waslasoftreport/screens/homescreen.dart';
import 'package:waslasoftreport/screens/login_screen.dart';
import 'package:waslasoftreport/screens/splashscreen.dart';
import 'package:waslasoftreport/services/api_services/auth_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    final loggedIn = await authService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waslasoft Report',
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isLoggedIn
          ? const SplashScreen()
          : const LoginScreen1(),
      routes: {
        "/home": (context) => const Homescreen(),
        "/login": (context) => const LoginScreen1(),
      },
    );
  }
}
