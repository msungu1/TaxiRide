import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/Onetime2/OnetimetwoScreen.dart';
import 'package:sizemore_taxi/adminuser/AdminScreen.dart';
import 'package:sizemore_taxi/emergency/EmergencyContactScreen.dart';
import 'package:sizemore_taxi/newride/NewRideScreen.dart';
import 'package:sizemore_taxi/requestride/RequestRideScreen.dart';
import 'package:sizemore_taxi/requestridetwo/RequestRideTwo.dart';
import 'package:sizemore_taxi/ridestarted/RideStartedScreen.dart';
import 'package:sizemore_taxi/tripdetails/TripDetailsScreen.dart';
import 'package:sizemore_taxi/triphistory/TripHostryScreen.dart';
import 'package:sizemore_taxi/userdetails/UserDetailsScreen.dart';
import 'ProfileScreen/ProfileScreen.dart';
import 'splash_screen/SplashScreen.dart';
import 'login_screen/LoginScreen.dart';
import 'registration_Screen/RegistrationScreen.dart';
import 'onetimescreen/OnetimeScreen.dart';
// import 'mainscreen/MainScreen.dart'; // adjust path if needed


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
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
      debugShowCheckedModeBanner: false, //This line removes the red debug banner that
      // appears at the top-right of your app when you're running it in debug mode (which is the default when testing on an emulator or a real device).



      title: 'Sizemore Taxi',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      initialRoute: '/splash',
      // home: const SplashScreen(),
     routes:  {
        '/splash':       (context)     => const SplashScreen(),
       '/login':         (context)     => const LoginScreen(),
       '/register':      (context)     => const RegistrationScreen(),
       '/profile':       (context)     => const ProfileScreen(),
       '/onetime':       (context)     => const OnetimeScreen(),
       '/adminuser':     (context)     => const AdminScreen(),
       '/emergency':     (context)     => const EmergencyContactScreen(),
       '/requestride'   :(context)     => const RequestRideScreen(),
       '/requestridetwo':(context)     => const RequestRideTwo(),
       '/newride'       :(context)    => const NewRideScreen(),
       '/ridestarted'   : (context)    => const RideStartedScreen(),
       '/onetimetwo':  (context) => const OnetimeTwoScreen(),
        '/userdetails' : (context) => const UserDetailsScreen(),
       '/triphistory' : (context) => const  TripHistoryScreen(),
       '/tripdetails' :(contex) => const  TripDetailsScreen(),
       // '/main': (context) => const MainScreen(), // 👈 Add this





     },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
