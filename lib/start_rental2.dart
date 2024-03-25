import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:surf_app_2/session_started.dart';
import 'state_manager.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'homepage.dart';
import 'package:intl/intl.dart';
import 'Confirmation_Page.dart';


class StartRental extends StatefulWidget {
  const StartRental({Key? key}) : super(key: key);
  @override
  State<StartRental> createState() => _StartRentalState();
}

class _StartRentalState extends State<StartRental>
    with SingleTickerProviderStateMixin {
  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

  // the name of the ardrino
  String deviceName  = "<My Board Name>";

  /// Connect to the firebase database
  FirebaseDatabase database = FirebaseDatabase.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  BluetoothDevice? bluetoothDevice;
  late AnimationController _controller;

  BluetoothCharacteristic? lock1;
  BluetoothCharacteristic? lock2;
  BluetoothCharacteristic? lock3;
  BluetoothCharacteristic? lock4;

  // the current characteristics for each lock values
  int? lock1Status;
  int? lock2Status;
  int? lock3Status;
  int? lock4Status;

  //lock characteristics that were unlocked - used to relock if database fails to write
  List<BluetoothCharacteristic> unlockedCharacteristicsList = [];

  // SATE OF THE UNLOCKING PROGRESS
  bool _isUnlocking = false;

  // number of boards unlocked
  int numberOfBoardsUnlocked = 0;

  // if all boards unlocked suucesfully
  bool _boardsUnlockedSuccessfully = false;

  List<int> lockStates = [];

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController with the appropriate parameters
    _controller = AnimationController(
      vsync:
          this, // Provide the TickerProvider, which is SingleTickerProviderStateMixin in this case
      duration: Duration(milliseconds: 500),
    );

    myAppState = Provider.of<MyAppState>(context, listen: false);
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _adapterStateStateSubscription.cancel();
    bluetoothDevice?.disconnect();

    super.dispose();
  }

  // Warning messages to show the user

  void showReconnectionWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reconnection Failed"),
          content: const Text("Failed to reconnect to the device."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
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
          title: const Text("We Cannot comunicate with the Board Wrack"),
          content: const Text("Are you standing near it?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
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
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void databaseSessionWriteFail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Your Session was not logged with the database"),
          content: const Text(
              "Something has gone wrong while starting your session. Please try again later."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return const MyHomePage(title: "End Session");
                      }));
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Functions for connecting and operating the locks

  Future<void> _scanBluetoothDevice() async {
    setState(() {
      _isUnlocking = true;
    });

    if (!await _checkBluetoothSupport()) {
      
      bluetoothNotSupportedWarning(context);
      return;
    }

    if (!await _checkConnectionStatus()) {
      if (!await _scanAndConnectToDevice()) {
        showFailedToFindDevice(context);
        return;
      }
    }

    await _discoverServices();
  }

  Future<bool> _checkBluetoothSupport() async {
    return await FlutterBluePlus.isSupported;
  }

  Future<bool> _checkConnectionStatus() async {

    // Check if a the device with the ardino name is indeeed connected, and set to bluetooth device to device
    if (FlutterBluePlus.connectedDevices.isNotEmpty && FlutterBluePlus.connectedDevices.any((device) => device.platformName == deviceName)) {
      setState(() {
        bluetoothDevice = FlutterBluePlus.connectedDevices.first;
      });
      return true;
    }
    return false;
  }

  Future<bool> _scanAndConnectToDevice() async {
    await _scanForDevices();

    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      setState(() {
        bluetoothDevice = FlutterBluePlus.connectedDevices.first;
      });
      return true;
    }

    return false;
  }

  Future<void> _scanForDevices() async {
    // Start scanning for devices
    await FlutterBluePlus.startScan(
      withNames: ["<My Board Name>"],
      timeout: const Duration(seconds: 5),
    );

    // Wait until scanning finishes
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    // Retrieve the list of scan results
    List<ScanResult> scanResults = await FlutterBluePlus.scanResults.first;

    // Process the scan results
    if (scanResults.isNotEmpty) {
      // Handle the case when devices are found
      // You can update UI or perform other actions here
      await scanResults.first.device.connect();
      bluetoothDevice = scanResults.first as BluetoothDevice?;
    } else {
      // Handle the case

      // You can show a message to the user or take appropriate action
    }
  }

  Future<void> _discoverServices() async {
    List<BluetoothService> services = await bluetoothDevice!.discoverServices();

    bool lock1Found = false;
    bool lock2Found = false;
    bool lock3Found = false;
    bool lock4Found = false;

    for (BluetoothService service in services) {
      if (service.uuid.toString() == '180a') {
        var characteristics = service.characteristics;

        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid.toString() == '2a57') {
            setState(() {
              lock1 = c;
            });
            lock1Found = true;
          } else if (c.uuid.toString() == '2a58') {
            setState(() {
              lock2 = c;
            });
            lock2Found = true;
          } else if (c.uuid.toString() == '2a59') {
            setState(() {
              lock3 = c;
            });
            lock3Found = true;
          } else if (c.uuid.toString() == '2a60') {
            setState(() {
              lock4 = c;
            });
            lock4Found = true;
          }
        }

        // Check if both locks are found
        if (lock1Found && lock2Found && lock3Found && lock4Found) {
          // If both locks are found, unlock the locks
          await unlockLocks();
        }

        return;
      } else {
        print("Not a service that can be used!");
      }
      }
    }

  Future<void> readLockStatus(
      BluetoothCharacteristic? lock, String lockName) async {
    if (lock != null) {
      try {
        List<int> value = await lock.read();
        setState(() {
          if (lockName == 'Lock1') {
            lock1Status = value.isNotEmpty ? value[0] : null;
          } else if (lockName == 'Lock2') {
            lock2Status = value.isNotEmpty ? value[0] : null;
          } else if (lockName == 'Lock3') {
            lock3Status = value.isNotEmpty ? value[0] : null;
          } else if (lockName == 'Lock4') {
            lock4Status = value.isNotEmpty ? value[0] : null;
          }
        });
      } catch (e) {
        // Handle error appropriately, such as showing an error message
        print('Error reading $lockName: $e');
      }
    } else {
      print('$lockName is not yet initialized');
    }
  }

  Future<void> attemptUnlock(
    
    
    BluetoothCharacteristic? lock, String lockName) async {

      
  
    if (lock != null) {
      try {
        await lock.write([1]);

        await Future.delayed(Duration(seconds: 1));

        try {
          await readLockStatus(lock, lockName);

          if (lockName == "Lock1") {
            if (lock1Status != 1) {
              print("Failed to unlock lock 1!");
            } else {
              setState(() {
                numberOfBoardsUnlocked += 1; // increasing the number of unlocked locks by 1
                unlockedCharacteristicsList.add(lock); // adding lock char to list if unlocked
              });

              // adding the lock to state
              String lock1ID = lock1!.characteristicUuid.toString();
              myAppState.addWrackIDNumber(lock1ID);
            }
          }

          if (lockName == "Lock2") {
            if (lock2Status != 1) {
              print("Failed to unlock lock 2!");
            } else {
              setState(() {
                numberOfBoardsUnlocked += 1; // increasing the number of unlocked locks by 1
                unlockedCharacteristicsList.add(lock); // adding lock char to list if unlocked
              });

              // adding the lock to state
              String lock2ID = lock2!.characteristicUuid.toString();
              myAppState.addWrackIDNumber(lock2ID);
            }
          }

          if (lockName == "Lock3") {
            if (lock3Status != 1) {
              print("Failed to unlock lock 3!");
            } else {
              setState(() {
                numberOfBoardsUnlocked += 1; // increasing the number of unlocked locks by 1
                unlockedCharacteristicsList.add(lock); // adding lock char to list if unlocked
              });

              // adding the lock to state
              String lock3ID = lock3!.characteristicUuid.toString();
              myAppState.addWrackIDNumber(lock3ID);
            }
          }

          if (lockName == "Lock4") {
            if (lock4Status != 1) {
              print("Failed to unlock lock 4!");
            } else {
              setState(() {
                numberOfBoardsUnlocked += 1; // increasing the number of unlocked locks by 1
                unlockedCharacteristicsList.add(lock); // adding lock char to list if unlocked
              });

              // adding the lock to state
              String lock4ID = lock4!.characteristicUuid.toString();
              myAppState.addWrackIDNumber(lock4ID);
            }
          }

        } catch (e) {
          print('Failed to read lock 1 after write!');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> unlockLocks() async {

    // clear all existing unlocked numbers. 
    myAppState.clearAllWrackIDNumbers();

    // get the current status of all locks
    await readLockStatus(lock1, 'Lock1');
    await readLockStatus(lock2, 'Lock2');
    await readLockStatus(lock2, 'Lock3');
    await readLockStatus(lock2, 'Lock4');

    // get the number of boards user selected to unlock
    int numberOfBoardsToUnlock = myAppState.getNumberOfBoardsSelected();

    // If characteristics are read, attempt to unlock, locks already unlocked will be left.
    if (lock1 != null && lock2 != null && lock3 != null && lock4 != null) {
      // check the nunmber of boards to unlock is greater than 1
      if (numberOfBoardsToUnlock > 0) {
        // check if the lock1 is locked, and if the numberOfBoardsToUnlock is < then the selected number of boards to unlock.
        if (lock1Status == 0 &&
            numberOfBoardsUnlocked < numberOfBoardsToUnlock) {
          // this unlocks the lock and increases the numberOfBoardsUnlocked var by one
          await attemptUnlock(lock1, "Lock1");
        }

        if (lock2Status == 0 &&
            numberOfBoardsUnlocked < numberOfBoardsToUnlock) {
          await attemptUnlock(lock2, "Lock2");
        }

        if (lock3Status == 0 &&
            numberOfBoardsUnlocked < numberOfBoardsToUnlock) {
          await attemptUnlock(lock3, "Lock3");
        }

         if (lock4Status == 0 &&
            numberOfBoardsUnlocked < numberOfBoardsToUnlock) {
          await attemptUnlock(lock4, "Lock4");
        }

        // add more locks here when needed
      }
    } else {
      // if both or one of the choosen locks had no characteristic found,this should never happen.

      print("Lock status was not set/found ");
      _isUnlocking = false;
      _boardsUnlockedSuccessfully = false;
      setState(() {});
    }

    // final check to make sure all locks where unlocked
    if (numberOfBoardsToUnlock != numberOfBoardsUnlocked) {
      print('Failed to Unlock all the boards');

      _isUnlocking = false;
      _boardsUnlockedSuccessfully = false;
      setState(() {});

      if (unlockedCharacteristicsList.isNotEmpty) {
        // Loop over each BluetoothCharacteristic in the list
        for (BluetoothCharacteristic characteristic in unlockedCharacteristicsList) {
          // Perform some action for each characteristic
          print('Processing relocking characteristic: $characteristic');
          // Add your custom logic here for each characteristic

          try {

            characteristic.write([1]);
          } 
          
          catch (error){

            print('FAILED TO RELOCK LOCKS'); 

          }

        }

      }

      return;

    } else {

      // we write the session to the firebase database
    
      await addSessionWithRetry(myAppState.getEmailAdress(), myAppState.getSiteName(),
          numberOfBoardsToUnlock);

    }
  }

  Future<void> addSessionWithRetry(

    // We try to write the session to the database, if it fails we try again. If it fails a thrid time we 
    // relock all locks. Show error message and re-route to home page.

    String email,
    String location,
    int board_num,
    
  ) async {
    final DatabaseReference sessionsRef =
        FirebaseDatabase.instance.ref().child('Sessions');

    // Get the current time as a timestamp
    final currentTime = ServerValue.timestamp;

    int retryCount = 0;
    int maxRetries = 3;
    bool success = false;

    while (!success && retryCount < maxRetries) {
      try {
        await sessionsRef.push().set({
          'email': email,
          'location': location,
          'board_num': board_num,
          'start_time': currentTime,
          'end_time': "Active Session",
        });

        // If set operation succeeds, set success flag to true
        success = true;
      } catch (error) {
        print('Error writing session to Firebase: $error');
        retryCount++;
        await Future.delayed(
            Duration(seconds: 2)); // Wait for a short duration before retrying
      }
    }

    if (!success) {

       // if the data is not written to the database we want to lock the locks again so
      // they can walk off with them. 

      print('Failed to add session after $maxRetries attempts');

      setState(() {
      _isUnlocking = false;
      _boardsUnlockedSuccessfully = false;
      });

      // Set global state in session to be true
      myAppState.setInSession(false);
      
      if (unlockedCharacteristicsList.isNotEmpty) {
        // Loop over each BluetoothCharacteristic in the list
        for (BluetoothCharacteristic characteristic in unlockedCharacteristicsList) {
          // Perform some action for each characteristic
          print('Processing relocking characteristic: $characteristic');
          // Add your custom logic here for each characteristic

          try {

            characteristic.write([0]);
          } 
          
          catch (error){

            print('FAILED TO RELOCK LOCKS'); 

          }

        }

      }

      // If the seesion was not written and the locks have been relocked if any were unlocked. 
      // Show a message to the user that something went wrong and redirect them back to the home page. 
      databaseSessionWriteFail(context);
      return; // Return without updating state since session addition failed
    }else {

    // Session added successfully, update state
    setState(() {
      _isUnlocking = false;
      _boardsUnlockedSuccessfully = true;
    });

    // Set global state in session to be true
    myAppState.setInSession(true);
}}

  @override
Widget build(BuildContext context) {
  DateTime now = DateTime.now();
  String currentTime = DateFormat('hh:mm a').format(now);

  if (_isUnlocking == false && _boardsUnlockedSuccessfully == true) {
    
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 3),
          pageBuilder: (context, animation, secondaryAnimation) =>
              SessionStartedPage(title: 'Take Boards'),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  return Consumer<MyAppState>(
    builder: (context, myAppState, child) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 153, 240, 252),
       
        body: buildBody(context, myAppState, currentTime),
        bottomNavigationBar: buildBottomNavigationBar(context),
        floatingActionButton: buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


      );
    },
  );
}

PreferredSizeWidget buildAppBar(BuildContext context) {
  return AppBar(
    automaticallyImplyLeading: false,
    actions: <Widget>[
      if (_isUnlocking == false)
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Home',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyHomePage(title: "Surf-to-Rent"),
              ),
            );
          },
          color: Color.fromARGB(115, 24, 2, 126),
          iconSize: 35,
        ),
    ],
    backgroundColor: Color.fromARGB(255, 247, 5, 194),
    title: const Text('Start Rental'),
  );
}

