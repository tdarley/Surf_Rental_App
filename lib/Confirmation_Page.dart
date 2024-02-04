import 'package:flutter/material.dart';
import 'main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'main.dart';
import 'start_rental.dart';


class ConfirmBoardSelection extends StatelessWidget {
  final String? selectedBoard; // Nullable String

  ConfirmBoardSelection({required this.selectedBoard});
  
  

  @override
  Widget build(BuildContext context) {


    // I could not get the state to set correcly from the QC screen.
    // Added a function that on clicking confirm selection button state is
    // set to the current board.
    //MyAppState myappState = MyAppState();
    //void updateSelectedBoard(newString) {
    //  String newValue = newString;
    //  myappState.updateStringSelection(newValue);



    //}

     
// Check if selectedBoard is not null and contains "_"
String? boardName = selectedBoard?.contains("_") ?? false
    ? selectedBoard!.split('_')[0] + selectedBoard!.split('_')[1]
    : null;
  

  String? siteName = selectedBoard?.contains(".")
      ?? false
      ? selectedBoard!.split('_')[2].split('.')[0]
      : null;

    // Now you can use the currentBoardSelection in your widget
    return Consumer<MyAppState>(
    builder: (context, myAppState, child) =>
      Container(
        color: Colors.lightBlue,
        child: Scaffold(
          appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Login',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage(title: 'Rent-to-Surf')),
                );
              },
              color: Color.fromARGB(115, 24, 2, 126),
              iconSize: 35,
            ),
          ],
          backgroundColor: Colors.amber,
          title: Text('Confirm Rental'),
          
        ),
          body: Column(
            
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Align(
                      alignment: Alignment.center,
                      child: Text(
                        siteName!,
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 10, 2, 59),
                              letterSpacing: .2,
                              fontSize:50,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Align(
                      alignment: Alignment.center,
                      child: Text(
                        boardName!,
                        style: GoogleFonts.indieFlower(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 10, 2, 59),
                              letterSpacing: .2,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
        
              Divider(
                height: 50,
                thickness: 1,
                color: Colors.purpleAccent,
              ),
        
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.8, // Adjust the multiplier as needed
                    height: MediaQuery.of(context).size.height *
                        0.3, // Adjust the multiplier as needed
                    child: Image.asset(
                      'assets/images/$selectedBoard',
                      fit: BoxFit.contain, // Adjust the fit property as needed
                    ),
                  ),
                ],
              ),
              Divider(
                height: 60,
                thickness: 1,
                color: Colors.purpleAccent,
              ),
        
              Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Do you want to start the rental?'),
                        Row(
                          children: [
                            Center(
                              child: ElevatedButton(
                                
                                onPressed: (){

                                  print('setting board state selection to $selectedBoard');
      
                                  myAppState.updateStringSelection(selectedBoard.toString());
      
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return MyHomePage(title: 'Surf-to-Rent'); // Replace YourNewPage with the actual page you want to navigate to
                                  }),);
      
                                  print('dd');
                              
                                },
      
                                onLongPress: () {
                                  myAppState.updateStringSelection(selectedBoard.toString());
      
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) {
                                    return MyHomePage(title: 'Surf-to-Rent'); // Replace YourNewPage with the actual page you want to navigate to
                                  }),);
                                },
                                style: ElevatedButton.styleFrom(
                                  //primary: Colors.transparent,
                                  //onPrimary: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Color.fromARGB(255, 231, 151, 2),
                                      size: 24.0,
                                    ),
                                    SizedBox(
                                        width: 8.0), // Adjust spacing if needed
                                    Text('Changed My Mind!'),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                      
                                },
      
                                onLongPress: (){
      
                                  myAppState.updateStringSelection(selectedBoard.toString());
      
                                      // Navigate to a new page using Navigator
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      return StartRental(); // Replace YourNewPage with the actual page you want to navigate to
                                    }),);
      
                                },
                                style: ElevatedButton.styleFrom(
                                  //primary: Colors.transparent,
                                  //onPrimary: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 24.0,
                                    ),
                                    SizedBox(
                                        width: 8.0), // Adjust spacing if needed
                                    Text('Yeah Braa!'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ])
              // Other rows or widgets...
            ],
          ),
        ),
      ),
    );
  }
}
