import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'state_manager.dart';
import 'sessionpage.dart';
import 'homepage.dart';
import 'login_page.dart';
import 'logout.dart';
// This page shows the user that session has started and to take the boards from the wrack

class SessionStartedPage extends StatefulWidget {
  final String title;

  SessionStartedPage({required this.title});

  @override
  State<SessionStartedPage> createState() => _SessionStartedPageState();
}

class _SessionStartedPageState extends State<SessionStartedPage> {

  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

  String? humanReadableLockNames;


  @override
  void initState() {
    super.initState();
    myAppState = Provider.of<MyAppState>(context, listen: false);
    makeHumanReadableWrackNumbers(myAppState.getWrackIDNumbers());
  }

  @override
  void dispose() {   
    super.dispose();
  }

  Future<void>makeHumanReadableWrackNumbers(unlockedWrackIDs) async{
     List<String> formattedNames = [];
     String newName ='';

     int numberOfSlots = 0;

    /// Function formats the wrack ids into slot names eg.2a57 Slot One.  
    for (String wrackID in unlockedWrackIDs){

        if (wrackID.contains('2a57')){
          formattedNames.add('Slot 1') ;
          numberOfSlots +=1;
        }else if (wrackID.contains('2a58')){
          formattedNames.add('Slot 2') ;
          numberOfSlots +=1;

        }else if (wrackID.contains('2a59')){
          formattedNames.add('Slot 3') ;
          numberOfSlots +=1;

        }else if (wrackID.contains('2a60')){
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
      humanReadableLockNames =result;
      
    });
    
    }


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }


Widget buildBody(BuildContext context) {

  List<String> unlockedWrackIDs = myAppState.getWrackIDNumbers();
  List<String> unlockedWrackNames = [];
  unlockedWrackNames.clear();

    for (String wrackID in unlockedWrackIDs){
      if (wrackID == '2a57'){
        unlockedWrackNames.add('Slot 1');
      } 
      else if (wrackID == '2a58'){
        unlockedWrackNames.add('Slot 2');

      }
       else if (wrackID == '2a59'){
        unlockedWrackNames.add('Slot 3');

      }
      else if (wrackID == '2a60'){
        unlockedWrackNames.add('Slot 4');

      }

    } 

  return Container(
    height: MediaQuery.of(context).size.height,
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/Tidal_Drift_Background.png'), // Replace with your background image path
        fit: BoxFit.fill,
      ),
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          makeTitleText(context, unlockedWrackNames),

          buildSessionPageButton(),
          SizedBox(height:50),


          buildBoardWrackWidget(unlockedWrackNames),
          
          
        ],
      ),
    ),
  );
}

Widget makeTitleText(context, unlockedWrackNames){

     // creating strings to based on the user selections
    int boardsSelected  = myAppState.getNumberOfBoardsSelected();
    
    String boardsString ="Your board is now ready to take."; 
    if (boardsSelected >1){
      boardsString = "Your boards are now ready to take."; 
    } else {
      boardsString ="Your boards are now ready to take."; 
    }

    String wrackIDString = "None Given Yet";

    if (unlockedWrackNames.length == 1) {
    String id = unlockedWrackNames.first;
    wrackIDString = "We have unlocked the board in ";
  } else {
    String baseString = "We have unlocked the boards in ";
    wrackIDString = baseString;
    
  }

  return 

        Column(
              //smainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50,),
            
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Text(
                        "Thank you for renting with us. $boardsString $wrackIDString $humanReadableLockNames. ",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          textStyle: const TextStyle(
                              color: Color.fromARGB(255, 7, 7, 49),
                              letterSpacing: .1,
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ),
            
                     const SizedBox( height: 50), 
            
                                
              ],
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
            const Spacer(),

            
              IconButton(
                icon: const Icon(Icons.home, color: Color.fromARGB(255, 248, 5, 216),size: 35,),
                onPressed: () {
                  // Handle settings button press
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home',)),
                  );
                },
              ),
         
          ],
        ),
      );
}

Widget buildSessionPageButton(){


    return ElevatedButton.icon(onPressed: (){
            
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SessionPage(title: 'Sessions Page',)),
                    );
            
                    
                   }, icon: Icon(Icons.receipt_long_outlined), label: Text('My Sessions'),
                    style: ElevatedButton.styleFrom(
                     minimumSize: Size(200, 50), 
                     foregroundColor: Color.fromARGB(255, 240, 240, 240),
                     backgroundColor: Color.fromARGB(255, 8, 134, 218),
                     elevation: 10,
                     // Adjust size as needed
                    ),);

  }

Widget buildBoardWrackWidget(unlockedWrackNames) {

  
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
                Positioned(
                      
                      left: 35,
                      top: 15,
                      bottom: 0,
                      child: Visibility(
                          visible: true,
                          child: Container(
                            decoration: BoxDecoration(
                            color: unlockedWrackNames.contains('Slot 1')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 115, 119, 114),
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
                          visible: true,
                          child: Container(
                            decoration: BoxDecoration(
                            color: unlockedWrackNames.contains('Slot 2')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 115, 119, 114),
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
                          visible: true,
                          child: Container(
                            decoration: BoxDecoration(
                            color: unlockedWrackNames.contains('Slot 3')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 115, 119, 114),
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
                          visible: true,
                          child: Container(
                            decoration: BoxDecoration(
                            color: unlockedWrackNames.contains('Slot 4')
                            ? Color.fromARGB(255, 81, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 115, 119, 114),
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
      
                const Row(
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
                    backgroundColor: unlockedWrackNames.contains('Slot 1')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 102, 104, 102)// Red color when lock_value_1 is not 1
                                          
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: unlockedWrackNames.contains('Slot 2')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 102, 104, 102)// Red color when lock_value_1 is not 1
                                          
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: unlockedWrackNames.contains('Slot 3')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 102, 104, 102)// Red color when lock_value_1 is not 1
                                          
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: unlockedWrackNames.contains('Slot 4')
                            ? Color.fromARGB(255, 22, 255, 1) // Change color to blue if "Slot 1" is present
                            : Color.fromARGB(255, 102, 104, 102)// Red color when lock_value_1 is not 1
                                          
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

void drawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromARGB(255, 235, 240, 239),
         
          height: 250,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[

                ListTile(
                  leading: const Icon(Icons.home,color: Colors.blue),
                  title: Text('Home', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 1 press
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Home',)),
                    );
                  },
                ),

                 if (myAppState.getLoggedIn() == false && myAppState.getInternetConnected()==true)
                 ListTile(
                  leading: const Icon(Icons.login,color: Colors.blue),
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
                 if (myAppState.getLoggedIn() == true && myAppState.getInternetConnected()==true)
                 ListTile(
                  leading: Icon(Icons.logout,color: Colors.blue),
                  title: const Text('Logout', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
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


                  
                if (myAppState.getInternetConnected()==true)
                ListTile(
                  leading: const Icon(Icons.map_rounded,color: Colors.blue),
                  title: Text('Locations',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 2 press
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield,color: Colors.blue),
                  title: Text('Terms and Conditions',style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                  splashColor: Color.fromARGB(255, 115, 255, 1),
                  onTap: () {
                    // Handle option 3 press
                    Navigator.pop(context);
                  },
                ),
                 ListTile(
                  leading: Icon(Icons.lock, color: Colors.blue),
                  title: const Text('Private Policy', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
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