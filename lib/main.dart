import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'start_rental.dart';


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
        // This is the theme of your application.
    
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 2, 55, 80)),
        useMaterial3: true,
      ),
      //home: const MyHomePage(title: 'Surf to Rent',),
       home:  LoginScreen(),

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
    builder: (context, myAppState, child) =>
       Scaffold(
        backgroundColor: Color.fromARGB(255, 244, 245, 231),
        appBar: AppBar(
          actions: <Widget>[
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
            ),
          ],
          backgroundColor: Color.fromARGB(255, 175, 185, 31),
          title: Text(widget.title),
        ),
      
        
      
        body:
         Stack(
           children: [
      
            Align(alignment: Alignment.center,
            
             child:ScanButton(),),
      
             SingleChildScrollView(child: Container(height: 600, child: SwipeCards(),
      
      
             ),
              
      
             ),
      
             
           ],
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

  // duct holds the text and image for each card.
  final List<Map<String, dynamic>> cardList = [
    {
      "text": "1) Scan the boards QR code",
      "imagePath": "assets/images/Scan_Board.PNG",
    },
    {
      "text": "2) Start the Rental",
      "imagePath": "assets/images/Logging_In.png",
    },

    {
      "text": "3) Take the Board Out of the Rack",
      "imagePath": "assets/images/Remove_Board.PNG",
    },

    {
      "text": "4) Go Surf!",
      "imagePath": "assets/images/Go_Surfing.PNG",
    },
    {
      "text": "5) Return the board",
      "imagePath": "assets/images/placeholder.png",
    },
  ];


  late PageController _pageController;
  int currentIndex = 0;
  bool _is_visible = true;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Start a timer to automatically swipe every 3 seconds
    Timer.periodic(Duration(seconds: 4), (Timer timer) {
      if (currentIndex < cardList.length - 1) {
        currentIndex++;
      } else {
        // Reset to the first card when the last card is reached
        currentIndex = 0;
       
      }

      // Animate to the next card
       if (_is_visible) {
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
    return Visibility(
      visible: _is_visible,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: PageView.builder(
          controller: _pageController,
          itemCount: cardList.length,
          itemBuilder: (context, index) {
            return Card(
              color: Color.fromARGB(255, 46, 228, 235),
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: 50, vertical: 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
            
                // Exit button in the top right corner
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          // Handle exit button click
                          setState(() {
                            _is_visible = false;
                          }); }),
                    ),
                        
                        
                   
                  // Title at the top of each card
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      cardList[index]["text"],
                      style: GoogleFonts.indieFlower(
                        textStyle: TextStyle(
                            color: Color.fromARGB(255, 10, 2, 59),
                            letterSpacing: .2,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            
                  SizedBox(height: 30),
            
            
            
                  // Image in the middle
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3, // Adjust the height as needed
                    width: MediaQuery.of(context).size.width * 0.6, // Adjust the width as needed

                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            cardList[index]["imagePath"]), // Replace with your image asset path
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(
                          90), // Adjust the border radius as needed
                    ),
                  ),
            

                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


class ScanButton extends StatefulWidget {
  @override
  _ScanButtonState createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> with SingleTickerProviderStateMixin {
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
         Navigator.push(context,
                  new MaterialPageRoute(builder: (context) => new QRViewExample()),);

      },
      child: Container(
        width: 200.0,
        height: 200.0,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                for (int i = 0; i < 3; i++)
                  _buildPulseRing(i * 0.3, context),
                Center(
                  child: Text(
                    'Start Scanning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
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
              color: const Color.fromARGB(255, 240, 243, 33).withOpacity(maxOpacity - maxOpacity * _controller.value),
              width: 5.0,
            ),
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
