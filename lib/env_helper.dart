import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvHelper {
  // Google Maps Key
  static String get googleMapsKey {
    if (kIsWeb) {
      return 'AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM';  // Hardcoded for Web dev
    }
    return dotenv.env['GOOGLE_MAPS_KEY'] ?? 'AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM';
  }

  // Distance Matrix URL
  static String get distanceMatrixUrl {
    if (kIsWeb) {
      return 'https://maps.googleapis.com/maps/api/distancematrix/json';
    }
    return dotenv.env['API_URL'] ?? 'https://maps.googleapis.com/maps/api/distancematrix/json';
  }
}