
// This file defines the screen where a user can edit their basic profile information.
// It provides a simple form pre-filled with the user's current data (name, email, phone)
// and allows them to make changes. It also includes UI for changing the profile picture,
// though the implementation for that and the actual saving of data to the backend are placeholders.

import 'package:flutter/material.dart';

// The main widget for the EditProfilePage. It's a StatefulWidget because it manages
// the state of the form fields through TextEditingControllers.
class EditProfilePage extends StatefulWidget {
  // `userData` contains the current details of the logged-in user.
  final Map<String, dynamic>? userData;

  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

// This class holds the state and logic for the EditProfilePage.
class _EditProfilePageState extends State<EditProfilePage> {
  // --- STATE VARIABLES ---
  // Controllers to manage the text inside the input fields.
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with the user's existing data, which is passed
    // into the widget. This pre-fills the form for the user.
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phone'] ?? '');
  }

  // dispose is a lifecycle method called when the widget is permanently removed.
  // It's crucial to dispose of controllers to free up resources and prevent memory leaks.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// This function is called when the "Save Changes" button is pressed.
  /// Currently, it contains placeholder logic.
  void _handleSaveChanges() {
    // TODO: Implement the actual API call to the backend to save the updated user profile.
    // This would involve sending the new values from the text controllers to a server endpoint.

    // For now, it just shows a success message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // After "saving", it navigates back to the previous screen (the profile page).
    Navigator.of(context).pop();
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // A helper widget to build the user avatar with an edit button.
            _buildAvatar(),
            const SizedBox(height: 40),
            // Helper widgets to build the text fields for name, email, and phone.
            _buildTextField(_nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
            const SizedBox(height: 40),
            // The main action button to save the changes.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSaveChanges,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget that builds the circular user avatar with an overlapping edit icon.
  Widget _buildAvatar() {
    // `Stack` allows widgets to be layered on top of each other.
    return Stack(
      children: [
        const CircleAvatar(
          radius: 60,
          // Currently uses a placeholder image URL.
          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
        ),
        // `Positioned` is used within a Stack to place a widget at a specific location.
        Positioned(
          bottom: 0, // Position at the bottom of the CircleAvatar.
          right: 0,  // Position at the right of the CircleAvatar.
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: () {
                // TODO: Implement the image picking logic.
                // This would typically open the device's gallery for the user to select a new profile picture.
              },
            ),
          ),
        ),
      ],
    );
  }

  /// A reusable helper widget to create a styled TextFormField.
  /// It takes a controller, a label, and an icon to create a consistent look for all text fields.
  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
