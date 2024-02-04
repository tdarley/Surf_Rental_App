import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dart:async';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

///Page intiates:
///1)  connection to the ardrino.
///2)  sends start time and other user info to real time db
///3)  unlocks the specifc board chosen

class StartRental extends StatefulWidget {
  final String? selectedBoard;

  StartRental({Key? key, this.selectedBoard}) : super(key: key);

  @override
  State<StartRental> createState() => _StartRentalState();
}

class _StartRentalState extends State<StartRental> {
  /// Connect to the firebase database
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  // HOLDS THE REULTS OF THE SCAN
  List<BluetoothDiscoveryResult> results = [];

  // BLUETOOTH DEVICE ELECTED
  BluetoothDevice? connectedDevice;

  // CONNECTION SET BLUETOOTH DEVICE
  BluetoothConnection? linkedDevice;

 // State of the lock 
  bool isLocked = true;

 // SATE OF THE UNLOCKING PROGRESS
  bool _isUnlocking = false;


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState>(
      builder: (context, myAppState, child) => Scaffold(
        backgroundColor: Color.fromARGB(255, 227, 230, 207),
        
        appBar:AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Login',
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
          backgroundColor: Colors.amber,
          title: Text('Start Rental'),
          
        ),
        body: Center(
         
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Aligns the Column to the top
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [


                  Text(myAppState.getBoardSelection()),


                  
                ],
              ),
              SizedBox(height: 50.0), // Adding some space between the text and the button

            /// This is the button that enttiates session.
             ScanButton()




            ],
          ),
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


  // HOLDS THE REULTS OF THE SCAN
  List<BluetoothDiscoveryResult> results = [];

  // BLUETOOTH DEVICE ELECTED
  BluetoothDevice? connectedDevice;

  // CONNECTION SET BLUETOOTH DEVICE
  BluetoothConnection? linkedDevice;

 // State of the lock 
  bool isLocked = true;

 // SATE OF THE UNLOCKING PROGRESS
  bool _isUnlocking = false;

  late AnimationController _controller;



  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }


/// Permission functions to allow access to bluetooth etc. 
 Future<void> requestBluetoothPermission() async {
    final permission = Permission.bluetooth;

    if (await permission.isDenied) {
      final result = await permission.request();

      if (result.isGranted) {
        print('Bluetooth Permission is Granted!');
        // Permission is granted
      } else if (result.isDenied) {
        // Permission is denied
        print('Bluetooth Permission is denied!');
      } else if (result.isPermanentlyDenied) {
        // Permission is permanently denied
        print('Bluetooth Permission is permanently denied!');
      }
    }
  }

 Future<void> requestBluetoothScanPermission() async {
    final permission = Permission.bluetoothScan;

    if (await permission.isDenied) {
      final result = await permission.request();

      if (result.isGranted) {
        print('Bluetooth Scan Permission is Granted!');
        // Permission is granted
      } else if (result.isDenied) {
        // Permission is denied
        print('Bluetooth Scan Permission is denied!');
      } else if (result.isPermanentlyDenied) {
        // Permission is permanently denied
        print('Bluetooth Scan Permission is permanently denied!');
      }
    }
  }

Future<void> requestBluetoothConnectPermission() async {

    final permission = Permission.bluetoothConnect;

    if (await permission.isDenied) {
      final result = await permission.request();

      if (result.isGranted) {
        print('Bluetooth Scan Permission is Granted!');
        // Permission is granted
      } else if (result.isDenied) {
        // Permission is denied
        print('Bluetooth Scan Permission is denied!');
      } else if (result.isPermanentlyDenied) {
        // Permission is permanently denied
        print('Bluetooth Scan Permission is permanently denied!');
      }
    }else{

      print('$permission');


    }
  }
 
 /// Function that connects and unlocks the board
 Future<void>_connectAndUnlock() async {

    setState(() {
      _isUnlocking = true;
    });


  // Scan for avaialble devices
   var streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          print('result $r');
          if (r.device.name == "HC-06"){
            results.add(r);
            return;
          }
      
    });
    
    streamSubscription.onDone(() async{
      //Do something when the discovery process ends
      print(results);

      for (BluetoothDiscoveryResult result in results) {
      String names = result.device.name.toString();
      print(names);

      if (result.device.name == "HC-06") {
        // Found the device with name "HC-06", connect to it
        BluetoothConnection connection =
            await BluetoothConnection.toAddress(result.device.address);
        print("Connected to HC-06");

        setState(() {
          linkedDevice = connection;
        });

        // Send unlock signal
        try {
          if (linkedDevice != Null) {
            if (linkedDevice!.isConnected == true) {
              linkedDevice?.output.add(utf8.encode('1'));
              print('Unlock command sent!');

              setState(() {
                isLocked = false;
              });

              // Add a delay of 10 seconds
              await Future.delayed(Duration(seconds: 10));



              // Close the connection
              linkedDevice?.close();

               setState(() {
                _isUnlocking = false;
               });

              // Add a delay of 10 seconds

            } else {
              print(" No device connected!");
               setState(() {
      _isUnlocking = false;
    });

            }
          }
        } catch (exception) {
          print('Cannot set lock state');
           setState(() {
      _isUnlocking = false;
    });
        }

        // You can do additional operations after connecting
        return; // Exit the loop after connecting to the first device with name "HC-06"
      }
    }
     setState(() {
      _isUnlocking = false;
    });

    });
  }

