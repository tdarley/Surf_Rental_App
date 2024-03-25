import 'dart:ffi';

import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'Confirmation_Page.dart';
import 'state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homepage.dart';

import 'login_page.dart';
import 'logout.dart';
import 'state_manager.dart';
import 'homepage.dart';

import 'sessionpage.dart';



class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

  Barcode? result;
  QRViewController? controller;
  //final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // Unique GlobalKey for the QRView
  final GlobalKey qrViewKey = GlobalKey(debugLabel: 'QRView');
  final GlobalKey bottomNavigationBarKey = GlobalKey();




  // Change these to the site names
  final List _validQrCodes = ['Green_Foamy_Hollywell.png','Red_Foamy_Hollywell.png'];

  bool gotValidQR = false; // if the qr codes is valid

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
    myAppState = Provider.of<MyAppState>(context, listen: false);
  }

  
  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Consumer<MyAppState>(
      
      builder: (context, myAppState, child) =>
      
        Scaffold(
          
          body: Container(
            decoration: BoxDecoration(
                  color: Color.fromARGB(255, 0, 0, 0)
          
                ),



            child: Column(
              children: <Widget>[
                Expanded(flex: 4, child: _buildQrView(context)),
                Expanded(
                  flex: 1,
                  child: FittedBox(
                    
                    fit: BoxFit.contain,
                    child: Column(
                      
                      
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                  
                        // Here we can put in the custon logic for board detection
                  
                        if (result != null)
            
                          const Text(
                              'Not the right QR CODE!')
                        
                        else
                          //const Text('Scanthe QR code on the Board :)'),
                  
                          Text(
                            'Scan a QR code on the Wrack',
                            style: GoogleFonts.nunito(
                              textStyle: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  letterSpacing: .1,
                                  fontSize:12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                  
                    
                        Padding(
                          
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                           
                              Container(
                               
                                margin: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                    onPressed: () async {
                                      await controller?.flipCamera();
                                      setState(() {});
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.blue),
                                      shape:
                                          MaterialStateProperty.all<OutlinedBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              10.0), // Adjust the radius as needed
                                        ),
                                      ),
                                      elevation: MaterialStateProperty.all<double>(
                                          8.0), // Adjust the elevation as needed
                                    ),
                                
                          
                                    child: FutureBuilder(
                                      future: controller?.getCameraInfo(),
                                      builder: (context, snapshot) {
                                        if (snapshot.data != null) {
                                          return Text(
                                            'Camera facing ${describeEnum(snapshot.data!)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.0,
                                              // You can add more text styling properties as needed
                                            ),
                                          );
                                        } else {
                                          return const Text('loading');
                                        }
                                      },
                                    )),
                              )
                            ],
                          ),
                        ),
                      
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
           bottomNavigationBar: buildBottomNavigationBar(context),
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrViewKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
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
          
            Spacer(),

           
              IconButton(
                icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 248, 5, 216),size: 35),
                onPressed: () {
                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title: 'Tidal Drift',)),
                  );
                },
              ),
          ],
        ),
      );
}

  /// Heavily modified default code
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      //It checks if a valid QR code has already been processed. If gotValidQR is true,
      //it means that a valid QR code has already been handled, and the function returns early,
      // avoiding further processing of duplicate scans.
      
      if (gotValidQR) {
        return;
      }
      gotValidQR = true;

      result = scanData;
      print(result!.code!);

      // Check if board id is in list of board ids
      if (_validQrCodes.contains(result!.code!)) {
        String selectedBoard = result!.code!;



        // waut for the page to be loaded
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) {
            
            return ConfirmationPage(key: UniqueKey(), title: selectedBoard);
          }),
        );

    
      // then reset the gotValidQR
      gotValidQR = false;

    }});
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
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
                   if (myAppState.getLoggedIn() == false)
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
                   if (myAppState.getLoggedIn() == true)
                   ListTile(
                    leading: Icon(Icons.logout,color: Colors.blue),
                    title: Text('Login', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
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


                  if (myAppState.getLoggedIn() == true)
                  ListTile(
                    leading: Icon(Icons.receipt,color: Colors.blue),
                    title: Text('Your Sessions',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                    splashColor: Color.fromARGB(255, 115, 255, 1),
                    onTap: () {
                      // Handle option 1 press
                      Navigator.pop(context);
                    },
                  ),
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


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
