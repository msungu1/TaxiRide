import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/userdetails/UserDetailsScreen.dart';
import 'UserProvider/UserProvider.dart';
import 'driverRequest/DriverAvailableTripsScreen.dart';
import 'login_screen/LoginScreen.dart';
import 'registration_Screen/RegistrationScreen.dart';
import 'ProfileScreen/ProfileScreen.dart';
import 'splash_screen/SplashScreen.dart';
import 'onetimescreen/OnetimeScreen.dart';
import 'otpverification/OtpVerificationScreen.dart';
import 'termsandcondition/TermsAndConditionsScreen.dart';
import 'usermodel/UserModel.dart';
import 'DriverProfile/DriverProfileScreen.dart';
import 'driverListscreen/DriverListScreen.dart';
import 'adminuser/AdminScreen.dart';
import 'emergency/EmergencyContactScreen.dart';
import 'newride/NewRideScreen.dart';
import 'requestride/RequestRideScreen.dart';
import 'ridestarted/RideStartedScreen.dart';
import 'triphistory/TripHostryScreen.dart';
import 'tripdetails/TripDetailsScreen.dart';
import 'forgort/ForgotPasswordScreen.dart';
import 'changepassword/ChangePasswordScreen.dart';
import 'FeedbackScreen/FeedbackScreen.dart';
import 'help/HelpSupportScreen.dart';
import 'privacy/PrivacyPolicyScreen.dart';
import 'Onetime2/OnetimetwoScreen.dart';
// import 'env_helper.dart';
// ✅ Socket Import
import 'package:sizemore_taxi/sockets/sockets_service.dart';
// import 'package:sizemore_taxi/driverRequest/DriverAvailableTripsScreen.dart';
//
// 1. GLOBAL NAVIGATOR KEY - Essential for showing popups from outside widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

// ✅ PUT IT HERE
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode;

  ThemeNotifier(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  ThemeMode get currentTheme =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool isDark) async {
    _isDarkMode = isDark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);

    notifyListeners();
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. LINK NAVIGATOR KEY TO SOCKET SERVICE IMMEDIATELY
  SocketService.instance.setNavigatorKey(navigatorKey);
  debugPrint("🚀 Main: NavigatorKey linked to SocketService");

  HttpOverrides.global = MyHttpOverrides();

  // Load .env logic
  try {
    if (kIsWeb) {
      await dotenv.load(
        mergeWith: {
          'GOOGLE_MAPS_KEY': 'AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM',
          'API_URL': 'https://maps.googleapis.com/maps/api/distancematrix/json',
        },
      );
      debugPrint("✅ Web: dotenv merged with hardcoded values");
    } else {
      await dotenv.load(fileName: "assets/.env");
      debugPrint("✅ Desktop/Mobile: .env loaded from assets");
    }
  } catch (e) {
    debugPrint("⚠️ .env load error: $e");
    // Fallback: reload with hardcoded values (using mergeWith inside load)
    await dotenv.load(
      mergeWith: {
        'GOOGLE_MAPS_KEY': 'AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM',
        'API_URL': 'https://maps.googleapis.com/maps/api/distancematrix/json',
      },
    );
    debugPrint("Fallback: hardcoded values merged");
  }
  // runApp(
  //   ChangeNotifierProvider(create: (_) => UserProvider(), child: const MyApp()),
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add the ThemeNotifier here to fix the red error screen
        ChangeNotifierProvider(create: (_) => ThemeNotifier(true)),      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 3. AUTO-RECONNECT SOCKET ON APP START
    _initExistingUserSocket();
  }

  /// Checks SharedPreferences and re-initializes socket if user is already logged in
  Future<void> _initExistingUserSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? role = prefs.getString('role');

    if (userId != null && userId.isNotEmpty) {
      debugPrint(
        "🔄 Auto-initializing socket for existing user: $userId (Role: $role)",
      );

      // We initialize with 0.0, 0.0. The DriverProfileScreen will update this
      // with real GPS coordinates as soon as it builds.
      SocketService.instance.init(userId: userId, lat: -1.2633, lng: 36.8087);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ REQUIRED FOR POPUPS
      debugShowCheckedModeBanner: false,
      title: 'Sizemore Taxi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
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
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return OtpVerificationScreen(
            userId: args['email'] ?? '',
            role: args['role'] ?? '',
          );
        },
        '/userdetails': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          final user = args['user'] as UserModel;
          return UserDetailsScreen(user: user);
        },
        '/marketplace': (context) => const DriverAvailableTripsScreen(),
      },
    );
  }
}
