import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:surf_app_2/homepage.dart';
import 'state_manager.dart'; 
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'logout.dart';
import 'end_session.dart';

class SessionPage extends StatefulWidget {
  final String title;

  // Constructor with required parameter
  const SessionPage({required this.title});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {

  late MyAppState myAppState = Provider.of<MyAppState>(context, listen: false);

  var _latestSession = null;  // holds a dict of the latest session for the user.

  List _allOtherSessions = []; // holds all other sessions, separated from the latest session.

  bool _noExistingSession = true; // if no sessions currently exist in the database for the user.

  bool _noActiveSession = true; // if no active session is open for the user.
  
  get outerMap => null; 

  late String mostRecentKey; // holds the unique session key for the most recent session if one exists. 



@override
  void initState() {
    super.initState();
     myAppState = Provider.of<MyAppState>(context, listen: false);
     getUserSessions(myAppState.getEmailAdress());  }


 
Future<String> convertTime(int timestamp) async {

  // Function converts firebase int time stamp to readable datetime
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  String formattedDateTime = dateTime.toString();
  print(formattedDateTime); // Output: 2023-12-07 02:32:30.008
  return formattedDateTime;
}

Future<void> getUserSessions(String email) async {
  final ref = FirebaseDatabase.instance.ref().child('Sessions');
  final query = ref.orderByChild('email').equalTo(email);
  final event = await query.once(DatabaseEventType.value);

  if (event.snapshot.value != null) {
    final data = event.snapshot.value as Map<dynamic, dynamic>;

    if (data.isNotEmpty) {
      Map<String, int> timestamps = {};
      data.forEach((key, value) {
        int startTime = value['start_time'];
        timestamps[key] = startTime;
        print(startTime);
      });

      String? mostRecentKey;
      int mostRecentTimestamp = 0;
      timestamps.forEach((key, value) {
        if (value > mostRecentTimestamp) {
          mostRecentTimestamp = value;
          mostRecentKey = key;
        }
      });

      if (data.length == 1) {
        String mostRecentEndTime = data[mostRecentKey!]['end_time'];
        setState(() {
          _noActiveSession = mostRecentEndTime != "Active Session";
          _latestSession = data.values.first;
          _noExistingSession = false;
        });
      } else if (data.length > 1) {
        print(data.keys);

        String mostRecentEndTime = data[mostRecentKey]['end_time'].toString();
        print(mostRecentEndTime);
        setState(() {
          _noActiveSession = mostRecentEndTime != "Active Session";
          _latestSession = data[mostRecentKey];
          _noExistingSession = false;
        });

        print(_noActiveSession);
        print(_latestSession);
        print(_noExistingSession);

        List<dynamic> allOtherSessions = [];
        data.forEach((key, value) {
          if (key != mostRecentKey) {
            allOtherSessions.add(value);
          }
        });
        setState(() {
          _allOtherSessions = allOtherSessions;
        });
        print('All other sessions: $_allOtherSessions');
      }
    } else {
      setState(() {
        _noExistingSession = true;
      });
      print('No sessions found for email: $email');
    }
  } else {
    print('No data available for email: $email');
  }
}

@override
Widget build(BuildContext context) {
   
    return Scaffold(
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
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
                icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 248, 5, 216),size: 35,),
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
  

Widget buildBody(BuildContext context) {

  DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  return SingleChildScrollView(
    child: Container(
      height: MediaQuery.of(context).size.height + 50*_allOtherSessions.length,
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

            const SizedBox(height: 20,),

            // if no active session, but there are old sessions
            if (_latestSession != null && _noExistingSession == false && _noActiveSession ==false)

            buildCard(
              "Current Session", 
              _latestSession['location'].toString(),
              dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_latestSession['start_time'])),
               'Active Session',
              
              _latestSession["board_num"],
              true, 
              _noActiveSession),

           // if an session, and there are old sessions
           if (_latestSession != null && _noExistingSession == false && _noActiveSession ==true)
              buildCard(
                "Last Session", 
                _latestSession['location'].toString(),
                dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_latestSession['start_time'])),
               dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_latestSession['end_time'])),
                _latestSession["board_num"],
                true, 
                _noActiveSession),

          // if no sessions
          if (_noExistingSession == false)
          
          for (var session in _allOtherSessions)
            buildCard(
              "Other Session",
              session['location'].toString(),
              dateFormat.format(DateTime.fromMillisecondsSinceEpoch(session['start_time'])), 
              dateFormat.format(DateTime.fromMillisecondsSinceEpoch(session['end_time'])),
              session["board_num"],
              false,
              _noActiveSession
            ),

            if (_noExistingSession == true)
            buildCard("No Sessions With Us Yet",
            "None",
            "None",
            "None",
            0,
            true,
            _noActiveSession,

            
            )
            
          
          ],
        ),
      ),
    ),
  );
}


Widget buildCard(String title, String siteName, String startTime, String endTime, int boradNum, bool isCurrent, bool noActiveSession ) =>
  Card(
      color: isCurrent
          ? const Color.fromARGB(255, 253, 253, 253)
          : const Color.fromARGB(255, 255, 255, 255),
      child: ExpandablePanel(
          header: Container(
            decoration: BoxDecoration(
                color: isCurrent
                    ? Color.fromARGB(255, 7, 187, 133)
                    : Color.fromARGB(255, 18, 170, 190),
                border: Border.all(
                  color: Colors.black, // Choose your border color
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(10.0)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(title,
                  style: isCurrent
                      ? const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255))
                      : const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,  color: Color.fromARGB(255, 255, 255, 255))),
            ),
          ),
          collapsed: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(siteName),
          ),
          expanded: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns the children at the start and end of the row
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                                           
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Site Name: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: siteName,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Start Time: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: startTime,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'End Time: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: endTime,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Boards: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: boradNum.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                                            
                    if (isCurrent == true && noActiveSession == false)
                      ElevatedButton(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EndSessionPage(title: 'End Session',)),
                            );

                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 211, 127, 1), // Background color
                            foregroundColor: Colors.white, // Text color
                            padding: const EdgeInsets.all(10.0), // Button padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Button border radius
                            ),
                          ),
                          child: const Text("End Session"))
                  ]),
                ),
              ],
            ),
          )));
  
  
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


