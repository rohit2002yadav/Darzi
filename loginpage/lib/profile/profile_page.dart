
// This file defines the main Profile screen for the application.
// It displays the user's basic information (name, email) and provides a menu
// with various navigation options. The menu items that are displayed change
// dynamically based on the user's role (either "customer" or "tailor").

import 'package:flutter/material.dart';

// The ProfilePage is a StatelessWidget because all the data it displays (`userData`)
// is passed in from its parent. It does not manage any internal state itself.
class ProfilePage extends StatelessWidget {
  // `userData` contains the details of the logged-in user.
  final Map<String, dynamic>? userData;

  const ProfilePage({super.key, this.userData});

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    // Safely extract user details from the `userData` map, providing default fallback values.
    final name = userData?['name'] ?? 'User';
    final email = userData?['email'] ?? 'user@example.com';
    final String role = userData?['role'] ?? 'customer';

    return Scaffold(
      backgroundColor: Colors.grey[100], // A light background color.
      appBar: AppBar(
        title: const Text('My Profile'),
        // `automaticallyImplyLeading: false` prevents Flutter from automatically adding a back button,
        // which is desired here since this page is part of the main bottom navigation.
        automaticallyImplyLeading: false,
        elevation: 1, // A subtle shadow for the app bar.
      ),
      // A ListView is used to ensure the content is scrollable, especially on smaller screens.
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 10),
          // The header section with the user's avatar, name, and email.
          _buildProfileHeader(name, email),
          const SizedBox(height: 20),
          
          // --- Account Section ---
          _buildSectionHeader("My Account"),
          _buildProfileCard([
            _buildProfileMenuItem(context, icon: Icons.edit_outlined, title: 'Edit Profile', onTap: () {
              // Navigate to the Edit Profile screen, passing along the user data.
              Navigator.pushNamed(context, '/edit-profile', arguments: userData);
            }),
            // This item is currently a placeholder with no action.
            _buildProfileMenuItem(context, icon: Icons.lock_outline, title: 'Change Password', onTap: () {}), 
          ]),

          // --- Role-Specific Sections ---
          // The `if` condition here dynamically changes the UI based on the user's role.
          if (role == 'customer') ...[
            _buildSectionHeader("My Orders"),
            _buildProfileCard([
              _buildProfileMenuItem(context, icon: Icons.straighten_outlined, title: 'My Measurements', onTap: () {
                Navigator.pushNamed(context, '/measurements', arguments: userData);
              }),
              _buildProfileMenuItem(context, icon: Icons.history_outlined, title: 'Order History', onTap: () {
                Navigator.pushNamed(context, '/order-history', arguments: userData);
              }),
            ]),
          ] else if (role == 'tailor') ...[
            _buildSectionHeader("My Business"),
            _buildProfileCard([
               _buildProfileMenuItem(context, icon: Icons.inventory_2_outlined, title: 'Manage My Fabrics', onTap: () {
                Navigator.pushNamed(context, '/tailor-fabrics', arguments: userData);
              }),
            ]),
          ],

          // --- General Section ---
          _buildSectionHeader("General"),
          _buildProfileCard([
            _buildProfileMenuItem(context, icon: Icons.settings_outlined, title: 'Settings', onTap: () {}),
            _buildProfileMenuItem(context, icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
          ]),

          const SizedBox(height: 20),
          // --- Logout Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () {
                // `pushNamedAndRemoveUntil` navigates to the login screen and clears all previous
                // screens from the navigation stack, ensuring the user can't go back after logging out.
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// A helper widget that builds the profile header, containing the user's avatar, name, and email.
  Widget _buildProfileHeader(String name, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.purple.shade100,
            // Display the first letter of the user's name in uppercase as a fallback avatar.
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // `overflow: TextOverflow.ellipsis` prevents long emails from breaking the layout.
                Text(email, style: const TextStyle(fontSize: 15, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget that builds a styled header for each section of the profile menu.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
  
  /// A helper widget that wraps a list of menu items in a styled `Card`.
  Widget _buildProfileCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  /// A helper widget that builds a single, tappable menu item (like "Edit Profile").
  /// It consists of an icon, a title, and a trailing arrow, and executes an `onTap` callback.
  Widget _buildProfileMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    // Use the provided color or default to black.
    final Color itemColor = color ?? Colors.black87;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: itemColor),
      title: Text(title, style: TextStyle(color: itemColor, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
