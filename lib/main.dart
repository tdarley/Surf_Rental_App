import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:surf_app_2/splash_screen.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'homepage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'Confirmation_Page.dart';
import 'dart:async';
import 'sessionpage.dart';
import 'session_started.dart';
import 'splash_screen.dart';
void main() async {

  // intilise connection to firbase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (Firebase.apps.isNotEmpty) {
    print("Firebase connected successfully!");
  } else {
    print("Error connecting to Firebase.");

  }

  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  // Run app with change notifier allowing state to be set using statemanager
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MaterialApp(
        
        title: 'Flutter Demo',
      
      
        // Change the default theme here
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 254, 66, 127)),
          useMaterial3: true,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Color.fromARGB(255, 247, 245, 217),
         
        ),
        home: SplashScreen(),
        ),
        //home:  LoginScreen(),
         //home:  ConfirmationPage(key: Key('your_key'), title: 'Flutter BLE Demo'),
        //home: SessionPage(title: "Session Page",)
        //home: SessionStartedPage(title: 'Session Started')
      
        //home: StartRental(),
     
    );
  }
}