/// Function pushes session to firebase real time db
Future<void> addSession(String email, String location, String boardId, String startTime, String endTime) async {

  startTime = TimeOfDay.now().toString();
  endTime = "Active Session";

  final DatabaseReference sessionsRef = FirebaseDatabase.instance.ref().child('Sessions');
  await sessionsRef.push().set({
    'email': email,
    'location': location,
    'board_id': boardId,
    'start_time': startTime,
    'end_time': endTime,
  });
}

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAppState> (
       builder: (context, myAppState, child) =>
      Column(
        children: [
          
          if (_isUnlocking == false && isLocked==true)
          InkWell(
            onTap: () async{
              // Add your scanning logic here
              print('Scanning...');
              await requestBluetoothPermission();
              await requestBluetoothScanPermission();
              await requestBluetoothConnectPermission();
          
              await _connectAndUnlock();
      
      
          
              // Load qr scanner page.
              //Navigator.push(
              //  context,
              //  MaterialPageRoute(builder: (context) => QRViewExample()),
              //);
            },
            child: Container(
              width: 200.0,
              height: 200.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 38, 99, 2),
                  width: 3.0,
                ),
                color: const Color.fromARGB(255, 78, 176, 39),
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
                          'Start Session',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 25,
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
      
           if (_isUnlocking)
                InkWell(
            onTap: () async{
             
            },
            child: Container(
              width: 200.0,
              height: 200.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 255, 196, 1),
                  width: 3.0,
                ),
                color: Color.fromARGB(255, 255, 217, 0),
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
                      for (int i = 0; i < 3; i++) _buildPulseRing2(i * 0.3, context),
                      Center(
                        child: Text(
                          'Unlocking',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 25,
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
      
          if (_isUnlocking == false && isLocked==false)
          InkWell(
            onTap: () async{

            var state_call_for_qr_string = myAppState.getBoardSelection();
             
            String? boardName = state_call_for_qr_string.contains("_") ?? false
                ? state_call_for_qr_string.split('_')[0] + state_call_for_qr_string.split('_')[1]
                : null;


              String? location = state_call_for_qr_string.contains(".")
                  ?? false
                  ? state_call_for_qr_string.split('_')[2].split('.')[0]
                  : null;

              
      
              await addSession( myAppState.getEmailAdress(), location!, boardName!, '00:00:00', '00:00:00');

             
            },
            child: Container(
              width: 200.0,
              height: 200.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 1, 141, 255),
                  width: 3.0,
                ),
                color: Color.fromARGB(255, 38, 0, 255),
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
                      for (int i = 0; i < 3; i++) _buildPulseRing3(i * 0.3, context),
                      Center(
                        child: Text(
                          'Take Board',
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 249, 249),
                            fontSize: 25,
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
          
          
      
            
      
      
      
      
      
        ],
      ),
    );
  }

  Widget _buildPulseRing(double delay, BuildContext context) {
    final double size = 200.0;
    final double maxOpacity = 0.4;

    return 
    Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: 
        Container(
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
                color: Color.fromARGB(255, 104, 255, 4).withOpacity(0.2),
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
 Widget _buildPulseRing2(double delay, BuildContext context) {
    final double size = 200.0;
    final double maxOpacity = 0.4;

    return 
    Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: 
        Container(
          width: size * _controller.value,
          height: size * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              
              color: Color.fromARGB(255, 243, 33, 33)
                  .withOpacity(maxOpacity - maxOpacity * _controller.value),
              width: 6.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 255, 4, 222).withOpacity(0.2),
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
Widget _buildPulseRing3(double delay, BuildContext context) {
    final double size = 200.0;
    final double maxOpacity = 0.4;

    return 
    Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: 
        Container(
          width: size * _controller.value,
          height: size * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              
              color: Color.fromARGB(255, 33, 117, 243)
                  .withOpacity(maxOpacity - maxOpacity * _controller.value),
              width: 6.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 4, 50, 255).withOpacity(0.2),
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



