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
import 'package:sizemore_taxi/env_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
    _getCurrentLocation();
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
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
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        setState(() {
          fromController.text = address;
          fromLatLng = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print("Location error: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE, MMMM d • hh:mm a').format(now);
    setState(() => _currentDateTime = formatted);
  }

  // Get real prices from your backend
  Future<void> _onRequestRidePressed() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select date & time")));
      return;
    }
    if (fromLatLng == null || toLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select pickup & destination")));
      return;
    }

    setState(() {
      _isCalculating = true;
      _showRideOptions = false;
      _rideOptions.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('https://sizemoretaxi.onrender.com/api/trip/options'),        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "riderId": "test_rider_123", // replace with real auth later
          "pickupLocation": fromLatLng!.toJson(),
          "dropoffLocation": toLatLng!.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final vehicles = json['data']['vehicles'] as List;

        final List<RideOption> options = vehicles.map((v) {
          final type = v['type'] as String;
          return RideOption(
            id: type,
            title: type == "Car" ? "Sedan" : type == "Bike" ? "Chopper" : "Neta EV",
            imagePath: type == "Car"
                ? 'assets/images/sedan.png'
                : type == "Bike"
                ? 'assets/images/chopper.jpeg'
                : 'assets/images/neta.png',
            time: "${v['durationMin'] ?? 5} min away",
            price: "KES ${v['total']}",
            isPopular: type == "Car",
            eco: type == "Van" || type == "Neta",
          );
        }).toList();

        setState(() {
          _rideOptions = options;
          _isCalculating = false;
          _showRideOptions = true;
        });

        // Smooth scroll to ride options
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isCalculating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load prices: $e')));
    }
  }

  // Confirm trip after user selects a vehicle
  Future<void> _confirmRide(String vehicleType) async {
    final scheduled = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    try {
      final response = await http.post(
        Uri.parse('https://sizemoretaxi.onrender.com/api/trip/options'),        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "riderId": "test_rider_123",
          "pickupLocation": fromLatLng!.toJson(),
          "dropoffLocation": toLatLng!.toJson(),
          "vehicleType": vehicleType,
          "scheduledTime": scheduled.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride confirmed! Finding driver..."), backgroundColor: Colors.green),
        );
        // Navigate to waiting screen
        // Navigator.pushNamed(context, '/waiting');
        Navigator.pop(context); // or go to home
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to confirm ride")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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

              // From & To fields
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

              // Schedule Picker
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

              // Request Ride Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isCalculating ? null : _onRequestRidePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD60A),
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isCalculating
                        ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                    )
                        : Text("Request Ride", style: GoogleFonts.manrope(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),

              // Ride Options (appear after calculation)
              if (_showRideOptions && _rideOptions.isNotEmpty) ...[
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text("Choose your ride", style: GoogleFonts.manrope(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                ..._rideOptions.map((option) => GestureDetector(
                  onTap: () => _confirmRide(option.id),
                  child: _rideOption(
                    imagePath: option.imagePath,
                    title: option.title,
                    time: option.time,
                    price: option.price,
                    isPopular: option.isPopular,
                    eco: option.eco,
                  ),
                )),
                const SizedBox(height: 120),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Location Input Field
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
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: controller,
              googleAPIKey: EnvHelper.googleMapsKey,
              inputDecoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.manrope(color: Colors.white54, fontSize: 16),
                prefixIcon: Icon(icon, color: const Color(0xFFFFD60A), size: 26),
                suffixIcon: isLoading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD60A)))
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              textStyle: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
              debounceTime: 400,
              countries: const ["ke"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction p) {
                if (p.lat != null && p.lng != null) {
                  final lat = double.tryParse(p.lat!);
                  final lng = double.tryParse(p.lng!);
                  if (lat != null && lng != null) onLatLngSelected(LatLng(lat, lng));
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

  // Ride Option Card
  Widget _rideOption({
    required String imagePath,
    required String title,
    required String time,
    required String price,
    bool isPopular = false,
    bool eco = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPopular ? const Color(0xFFFFD60A) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(imagePath, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.manrope(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                      if (isPopular)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFD60A), borderRadius: BorderRadius.circular(20)),
                            child: Text("POPULAR", style: GoogleFonts.manrope(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (eco) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.eco, color: Colors.greenAccent, size: 22)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: GoogleFonts.manrope(color: const Color(0xFFAAAAAA), fontSize: 15)),
                ],
              ),
            ),
            Text(price, style: GoogleFonts.manrope(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// DateTime Picker Widget
class DateTimePickerWidget extends StatefulWidget {
  final void Function(DateTime, TimeOfDay) onDateTimeSelected;
  const DateTimePickerWidget({super.key, required this.onDateTimeSelected});

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFFFD60A), onPrimary: Colors.black)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      if (selectedTime != null) widget.onDateTimeSelected(selectedDate!, selectedTime!);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFFFD60A))), child: child!),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
      if (selectedDate != null) widget.onDateTimeSelected(selectedDate!, selectedTime!);
    }
  }

  String _formatDateTime() {
    if (selectedDate == null || selectedTime == null) return "Tap to schedule ride";
    final combined = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
    return DateFormat("EEE, d MMM • hh:mm a").format(combined);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _selectDate();
        await _selectTime();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFFFFD60A), size: 26),
            const SizedBox(width: 16),
            Text(_formatDateTime(), style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}