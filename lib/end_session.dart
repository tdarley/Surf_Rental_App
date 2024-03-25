import 'package:flutter/material.dart';
import 'state_manager.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'homepage.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:rxdart/rxdart.dart';
import 'login_page.dart';
import 'logout.dart';
import 'sessionpage.dart';
import 'package:google_fonts/google_fonts.dart';
// used for internet connection checking
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EndSessionPage extends StatefulWidget {
  final String title;

  EndSessionPage({required this.title});

  @override
  State<EndSessionPage> createState() => _EndSessionPageState();
}

class _EndSessionPageState extends State<EndSessionPage> {
  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

   // handling internet connection checks
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  String deviceName = "<My Board Name>";

  // holds the active session data
  String? location;
  int? bordnum;
  // ignore: non_constant_identifier_names
  int? start_time;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  bool _tryingToConnect = false;
  BluetoothDevice? bluetoothDevice;

  BluetoothCharacteristic? lock1;
  BluetoothCharacteristic? lock2;

  List<int> lockStates = [];

  // number of sensors needed to be on to end the session
  int? totalSensorsRequired;

  // Declare a list to hold subscriptions
  List<StreamSubscription> _subscriptions = [];

  // dict that holds all lock characterisitc
  Map<String, BluetoothCharacteristic?> lockCharacteristicDict = {
    'lock_char_1': null,
    'lock_char_2': null,
    'lock_char_3': null,
    'lock_char_4': null,
    //add as required
  };

  // dict that holds all lock characterisitc
  Map<String, BluetoothCharacteristic?> sensorCharacteristicDict = {
    'sensor_char_1': null,
    'sensor_char_2': null,
    'sensor_char_3': null,
    'sensor_char_4': null,
    //add as required
  };

  // dict that holds all lock values updated by stream
  Map<String, int?> lockValuesDict = {
    'lock_value_1': null,
    'lock_value_2': null,
    'lock_value_3': null,
    'lock_value_4': null,
    //add as required
  };

    // dict that holds all lock values on load only
  Map<String, int?> lockValuesDictInitial = {
    'lock_value_1': null,
    'lock_value_2': null,
    'lock_value_3': null,
    'lock_value_4': null,
    //add as required
  };


  // dict that holds all sensor values from stream
  Map<String, int?> sensorValuesDict = {
    'sensor_value_1': null,
    'sensor_value_2': null,
    'sensor_value_3': null,
    'sensor_value_4': null,
    //add as required
  };

    // dict that holds all senor values on load only
  Map<String, int?> sensorValuesDictInitial = {
    'sensor_value_1': null,
    'sensor_value_2': null,
    'sensor_value_3': null,
    'sensor_value_4': null,
    //add as required
  };

  int? lock1State;
  int? lock1MagnetConnected;

  int? lock2State;
  int? lock2MagnetConnected;

  int? lock3State;
  int? lock3MagnetConnected;

  int? lock4State;
  int? lock4MagnetConnected;

  // holds picked rackvalues or locknames that must have the sensor on to end session
  List<String>? selectedKeysWithValueOne;

  // use this for the end session button logic. Holds e.g sensor_value_1, sensor_value_2 etc.
  List<String> selectedSensorNamesNeedtoBeOn =[];
  String humanReadableSensorNamesToBeOn ='';

  bool boardsAreInTheWrack = false;

  String? sessionKey;

  String? _siteName;

  String? selectedDropDownValue;

  bool? _isConnected = false;
  bool? _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();

