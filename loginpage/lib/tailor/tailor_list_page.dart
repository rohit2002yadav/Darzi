
// This file defines the screen where a customer can see a list of nearby tailors.
// It's a crucial part of the order flow, as it helps the user choose who will work on their garment.
// The key features of this screen are:
// 1. It automatically requests location permissions from the user.
// 2. It fetches the user's current GPS location.
// 3. It searches for tailors within an initial radius (e.g., 1km).
// 4. If no tailors are found, it automatically expands the search radius incrementally (up to 5km)
//    and retries the search, providing a better user experience.
// 5. It handles various states gracefully: loading, error (e.g., location permissions denied),
//    no tailors found, and a successful display of the tailor list.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // The plugin to get the device's GPS location.
import '../services/tailor_service.dart'; // The service class to fetch tailor data from the API.
import '../services/location_service.dart'; // A custom service to simplify location handling.

// The main widget for the TailorListPage. It's a StatefulWidget because its content
// is dynamic and depends on asynchronous data fetching (the list of tailors).
class TailorListPage extends StatefulWidget {
  // `userData` is passed from previous screens and will be passed along to the next.
  final Map<String, dynamic>? userData;
  const TailorListPage({super.key, this.userData});

  @override
  State<TailorListPage> createState() => _TailorListPageState();
}

// This class holds the state and logic for the TailorListPage.
class _TailorListPageState extends State<TailorListPage> {
  // --- STATE VARIABLES ---
  bool _isLoading = true; // Tracks if the app is currently fetching data.
  List<Map<String, dynamic>> _tailors = []; // The list of tailors fetched from the server.
  String? _errorMessage; // Stores any error message to be displayed to the user.
  Position? _currentPosition; // Stores the user's current geographical position.
  double _currentRadius = 1.0; // The current search radius in kilometers.

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Start the process of fetching tailors as soon as the page loads.
    _fetchTailorsWithRetry();
  }

  /// Fetches nearby tailors from the server with an incremental radius search logic.
  Future<void> _fetchTailorsWithRetry() async {
    if (!mounted) return; // Safety check: ensures the widget is still on screen.
    // Reset the state to show the loading indicator and clear previous errors.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentRadius = 1.0; // Reset radius for each new search attempt.
    });

    try {
      // 1. Request Permission: First, ensure the app has permission to access location.
      final hasPermission = await LocationService.requestPermission();
      if (!hasPermission) {
        throw Exception("Location permission is required to find nearby tailors.");
      }

      // 2. Get Location: Fetch the user's current GPS coordinates.
      _currentPosition = await LocationService.getCurrentLocation();

      if (_currentPosition == null) {
        // This can happen if the device's GPS is turned off.
        throw Exception("Could not determine your location. Please ensure GPS is enabled.");
      }

      // 3. Incremental Search: Try to find tailors, expanding the search area if none are found.
      List<Map<String, dynamic>> foundTailors = [];
      while (_currentRadius <= 5.0 && foundTailors.isEmpty) {
        // Make the API call with the current location and radius.
        final response = await TailorService.getRegisteredTailors(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          radius: _currentRadius,
        );
        foundTailors = response;
        // If no tailors were found and we haven't reached the max radius...
        if (foundTailors.isEmpty && _currentRadius < 5.0) {
          // ...increment the radius and the loop will continue.
          if (mounted) setState(() => _currentRadius += 1.0);
        } else {
          // If tailors are found or we've reached the max radius, exit the loop.
          break;
        }
      }

      // 4. Update UI: Update the state with the found tailors and stop loading.
      if (mounted) {
        setState(() {
          _tailors = foundTailors;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 5. Handle Errors: If any part of the process fails, store the error message.
      if (mounted) {
        setState(() {
          // Clean up the exception message for better readability.
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // The build method describes the main UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Nearby Verified Tailors"),
        actions: [
          // A refresh button to manually trigger the search again.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTailorsWithRetry,
          ),
        ],
      ),
      // The body is built by a helper method that handles different states.
      body: _buildBody(theme),
    );
  }

  /// A helper method that builds the body of the scaffold based on the current state.
  Widget _buildBody(ThemeData theme) {
    // State 1: Loading
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            // Display the current search radius to the user.
            Text("Searching tailors within ${_currentRadius.toInt()}km...",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // State 2: Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchTailorsWithRetry,
                label: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }

    // State 3: Empty (No tailors found)
    if (_tailors.isEmpty) {
      return const Center(
        child: Text("No tailors found nearby."),
      );
    }

    // State 4: Success (Data is available)
    return Column(
      children: [
        // A banner to inform the user about the final search radius.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: theme.primaryColor.withAlpha(13),
          child: Text("Showing tailors within ${_currentRadius.toInt()}km", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        // Display the list of tailors.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tailors.length,
            itemBuilder: (context, index) => _buildTailorCard(context, _tailors[index]),
          ),
        ),
      ],
    );
  }

  /// Builds a single, styled card widget for a tailor in the list.
  Widget _buildTailorCard(BuildContext context, Map<String, dynamic> tailor) {
    final theme = Theme.of(context);
    // Safely extract data from the tailor map with fallback values.
    final String shopName = tailor['shopName'] ?? tailor['name'] ?? "Tailor";
    final String specializations = (tailor['specializations'] as List?)?.join(", ") ?? "General Tailoring";
    final double rating = (tailor['rating'] ?? 4.5).toDouble();
    final double distance = (tailor['distance'] ?? 0.0).toDouble(); // This distance is calculated by the backend API.
    final bool homePickup = tailor['homePickup'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // When tapped, navigate to the tailor's profile page, passing along the necessary data.
        onTap: () => Navigator.pushNamed(context, '/tailor-profile', arguments: {
          'tailorData': tailor,
          'userData': widget.userData,
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(shopName, rating, theme, tailor['profilePictureUrl'] ?? ''),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(specializations, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                  const Divider(height: 24),
                  Row(children: [
                    _infoChip(Icons.near_me_outlined, "${distance.toStringAsFixed(1)} km away"),
                    const SizedBox(width: 8),
                    // Conditionally display the "Home Pickup" chip.
                    if (homePickup) _infoChip(Icons.home_outlined, "Home Pickup", color: Colors.green),
                  ]),
                  const SizedBox(height: 12),
                  const Text("✅ Verified Partner", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to build the header part of the tailor card.
  Widget _buildCardHeader(String shopName, double rating, ThemeData theme, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withAlpha(26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          // If there's no image, show the first letter of the shop name as a fallback.
          child: imageUrl.isEmpty ? Text(shopName[0]) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        // The rating display.
        Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(rating.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  /// A small, reusable helper widget to build a styled "chip" for displaying information like distance or services.
  Widget _infoChip(IconData icon, String text, {Color color = Colors.deepPurple}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // A light, transparent version of the provided color.
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
