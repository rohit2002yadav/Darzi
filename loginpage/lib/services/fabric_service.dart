
// This file defines the `FabricService` class, which is responsible for handling all
// network operations related to fabrics. It acts as a bridge between the app's UI
// and the backend API, providing a clean and organized way to fetch, add, and update
// fabric data.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.

// A service class that encapsulates all API calls for the 'fabrics' resource.
class FabricService {
  // The base URL for all fabric-related API endpoints.
  static const String baseUrl = "https://darziapplication.onrender.com/api/fabrics";

  /// Fetches a list of all fabrics available for a specific tailor.
  ///
  /// This method makes a GET request to the `/api/fabrics/tailor/{tailorId}` endpoint.
  /// It returns a list of maps, where each map represents a single fabric object.
  /// Throws an [Exception] if the request fails or the server returns an error code.
  static Future<List<Map<String, dynamic>>> getFabricsForTailor(String tailorId) async {
    try {
      // Make the GET request.
      final response = await http.get(Uri.parse("$baseUrl/tailor/$tailorId"));
      // Check if the request was successful (HTTP status code 200 OK).
      if (response.statusCode == 200) {
        // Decode the JSON response body, which is expected to be a list.
        final List<dynamic> data = jsonDecode(response.body);
        // Convert the list of dynamic objects into a list of maps.
        return List<Map<String, dynamic>>.from(data);
      } else {
        // If the server returns an error, decode the error message and throw an exception.
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load fabrics');
      }
    } catch (e) {
      // Catch any network-related errors or exceptions from the block above.
      print("FabricService Error fetching fabrics: $e");
      // Throw a user-friendly exception to be handled by the UI.
      throw Exception("Could not fetch fabrics. Please try again.");
    }
  }

  /// Adds a new fabric to the database for a tailor.
  ///
  /// This method makes a POST request to the `/api/fabrics` endpoint.
  /// The `fabricData` map is sent as the JSON body of the request.
  /// It expects an HTTP 201 Created status code for success.
  /// Throws an [Exception] if the request fails.
  static Future<void> addFabric(Map<String, dynamic> fabricData) async {
    try {
      // Make the POST request, setting the appropriate headers and encoding the body.
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(fabricData),
      );
      // A successful creation should return a 201 status code.
      if (response.statusCode != 201) {
        // If not successful, handle the error.
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add fabric');
      }
    } catch (e) {
      // Catch and report any errors.
      print("FabricService Error adding fabric: $e");
      throw Exception("Could not add fabric. Please try again.");
    }
  }

  /// Updates an existing fabric by its ID.
  ///
  /// This method makes a PUT request to the `/api/fabrics/{fabricId}` endpoint.
  /// The `fabricData` map contains the fields to be updated.
  /// It expects an HTTP 200 OK status code for success.
  /// Throws an [Exception] if the request fails.
  static Future<void> updateFabric(String fabricId, Map<String, dynamic> fabricData) async {
    try {
      // Make the PUT request to the specific fabric's URL.
      final response = await http.put(
        Uri.parse("$baseUrl/$fabricId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(fabricData),
      );
      // A successful update should return a 200 status code.
      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update fabric');
      }
    } catch (e) {
      print("FabricService Error updating fabric: $e");
      throw Exception("Could not update fabric. Please try again.");
    }
  }
}
