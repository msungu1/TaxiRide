// import 'package:flutter/material.dart';
// import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// class PlacePredictionScreen extends StatefulWidget {
//   @override
//   _PlacePredictionScreenState createState() => _PlacePredictionScreenState();
// }
//
// class _PlacePredictionScreenState extends State<PlacePredictionScreen> {
//   final TextEditingController _controller = TextEditingController();
//   List<AutocompletePrediction> _predictions = [];
//   bool _isLoading = false;
//
//   late final FlutterGooglePlacesSdk _placesSdk;
//
//   @override
//   void initState() {
//     super.initState();
//     _placesSdk = FlutterGooglePlacesSdk(dotenv.env['GOOGLE_PLACES_API_KEY']!);
//   }
//
//   Future<void> _searchPlaces(String input) async {
//     if (input.isEmpty) {
//       setState(() => _predictions = []);
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     final response = await _placesSdk.findAutocompletePredictions(
//       input,
//       countries: ['ke'], // Change to your country
//       newSessionToken: true,
//     );
//
//     setState(() {
//       _predictions = response.predictions;
//       _isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0D0D0D),
//       appBar: AppBar(
//         title: Text("Search Places", style: TextStyle(color: Colors.white)),
//         backgroundColor: Color(0xFF1E1E1E),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: TextField(
//               controller: _controller,
//               style: TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: "Where to?",
//                 hintStyle: TextStyle(color: Colors.white54),
//                 filled: true,
//                 fillColor: Color(0xFF1E1E1E),
//                 prefixIcon: Icon(Icons.search, color: Color(0xFFFFD60A)),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
//               ),
//               onChanged: (value) => _searchPlaces(value),
//             ),
//           ),
//
//           _isLoading
//               ? Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFFFFD60A)))
//               : Expanded(
//             child: ListView.builder(
//               itemCount: _predictions.length,
//               itemBuilder: (context, index) {
//                 final place = _predictions[index];
//                 return ListTile(
//                   leading: Icon(Icons.location_on, color: Color(0xFFFFD60A)),
//                   title: Text(
//                     place.fullText,
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   subtitle: Text(
//                     place.secondaryText ?? "",
//                     style: TextStyle(color: Colors.white54),
//                   ),
//                   onTap: () async {
//                     // Get full place details
//                     final details = await _placesSdk.fetchPlace(
//                       place.placeId,
//                       fields: [PlaceField.Location],  // This line fixes it!
//                     );
//                     final lat = details?.place?.latLng?.lat;
//                     final lng = details?.place?.latLng?.lng;
//                     print("Selected: ${place.fullText} → ($lat, $lng)");
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Selected: ${place.fullText}")),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacePredictionScreen extends StatefulWidget {
  const PlacePredictionScreen({super.key});

  @override
  State<PlacePredictionScreen> createState() => _PlacePredictionScreenState();
}

class _PlacePredictionScreenState extends State<PlacePredictionScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Search Places", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _controller,
              googleAPIKey: dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '', // From .env
              inputDecoration: InputDecoration(
                hintText: "Where to?",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD60A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              debounceTime: 600, // ms before search
              countries: const ["ke"], // Restrict to Kenya
              isLatLngRequired: true, // Get lat/lng
              getPlaceDetailWithLatLng: (Prediction prediction) {
                print("Place: ${prediction.description}");
                print("Lat: ${prediction.lat}, Lng: ${prediction.lng}");
                // Here you can save to state, navigate, or use for ride
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Selected: ${prediction.description}\n($prediction.lat, $prediction.lng)"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              itemClick: (Prediction prediction) {
                _controller.text = prediction.description ?? "";
                // Optional: trigger getPlaceDetailWithLatLng automatically
              },
              itemBuilder: (context, index, Prediction prediction) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFD60A)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prediction.description ?? "",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              seperatedBuilder: const Divider(),
              isCrossBtnShown: true,
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFFFD60A)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}