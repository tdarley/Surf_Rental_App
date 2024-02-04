import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (Firebase.apps.isNotEmpty) {
    print("Firebase connected successfully!");
  } else {
    print("Error connecting to Firebase.");
  }

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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 254, 66, 127)),

        useMaterial3: true,
        primarySwatch: Colors.blue,
        // Customize the primary color swatch
        // Customize the accent color
        scaffoldBackgroundColor: Color.fromARGB(255, 247, 245, 217),
        // Customize scaffold background color
      ),
      home: const MyHomePage(
        title: 'Surf to Rent',
      ),
      //home:  LoginScreen(),

      //home: StartRental(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, myAppState, child) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          actions: <Widget>[

            // if not logged in show login icon
            if (myAppState.getLoggedIn() == false)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              color: Color.fromARGB(115, 24, 2, 126),
              iconSize: 35,
            ), if (myAppState.getLoggedIn()==true)

              IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'My Sessions',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Placeholder()),
                );
              },
              color: Color.fromARGB(115, 24, 2, 126),
              iconSize: 35,
            ),

              if (myAppState.getLoggedIn()==true)
              IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Placeholder()),
                );
              },
              color: Color.fromARGB(115, 24, 2, 126),
              iconSize: 35,
            ),

          









          ],
          backgroundColor: Color.fromARGB(255, 126, 215, 193),
          title: Text(widget.title),
        ),
        body:

            /// this contains cards and scan button.
            SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Expanded(
                      flex: 1,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.4,
                        child: Text(
                          "Welcome to SurfRent! 🏄‍♂️ Embrace the waves and dive into the ultimate surfing experience.",
                          style: GoogleFonts.indieFlower(
                            textStyle: TextStyle(
                                color: Color.fromARGB(255, 10, 2, 59),
                                letterSpacing: .2,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 300, // Adjust the height as needed
                          child: SwipeCards(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (myAppState.loggedIn == true)
                    ScanButton(),

                    if(myAppState.loggedIn == false)
                   Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return LoginScreen();
                            }),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Color.fromARGB(255, 13, 123, 212), // Change the color to the desired blueish shade
                          minimumSize: Size(200, 60), // Set the minimum width and height
                        ),
                        child: Text(
                          "Login to Get Started",
                          style: TextStyle(color: Colors.white), // Set the text color to white
                        ),
                      ),
                    )
                  ]),
            ],
          ),
        ),
      ),
    );
  }
}

class SwipeCards extends StatefulWidget {
  @override
  _SwipeCardsState createState() => _SwipeCardsState();
}

class _SwipeCardsState extends State<SwipeCards> {
  late PageController _pageController;
  int currentIndex = 0;

  final List<Map<String, dynamic>> cardList = [
    {
      "text": "Step 1: Scan a board's QR code",
      "imagePath": "assets/images/Scan_Board.PNG",
      "description":
          "Each board has a QR Code, use the scan button and scan the board you want to rent"
    },
    {
      "text": "Step 2: Start the Rental",
      "imagePath": "assets/images/Logging_In.png",
      "description":
          "Confirm the selected board and unlock the board from the rack. This is automatic, and the app will let you know once unlocked"
    },
    {
      "text": "Step 3: Take the Board Out of the Rack",
      "imagePath": "assets/images/Remove_Board.PNG",
      "description":
          "Once the board has been unlocked, lift the board out of the rack."
    },
    {
      "text": "Step 4: Go Enjoy the Surf!",
      "imagePath": "assets/images/Go_Surfing.PNG",
      "description":
          "The most important part, go have fun in the waves. The first 10 minutes are free, and there are no time limits."
    },
    {
      "text": "Step 5: Return the board",
      "imagePath": "assets/images/Go_Surfing.PNG",
      "description":
          "When finished, return the board to the rack, and the rental ends"
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Timer.periodic(Duration(seconds: 8), (Timer timer) {
      if (currentIndex < cardList.length - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }

      if (mounted) {
        _pageController.animateToPage(
          currentIndex,
          duration: Duration(milliseconds: 700),
          curve: Curves.ease,
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose the PageController when the widget is disposed
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: PageView.builder(
        controller: _pageController,
        itemCount: cardList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(150, 253, 253, 0),
                    Color.fromARGB(255, 45, 253, 0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(0.0),
                border: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              child: Card(
                color: Color.fromARGB(255, 253, 253, 0),
                elevation: 5,
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                child: Row(
                  children: [
                    _buildTextColumn(context, index),
                    _buildImageColumn(context, index),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextColumn(BuildContext context, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Text(
                cardList[index]["text"],
                style: GoogleFonts.indieFlower(
                  textStyle: TextStyle(
                    color: Color.fromARGB(255, 10, 2, 59),
                    letterSpacing: .2,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            height: MediaQuery.of(context).size.width * 0.3,
            child: Text(
              cardList[index]["description"],
              style: GoogleFonts.indieFlower(
                textStyle: TextStyle(
                  color: Color.fromARGB(255, 10, 2, 59),
                  letterSpacing: .2,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageColumn(BuildContext context, int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 15, width: 15),
        Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.2,
            width: MediaQuery.of(context).size.width * 0.3,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(cardList[index]["imagePath"]),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(90),
            ),
          ),
        ),
      ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}