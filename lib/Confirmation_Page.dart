import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:surf_app_2/homepage.dart';
import 'package:surf_app_2/state_manager.dart';
import 'start_rental2.dart';
import 'qr_scanner.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
 

  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

   // the name of the ardrino
  String deviceName  = "<My Board Name>";
  final List<String> existingList = ['1 board', '2 boards','3 boards', '4 boards']; 

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;


  BluetoothDevice? bluetoothDevice;
  List<int> lockStates = [];
  String? _siteName;
  String? selectedDropDownValue;
  bool? _isConnected = false;
  bool? _connectionFailed = false;
  bool? _tryingToConnect = false; 

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });

    });
    _scanBluetoothDevice();
     myAppState = Provider.of<MyAppState>(context, listen: false);
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  void showReconnectionWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Reconnection Failed"),
          content: Text("Failed to reconnect to the device."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

void bluetoothNotSupportedWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bluetooth is not Supported"),
          content: const Text("Your Device does not support bluetooth. This is required to rent a board."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

//
  void showFailedToFindDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Can't Connect to the Board Wrack", textAlign: TextAlign.center,),
          content: Text("To connect, bluetooth must be enabled and you must be near the board wrack. You can try to reconnect again using the connection button.", textAlign: TextAlign.center,),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK", style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 61, 7, 255)), textAlign: TextAlign.center,),
              ),
            ),
          ],
        );
      },
    );
  }

// warning message when user has not selected a board number to rent.
  void showNoBoardsSelected(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Please select at least one board to rent"),
          content: Text(
              "Use the dropdown to select the number of boards you want to rent.\nNo boards in the wrack? try again later."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

// warning message when user has not selected a board number to rent.
  void showAllBoardsRented(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("I'm sory all the boards are being rented at this time"),
          content: Text("Come back later, most session only last a few hours"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

void _scanBluetoothDevice() async {
  setState(() {
    _tryingToConnect = true;
  });

  if (!await _isBluetoothSupported()) {
    print("Bluetooth not supported by this device");
    bluetoothNotSupportedWarning;
    return;
  }

  //if (await _checkConnectionStatus() || await _scanAndConnectToDevice()) {
  //  await _discoverServices();
  //} else {
  //  showFailedToFindDevice(context);
  //}

  if (await _checkConnectionStatus()){
    _discoverServices();
  } else {
    await _scanAndConnectToDevice();
  }


  if (await _checkConnectionStatus()){
    await _discoverServices();
  } else {

    showFailedToFindDevice(context);

    setState(() {
      _connectionFailed = true;

    });

  }
  setState(() {
    _tryingToConnect = false;
  });
}


Future<bool> _checkConnectionStatus() async {

    // Check if a the device with the ardino name is indeeed connected, and set to bluetooth device to device
    if (FlutterBluePlus.connectedDevices.isNotEmpty && FlutterBluePlus.connectedDevices.any((device) => device.platformName == deviceName)) {
      setState(() {
        bluetoothDevice = FlutterBluePlus.connectedDevices.first;
      });

       setState(() {
      _isConnected = true;
      _connectionFailed = false;
      });
      return true;
    }
    return false;
  }

Future<bool> _isBluetoothSupported() async {
  return await FlutterBluePlus.isSupported;
}

Future<bool> _scanAndConnectToDevice() async {
  await FlutterBluePlus.startScan(
    withNames: ["<My Board Name>"],
    timeout: const Duration(seconds: 5),
  );

  await FlutterBluePlus.isScanning.where((val) => val == false).first;

  List<ScanResult> scanResults = await FlutterBluePlus.scanResults.first;

  if (scanResults.isEmpty) {
    return false;
  }

  await scanResults.first.device.connect();

  setState(() {
    bluetoothDevice = scanResults.first.device;
    _isConnected = true;
    _connectionFailed = false;
  });

  return true;
}

Future<void> _discoverServices() async {
  List<BluetoothService> services = await bluetoothDevice!.discoverServices();

  for (BluetoothService service in services) {
    if (service.uuid.toString() == '180a') {
      await _processCharacteristics(service.characteristics);
      return;
    }
  }
}

Future<void> _processCharacteristics(List<BluetoothCharacteristic> characteristics) async {
  lockStates.clear();
  for (BluetoothCharacteristic c in characteristics) {
    if (c.uuid.toString() == '2a57' || c.uuid.toString() == '2a58'|| c.uuid.toString() == '2a59' || c.uuid.toString() == '2a60') {
      var value = await c.read();
      lockStates.add(value[0] as int);
    } else if (c.uuid.toString() == '2a65') {
      var value = await c.read();
      String decodedString = String.fromCharCodes(value);
      _siteName = decodedString;
    }
  }
}

List<int> generateBoardNumberList(List<int> lockStates) {
   
    return lockStates.where((number) => number == 0).toList();
  }
  
@override
Widget build(BuildContext context) {
  
    if (_adapterState != BluetoothAdapterState.on) {
      // Prompt the user to turn on Bluetooth
      return AlertDialog(
        title: Text('Turn on Bluetooth'),
        content:
            Text('This app requires Bluetooth to operate. Please turn it on.'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Request to enable Bluetooth

              await FlutterBluePlus.turnOn();

              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Turn On'),
          ),
        ],
      );
    } else {
      // Continue with your widget tree

      return Consumer<MyAppState>(
        builder: (context, myAppState, child) {
          return MaterialApp(
            home: Scaffold(
             
              body: buildBody(context, myAppState),
              bottomNavigationBar: buildBottomNavigationBar(context),
              floatingActionButton: buildFloatingActionButton(),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

            ),
          );
        },
      );
    }
  }


PreferredSizeWidget buildAppBar(BuildContext context) {
  return AppBar(
    actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.home),
        tooltip: 'Home',
        onPressed: () {
          if (FlutterBluePlus.connectedDevices.isNotEmpty) {
            FlutterBluePlus.connectedDevices.first.disconnect();
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Surf to Rent'),
            ),
          );
        },
        color: const Color.fromARGB(115, 24, 2, 126),
        iconSize: 35,
      ),
    ],
    backgroundColor: const Color.fromARGB(255, 255, 1, 255),
    title: const Text(
      "Board Selection",
      style: TextStyle(color: Colors.white),
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
              icon: Icon(Icons.home, color: Color.fromARGB(255, 255, 4, 159),size: 35,),
              onPressed: () {

                bluetoothDevice?.disconnect();
                    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
                      FlutterBluePlus.connectedDevices.first.disconnect();
                    }
                    bluetoothDevice?.disconnect();
                    _isConnected = false;
                    _connectionFailed = false;

                // Handle menu button press
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title:'Tidal Drift')),
                  );
              },
            ),
           
            const Spacer(),

            if (myAppState.getLoggedIn() == true)
              IconButton(
                icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 248, 5, 216),size: 35),
                onPressed: () {
                  bluetoothDevice?.disconnect();
                    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
                      FlutterBluePlus.connectedDevices.first.disconnect();
                    }
                    bluetoothDevice?.disconnect();
                    _isConnected = false;
                    _connectionFailed = false;


                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRViewExample()),
                  );
                },
              ),
          ],
        ),
      );
}

