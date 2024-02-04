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

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  List boardids = ['Green_Foamy_Hollywell.png','Red_Foamy_Hollywell.png'];

  bool gotValidQR = false;


  ////// Fuction updates the global state for board selection
  //MyAppState myappState = MyAppState();
  //void updateSelectedBoard(newString) {
  //  if (gotValidQR== true){
  //    String newValue = newString;
  //    myappState.updateStringSelection(newValue);
  //
  //    }
  //}

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }



  @override
  Widget build(BuildContext context) {

    
    return Consumer<MyAppState>(

    builder: (context, myAppState, child) =>

      Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => (const MyHomePage(
                            title: 'Surf to Rent',
                          ))),
                );
              },
              color: Color.fromARGB(115, 24, 2, 126),
              iconSize: 35,
            ),
          ],
          backgroundColor: Colors.amber,
          title: Text("QR Scanner"),
        ),
        body: Column(
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
                      Text(
                          'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                    
                    else
                      //const Text('Scanthe QR code on the Board :)'),

                      Text(
                        'Scan a QR code on the board you want',
                        style: GoogleFonts.indieFlower(
                          textStyle: TextStyle(
                              color: Color.fromARGB(255, 10, 2, 59),
                              letterSpacing: .1,
                              fontSize:12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //Container(
                        //  margin: const EdgeInsets.all(8),
                        //  child: ElevatedButton(
                        //      onPressed: () async {
                        //        await controller?.toggleFlash();
                        //        setState(() {});
                        //      },
                        //      child: FutureBuilder(
                        //        future: controller?.getFlashStatus(),
                        //        builder: (context, snapshot) {
                        //          return Text('Flash: ${snapshot.data}');
                        //        },
                        //      )),
                        //),
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
                                      style: TextStyle(
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
                    //Row(
                    //  mainAxisAlignment: MainAxisAlignment.center,
                    //  crossAxisAlignment: CrossAxisAlignment.center,
                    //  children: <Widget>[
                    //    Container(
                    //      margin: const EdgeInsets.all(8),
                    //      child: ElevatedButton(
                    //        onPressed: () async {
                    //          await controller?.pauseCamera();
                    //        },
                    //        child: const Text('pause',
                    //            style: TextStyle(fontSize: 20)),
                    //      ),
                    //    ),
                    //    Container(
                    //      margin: const EdgeInsets.all(8),
                    //      child: ElevatedButton(
                    //        onPressed: () async {
                    //          await controller?.resumeCamera();
                    //        },
                    //        child: const Text('resume',
                    //            style: TextStyle(fontSize: 20)),
                    //      ),
                    //    )
                    //  ],
                    //),
                  ],
                ),
              ),
            )
          ],
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
      key: qrKey,
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
      if (boardids.contains(result!.code!)) {
        String selectedBoard = result!.code!;



        // waut for the page to be loaded
        dynamic pop = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            
            return ConfirmBoardSelection(selectedBoard: selectedBoard);
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
