import 'dart:async';
import 'package:flutter/material.dart';
import 'homepage.dart'; // Replace home_screen.dart with the actual file name for your main screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 4), // Change the duration as needed
      () => Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500), // Adjust the duration of the fade transition
          pageBuilder: (context, animation, secondaryAnimation) => MyHomePage(title: 'Tidal Drift',),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
              child: child,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 31, 220, 253),
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100), // Adjust the value as needed
          child: Image.asset(
            'assets/images/Tidal_Drift_Logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}