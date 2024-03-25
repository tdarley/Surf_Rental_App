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


/// NEED TO ADD ANOTHER VIEW TO DETERMIN IF IN A SEESION ALREADY, NOT ALLOWING MORE THAN MONE AT A TIME
/// USE DB CALL TO DETERMINE THIS.

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);





  @override
  void initState() {
    super.initState();
    myAppState = Provider.of<MyAppState>(context, listen: false);
    if (myAppState.getEmailAdress() != ''){
        String userEmail =  myAppState.getEmailAdress(); 

       getUserSessions(userEmail); 
    }
   
  }

  @override
  void dispose() {
    super.dispose();
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

    List images =['assets/images/Remove_Board.PNG',
                  'assets/images/Scan_Board.PNG',
                  'assets/images/Logging_In.png'
                  ];

    List titles = ['1) Wrap the leash', '2) Push the Step Plate Down', '3) Insert the Board'];

    List instructions = ['Wrap the leash around the bottom of the board above the fins',
                        'Step on any unlocked push plate. Only Unlocked push plates will freely move',
                        'With the Deck of the board facing you and the nose pointing upwards slide the front of the board underneath the top wrack hook and then push the tail into the wrack' ];

    return SafeArea(
      child: Consumer<MyAppState>(
        builder: (context, myAppState, child) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: const Text('Surf-Rental', style: TextStyle(color: Colors.white),),  backgroundColor: Color.fromARGB(255, 224, 1, 187),
          ),

          endDrawer: Drawer(
            width: 200,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 100,
                  child: DrawerHeader(
                    child: Text('Menu'),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 126, 215, 193),
                    ),
                  ),
                ),
                if (myAppState.getLoggedIn() == false)
                  ListTile(
                    leading: Icon(Icons.login),
                    title: Text('Login'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                  ),
                if (myAppState.getLoggedIn() == true)
                  ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('My Sessions'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SessionPage(
                            title: 'Sessions Page',
                          ),
                        ),
                      );
                    },
                  ),
                if (myAppState.getLoggedIn() == true)
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LogoutPage()),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          body:
              /// this contains cards and scan button.
            SingleChildScrollView(
  child: Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/Background.jpg"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myAppState.getLoggedIn() == true && myAppState.getInSession() == false)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Expanded(
                  flex: 1,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.4,
                    child: Text(
                      "Welcome ${myAppState.getEmailAdress()}\n\nYour logged in and ready to go! Find the QR code on a board you want and scan it :)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 252, 252, 253),
                          letterSpacing: .2,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (myAppState.getLoggedIn() == true && myAppState.getInSession() == true)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Expanded(
                  flex: 1,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.4,
                    child: Text(
                      "Enjoy the waves :), when you're ready to call it a day end the session using the button below or from the My Sessions Tab",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.indieFlower(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 252, 252, 253),
                          letterSpacing: .2,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (myAppState.getLoggedIn() == false)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Expanded(
                  flex: 1,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    //height: MediaQuery.of(context).size.width * 0.80,
                    child: Text(
                      "Welcome to where Surfing Meets Innovation!\n\nWith our app, unlock the waves at your fingertips by seamlessly connecting your phone via Bluetooth to our smart boards. Embrace the thrill of surfing with ease and convenience like never before.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.architectsDaughter(
                        textStyle: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          letterSpacing: .2,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (myAppState.loggedIn == true && myAppState.getInSession() == false)
              ScanButton(),
            if (myAppState.loggedIn == true && myAppState.getInSession() == true)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return EndSessionPage(title: "End Session");
                      }),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 247, 224, 22), // Change the color to the desired blueish shade
                    minimumSize: Size(200, 60), // Set the minimum width and height
                    elevation: 20,
                  ),
                  child: Text(
                    "End Current Session",
                    style: TextStyle(
                      color: Color.fromARGB(255, 13, 27, 151), // Set the text color to white
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            if (myAppState.loggedIn == false)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return LoginScreen();
                      }),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 5, 239, 247), // Change the color to the desired blueish shade
                    minimumSize: Size(200, 60), // Set the minimum width and height
                  ),
                  child: Text(
                    "Login to Get Started",
                    style: TextStyle(
                      color: Colors.white, // Set the text color to white
                      fontSize: 15,
                    ),
                  ),
                ),
              )
          ],
        ),
        SizedBox(
          height: 420,
          child: Swiper(
            itemBuilder: (BuildContext context, int index) {
              final image = images[index];

              return Card(
                color: Color.fromARGB(255, 174, 243, 62),
                child: Column(
                  children: [
                    Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 3, 71, 148),
                      ),
                    ),
                    Image.asset(
                      image,
                      fit: BoxFit.fill,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        instructions[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 8, 62, 124),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            itemCount: 3,
            viewportFraction: 0.6,
            scale: 0.6,
            pagination: const SwiperPagination(alignment: Alignment.bottomCenter),
          ),
        ),
        SizedBox(height:50)
      ],
    ),
  ),
)
          
         
        ),
      ),
    );
  }
}


class ScanButton extends StatefulWidget {
  @override
  _ScanButtonState createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Add your scanning logic here
        print('Scanning...');

        // Load qr scanner page.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QRViewExample()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          width: 150.0,
          height: 150.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color.fromARGB(255, 99, 2, 94),
              width: 2.0,
            ),
            color: Color.fromARGB(255, 147, 143, 202),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  for (int i = 0; i < 3; i++) _buildPulseRing(i * 0.3, context),
                  Center(
                    child: Text(
                      'Start Scanning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing(double delay, BuildContext context) {
    final double size = 200.0;
    final double maxOpacity = 0.4;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: size * _controller.value,
          height: size * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color.fromARGB(255, 33, 142, 243)
                  .withOpacity(maxOpacity - maxOpacity * _controller.value),
              width: 6.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 18, 42, 148).withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
