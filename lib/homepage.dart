import 'dart:ffi';

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'logout.dart';
import 'sessionpage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'end_session.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
// used for internet connection checking
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

    if (myAppState.getEmailAdress() != ''){
        String userEmail =  myAppState.getEmailAdress(); 

       getUserSessions(userEmail); 
    }
   
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


  void getUserSessions(String email) async {

    final ref = FirebaseDatabase.instance.ref().child('Sessions');
    final query = ref.orderByChild('email').equalTo(email);
    final event = await query.once(DatabaseEventType.value);
  
    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      late String mostRecentKey;

    Map<String, int> timestamps = {};


    // Add all other sessions to the allOtherSessions list
    data.forEach((key, value) {
      int startTime = value['start_time'];
      timestamps[key] = startTime;
      print(startTime);
    });

    var mostRecenSession;

    int mostRecentTimestamp = 0;

    timestamps.forEach(
      (key, value) {
        if (value > mostRecentTimestamp) {
          mostRecentTimestamp = value;
          mostRecentKey = key;
          setState(() {});
        }
      },
    );

    if (mostRecenSession != null) {
      mostRecenSession = data[mostRecenSession];
    }

    if (data != null && data is Map) {
      // check if the end time is active, use this to style the cards shown
      if (data[mostRecentKey]['end_time'] == "Active Session") {
        setState(() {
          myAppState.setInSession(true);
        });
      } else {
        setState(() {
          myAppState.setInSession(false);
        });
      }
    }
      // Process the retrieved data...
    } else {
      // Handle case where no data is found
      print('No data found for email: $email');
    }
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    //appBar: buildAppBar(context),
    
    body: buildBody(context),
    bottomNavigationBar: buildBottomNavigationBar(context),
    // Add bottom navigation bar here
    
    floatingActionButton: buildFloatingActionButton(),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
}

Widget buildBody(BuildContext context) {
  return SingleChildScrollView(
    child: Container(
      height: MediaQuery.of(context).size.height+250,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your background image path
          fit: BoxFit.fill,
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          
          
          children: [
            

            const SizedBox(height: 10.0),
            // Add your content widgets here
            
           
            TitleTextWidget(),
            const Divider( // Divider widget to create a solid line
            color: Color.fromARGB(255, 243, 4, 243), // Color of the line
            thickness: 2,
            height:40,
            indent: 30, 
            endIndent: 30,// Thickness of the line
            ),
            //const SizedBox(height: 50.0),
            // Add more content widgets as needed
            buildIntroText(),
          
            const SizedBox(height: 60.0),
            buildSwiper(),
            const SizedBox(height: 10.0),
            // Add additional spacing or widgets
            const SizedBox(height: 30.0),
            // Add more content widgets or spacing
            const SizedBox(height: 50),
          ],
        ),
      ),
    ),
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
            Spacer(),

            if (myAppState.getLoggedIn() == true)
              IconButton(
                icon: Icon(Icons.receipt, color: Color.fromARGB(255, 255, 4, 159),size: 35,),
                onPressed: () {
                  // Handle notifications button press
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SessionPage(title:'Sessions')),
                  );
                },
              ),
            if (myAppState.getLoggedIn() == false && myAppState.getInternetConnected()==true)
              IconButton(
                icon: Icon(Icons.login, color: Color.fromARGB(255, 248, 5, 216),size: 35,),
                onPressed: () {
                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            if (myAppState.getLoggedIn() == true && myAppState.getInternetConnected()==true)
              IconButton(
                icon: Icon(Icons.logout, color: Color.fromARGB(255, 248, 5, 216),size: 35),
                onPressed: () {
                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogoutPage()),
                  );
                },
              ),
          ],
        ),
      );
}

Widget buildIntroText() {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      
      children: [
        if (myAppState.getLoggedIn() == true && myAppState.getInSession() == false)
        SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  TyperAnimatedText(
                      "Welcome ${myAppState.getEmailAdress()}\n\nYour logged in and ready to go! Find the QR code on a board you want and scan it :)",
                      speed: const Duration(milliseconds: 20),
                      textAlign: TextAlign.center,
                      textStyle: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                        color: Color.fromARGB(255, 23, 2, 143),
                        letterSpacing: .2,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        
                      )),
                      
                      
                      
                      
                      )
                ],
                displayFullTextOnTap: true,
               
              )
              ),

        if (myAppState.getLoggedIn() == true && myAppState.getInSession() == true)

          SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  TyperAnimatedText(
                      "Enjoy the waves :), when you're ready to call it a day end the session using the button below or from the My Sessions Tab",
                      speed: const Duration(milliseconds: 20),
                      textAlign: TextAlign.center,
                      textStyle: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                        color: Color.fromARGB(255, 23, 2, 143),
                        letterSpacing: .2,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        
                      )),
                      
                      
                      
                      
                      )
                ],
                displayFullTextOnTap: true,
               
              )
              ),
            
         if (myAppState.getLoggedIn() == false)
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  TyperAnimatedText(
                      "Welcome to where Surfing Meets Innovation!\n\nWith our app, unlock the waves at your fingertips by seamlessly renting boards using your phone\n\nLogin to Get Started",
                      speed: const Duration(milliseconds: 20),
                      textAlign: TextAlign.center,
                      textStyle: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                        color: Color.fromARGB(255, 23, 2, 143),
                        letterSpacing: .2,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        
                      )),
                      
                      
                      
                      
                      )
                ],
                displayFullTextOnTap: true,
               
              )
              ),
             

      ],
    );
  }