Widget buildBody(BuildContext context, MyAppState myAppState, String currentTime) {
  return Container(
    decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your background image path
          fit: BoxFit.fill,
        ),
      ),


    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            buildSessionDetails(),
            buildSessionCard(context, myAppState, currentTime),
            //buildUnlockButton(),
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
              icon: Icon(Icons.home, color: Color.fromARGB(255, 255, 4, 159),size: 35,),
              onPressed: () {

                bluetoothDevice?.disconnect();
                    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
                      FlutterBluePlus.connectedDevices.first.disconnect();
                    }
                     bluetoothDevice?.disconnect();
                 
                // Handle menu button press
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title:'Tidal Drift')),
                  );
              },
            ),
           
            const Spacer(),

            
              IconButton(
                icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 248, 5, 216),size: 35),
                onPressed: () async {
                  bluetoothDevice?.disconnect();
                    if (FlutterBluePlus.connectedDevices.isNotEmpty)  {
                      FlutterBluePlus.connectedDevices.first.disconnect();
                    }
                    bluetoothDevice?.disconnect();
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmationPage(title: 'Confirmation', key: null),
                            ),
                          );
                  

                  // Handle settings button press
                
                },
              ),
          ],
        ),
      );
}

Widget buildSessionTable(BuildContext context, MyAppState myAppState, String currentTime){
  return   Center(
        child: Table(
          border: TableBorder.all(width:2, color: const Color.fromARGB(255, 2, 90, 253),borderRadius: BorderRadius.circular(5)),
          columnWidths: const {
            0: FractionColumnWidth(0.5),
            1: FractionColumnWidth(0.5),
           
          },
          children: [
          
            TableRow(
              children: [
                const TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Location',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 8, 139, 226)),),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(myAppState.getSiteName(),style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 1, 80, 14),),textAlign: TextAlign.center,),
                  ),
                ),
              
              ],
            ),
            TableRow(
              children: [
                const TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Boards',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 8, 139, 226))),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(myAppState.getNumberOfBoardsSelected().toString(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 24, 107, 3)),textAlign: TextAlign.center,),
                  ),
                ),
               
              ],
            ),
            TableRow(
              children: [
                const TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Start Time',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 8, 139, 226))),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(currentTime,style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Color.fromARGB(255, 2, 88, 35)),textAlign:TextAlign.center,),
                  ),
                ),
              
              ],
            ),
          ],
        ),
      );
    
  

}