    // running internet conncetion stream and checks
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);



    myAppState = Provider.of<MyAppState>(context, listen: false);
    if (myAppState.getEmailAdress() != '') {
      String userEmail = myAppState.getEmailAdress();
      getUserSessions(userEmail);
    }
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });





    _scanBluetoothDevice();

   
  }
   
  @override
  void dispose() async{
    super.dispose();
    // Cancel all subscriptions
    _subscriptions.forEach((subscription) {
      subscription.cancel();
      
    });
     _subscriptions.clear(); 

    bluetoothDevice?.disconnect();
    await FlutterBluePlus.connectedDevices.first.disconnect();
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


  // get the number of boards from AWS -DONE 
  // read the boards lock and senor states store initial values 
  // calculate the number of sesors that need to be showing board in position to finish the session
  // if that number matches number of boards in position then enable end session

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
          content: const Text(
              "Your Device does not support bluetooth. This is required to rent a board."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
              //hbbhb
              
            ),
          ],
        );
      },
    );
  }

  void showFailedToFindDevice(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("We Cannot comunicate with the Board Wrack"),
          content: Text("Are you standing near it?"),
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

  void generalLogicFail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Someting with the logic failed"),
          content: Text("Try Refreshing the page"),
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

  void getUserSessions(String email) async {
    final ref = FirebaseDatabase.instance.ref().child('Sessions');
    final query =
        ref.orderByChild('email').equalTo(myAppState.getEmailAdress());
    final event = await query.once(DatabaseEventType.value);
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

        location = data[mostRecentKey]['location'];
        bordnum = data[mostRecentKey]['board_num'];
        start_time = data[mostRecentKey]['start_time'];
        sessionKey = mostRecentKey;

        setState(() {});
      } else {
        setState(() {
          myAppState.setInSession(false);
        });
      }
    }
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

    if (await _checkConnectionStatus()) {
      _discoverServices();
    } else {
      await _scanAndConnectToDevice();
    }

    if (await _checkConnectionStatus()) {
      await _discoverServices();

      // add null handler here

      // read the initial values of the locks and sensors - no error handling yet. 
      await readLockStatus( lockCharacteristicDict['lock_char_1']!, 'lock_value_1');
      await readLockStatus( lockCharacteristicDict['lock_char_2']!, 'lock_value_2');
      await readLockStatus( lockCharacteristicDict['lock_char_3']!, 'lock_value_3');
      await readLockStatus( lockCharacteristicDict['lock_char_4']!, 'lock_value_4');

      await readSensorStatus( sensorCharacteristicDict['sensor_char_1']!, 'sensor_value_1');
      await readSensorStatus( sensorCharacteristicDict['sensor_char_2']!, 'sensor_value_2');
      await readSensorStatus( sensorCharacteristicDict['sensor_char_3']!, 'sensor_value_3');
      await readSensorStatus( sensorCharacteristicDict['sensor_char_4']!, 'sensor_value_4');
      calculateNumberOfSensorsToBeOn();

      await setUpSenorCharacteriticListener(
          sensorCharacteristicDict['sensor_char_1']!, 'sensor_value_1');
      await setUpSenorCharacteriticListener(
          sensorCharacteristicDict['sensor_char_2']!, 'sensor_value_2');

      await setUpSenorCharacteriticListener(
          sensorCharacteristicDict['sensor_char_3']!, 'sensor_value_3');
      await setUpSenorCharacteriticListener(
          sensorCharacteristicDict['sensor_char_4']!, 'sensor_value_4');

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
    if (FlutterBluePlus.connectedDevices.isNotEmpty &&
        FlutterBluePlus.connectedDevices
            .any((device) => device.platformName == deviceName)) {
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
      withNames: [deviceName],
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

  Future<void> _processCharacteristics(
      List<BluetoothCharacteristic> characteristics) async {
    for (BluetoothCharacteristic c in characteristics) {
      // get the lock services and current values
      if (c.uuid.toString() == '2a57') {
        lockCharacteristicDict['lock_char_1'] = c;
      } else if (c.uuid.toString() == '2a58') {
        lockCharacteristicDict['lock_char_2'] = c;
      }  else if (c.uuid.toString() == '2a59') {
        lockCharacteristicDict['lock_char_3'] = c;
      }  else if (c.uuid.toString() == '2a60') {
        lockCharacteristicDict['lock_char_4'] = c;
      }

      // get the magnetic lock characteristics
      else if (c.uuid.toString() == '2a61') {
        sensorCharacteristicDict['sensor_char_1'] = c;
      } else if (c.uuid.toString() == '2a62') {
        sensorCharacteristicDict['sensor_char_2'] = c;
      } else if (c.uuid.toString() == '2a63') {
        sensorCharacteristicDict['sensor_char_3'] = c;
      } else if (c.uuid.toString() == '2a64') {
        sensorCharacteristicDict['sensor_char_4'] = c;
      }
    }
  }

  Future<void> readLockStatus(BluetoothCharacteristic lockCharacteristic, String lockKeyName) async {

     List<int> value = await lockCharacteristic.read();
      
       setState(() {
          lockValuesDictInitial[lockKeyName] = value.isNotEmpty ? value[0] : null;
       });
  }

  Future<void> readSensorStatus(BluetoothCharacteristic sensorCharacteristic, String sensorKeyName) async {
    
     List<int> value = await sensorCharacteristic.read();
      
       setState(() {
          sensorValuesDictInitial[sensorKeyName] = value.isNotEmpty ? value[0] : null;
       });
  }

  Future<void> calculateNumberOfSensorsToBeOn() async {
    // we need to actually assign a which sensors need to be on.
    int? numberBoardsRented = bordnum;
    List<String> keysWithValueOne = [];

    lockValuesDictInitial.forEach((key, value) {
      if (value == 1) {
        keysWithValueOne.add(key);
      }
    });
    
    if (numberBoardsRented != null) {
      if (numberBoardsRented <= keysWithValueOne.length) {
         //`selectedKeysWithValueOne` will contain the keys from `keysWithValueOne`
        // up to the number specified by `numberBoardsRented`.

        setState(() {
            selectedKeysWithValueOne = keysWithValueOne.sublist(0, numberBoardsRented);
        });
      
      if (selectedKeysWithValueOne != null){
         if (selectedKeysWithValueOne!.isNotEmpty){

            for (String keyName in selectedKeysWithValueOne!) {

              if (keyName.contains('1')){

                setState(() {
                  selectedSensorNamesNeedtoBeOn.add("sensor_value_1");
                });

              } else if (keyName.contains('2')){

                
                setState(() {
                  selectedSensorNamesNeedtoBeOn.add("sensor_value_2");
                });

              } else if (keyName.contains('3')){

                
                setState(() {
                  selectedSensorNamesNeedtoBeOn.add("sensor_value_3");
                });


              } else if (keyName.contains('4')){

                
                setState(() {
                  selectedSensorNamesNeedtoBeOn.add("sensor_value_4");
                });

              }


                }
          // Creating human readable names to be displayed for each slot to have a sensor on.       
          makeHumanReadableWrackNumbers();


         } else {
            print("selectedKeysWithValueOne is empty!");
            generalLogicFail(context);

        }     

      } else {

        print("selectedKeysWithValueOne is empty!!!");
        generalLogicFail(context);
        }
        
      } else {
        print("Number of boards is greater than the number of unlocked locks");
        generalLogicFail(context);

      }
     
   } else {
      print("No boards rented"); 
      generalLogicFail(context);
   }
     
}

  Future<void> setUpSenorCharacteriticListener(BluetoothCharacteristic sensorCharacteristic,String sensorCharNumber,) async {
    _subscriptions.clear();
    // Set up a listener for the characteristic
    sensorCharacteristic.setNotifyValue(true).then((value) {
      // Listen for data received from the characteristic
      StreamSubscription subscription =
          sensorCharacteristic.lastValueStream.listen((data) {
        // Compare the new data with the existing data
        if (sensorValuesDict[sensorCharNumber] != data[0]) {
          print('Received data: $data');
          // Update the state only when there is a change
          setState(() {
            sensorValuesDict[sensorCharNumber] = data[0];
          });
        }
      });
      _subscriptions.add(subscription);
    }).catchError((error) {
      // Handle errors, if any
      print('Error setting up characteristic listener: $error');
    });
}

Future<void> cancelSubscriptions() async {
  for (var subscription in _subscriptions) {
    subscription.cancel(); // Cancel each subscription
  }
  _subscriptions.clear(); // Clear the list after cancelling subscriptions
}

  Future<void>checkEndSessionReady()async{
    // function checks if the named locks sensor values are on

    bool allValuesEqualToOne = true; // Flag to keep track of all values being equal to 1

    // Loop through each key in the list
    for (String keyName in selectedSensorNamesNeedtoBeOn) {
      // Check if the value associated with the key is not equal to 1
      if (sensorValuesDict[keyName] != 1) {
        // If any value is not equal to 1, set the flag to false and break out of the loop
        allValuesEqualToOne = false;
        break;
      }
    }

        // Check the flag to determine if all values were equal to 1
    if (allValuesEqualToOne) {
      print('All values are equal to 1');
      setState(() {
        boardsAreInTheWrack = true;
      });

    } else {
      print('Not all values are equal to 1');
      setState(() {
        boardsAreInTheWrack = false;
      });
    }
  }

  Future<void>makeHumanReadableWrackNumbers() async{
     List<String> formattedNames = [];
     String newName ='';

     int numberOfSlots = 0;
    /// Function formats the selectedSensorNamesNeedtoBeOn  list to readabale string. 
    for (String sensorName in selectedSensorNamesNeedtoBeOn){

        if (sensorName.contains('1')){
          formattedNames.add('Slot 1') ;
          numberOfSlots +=1;
        }else if (sensorName.contains('2')){
          formattedNames.add('Slot 2') ;
          numberOfSlots +=1;

        }else if (sensorName.contains('3')){
          formattedNames.add('Slot 3') ;
          numberOfSlots +=1;

        }else if (sensorName.contains('4')){
          formattedNames.add('Slot 4') ;
          numberOfSlots +=1;

        }

    }

    // Join formatted names into a single string
     String result = formattedNames.join(', ');

    // Handle the case where there are multiple slots
    if (formattedNames.length > 1) {
      int lastCommaIndex = result.lastIndexOf(', ');
      if (lastCommaIndex != -1) {
        result = result.replaceRange(lastCommaIndex, lastCommaIndex + 2, ' and ');
      }
      
    }
    setState(() {
      humanReadableSensorNamesToBeOn =result;
      
    });
    


  }
 
  Future<void> endSession() async {
    bool success = false;
    int retries = 3; // Number of retries
    
    // Lock the locks before ending the session
    await lockLocks();
    
    if (sessionKey != null) {
      while (retries > 0 && !success) {
        try {
          // Get a reference to the session in the Firebase database
          DatabaseReference sessionRef =
              FirebaseDatabase.instance.ref().child('Sessions').child(sessionKey!);
    
          // Update the "end_time" field with the current time
          await sessionRef.update({
            'end_time': ServerValue.timestamp, // Use milliseconds since epoch for the current time
          });
    
          print('Session ended successfully.');
          success = true;
        } catch (error) {
          print('Error ending session: $error');
          retries--; // Decrement retries
          if (retries > 0) {
            print('Retrying...');
            await Future.delayed(Duration(seconds: 2)); // Wait before retrying
          } else {
            // Handle any errors that occur during the process
            // ignore: use_build_context_synchronously
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: const Text('Failed to end session. Please try again later.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    }
    
    if (success) {
      myAppState.setInSession(false);
      FlutterBluePlus.connectedDevices.first.disconnect();
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Tidal Drift')),
    );
  }
}

Future<void> lockLocks() async {
 

  for (String sensorName in selectedSensorNamesNeedtoBeOn) {
    if (sensorName == 'sensor_value_1') {
      await lockLock('lock_char_1');
    } else if (sensorName == 'sensor_value_2') {
      await lockLock('lock_char_2');
    } else if (sensorName == 'sensor_value_3') {
      await lockLock('lock_char_3');
    } else if (sensorName == 'sensor_value_4') {
      await lockLock('lock_char_4');
    }
  }
}

Future<void> lockLock(String lockCharKey) async {
  BluetoothCharacteristic? lockTarget = lockCharacteristicDict[lockCharKey];
  if (lockTarget != null) {
    try {
      await lockTarget.write([0]);
      await Future.delayed(Duration(seconds: 2));
      print('Lock signal sent to $lockCharKey');
    } catch (e) {
      print('Failed to lock $lockCharKey after write!');
    }

     List<int> value = await lockTarget.read();lockTarget.read();

     print(value);
  }
  // Add a delay between each lock
  await Future.delayed(Duration(seconds: 1));
}


  @override
  Widget build(BuildContext context) {
    checkEndSessionReady();
    return Scaffold(
      
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
      floatingActionButton: buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


    );
  }

  PreferredSizeWidget buildAppBar(BuildContext context) {
    return AppBar(
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyHomePage(
                  title: 'Surf to Rent',
                ),
              ),
            );
          },
          color: const Color.fromARGB(115, 24, 2, 126),
          iconSize: 35,
        ),
      ],
      backgroundColor: const Color.fromARGB(255, 255, 1, 255),
      title: const Text(
        "Finish Session",
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

           
              IconButton(
                icon: Icon(Icons.home, color: Color.fromARGB(255, 248, 5, 216),size: 35),
                onPressed: () {
                  // Handle settings button press
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home',)),
                  );
                },
              ),
          ],
        ),
      );
}

  Widget buildBody(BuildContext context) {

    
    return SingleChildScrollView(
      
      child: Container(
        height: 800,
         decoration: const BoxDecoration(
              color: Color.fromARGB(255, 140, 203, 240),
               image: DecorationImage(
          image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your background image path
          fit: BoxFit.fill,
         )),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
               
                const SizedBox(height: 10.0),
                buildHeaderTextWidgets(context),
                const SizedBox(height: 20.0),
                buildStatusMessages(),

                //buildSwiperWidget(),
                const SizedBox(height: 50.0),
                buildBoardWrackWidget(),
                const SizedBox(height: 30.0),
                //buildEndSessionButton(context),
                const SizedBox(height: 50),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeaderTextWidgets(context) {
    if (_tryingToConnect == true){
      return  Text(
            "Connecting to the Wrack..",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 5, 6, 87),
                letterSpacing: .2,
                fontSize: 18,
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
          );
    } else if (_connectionFailed!= true ) {
      return 

        Text(
            "We hope you had a good time in the waves, place you boards in any green slot.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 5, 6, 87),
                letterSpacing: .2,
                fontSize: 18,
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
          );
    } else {
      return(Text(''));
    }
    
  }

  Widget buildSwiperWidget() {
    List<String> images = [
      'assets/images/Remove_Board.PNG',
      'assets/images/Scan_Board.PNG',
      'assets/images/Logging_In.png'
    ];

    List<String> titles = [
      '1) Wrap the leash',
      '2) Push the Step Plate Down',
      '3) Insert the Board'
    ];

    List<String> instructions = [
      'Wrap the leash around the bottom of the board above the fins',
      'Step on any unlocked push plate. Only Unlocked push plates will freely move',
      'With the Deck of the board facing you and the nose pointing upwards slide the front of the board underneath the top wrack hook and then push the tail into the wrack'
    ];

    return SizedBox(
      height: 420,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          final image = images[index];

          return Card(
            color: const Color.fromARGB(255, 174, 243, 62),
            child: Column(
              children: [
                Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                    style: const TextStyle(
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
    );
  }

  Widget buildBoardWrackWidget() {
    return Container(
      decoration: BoxDecoration(
                color: Color.fromARGB(230, 236, 235, 232),
                borderRadius:
                    BorderRadius.circular(20), // Adjust the radius as needed
              ),



      child: Column(
        children: [
          
          Container(
              height: 200,
              width: 300,
              decoration: BoxDecoration(
                color: Color.fromARGB(230, 236, 235, 232),
                borderRadius:
                    BorderRadius.circular(20), // Adjust the radius as needed
              ),
              child: Stack(
                children: [

                  if (_tryingToConnect == true)
                  Positioned(
                      left: 140,
                      top: 60,
                     
                      child: Container(child:const CircularProgressIndicator())),

                Positioned(
                      
                      left: 35,
                      top: 15,
                      bottom: 0,
                      child: Visibility(
                          visible: sensorValuesDict['sensor_value_1'] == 1,
                          child: Container(
                            decoration: BoxDecoration(
                            color: selectedSensorNamesNeedtoBeOn.contains('sensor_value_1')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_1'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                                            borderRadius:
                                            BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              topRight: Radius.circular(20),


                            ), // Adjust the radius as needed
                            ),
                              
                            height: 150,
                            width: 20,
                              ))),
              
                  Positioned(
                      
                      left: 100,
                      top: 15,
                      bottom: 0,
                      child: Visibility(
                          visible: sensorValuesDict['sensor_value_2'] == 1,
                          child: Container(
                            decoration: BoxDecoration(
                            color: selectedSensorNamesNeedtoBeOn.contains('sensor_value_2')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_2'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                            borderRadius:
                             BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),


                            ), // Adjust the radius as needed
                            ),
                              
                            height: 150,
                            width: 20,
                              ))),
                


                  Positioned(
                      
                      right: 100,
                      top: 15,
                      bottom: 0,
                      child: Visibility(
                          visible: sensorValuesDict['sensor_value_3'] == 1,
                          child: Container(
                            decoration: BoxDecoration(
                            color: selectedSensorNamesNeedtoBeOn.contains('sensor_value_3')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_3'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                            borderRadius:
                             BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),


                            ), // Adjust the radius as needed
                            ),
                              
                            height: 150,
                            width: 20,
                              ))),

                  Positioned(
                      
                      right: 25,
                      top: 15,
                      bottom: 0,
                      child: Visibility(
                          visible: sensorValuesDict['sensor_value_4'] == 1,
                          child: Container(
                            decoration: BoxDecoration(
                            color: selectedSensorNamesNeedtoBeOn.contains('sensor_value_4')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_4'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                            borderRadius:
                             BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),


                            ), // Adjust the radius as needed
                            ),
                              
                            height: 150,
                            width: 20,
                              ))),           
                  
                ],
              )),
          Container(
            height: 80,
            width: 300,
           
            decoration: BoxDecoration(
                color: Color.fromARGB(230, 9, 157, 243),
                borderRadius:
                    BorderRadius.circular(20), // Adjust the radius as needed
              ),
            child: Column(
              children: [
      
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  
                  
                  children: [
      
                    Text('Slot 1',style: TextStyle(color: Colors.white),),
                    Text('Slot 2',style: TextStyle(color: Colors.white)),
                    Text('Slot 3',style: TextStyle(color: Colors.white)),
                    Text('Slot 4',style: TextStyle(color: Colors.white)),
                    
      
      
                ],),
                SizedBox(height:5),

                // the lock circle markers
      
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                    radius: 20,
                    backgroundColor: selectedSensorNamesNeedtoBeOn.contains('sensor_value_1')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_1'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                                          
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: selectedSensorNamesNeedtoBeOn.contains('sensor_value_2')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_2'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: selectedSensorNamesNeedtoBeOn.contains('sensor_value_3')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_3'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: selectedSensorNamesNeedtoBeOn.contains('sensor_value_4')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : lockValuesDictInitial['lock_value_4'] == 1
                                ? Color.fromARGB(255, 12, 75, 247) // Green color when lock_value_1 is 1
                                : Color.fromARGB(255, 240, 6, 6), // Red color when lock_value_1 is not 1
                  ),
                  
                
                  ],

                  
              
                ),
               
              ],
            ),
          ),
        ],
      ),
      
    );
    
  }

  Widget buildEndSessionButton(context) {
  
    if (_tryingToConnect == true){
      return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 48, 69, 255),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      child: const Text(
        "Connecting",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );
    }
  else if (_tryingToConnect == false && (boardsAreInTheWrack ==false)){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 48, 69, 255),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      child: const Text(
        "Insert Boards",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );

  }
  else if (_tryingToConnect == false && (boardsAreInTheWrack ==true)){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 48, 69, 255),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      child: const Text(
        "End Session",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );

  }
  
  else{
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 48, 69, 255),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      child: const Text(
        "Waiting",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );



  }
    
  }

  Widget buildStatusMessages(){
    if (_tryingToConnect == true && _connectionFailed!=false) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Text(
            "Attempting to connect to the wrack",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 0, 255),
                letterSpacing: .2,
                fontSize: 18,
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
          ),);

  } else if (_tryingToConnect == false && boardsAreInTheWrack ==false && _connectionFailed!=true){
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Text(
            "Insert your boards into ${humanReadableSensorNamesToBeOn} indicated by the  green slot locations",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 1, 242),
                letterSpacing: .2,
                fontSize: 18,
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
      
      );


  }  else if (_tryingToConnect == false && boardsAreInTheWrack ==true && _connectionFailed!=true) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: 
                Text(
            "All boards are correctly in the wrack, press the End Session Button",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 2, 242),
                letterSpacing: .2,
                fontSize: 18,
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
          ),);

  } else if  (_tryingToConnect == false && _connectionFailed==true){
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: 
            Text(
            "We couln't connect to the wrack, please rescan to try again.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 247, 3, 255),
                letterSpacing: .2,
                fontSize: 18,
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
          ),);
  } else {
     return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Text(
            "",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 247, 7, 255),
                letterSpacing: .2,
                fontSize: 18,
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
          );

  }
  
  
  
  }
  
  Widget buildFloatingActionButton() {

  if (_tryingToConnect == true && _connectionFailed!=false) {
    return FloatingActionButton.large(
      onPressed: () async{                     
      },
      child: Icon(Icons.keyboard_double_arrow_down_outlined),
      foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
      backgroundColor: Color.fromARGB(255, 247, 223, 3),
      splashColor: Color.fromARGB(255, 234, 3, 255),
      elevation: 10,
      autofocus: true,
      tooltip: 'Connecting with the Wrack', // You can change the background color as needed
    );
  } 
  
  else if (_tryingToConnect == false && boardsAreInTheWrack ==false && _connectionFailed!=true) {

    // Return another widget based on condition2
    return Visibility(
      visible: true,
      child: FloatingActionButton.large(
        onPressed: () {
          // Add your onPressed action here
        },
        child: Icon(Icons.keyboard_double_arrow_down_outlined),
        backgroundColor: Color.fromARGB(255, 4, 202, 252),
        tooltip: 'Insert Boards',
        elevation: 10,
      ),
    );}

    else if (_tryingToConnect == false && boardsAreInTheWrack ==true && _connectionFailed!=true) {
    // If the bords are correcly in the wrack
    return FloatingActionButton.large(
      onPressed: () async {
         await cancelSubscriptions();

        await endSession();
                     
              
                },
      child: Icon(Icons.stop_circle),
      backgroundColor: Color.fromARGB(255, 73, 255, 1),
      tooltip: 'End Session',
      elevation: 10,
      
    );
    


    } else if (_tryingToConnect == false && _connectionFailed==true) {
    // Return another widget based on condition2
    return FloatingActionButton.large(
      onPressed: () {

        _scanBluetoothDevice();
                
              
                },
      child: Icon(Icons.restart_alt_rounded),
      backgroundColor: Color.fromARGB(255, 253, 249, 3),
      tooltip: 'Scan Again',
      elevation: 10,
      
    );
    }
    
    else {
    // Return a default widget if none of the conditions are met
    return Visibility(
      visible: false,
      child: FloatingActionButton(
        onPressed: ()async {

         
          // Add your onPressed action here
        },
        child: Icon(Icons.error),
        backgroundColor: const Color.fromARGB(255, 247, 193, 189),
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
                    Navigator.pushReplacement(
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
                     Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SessionPage(title: 'Sessions',)),
                  );

                  dispose();
                    
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


