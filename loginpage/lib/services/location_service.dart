
// This file defines the `LocationService` class, a utility that abstracts away the complexities
// of using the `geolocator` package. It provides simple, static methods to handle common
// location-related tasks like requesting permissions and fetching the device's current GPS position.

import 'package:geolocator/geolocator.dart'; // The core plugin for accessing device location.

// A service class that encapsulates all location-related logic.
// Using a service class like this helps keep the UI code clean and separates concerns.
class LocationService {

  /// Handles the process of checking and requesting location permissions from the user.
  ///
  /// It follows the standard flow recommended by the `geolocator` package:
  /// 1. Check the current permission status.
  /// 2. If permission is denied, request it from the user.
  /// 3. Handle cases where permission is denied permanently.
  ///
  /// Returns `true` if permissions are granted, and `false` otherwise.
  static Future<bool> requestPermission() async {
    // Check the current state of location permissions.
    LocationPermission permission = await Geolocator.checkPermission();
    
    // If permissions are denied, we need to ask the user for them.
    if (permission == LocationPermission.denied) {
      // This triggers the native OS permission dialog.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // If the user explicitly denies the request this time, we can't proceed.
        // The app can try asking again later.
        return false;
      }
    }
    
    // If permissions are denied forever, the user has blocked the app from asking again.
    // In this case, the only way to enable permissions is through the device's app settings.
    if (permission == LocationPermission.deniedForever) {
      // The app should ideally guide the user to their settings screen.
      return false;
    }

    // If we reach this point, it means permissions have been successfully granted.
    return true;
  }

  /// Fetches the device's current geographical position (latitude and longitude).
  ///
  /// This method performs the necessary checks before attempting to get the location:
  /// 1. It verifies that location services are enabled on the device itself.
  /// 2. It requests location permission (though it's good practice to call `requestPermission` explicitly before this).
  ///
  /// Returns a `Position` object on success, or `null` if location services are disabled
  /// or if an error (like permission denial) occurs.
  static Future<Position?> getCurrentLocation() async {
    try {
      // First, check if location services are enabled globally on the device (e.g., GPS is turned on).
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If location services are off, we cannot get a location.
        // The app should inform the user and prompt them to enable location services.
        print("Location services are disabled.");
        return null;
      }

      // After confirming services are enabled and permissions are granted (implicitly handled by geolocator),
      // fetch the current position with high accuracy.
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // This catch block will handle various exceptions, such as if the user denies
      // permission when `getCurrentPosition` is called without a prior permission check.
      print("Error getting location: $e");
      return null;
    }
  }
}