Widget buildSessionDetails() {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.8,
    child: Text(
            "Okay all set. Check the Session details and push the start rental button to Unlock the boards. ",
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
  );
}

Widget buildSessionCard(BuildContext context, MyAppState myAppState, String currentTime) {
  return Card(
    elevation: 5,
    margin: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildSessionTitle(),
        
        buildSessionTable(context, myAppState, currentTime)
      ],
    ),
  );
}

Widget buildSessionTitle() {
  return Container(
    color: Color.fromARGB(255, 1, 36, 82),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.all(10.0),
          child: Text(
            "Session",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                letterSpacing: .2,
                fontSize: 25,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildUnlockButton() {
  return Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(height: 150),
      buildUnlockButtonBasedOnState(),
    ],
  );
}

Widget buildUnlockButtonBasedOnState() {
  if (_isUnlocking == false && _boardsUnlockedSuccessfully == false) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 253, 253, 253),
        backgroundColor: Color.fromARGB(255, 68, 155, 226),
      ),
      child: const Text(
        "Start Rental",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {
        await _scanBluetoothDevice();
      },
    );
  } else if (_isUnlocking == true && _boardsUnlockedSuccessfully == false) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: Color.fromARGB(255, 48, 69, 255),
        backgroundColor: Color.fromARGB(255, 226, 223, 68),
      ),
      child: const Text(
        "Unlocking Boards",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );
  } else if (_isUnlocking == false && _boardsUnlockedSuccessfully == true) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0),
        foregroundColor: const Color.fromARGB(255, 253, 253, 253),
        backgroundColor: Color.fromARGB(255, 68, 226, 81),
      ),
      child: const Text(
        "Boards have been unlocked :)",
        style: TextStyle(fontSize: 18.0),
      ),
      onPressed: () async {},
    );
  } else {
    return const SizedBox(); // Return an empty SizedBox if no condition matches
  }
}