Widget buildBody(BuildContext context, MyAppState myAppState) {
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
          image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your image path
          fit: BoxFit.fill, // Adjust the fit as needed
          ),
          ),


        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100.0),
            buildConnectionStatusWidgets(),
            const SizedBox(height: 20.0),
            buildBoardSelectionWidgets2(context, myAppState),
            const SizedBox(height: 10.0),
            buildBoardNumberSelectionWidget(),
            const SizedBox(height: 50),
            //buildActionButtons(context),
          ],
        ),
      ),
    ),
  );
}

Widget buildConnectionStatusWidgets() {
  if (_isConnected == true) {
    return Text(
      _siteName.toString(),
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );
  } 
  
  else if (_isConnected == false && _connectionFailed == false) {
    return const Text(
      'Aquiring Location.....',
      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );

  } else if (_connectionFailed == true && _tryingToConnect == false) {
    return Text(
                        "Connection to the Wrack Failed",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 23, 2, 143),
                            letterSpacing: .1,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
  } 
  
  else {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(width: 200,
            
          ),
        ),
       
      ],
    );
  }
}

Widget buildBoardSelectionWidgets2(BuildContext context, MyAppState myAppState) {
  
    if (_isConnected == true && lockStates.every((element) => element == 1) == false) {

      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
                        "Select Number of Boards",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 23, 2, 143),
                            letterSpacing: .1,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
          )
      ]);

    } else if (_isConnected == true && lockStates.every((element) => element == 1) == true) {
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                        "No Boards Available",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 23, 2, 143),
                            letterSpacing: .1,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
            )
        ]);

    } else if (_isConnected == false && _connectionFailed == false || _tryingToConnect == true){
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 250,
                  child: Column(
                    children: [

                      Text(
                        "Attempting Connection to the Wrack",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 23, 2, 143),
                            letterSpacing: .1,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20,),

                      const CircularProgressIndicator()
                    ],
                  ),
                ),
              )
          ]);
    } else if (_connectionFailed == true && _tryingToConnect == false){
       return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 200,
                  child: Text(
                        "Falied, to connect. Try Reconnecting with the reconnect button",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 23, 2, 143),
                            letterSpacing: .1,
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                ),
              )
          ]);

    }else {
       return const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 200,
                  child: Text(
                    "Try to reconnet using the reconnect button",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center
                  ),
                ),
              )
          ]);




    }
    
    
    }

