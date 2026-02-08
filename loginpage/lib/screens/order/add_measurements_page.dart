
// This file defines the screen where a customer adds their measurements for a garment.
// It's a crucial step in the order process. The page is designed to be user-friendly by:
// 1. Allowing users to select from previously saved measurement profiles.
// 2. Providing manual entry fields tailored to the specific garment type (e.g., Shirt, Pant).
// 3. Offering visual guides (images) and text descriptions for each measurement.
// 4. Including a video guide link for general assistance.
// 5. Giving an option for users who are unsure of their measurements to let the tailor contact them.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:url_launcher/url_launcher.dart'; // A plugin to launch URLs, used here for the video guide.

// The main widget for the AddMeasurements page. It's a StatefulWidget because its state
// changes based on user input, such as typing in fields or selecting a profile.
class AddMeasurementsPage extends StatefulWidget {
  // User data passed from the previous screen. It contains garment type, customer details, etc.
  final Map<String, dynamic>? userData;
  const AddMeasurementsPage({super.key, this.userData});

  @override
  State<AddMeasurementsPage> createState() => _AddMeasurementsPageState();
}

// This class holds the state and logic for the AddMeasurementsPage.
class _AddMeasurementsPageState extends State<AddMeasurementsPage> {
  // --- STATE VARIABLES ---

  // A key to uniquely identify the Form widget and allow for validation.
  final _formKey = GlobalKey<FormState>();
  // A map to hold the TextEditingControllers for each measurement field.
  final Map<String, TextEditingController> _controllers = {};
  // The ID of the currently selected saved measurement profile.
  String? _selectedProfileId;
  // A flag to track if the user has checked the "I am not sure" box.
  bool _isNotSure = false;

  // A list to store the user's saved measurement profiles for the current garment type.
  late List<dynamic> _savedProfiles;
  // The type of garment being ordered (e.g., "Shirt", "Pant").
  late String _garmentType;

  // A map containing helpful text descriptions for each type of measurement.
  final Map<String, String> _measurementGuides = {
    "Length": "Measure from the highest point of the shoulder down to where you want the garment to end.",
    "Chest": "Wrap the tape around the fullest part of your chest. Keep it comfortable, not tight.",
    "Shoulder": "Measure from the edge of one shoulder to the other across your back.",
    "Sleeve": "Measure from the shoulder edge down to your wrist, with your arm relaxed.",
    "Waist": "Wrap the tape around your natural waistline, usually just above the navel.",
    "Hip": "Measure around the fullest part of your hips and bottom.",
    "Thigh": "Measure around the fullest part of your thigh."
  };

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Determine the garment type from the user data, defaulting to 'Shirt'.
    _garmentType = widget.userData?['garmentType'] ?? 'Shirt';
    
    // Filter the user's saved profiles to only show those that match the current garment type.
    _savedProfiles = (widget.userData?['customerDetails']?['measurementProfiles'] ?? [])
        .where((p) => p['garmentType'] == _garmentType)
        .toList();

