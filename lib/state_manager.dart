import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class MyAppState with ChangeNotifier {

  bool _isConnectedToInternet = false;
  bool get isConnectedToInternet => _isConnectedToInternet;

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn; // getter for the _logged in

  String  _emailAdress = ''; // var to store email adress
  String get emailAdress => _emailAdress;  // getter for emailadress


  String _boardSelection = 'testing'; // Add a variable to store the string value
  String get boardSelection => _boardSelection; // Add a getter for the string value

  bool _boardUnlockingInProgress = false; // Add a variable to store the string value
  bool get boardUnlockingInProgress => _boardUnlockingInProgress; // Add a getter for the string value

  int _numberOfBoardsSelected = 0; //Add variable that holds the number of selected boards
  int get numberOfBoardsSelected => _numberOfBoardsSelected; // Add a getter for the boards selected. 

  
  String _siteName = 'None'; // Add a variable to store the sitename retreived from the the ardruino
  String get sitename=> _siteName; // Add a getter for the string value

  bool _inSession = false;
  bool get inSession => _inSession; 

   // holds the wrack numbers unlocked
  List<String> _rackIDsUnlocked = [];
  List<String> get  rackIDsUnlocked => _rackIDsUnlocked;


  // Method for updating the internet connected
   void setInternetConnected(bool status) {
    _isConnectedToInternet = status;
    notifyListeners(); // Notify listeners about the change
    print('Internet connection set to :$_loggedIn');
   
  }

  // Method for retrieving the emailAdress
  bool getInternetConnected() {
    print('Retrieving Current Internet Connection Status: $_isConnectedToInternet');
    return _isConnectedToInternet;
  }

  

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
    print('User Email Set to: $_emailAdress');
   
  }

  // Add a method to update the string value
  void updateStringSelection(String newValue) {
    _boardSelection = newValue;
    notifyListeners();
    print('Current Board Selection: $_boardSelection');

  }

  // Method for updating the loginStatus
   void setIsUnlockingInProgress(bool status) {
    _boardUnlockingInProgress = status;
    notifyListeners(); // Notify listeners about the change
    print('User is attempting to unlock:$_boardUnlockingInProgress');
   
  }

   // Method for updating the number of boards selected
   void setNumberOfBoardsSelected(int status) {
    _numberOfBoardsSelected = status;
    notifyListeners(); // Notify listeners about the change
    print('User is has set number of boards to :$_numberOfBoardsSelected');
   
  }


   // Add a method to update the siteName value
  void setSiteName(String newValue) {
    _siteName = newValue;
    notifyListeners();
    print('Current Site: $_siteName');

  }

    // Method for updating the loginStatus
   void setInSession(bool status) {
    _inSession = status;
    notifyListeners(); // Notify listeners about the change
    print('In Session Set To:$_inSession');
   
  }

  void addWrackIDNumber(String newValue){

    _rackIDsUnlocked.add(newValue); 
    notifyListeners();
    print("Added Unlocked Warck ID: $_rackIDsUnlocked");

  }

  void clearAllWrackIDNumbers(){
    _rackIDsUnlocked.clear();
     notifyListeners();
    print("Cleared all unlocked IDs: $_rackIDsUnlocked");


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
  bool getLoggedIn() {
    print('Retrieving Current Email Adress: $_loggedIn');
    return _loggedIn;
  }

 
 // Method for retrieving if the user is trying to unlock the wrack
  bool getboardUnlockingInProgress() {
    print('Retrieving boardUnlockingInProgress: $_boardUnlockingInProgress');
    return _boardUnlockingInProgress;
  }

  // method for retreving the number of boards selected by the user
  int getNumberOfBoardsSelected() {
    print('Retrieving number of boards selected: $_numberOfBoardsSelected');
    return _numberOfBoardsSelected;
  }


   // Add this method to get the current board selection
  String getSiteName() {
    print('Retrieving Sitename: $_siteName');
    return _siteName;
  }

     // Add this method to get the current board selection
  bool getInSession() {
    print('Retrieving Sesssion Satus: $_inSession');
    return _inSession;
  }


  List<String> getWrackIDNumbers(){
    print('Retrieving Wrack Id Numbers: $_inSession');
    return _rackIDsUnlocked;

  }



  

}