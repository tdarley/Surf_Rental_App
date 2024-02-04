import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';



class MyAppState with ChangeNotifier {

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn; // getter for the _logged in

  String  _emailAdress = 'None'; // var to store email adress
  String get emailAdress => _emailAdress;  // getter for emailadress


  String _boardSelection = 'testing'; // Add a variable to store the string value
  String get boardSelection => _boardSelection; // Add a getter for the string value



  // Method for updating the loginStatus
   void setLoginStatus(bool status) {
    _loggedIn = status;
    notifyListeners(); // Notify listeners about the change
    print('User Loggin Set to:$_loggedIn');
   
  }

  // method for updating the emailAdress
   void setEmailAdress(String newValue) {
    _emailAdress = newValue;
    notifyListeners(); // Notify listeners about the change
    print('User Email Set to: $_loggedIn');
   
  }

  // Add a method to update the string value
  void updateStringSelection(String newValue) {
    _boardSelection = newValue;
    notifyListeners();
    print('Current Board Selection: $_boardSelection');

  }

  
  
  // Add this method to get the current board selection
  String getBoardSelection() {
    print('Retrieving Current Board Selection: $_boardSelection');
    return _boardSelection;
  }


  // Method for retrieving the emailAdress
  String getEmailAdress() {
    print('Retrieving Current Email Adress: $_emailAdress');
    return _emailAdress;
  }

  // Method for retrieving the emailAdress



}