    // Get the required measurement fields for the garment and create a controller for each one.
    final fields = _getFieldsForGarment(_garmentType);
    for (var field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  // A helper function to determine which measurement fields are needed for a given garment type.
  List<String> _getFieldsForGarment(String type) {
    if (type == "Pant") return ["Length", "Waist", "Hip", "Thigh"];
    if (type == "Kurta") return ["Length", "Chest", "Shoulder", "Sleeve"];
    return ["Length", "Chest", "Shoulder", "Sleeve"]; // Default for Shirt/Suit
  }

  // This function is called when a user taps on a saved measurement profile.
  // It populates the input fields with the data from that profile.
  void _applyProfile(Map<String, dynamic> profile) {
    setState(() {
      _selectedProfileId = profile['_id'];
      final measurements = profile['measurements'] as Map<String, dynamic>;
      // Iterate through the measurements in the profile and update the corresponding controller's text.
      measurements.forEach((key, value) {
        if (_controllers.containsKey(key)) {
          _controllers[key]!.text = value.toString();
        }
      });
    });
  }

  // This function displays a pop-up (ModalBottomSheet) with an image and text guide for a specific measurement.
  void _showMeasurementImage(String fieldName) {
    final imageName = fieldName.toLowerCase(); // e.g., "Chest" -> "chest"
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$fieldName Measurement Guide", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Display the measurement image from the assets folder.
              Image.asset(
                'assets/images/measurements/$imageName.png',
                // If the image fails to load, show a placeholder with an error message.
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          "Illustration for '$fieldName' is missing",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Display the corresponding guide text.
              Text(_measurementGuides[fieldName] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // This function uses the url_launcher package to open the YouTube video guide in a browser or app.
  void _launchVideoGuide() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=8Og50_VZCWI');
    if (!await launchUrl(url)) {
      if (mounted) {
        // If launching the URL fails, show a snackbar with an error message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch video guide.')),
        );
      }
    }
  }

  // A helper widget to build the small help text and "View Image" button that appears below each input field.
  Widget _buildHelpText(String fieldName, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 12, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          const Spacer(), // Pushes the following button to the end of the row.
          TextButton.icon(
            onPressed: () => _showMeasurementImage(fieldName),
            icon: const Icon(Icons.image_outlined, size: 16),
            label: const Text("View Image", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("$_garmentType Measurements")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SAVED PROFILES SECTION ---
              // This section is only displayed if the user has any saved profiles for this garment type.
              if (_savedProfiles.isNotEmpty) ...[
                const Text("Select from Saved Profiles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  // A horizontal list of saved profiles.
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedProfiles.length,
                    itemBuilder: (context, index) {
                      final profile = _savedProfiles[index];
                      final isSelected = _selectedProfileId == profile['_id'];
                      return GestureDetector(
                        onTap: () => _applyProfile(profile),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          // The card's appearance changes based on whether it is selected.
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(profile['profileName'], 
                                style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                                textAlign: TextAlign.center,
                              ),
                              Text("Saved Fit", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // --- MANUAL ENTRY SECTION ---
              const Text("Manual Entry (inches)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              
              // The button to launch the video guide.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Watch a General Measurement Video Guide"),
                  onPressed: _launchVideoGuide,
                ),
              ),
              const SizedBox(height: 12),

              // Dynamically create a TextFormField for each required measurement.
              ..._controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: entry.value,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: entry.key,
                          suffixText: "in", // Suffix to indicate the unit is inches.
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        // Validation logic for the field.
                        validator: (val) {
                          if (_isNotSure) return null; // Skip validation if user is not sure.
                          if (val == null || val.isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid number";
                          return null; // Return null if the input is valid.
                        },
                      ),
                      _buildHelpText(entry.key, _measurementGuides[entry.key] ?? "Enter the measurement in inches."),
                    ],
                  ),
                );
              }).toList(),
              
              const Divider(height: 32),

              // --- 'NOT SURE' CHECKBOX ---
              CheckboxListTile(
                title: const Text("I am not sure about the measurements"),
                subtitle: const Text("The tailor can contact you to confirm or adjust."),
                value: _isNotSure,
                onChanged: (bool? value) {
                  setState(() {
                    _isNotSure = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // Place checkbox at the start.
                activeColor: theme.primaryColor,
              ),

              const SizedBox(height: 100), // Extra space to prevent the bottom sheet from covering content.
            ],
          ),
        ),
      ),
      // The bottom sheet provides a persistent "Next" button at the bottom of the screen.
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Proceed if the user is not sure OR if the form is valid.
                if (_isNotSure || _formKey.currentState!.validate()) {
                  // Convert the text controller values into a map of measurements.
                  final Map<String, double> measurements = _controllers.map((key, controller) {
                    return MapEntry(key, _isNotSure ? 0.0 : double.tryParse(controller.text) ?? 0.0);
                  });
                  
                  // Navigate to the next page ('/fabric-handover'), passing along all the order data.
                  Navigator.pushNamed(context, '/fabric-handover', arguments: {
                    ...?widget.userData, // Pass existing user data.
                    'measurements': measurements,
                    'notes': _isNotSure ? 'Customer is not sure about measurements.' : null,
                  });
                }
              },
              child: const Text("Next: Choose Handover Method"),
            ),
          ),
        ),
      ),
    );
  }
}