Widget buildFloatingActionButton() {

  if (_isUnlocking == false && _boardsUnlockedSuccessfully == false) {
    return FloatingActionButton.large(
      onPressed: () async{      

         await _scanBluetoothDevice();             
                   
      },
      foregroundColor: Color.fromARGB(255, 255, 2, 200), // You can change the icon as needed
      backgroundColor: Color.fromARGB(255, 233, 250, 0),
      splashColor: Color.fromARGB(255, 234, 3, 255),
      elevation: 10,
      autofocus: true,
      tooltip: 'Start Rental',
      child: const Icon(Icons.start), // You can change the background color as needed
    );
  } 
  
  else if (_isUnlocking == true && _boardsUnlockedSuccessfully == false) {

    // Return another widget based on condition2
    return Visibility(
      visible: true,
      child: FloatingActionButton(
        onPressed: () {
          // Add your onPressed action here
        },
        backgroundColor: Color.fromARGB(255, 4, 41, 252),
        child: const Icon(Icons.add),
      ),
    );}

    else if (_isUnlocking == false && _boardsUnlockedSuccessfully == true) {
    // Return another widget based on condition2
    return FloatingActionButton.large(
      onPressed: () {
                
              
                },
      backgroundColor: Color.fromARGB(255, 94, 255, 1),
      child: const Icon(Icons.refresh),
      
    );

    } 
    
    else {
    // Return a default widget if none of the conditions are met
    return Visibility(
      visible: false,
      child: FloatingActionButton(
        onPressed: () async {

         
          // Add your onPressed action here
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.error),
      ),
    );
  }
}


}



