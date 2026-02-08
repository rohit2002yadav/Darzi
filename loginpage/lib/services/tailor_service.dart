
// This file defines the `TailorService` class, which serves as a comprehensive
// data layer for interacting with the backend API. It encapsulates all network
// requests related to tailors, orders, and associated actions like updating status.
// This separation of concerns keeps the UI code clean from HTTP logic.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'dart:async'; // Provides asynchronous functionality like Future and timeout.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.
import 'package:shared_preferences/shared_preferences.dart'; // A plugin to store and retrieve simple data locally.
import '../models/order_model.dart'; // The data model for an 'Order'.

// A service class that centralizes all API communication.
class TailorService {
  // The base URL for all API endpoints. Centralizing it here makes it easy to update.
  static const String baseUrl = "https://darziapplication.onrender.com/api";

  /// A private helper method to asynchronously retrieve the user's authentication token
  /// from the device's local storage.
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// A private helper method to asynchronously retrieve the logged-in user's ID
  /// from local storage. This is particularly useful for tailor-specific API calls.
  static Future<String?> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  /* -------------------- ORDERS -------------------- */

  /// Submits a new order to the server.
  ///
  /// Takes a map `orderData` representing the complete order and sends it as a JSON
  /// payload in a POST request. Throws an exception if the request fails or the server
  /// returns an error.
  /// Returns the server's response body as a map on success.
  static Future<Map<String, dynamic>> postOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    ).timeout(const Duration(seconds: 60)); // Sets a 60-second timeout for the request.

    final data = jsonDecode(response.body);
    // Check for any error status codes (4xx or 5xx) and throw an exception if found.
    if (response.statusCode >= 400) throw Exception(data['error'] ?? "Failed to post order");
    return data;
  }

  /// Fetches a list of orders for the currently logged-in tailor, filtered by status.
  ///
  /// It first retrieves the tailor's ID from local storage. Then, it makes a GET request
  /// to fetch orders matching the given `status` (e.g., 'PENDING', 'ACTIVE').
  /// Returns a list of `Order` objects.
  static Future<List<Order>> getTailorOrders(String status) async {
    final tailorId = await _userId();
    if (tailorId == null) return []; // Return an empty list if no tailor ID is found.

    final response = await http.get(
      Uri.parse("$baseUrl/orders/tailor?tailorId=$tailorId&status=$status"),
      headers: {"Accept": "application/json"},
    ).timeout(const Duration(seconds: 60));

    final data = jsonDecode(response.body);
    // The response is expected to be a JSON array. It maps each item in the array to an `Order` object.
    if (data is List) return data.map((e) => Order.fromJson(e)).toList();
    return [];
  }

  /// Fetches all orders for a specific customer, identified by their phone number.
  ///
  /// Returns a list of `Order` objects.
  static Future<List<Order>> getCustomerOrders(String phone) async {
    final response = await http.get(Uri.parse("$baseUrl/orders/customer?phone=$phone"))
        .timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body);
    if (data is List) return data.map((e) => Order.fromJson(e)).toList();
    return [];
  }

  /* -------------------- TAILORS -------------------- */

  /// Fetches a list of registered tailors, optionally filtered by proximity.
  ///
  /// If latitude (`lat`) and longitude (`lng`) are provided, the API will return tailors
  /// within a specified `radius` of that location.
  /// Returns a list of maps, where each map represents a tailor.
  static Future<List<Map<String, dynamic>>> getRegisteredTailors({
    double? lat,
    double? lng,
    double radius = 1, // Default radius is 1 kilometer.
  }) async {
    String url = "$baseUrl/auth/tailors/nearby?radius=$radius";
    if (lat != null && lng != null) {
      url += "&lat=$lat&lng=$lng";
    }

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    final data = jsonDecode(response.body);
    
    // The server response is expected to be a map containing a 'tailors' key.
    if (data is Map && data.containsKey('tailors')) {
      return List<Map<String, dynamic>>.from(data['tailors']);
    } else if (data is Map && data.containsKey('error')) {
      throw Exception(data['error']);
    }
    
    return [];
  }

  /* -------------------- ACTIONS -------------------- */
  // These methods perform specific state-changing actions on an order.

  /// Confirms that the initial deposit for an order has been paid.
  static Future<void> confirmDeposit(String orderId) async {
    final response = await http.post(Uri.parse("$baseUrl/orders/$orderId/confirm-deposit"));
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? "Failed to confirm deposit");
    }
  }

  /// Accepts a pending order.
  static Future<void> acceptOrder(String orderId) async {
    await http.post(Uri.parse("$baseUrl/orders/$orderId/accept"));
  }

  /// Rejects a pending order.
  static Future<void> rejectOrder(String orderId) async {
    await http.post(Uri.parse("$baseUrl/orders/$orderId/reject"));
  }

  /// Updates the status of an order to the next step in the workflow.
  static Future<void> updateStatus(String orderId) async {
    await http.post(Uri.parse("$baseUrl/orders/$orderId/update-status"));
  }

  /* -------------------- ANALYTICS -------------------- */

  /// Fetches simple analytics data for the logged-in tailor.
  ///
  /// This might include metrics like the number of orders today, total earnings, etc.
  /// Returns a map of analytics data.
  static Future<Map<String, dynamic>> getAnalytics() async {
    final tailorId = await _userId();
    if (tailorId == null) return {'todayOrders': 0}; // Return default data if no user is logged in.

    final response = await http.get(Uri.parse("$baseUrl/orders/analytics?tailorId=$tailorId"))
        .timeout(const Duration(seconds: 60));

    return jsonDecode(response.body);
  }
}
