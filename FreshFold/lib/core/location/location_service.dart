import 'package:geolocator/geolocator.dart';

/// Thrown for any permission/service failure in [determinePosition] — the
/// message is written to be shown directly in a SnackBar.
class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Runs geolocator's permission dance and returns the device's current
/// position. Shared by the address form's "Use current location" button
/// and the map picker's "locate me" action.
Future<Position> determinePosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw LocationException('Location services are turned off. Please enable them and try again.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw LocationException('Location permission denied.');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw LocationException('Location permission permanently denied — enable it from app settings.');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
