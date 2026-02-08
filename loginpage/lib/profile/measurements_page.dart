
// This file defines the screen where a user can manage their saved measurement profiles.
// It provides functionality to view a list of all saved profiles, add new ones for different
// garment types, and delete profiles that are no longer needed.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../services/measurement_service.dart'; // The service class to handle API calls for measurement profiles.

// The main widget for the MeasurementsPage. It's a StatefulWidget because its state
// (the list of profiles, loading state) changes based on user actions.
class MeasurementsPage extends StatefulWidget {
  // `userData` contains the details of the logged-in user, which is needed for API calls.
  final Map<String, dynamic> userData;
  const MeasurementsPage({super.key, required this.userData});

  @override
  State<MeasurementsPage> createState() => _MeasurementsPageState();
}

// This class holds the state and logic for the MeasurementsPage.
class _MeasurementsPageState extends State<MeasurementsPage> {
  // --- STATE VARIABLES ---
  late List<dynamic> _profiles; // A list to hold the user's measurement profiles.
  bool _isLoading = false; // A flag to track when an API call is in progress.

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Initialize the `_profiles` list by safely extracting it from the user data passed to the widget.
    // The `?? []` provides an empty list as a fallback if no profiles exist.
    _profiles = widget.userData['customerDetails']?['measurementProfiles'] ?? [];
  }

  /// This function handles the logic for deleting a measurement profile.
  /// It calls the `MeasurementService`, updates the local state, and shows feedback to the user.
  Future<void> _deleteProfile(String id) async {
    // Set loading state to true to show a spinner.
    setState(() => _isLoading = true);
    try {
      // Make the API call to delete the profile.
      final updatedProfiles = await MeasurementService.deleteProfile(widget.userData['phone'], id);
      if (!mounted) return; // Safety check before updating the UI.
      // On success, update the local list of profiles with the new list from the server.
      setState(() {
        _profiles = updatedProfiles;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile deleted!"), backgroundColor: Colors.green,));
    } catch (e) {
      // If an error occurs, show a red snackbar with the error message.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red,));
    } finally {
      // This block always runs. We ensure the loading spinner is turned off.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// This function displays a modal bottom sheet that contains a form for adding a new measurement profile.
  void _showAddProfileSheet() {
    // Controllers and state variables for the form within the bottom sheet.
    final nameController = TextEditingController();
    String selectedGarment = "Shirt";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to avoid being covered by the keyboard.
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        // Adjust padding to keep content visible when the keyboard is open.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // The sheet should only be as tall as its content.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Profile Name (e.g., My Best Fit)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGarment,
              decoration: const InputDecoration(labelText: "Garment Type", border: OutlineInputBorder()),
              items: ["Shirt", "Pant", "Kurta", "Suit"].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => selectedGarment = val!, // Update the selected garment when the dropdown changes.
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Basic validation.
                  if (nameController.text.isEmpty) return;
                  Navigator.pop(context); // Close the bottom sheet immediately for a responsive feel.
                  setState(() => _isLoading = true); // Show loading indicator on the main page.
                  try {
                    // Construct the new profile object.
                    final newProfile = {
                      "profileName": nameController.text,
                      "garmentType": selectedGarment,
                      // Note: These are placeholder measurements. A real implementation would have a more detailed form.
                      "measurements": {"Length": "40", "Chest": "38"} 
                    };
                    // Make the API call to add the new profile.
                    final updatedProfiles = await MeasurementService.addProfile(widget.userData['phone'], newProfile);
                    if (!mounted) return;
                    // Update the local state with the new list of profiles.
                    setState(() {
                      _profiles = updatedProfiles;
                    });
                  } catch (e) {
                    // Show an error message if the API call fails.
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text("Save Profile"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Measurements")),
      // The body of the scaffold changes based on the state.
      body: _isLoading 
        // State 1: Loading - Show a central progress indicator.
        ? const Center(child: CircularProgressIndicator())
        // State 2: Empty - If there are no profiles, show a helpful message.
        : _profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No saved measurements yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          // State 3: Data Available - Display the list of profiles.
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withAlpha(26),
                      child: Icon(Icons.person, color: theme.primaryColor),
                    ),
                    title: Text(profile['profileName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(profile['garmentType']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      // The delete button calls the _deleteProfile function with the profile's unique ID.
                      onPressed: () => _deleteProfile(profile['_id']),
                    ),
                  ),
                );
              },
            ),
      // The Floating Action Button is the primary action to add a new profile.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfileSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
