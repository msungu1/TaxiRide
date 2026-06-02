import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sizemore_taxi/PassengerRideDetailScreen/PassengerRideDetailScreen.dart';

// ✅ Internal Imports (Ensure paths match your project structure)
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/env_helper.dart';
import 'package:sizemore_taxi/requestridetwo/RequestRideTwo.dart'; // Import your second screen
import 'package:sizemore_taxi/ridedetail/RideDetailsScreen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
}

class RideOption {
  final String id;
  final String title;
  final String imagePath;
  final String time;
  final String price;
  final bool isPopular;
  final bool eco;

  RideOption({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.time,
    required this.price,
    this.isPopular = false,
    this.eco = false,
  });
}

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  String _currentDateTime = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  LatLng? fromLatLng;
  LatLng? toLatLng;

  bool _isLoadingLocation = true;
  bool _isCalculating = false;
  bool _showRideOptions = false;

  List<RideOption> _rideOptions = [];

  bool _isSearching = false; // ✅ ADD THIS to fix the undefined error
  StreamSubscription? _rideSubscription;
  @override
  void initState() {
    super.initState();
    _updateDateTime();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
    _getCurrentLocation();

    // ✅ LISTEN TO SOCKET FOR THE "LINK"
    _rideSubscription = SocketService.instance.rideUpdates.listen((data) {
      if (mounted) {
        // If we get driver info or a trip ID, it means the driver is linked
        if (data.containsKey('driverName') || data['tripId'] != null) {
          final String? tripId = data['tripId'];
          // ✅ JOIN ROOM HERE
          if (tripId != null) {
            // ✅ JOIN ROOM SAFELY
            SocketService.instance.joinTripRoom(tripId);
          }
          setState(() {
            _isSearching = false; // ✅ STOPS THE LOADING BAR
          });

          // Navigate to the Live Tracking Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PassengerRideDetailScreen(rideData: data), // Ensure this exists
            ),
          );
        }
      }
    });
  }
  @override
  void dispose() {
    _rideSubscription?.cancel(); // Stop listening when screen is closed
    super.dispose();
  }
  @override

  @override


  void _updateDateTime() {
    final now = DateTime.now();
    _currentDateTime = DateFormat('EEEE, MMMM d • hh:mm a').format(now);
    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

        setState(() {
          fromController.text = address;
          fromLatLng = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// 🚗 STEP 1: Get Prices/Options from Backend
  Future<void> _onRequestRidePressed() async {
    if (selectedDate == null || selectedTime == null) {
      _showMessage("Please select date & time");
      return;
    }
    if (fromLatLng == null || toLatLng == null) {
      _showMessage("Please select pickup & destination");
      return;
    }

    // Combine date/time for the backend
    final scheduled = DateTime(
      selectedDate!.year, selectedDate!.month, selectedDate!.day,
      selectedTime!.hour, selectedTime!.minute,
    );

    setState(() {
      _isCalculating = true;
      _showRideOptions = false;
      _rideOptions.clear();
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // ✅ 1. Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('https://sizemoretaxi-itpj.onrender.com/api/trips/options'),
        headers: {'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token', // ✅ 2. ADD THIS LINE
        },
        body: jsonEncode({
          "riderId": userProvider.id, // ✅ Real ID
          "pickupLocation": fromLatLng!.toJson(),
          "dropoffLocation": toLatLng!.toJson(),
          "scheduledTime": scheduled.toIso8601String(), // ✅ Real Time
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final vehicles = jsonResponse['data']['vehicles'] as List<dynamic>;

        setState(() {
          // First map to RideOption with correct titles & icons
          List<RideOption> mappedOptions = vehicles.map((v) {
            final type = v['type'] as String;

            String title;
            String imagePath;
            bool isPopular = false;
            bool eco = true;

            switch (type) {
              case "Comfort":
                title = "Comfort";
                imagePath = 'assets/icons/comfort.png';
                isPopular = true; // as you had
                break;
              case "bussines":
                title = "Business";
                imagePath = 'assets/icons/sedan.png';
                break;
              case "Premium":
                title = "Premium";
                imagePath = 'assets/icons/premium-service.png';
                break;
              case "Chopper":
                title = "Chopper";
                imagePath = 'assets/icons/chopper.png';
                eco = false; // as you had (only chopper non-eco)
                break;
              default:
                title = type; // fallback
                imagePath = 'assets/images/icons/default.png'; // add a default if needed
            }

            return RideOption(
              id: type,
              title: title,
              imagePath: imagePath,
              time: "${v['durationMin']} min away",
              price: "KES ${v['total']}",
              isPopular: isPopular,
              eco: eco,
            );
          }).toList();

          // Now sort to enforce your desired order: Comfort → Business → Premium → Chopper
          const order = ['Comfort', 'Business', 'Premium', 'Chopper'];
          mappedOptions.sort((a, b) {
            final indexA = order.indexOf(a.title);
            final indexB = order.indexOf(b.title);
            return indexA.compareTo(indexB);
          });

          _rideOptions = mappedOptions;

          _isCalculating = false;
          _showRideOptions = true;
        });





      } else {
        throw Exception("Failed to fetch ride options");
      }


    } catch (e) {
      setState(() => _isCalculating = false);
      _showMessage("Error: $e");
    }
  }



  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text("Request a Ride", style: GoogleFonts.manrope(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Inputs
              _locationInputField(
                title: "From",
                hint: "Your current location",
                controller: fromController,
                icon: Icons.my_location_rounded,
                isLoading: _isLoadingLocation,
                onLatLngSelected: (l) => fromLatLng = l,
              ),
              const SizedBox(height: 12),
              _locationInputField(
                title: "To",
                hint: "Where are you going?",
                controller: toController,
                icon: Icons.location_on_rounded,
                onLatLngSelected: (l) => toLatLng = l,
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_currentDateTime, style: GoogleFonts.manrope(color: Colors.white70, fontSize: 15)),
              ),

              const SizedBox(height: 20),

              // Schedule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Schedule your ride", style: GoogleFonts.manrope(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    DateTimePickerWidget(onDateTimeSelected: (date, time) {
                      setState(() {
                        selectedDate = date;
                        selectedTime = time;
                      });
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Main Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isCalculating ? null : _onRequestRidePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD60A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isCalculating
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text("Check Prices", style: GoogleFonts.manrope(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),

              // ✅ Ride Options List
              if (_showRideOptions && _rideOptions.isNotEmpty) ...[
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text("Choose your ride", style: GoogleFonts.manrope(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                ..._rideOptions.map((option) => GestureDetector(
                  onTap: () {
                    // ✅ Navigate to Confirmation Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestRideTwo(
                          selectedOption: option,
                          pickupAddress: fromController.text,
                          dropoffAddress: toController.text,
                          pickupLatLng: fromLatLng!,
                          dropoffLatLng: toLatLng!,
                          scheduledDate: selectedDate!,
                          scheduledTime: selectedTime!,
                        ),
                      ),
                    );
                  },
                  child: _rideOption(
                    imagePath: option.imagePath,
                    title: option.title,
                    time: option.time,
                    price: option.price,
                    isPopular: option.isPopular,
                    eco: option.eco,
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationInputField({
    required String title,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isLoading = false,
    required Function(LatLng) onLatLngSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: controller,
              googleAPIKey: EnvHelper.googleMapsKey,
              inputDecoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: Icon(icon, color: const Color(0xFFFFD60A)),
                suffixIcon: isLoading ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
                border: InputBorder.none,
              ),
              textStyle: const TextStyle(color: Colors.white),
              countries: const ["ke"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction p) {
                if (p.lat != null && p.lng != null) {
                  onLatLngSelected(LatLng(double.parse(p.lat!), double.parse(p.lng!)));
                }
              },
              itemClick: (p) {
                controller.text = p.description ?? "";
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _rideOption({
    required String imagePath,
    required String title,
    required String time,
    required String price,
    bool isPopular = false,
    bool eco = false,
  }) {
    // Define the unified theme color
    const Color brandYellow = Color(0xFFFFD60A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular ? brandYellow.withOpacity(0.5) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            // Styled Icon Container
            Container(
              height: 60,
              width: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: brandYellow.withOpacity(0.05), // Very subtle yellow glow
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                // THIS TINTS THE PNG TO ONE COLOR
                color: brandYellow,
                colorBlendMode: BlendMode.modulate,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.car_rental, color: brandYellow),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      )
                  ),
                  Text(
                      time,
                      style: const TextStyle(color: Colors.white54, fontSize: 14)
                  ),
                ],
              ),
            ),

            // Price
            Text(
                price,
                style: GoogleFonts.manrope(
                    color: brandYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.w800
                )
            ),

          ],
        ),
      ),
    );
  }
}

// ✅ DATE TIME PICKER WIDGET
class DateTimePickerWidget extends StatefulWidget {
  final void Function(DateTime, TimeOfDay) onDateTimeSelected;
  const DateTimePickerWidget({super.key, required this.onDateTimeSelected});

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> _pick() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() {
      selectedDate = date;
      selectedTime = time;
    });
    widget.onDateTimeSelected(date, time);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFFFFD60A)),
            const SizedBox(width: 12),
            Text(
              selectedDate == null ? "Tap to schedule" : "${DateFormat('d MMM').format(selectedDate!)} at ${selectedTime!.format(context)}",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}