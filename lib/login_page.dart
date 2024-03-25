import 'package:flutter_login/flutter_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'homepage.dart';

class LoginScreen extends StatelessWidget {
   LoginScreen({super.key}); // was a const


  // Load in state class to tell app has logged in!
   //MyAppState myappState = MyAppState();

  //void setLoginStatus(bool newBool) {
  //  bool newValue = newBool;
  //  myappState.userLoggedin(newValue);
  //}

  String _setEmail ='None';

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
     try {

    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: data.name ?? '',
      password: data.password ?? '',
      
    );


      _setEmail = data.name ?? '';
      
    
    // Successfully signed in
    return
    
      null;


  } on FirebaseAuthException catch (e) {
    // Handle specific authentication errors
    if (e.code == 'user-not-found') {
      return 'User not exists';
    } else if (e.code == 'wrong-password') {
      return 'Password does not match';
    } else {
      // Handle other errors
      return 'Error: ${e.message}';
    }
  } catch (e) {
    // Handle generic errors
    return 'Error: ${e.toString()}';
  }
}

  Future<String?> _signupUser(SignupData data) async {
    try {

      // Ensure that email and password are non-nullable
      String email = data.name ?? '';
      String password = data.password ?? '';


      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:email,
        password: password,
      );
     
      return null; // Successfully signed up
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  Future<String> _recoverPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      return 'Check your email for password reset instructions';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  @override
Widget build(BuildContext context) {
  return Consumer<MyAppState>(
    builder: (context, myAppState, child) => FlutterLogin(
     
      //title: 'Welcome',
      
      //logo: const AssetImage('assets/images/Logging_In.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {

       // Setting State
        myAppState.setLoginStatus(true);
        myAppState.setEmailAdress(_setEmail);
        

        // Navigate to the home page or perform any other action after login
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'Surf to Rent'),
        ));
      },
      onRecoverPassword: _recoverPassword,
      theme: LoginTheme(
        primaryColor: Color.fromARGB(255, 14, 34, 100), // Customize primary color
        accentColor: Color.fromARGB(255, 233, 161, 4), // Customize accent color
        errorColor: Colors.red, // Customize error color
        pageColorDark: Color.fromRGBO(2, 253, 241, 1), // Customize dark page color
        pageColorLight: Color.fromARGB(255, 1, 80, 73), // Customize light page color
        titleStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 15
       
        ),cardTheme: CardTheme(
          color: Color.fromARGB(248, 255, 255, 255), // Change the background color of the card
          elevation: 5.0, // Customize elevation
          margin: EdgeInsets.all(15.0), // Customize margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Customize border radius
          ),
        ),
        
        ), 

    ),
  );
}}