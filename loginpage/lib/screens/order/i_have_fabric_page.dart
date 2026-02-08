
// This file defines the screen where a user, who has indicated they already have fabric,
// can provide specific details about it. This includes the type of fabric, its length,
// its color, and an optional photo. This information is then passed to the next step
// in the order process, which is selecting a tailor.

import 'dart:io'; // Used for creating a File object from a path, necessary for displaying the picked image on mobile.
import 'package:flutter/foundation.dart' show kIsWeb; // A utility to check if the app is running on the web, to handle image display correctly.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:image_picker/image_picker.dart'; // A plugin to allow the user to pick images from their phone's gallery or camera.

// The main widget for the IHaveFabricPage. It's a StatefulWidget because its state
// changes as the user fills out the form.
class IHaveFabricPage extends StatefulWidget {
  // User data passed from the previous screen, which will be aggregated and passed to the next.
  final Map<String, dynamic>? userData;
  const IHaveFabricPage({super.key, this.userData});

  @override
  State<IHaveFabricPage> createState() => _IHaveFabricPageState();
}

// This class holds the state and logic for the IHaveFabricPage.
class _IHaveFabricPageState extends State<IHaveFabricPage> {
  // --- STATE VARIABLES ---

  // A key to uniquely identify the Form widget and allow for validation.
  final _formKey = GlobalKey<FormState>();
  // A controller to read and manage the text inside the fabric length input field.
  // It's pre-filled with a default value of '2.5'.
  final _lengthController = TextEditingController(text: '2.5');
  // State variables to hold the user's selection from the dropdown menus.
  String? _selectedFabricType;
  String? _selectedFabricColor;
  // A variable to store the image file picked by the user.
  XFile? _imageXFile;

  // A map that defines the available fabric colors and their corresponding Flutter Color objects.
  // This is used to build the color selection dropdown with visual swatches.
  final Map<String, Color> _fabricColors = {
    "Red": Colors.red, "Orange": Colors.orange, "Yellow": Colors.yellow,
    "Green": Colors.green, "Blue": Colors.blue, "Purple": Colors.purple,
    "Pink": Colors.pink, "Brown": Colors.brown, "Black": Colors.black,
    "White": Colors.white, "Gray": Colors.grey, "Cream": const Color(0xFFFFFDD0),
    "Navy": const Color(0xFF000080), "Teal": Colors.teal,
  };

  // This function handles the logic for picking an image from the device's gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Use the image_picker plugin to show the gallery and await the user's choice.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // If the user picks an image, update the state to store the image file.
    if (image != null) setState(() => _imageXFile = image);
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // A light background color for the page.
      appBar: AppBar(title: const Text('Fabric Details')),
      body: Form(
        key: _formKey, // Associate the form key with the Form widget.
        // Use a ListView to ensure the content is scrollable on smaller screens.
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text("Enter your fabric details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("This helps the tailor prepare for your order.", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 32),
            
            // Widget for uploading a photo of the fabric.
            _buildPhotoUpload(theme),
            const SizedBox(height: 32),
            
            // A reusable dropdown widget for selecting the fabric type.
            _buildDropdown(
              'Fabric Type',
              _selectedFabricType,
              ["Cotton", "Silk", "Linen", "Rayon", "Khadi", "Velvet", "Denim", "Satin"], // List of available fabric types.
              (val) => setState(() => _selectedFabricType = val), // Update state on selection.
              'Select a fabric type',
            ),
            const SizedBox(height: 24),
            
            // A section for entering the fabric length.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fabric Length', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lengthController,
                  keyboardType: TextInputType.number, // Show a numeric keyboard.
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: "pieces", // Unit displayed in the input field.
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  // Basic validation to ensure the field is not empty.
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // A specialized dropdown for selecting the fabric color.
            _buildColorDropdown(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // A persistent bottom navigation bar containing the main action button.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // Validate the form and check if all required dropdowns are selected.
              if (_formKey.currentState!.validate() && _selectedFabricType != null && _selectedFabricColor != null) {
                // If everything is valid, navigate to the tailor list screen.
                Navigator.pushNamed(context, '/tailor-list', arguments: {
                  ...?widget.userData, // Pass along all existing user data.
                  // Add the newly collected fabric details to the arguments.
                  'fabricDetails': {
                    'type': _selectedFabricType,
                    'length': _lengthController.text,
                    'color': _selectedFabricColor,
                    'photoPath': _imageXFile?.path, // Include the path to the uploaded photo.
                  }
                });
              } else {
                // If validation fails, show a snackbar prompting the user to complete the form.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all details")));
              }
            },
            child: const Text('Find Nearby Tailors'),
          ),
        ),
      ),
    );
  }

  /// A helper widget to build the photo upload area.
  Widget _buildPhotoUpload(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage, // Trigger the image picker when tapped.
      child: Container(
        height: 160, width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        // If an image has been picked, display it.
        child: _imageXFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                // Use Image.network for web and Image.file for mobile platforms.
                child: kIsWeb 
                    ? Image.network(_imageXFile!.path, fit: BoxFit.cover) 
                    : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
              )
            // If no image is selected, show a placeholder with an icon and prompt text.
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_outlined, size: 48, color: theme.primaryColor.withAlpha(128)), 
                const SizedBox(height: 12), 
                const Text('Upload fabric photo (Optional)', style: TextStyle(color: Colors.black54))
              ]),
      ),
    );
  }

  /// A reusable helper widget to create a styled DropdownButtonFormField with a label.
  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
      ),
    ]);
  }

  /// A helper widget specifically for the fabric color dropdown.
  Widget _buildColorDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Fabric Color', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _selectedFabricColor,
        hint: const Text('Select a color'),
        // Map over the _fabricColors map to create dropdown items.
        // Each item contains a color swatch and the name of the color.
        items: _fabricColors.entries.map((e) => DropdownMenuItem(value: e.key, child: Row(children: [
          _colorSwatch(e.value), // The visual color circle.
          const SizedBox(width: 12), 
          Text(e.key)
        ]))).toList(),
        onChanged: (val) => setState(() => _selectedFabricColor = val),
        decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300))),
      ),
    ]);
  }

  /// A small helper widget that creates a circular color swatch.
  Widget _colorSwatch(Color color) => Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)));
}
