import 'dart:io'; // ← ADD THIS

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/driverListscreen/DriverListScreen.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
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
import 'package:sizemore_taxi/forgort/ForgotPasswordScreen.dart';
import 'splash_screen/SplashScreen.dart';
import 'login_screen/LoginScreen.dart';
import 'registration_Screen/RegistrationScreen.dart';
import 'onetimescreen/OnetimeScreen.dart';
import 'otpverification/OtpVerificationScreen.dart';
import 'termsandcondition/TermsAndConditionsScreen.dart';
import 'usermodel/UserModel.dart';
import 'package:sizemore_taxi/FeedbackScreen/FeedbackScreen.dart';
import 'package:sizemore_taxi/ProfileScreen/ProfileScreen.dart';
import 'ridemodel/ridemodel.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
import 'package:sizemore_taxi/DriverProfile/DriverProfileScreen.dart';

// THIS FIXES THE HANDSHAKE ERROR
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIXES CERTIFICATE_VERIFY_FAILED (handshake.co, self-signed certs, local IPs, etc.)
  HttpOverrides.global = MyHttpOverrides();

  if (kIsWeb) {
    await dotenv.load(mergeWith: {
      'GOOGLE_MAPS_KEY': 'AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM',
      'API_URL': 'https://maps.googleapis.com/maps/api/distancematrix/json',
    });
    print("Web mode: Using hardcoded test API keys");
  } else {
    await dotenv.load(fileName: "assets/.env");
    print("Mobile mode: Loaded .env from assets/.env");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sizemore Taxi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/onetime': (context) => const OnetimeScreen(),
        '/adminuser': (context) => AdminScreen(),
        '/emergency': (context) => const EmergencyContactScreen(),
        '/requestride': (context) => const RequestRideScreen(),
        '/requestridetwo': (context) => const RequestRideTwo(),
        '/newride': (context) => const NewRideScreen(),
        '/ridestarted': (context) => const RideStartedScreen(),
        '/onetimetwo': (context) => const OnetimeTwoScreen(),
        '/triphistory': (context) => const TripHistoryScreen(),
        '/tripdetails': (context) => const TripDetailsScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/change': (context) => const ChangePasswordScreen(),
        '/termsandcondition': (context) => const TermsAndConditionsScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/rider': (context) => const ProfileScreen(),
        '/help': (context) => const HelpSupportScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/driver': (context) => const DriverListScreen(),
        '/driverscreen': (context) => const DriverProfileScreen(),
        '/otpVerification': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          final email = args['email'] ?? '';
          final role = args['role'] ?? '';
          return OtpVerificationScreen(userId: email, role: role);
        },
        '/userdetails': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
          final user = args['user'] as UserModel;
          return UserDetailsScreen(user: user);
        },
      },
    );
  }
}