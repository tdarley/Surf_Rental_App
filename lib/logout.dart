import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'state_manager.dart'; // Import your state manager class
import 'package:provider/provider.dart';
import 'homepage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
class LogoutPage extends StatefulWidget {
  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {

  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);
  // handling internet connection checks
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    myAppState = Provider.of<MyAppState>(context, listen: false);
    initConnectivity();

    // running internet conncetion stream and checks
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
   
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }


  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status');
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
    print(_connectionStatus);

    if (_connectionStatus == ConnectivityResult.none) {

      setState(() {
        myAppState.setInternetConnected(false);
      });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet Connection'),
          content: Text('This app requires an internet connection please connect'),
          actions: <Widget>[
          
            ElevatedButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  } else {
     setState(() {
        myAppState.setInternetConnected(true);
      });
  }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: Container(
        height: MediaQuery.of(context).size.height+250,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your background image path
          fit: BoxFit.fill)
          ),
        child: Center(
          child: ElevatedButton(

            style: ButtonStyle(
            elevation: MaterialStateProperty.all<double>(10),
            shadowColor: MaterialStateProperty.all<Color>(Colors.black),
            
            backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(255, 255, 136, 1)), // Change the background color
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.all(30.0)), // Increase padding to make the button bigger
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), 
                // Adjust border radius as needed
              ),
            
            
            ),
          ),


            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Sign out the user
              // Access your state manager and update login status
              Provider.of<MyAppState>(context, listen: false).setLoginStatus(false);
              Provider.of<MyAppState>(context, listen: false).setEmailAdress('None');
              Provider.of<MyAppState>(context, listen: false).updateStringSelection('None');
              Provider.of<MyAppState>(context, listen: false).setIsUnlockingInProgress(false);
              Provider.of<MyAppState>(context, listen: false).setInSession(false);
              //Navigator.pop(context);
               Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Home',)),
                    ); // Pop the logout page from the navigation stack
            },
            child: Text('Log Out', style: TextStyle(fontSize: 18, color:Colors.white),),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
  // Define your bottom navigation bar here
  return BottomAppBar(
        color: Color.fromARGB(255, 5, 138, 143),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu, color: Color.fromARGB(255, 255, 4, 159),size: 35,),
              onPressed: () {
                // Handle menu button press
                drawer(context);
              },
            ),
            if (myAppState.getInternetConnected()== true)
            IconButton(
              icon: Icon(Icons.map, color: Color.fromARGB(255, 255, 4, 159),size: 35,),
              onPressed: () {
                // Handle search button press
              },
            ),
            const Spacer(),

            
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 248, 5, 216),size: 35,),
                onPressed: () {
                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home',)),
                  );
                },
              ),
         
          ],
        ),
      );
}

 void drawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromARGB(255, 235, 240, 239),
         
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[

                ListTile(
                  leading: const Icon(Icons.home,color: Colors.blue),
                  title: Text('Home', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 1 press
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home',)),
                    );
                  },
                ),






                 if (myAppState.getLoggedIn() == false && myAppState.getInternetConnected()==true)
                 ListTile(
                  leading: const Icon(Icons.login,color: Colors.blue),
                  title: Text('Login', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 1 press
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
                 if (myAppState.getLoggedIn() == true && myAppState.getInternetConnected()==true)
                 ListTile(
                  leading: Icon(Icons.logout,color: Colors.blue),
                  title: const Text('Logout', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 1 press
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogoutPage()),
                    );
                  },
                ),


                  
                if (myAppState.getInternetConnected()==true)
                ListTile(
                  leading: const Icon(Icons.map_rounded,color: Colors.blue),
                  title: Text('Locations',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 2 press
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield,color: Colors.blue),
                  title: Text('Terms and Conditions',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 3 press
                    Navigator.pop(context);
                  },
                ),
                 ListTile(
                  leading: Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Private Policy', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 6, 7, 6),
                  onTap: () {
                    // Handle option 3 press
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    
    }
}