
// This file defines the `MeasurementService` class, which is responsible for managing a user's
// saved measurement profiles. It provides methods to communicate with the backend API
// to add new measurement profiles and delete existing ones.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.
import 'tailor_service.dart'; // Imports another service, likely to reuse its base URL or other constants.

// A service class that encapsulates all API calls related to customer measurement profiles.
class MeasurementService {

  /// Adds a new measurement profile for a specific user, identified by their phone number.
  ///
  /// This method makes a POST request to the `/auth/measurements` endpoint.
  /// The `phone` number and the `profile` data (a map of measurements) are sent in the request body.
  /// Upon success, it returns the user's updated list of all their measurement profiles.
  ///
  /// Throws an [Exception] if the request fails or the server returns an error code.
  static Future<List<Map<String, dynamic>>> addProfile(String phone, Map<String, dynamic> profile) async {
    // Makes a POST request to the server.
    final response = await http.post(
      // The URL is constructed using a base URL from another service class, which is not ideal.
      // A better practice would be to use a shared `ApiConfig` class for the base URL.
      Uri.parse("${TailorService.baseUrl}/auth/measurements"),
      headers: {"Content-Type": "application/json"}, // Specifies that the request body is in JSON format.
      body: jsonEncode({"phone": phone, "profile": profile}), // Encodes the Dart map into a JSON string.
    );

    // Check if the request was successful (HTTP status code 200 OK).
    if (response.statusCode == 200) {
      // If successful, decode the JSON response body, which is expected to be a list.
      final data = jsonDecode(response.body) as List;
      // Convert the list of dynamic objects into a list of maps and return it.
      return List<Map<String, dynamic>>.from(data);
    } else {
      // If the server returns an error, throw an exception to be handled by the UI.
      throw Exception("Failed to add measurement profile");
    }
  }

  /// Deletes a specific measurement profile for a user.
  ///
  /// This method makes a DELETE request to the `/auth/measurements/{phone}/{profileId}` endpoint.
  /// The user is identified by their `phone` number, and the specific profile is identified by `profileId`.
  /// Upon success, it returns the user's updated list of remaining measurement profiles.
  ///
  /// Throws an [Exception] if the request fails or the server returns an error code.
  static Future<List<Map<String, dynamic>>> deleteProfile(String phone, String profileId) async {
    // Makes a DELETE request to a URL that includes the phone and profileId as path parameters.
    final response = await http.delete(
      Uri.parse("${TailorService.baseUrl}/auth/measurements/$phone/$profileId"),
    );

    // Check for a successful response.
    if (response.statusCode == 200) {
      // Decode the response and return the updated list of profiles.
      final data = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(data);
    } else {
      // If the request fails, throw an exception.
      throw Exception("Failed to delete measurement profile");
    }
  }
}
