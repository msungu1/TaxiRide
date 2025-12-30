import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacePredictionScreen extends StatefulWidget {
  @override
  _PlacePredictionScreenState createState() => _PlacePredictionScreenState();
}

class _PlacePredictionScreenState extends State<PlacePredictionScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;

  late final FlutterGooglePlacesSdk _placesSdk;

  @override
  void initState() {
    super.initState();
    _placesSdk = FlutterGooglePlacesSdk(dotenv.env['GOOGLE_PLACES_API_KEY']!);
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isLoading = true);

    final response = await _placesSdk.findAutocompletePredictions(
      input,
      countries: ['ke'], // Change to your country
      newSessionToken: true,
    );

    setState(() {
      _predictions = response.predictions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text("Search Places", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E1E1E),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Where to?",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
                prefixIcon: Icon(Icons.search, color: Color(0xFFFFD60A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (value) => _searchPlaces(value),
            ),
          ),

          _isLoading
              ? Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFFFFD60A)))
              : Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final place = _predictions[index];
                return ListTile(
                  leading: Icon(Icons.location_on, color: Color(0xFFFFD60A)),
                  title: Text(
                    place.fullText,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    place.secondaryText ?? "",
                    style: TextStyle(color: Colors.white54),
                  ),
                  onTap: () async {
                    // Get full place details
                    final details = await _placesSdk.fetchPlace(
                      place.placeId,
                      fields: [PlaceField.Location],  // This line fixes it!
                    );
                    final lat = details?.place?.latLng?.lat;
                    final lng = details?.place?.latLng?.lng;
                    print("Selected: ${place.fullText} → ($lat, $lng)");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Selected: ${place.fullText}")),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}