Widget buildSwiper(){
    List images =['assets/images/Scan_Board.PNG',
                  'assets/images/Scan_Board.PNG',
                  'assets/images/Scan_Board.PNG',
                  'assets/images/Remove_Board.PNG'
                  ];

    List titles = ['1) Create an Account/Log in', '2) Scan the QR Code','3) Choose the Number Of Boards', '4) Take the Boards'];


    List instructions = ['Using the login icon register an account or login to an existing one',
                         'Once Logged In Scan the QR code on the board rack. ',
                         'Select the Number of Boards you wish to Rent. ',
                         'Confirm the Session, the wrack will unlock the boards. Lift them out and enjoy the surf' ];

     List images2 =['assets/images/Remove_Board.PNG',
                  'assets/images/Scan_Board.PNG',
                  'assets/images/Logging_In.png'
                  'assets/images/Logging_In.png'
                  ];

    List titles2 = ['1) Wrap the leash', '2) Push the Step Plate Down', '3) Insert the Board'];


    List instructions2 = ['Wrap the leash around the bottom of the board above the fins',
                        'Step on any unlocked push plate. Only Unlocked push plates will freely move',
                        'With the Deck of the board facing you and the nose pointing upwards slide the front of the board underneath the top wrack hook and then push the tail into the wrack' ];


  return Column(
    children: [
      SizedBox(
              height: 500,
              child: Container(
                 decoration: const BoxDecoration(
                  color: Color.fromARGB(29, 0, 0, 0)
          
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Swiper(
                    autoplay: true,
                    curve: Curves.elasticOut,
                    duration: 2000,
                   
                    itemBuilder: (BuildContext context, int index) {
                      final image = images[index];
                     
                  
                      return Card(
                        color: Color.fromARGB(255, 255, 255, 255),
                        
                        child: Column(
                          children: [
                        
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                titles[index],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  textStyle: const TextStyle(
                                    color: Color.fromARGB(255, 23, 2, 143),
                                    letterSpacing: .2,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                  
                  
                            Image.asset(
                              image,
                              fit: BoxFit.fill,
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                instructions[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 8, 62, 124),
                                  fontSize: 16
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    itemCount: 4,
                    viewportFraction: 0.7,
                    scale: 0.5,
                    pagination: const SwiperPagination(alignment: Alignment.bottomCenter),
                  ),
                ),
              ),
            ),
    ],
  );


}

Widget buildFloatingActionButton(){

  if (myAppState.getLoggedIn() == true && myAppState.getInSession() == false){
     return
     FloatingActionButton.large(
       onPressed: () {
         // Add your onPressed action here
         Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const QRViewExample()),
                   );
     
       },
       child: Icon(Icons.qr_code),
       foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
       backgroundColor: Color.fromARGB(255, 3, 218, 247),
       splashColor: Color.fromARGB(255, 234, 3, 255),
       elevation: 10,
       autofocus: true,
       tooltip: 'Scan The Board WrackS' // You can change the background color as needed
     );

     
  }else if (myAppState.getLoggedIn() == true && myAppState.getInSession() == true){
    return
     FloatingActionButton.large(
       onPressed: () {
         // Add your onPressed action here
         Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => EndSessionPage(title: 'End Session',)),
                   );
     
       },
       child: Icon(Icons.stop),
       foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
       backgroundColor: Color.fromARGB(255, 255, 187, 0),
       splashColor: Color.fromARGB(255, 234, 3, 255),
       elevation: 10,
       autofocus: true,
       tooltip: 'End Your Session' // You can change the background color as needed
     );

  }
  else {
    return 
    Visibility(
      visible: false,
      child: FloatingActionButton.large(
      
         onPressed: () {
           // Add your onPressed action here
        
         },
         child: Icon(Icons.stop),
         foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
         backgroundColor: Color.fromARGB(255, 255, 187, 0),
         splashColor: Color.fromARGB(255, 234, 3, 255),
         elevation: 10,
         autofocus: true,
         tooltip: 'End Your Session' // You can change the background color as needed
       ),
    );

    
  }




     
  }

void drawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Color.fromARGB(255, 235, 240, 239),
         
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                 if (myAppState.getLoggedIn() == false && myAppState.getInternetConnected()==true)
                 ListTile(
                  leading: Icon(Icons.login,color: Colors.blue),
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
                  title: Text('Logout', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
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


                if (myAppState.getLoggedIn() == true && myAppState.getInternetConnected()==true)
                ListTile(
                  leading: Icon(Icons.receipt,color: Colors.blue),
                  title: Text('Your Sessions',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 1 press
                    Navigator.pop(context);
                  },
                ),
                if (myAppState.getInternetConnected()==true)
                ListTile(
                  leading: Icon(Icons.map_rounded,color: Colors.blue),
                  title: Text('Locations',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 2 press
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.shield,color: Colors.blue),
                  title: Text('Terms and Conditions',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 3 press
                    Navigator.pop(context);
                  },
                ),
                 ListTile(
                  leading: Icon(Icons.lock, color: Colors.blue),
                  title: Text('Private Policy', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
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

class TitleTextWidget extends StatefulWidget {
  @override
  _TitleTextWidgetState createState() => _TitleTextWidgetState();
}

class _TitleTextWidgetState extends State<TitleTextWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(-1.0 ,-0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));

    // Start the animation when the widget is first loaded
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: Text(
            "Tidal Drift",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 245, 1, 253),
                letterSpacing: .2,
                fontSize: 40,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Color.fromARGB(0, 201, 205, 226),
                    offset: Offset(2, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        SlideTransition(
          position: _slideAnimation,
          child: Text(
            "Smart Rentals",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 23, 2, 143),
                letterSpacing: .2,
                fontSize: 25,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}