Widget buildActionButtons(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                bluetoothDevice?.disconnect();
                if (FlutterBluePlus.connectedDevices.isNotEmpty) {
                  FlutterBluePlus.connectedDevices.first.disconnect();
                }
                bluetoothDevice?.disconnect();
                _isConnected = false;
                _connectionFailed = false;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return MyHomePage(title: 'Surf to Rent');
                    },
                  ),
                );
              },
              icon: const Icon(Icons.cancel),
              label: const Text("Go Back!"),
            ),
          ),
        ],
      ),
      Column(
        children: [
          if (_isConnected == true &&
              (lockStates.every((element) => element == 1) != true))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (myAppState.getNumberOfBoardsSelected() != 0) {
                    myAppState.setSiteName(_siteName!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return StartRental();
                        },
                      ),
                    );
                  } else {
                    showNoBoardsSelected(context);
                  }
                },
                icon: const Icon(Icons.done),
                label: const Text("Confirm!"),
              ),
            ),
          if (_isConnected == false && _connectionFailed == false)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.safety_check),
                label: const Text("Not Connected !"),
              ),
            ),
          if (_isConnected == false && _connectionFailed == true)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  _scanBluetoothDevice();
                },
                icon: const Icon(Icons.replay),
                label: const Text("Connect!"),
              ),
            ),
          if (_isConnected == true &&
              lockStates.every((element) => element == 1) == true)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  bluetoothDevice?.disconnect();
                  _isConnected = false;
                  _connectionFailed = false;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return MyHomePage(title: 'Surf to Rent');
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text("Try Again Later"),
              ),
            ),
        ],
      )
    ],
  );
  }

Widget buildBoardNumberSelectionWidget() {
  List<String> boardList = [];
  int numberOfBoards = generateBoardNumberList(lockStates).length;
  
  // Generate boardList
  for (int i = 1; i <= numberOfBoards; i++) {
    boardList.add('$i Board${i > 1 ? 's' : ''}');
  }

  return SizedBox(
    width: 260,
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        isDense: true,
        fillColor: Colors.white
        
      ),
      icon: Icon(Icons.arrow_drop_down),
      iconEnabledColor: Color.fromARGB(255, 14, 30, 179),
      style: GoogleFonts.aBeeZee(
        textStyle: TextStyle(
          color: Colors.blue,
          fontSize: 20,
        ),
      ),
      value: selectedDropDownValue,
      items: boardList.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          selectedDropDownValue = value; // Update the selected value
          //numberOfBoardsSelected = int.parse(value!.split(" ")[0]);
          myAppState.setNumberOfBoardsSelected(
              int.parse(value!.split(" ")[0])); // Parse the selected value to get the number of boards selected
        });
      },
      hint: Text('Select Number of Boards', style: TextStyle(fontSize: 15),),
    ),
  );
}

Widget buildFloatingActionButton() {
  // Add your logic here
  if (_isConnected == true && (lockStates.every((element) => element == 1) != true)) {
    return FloatingActionButton.large(
      onPressed: () {

        if (myAppState.getNumberOfBoardsSelected() != 0) {
                    myAppState.setSiteName(_siteName!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return StartRental();
                        },
                      ),
                    );
                  } else {
                    showNoBoardsSelected(context);
                  }

      },
      child: Icon(Icons.start),
      foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
      backgroundColor: Color.fromARGB(255, 3, 218, 247),
      splashColor: Color.fromARGB(255, 234, 3, 255),
      elevation: 10,
      autofocus: true,
      tooltip: 'Scan The Board Wracks', // You can change the background color as needed
    );
  } 
  
  else if (_isConnected == false && _connectionFailed == false) {

    // Return another widget based on condition2
    return Visibility(
      visible: false,
      child: FloatingActionButton(
        onPressed: () {
          // Add your onPressed action here
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );}

    else if (_isConnected == false && _connectionFailed == true) {
    // Return another widget based on condition2
    return FloatingActionButton.large(
      onPressed: () async {
                  _scanBluetoothDevice();
                },
      child: Icon(Icons.refresh),
      backgroundColor: Color.fromARGB(255, 255, 230, 1),
      
    );

    } else if (_isConnected == true && lockStates.every((element) => element == 1) == true) {
       // Return another widget based on condition2
        return Visibility(
          visible: false,
          child: FloatingActionButton(
            onPressed: () {
              // Add your onPressed action here
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
        );




    }
    
    else {
    // Return a default widget if none of the conditions are met
    return Visibility(
      visible: false,
      child: FloatingActionButton(
        onPressed: () {
          // Add your onPressed action here
        },
        child: Icon(Icons.error),
        backgroundColor: Colors.red,
      ),
    );
  }
}



}

