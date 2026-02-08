
// This file defines the initial screen for starting a new order.
// It presents the user with three primary choices for how they want to source the fabric
// for their garment, which is the first step in the order creation process.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The StartNewOrderPage is a StatelessWidget because it only displays static information
// and its state does not change based on user interaction within this screen itself.
// The navigation is handled by the `onTap` callbacks.
class StartNewOrderPage extends StatelessWidget {
  const StartNewOrderPage({super.key});

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50], // Set background to a light purple color.
      appBar: AppBar(
        title: const Text('Start a New Order'),
        backgroundColor: Colors.purple[50], // Match the app bar color to the background.
        elevation: 0, // Remove the shadow from the app bar for a flatter look.
        iconTheme: const IconThemeData(color: Colors.black87), // Style for icons in the app bar (like the back button).
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ), // Style for the title text.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // A ListView is used to ensure the content is scrollable, especially on smaller screens.
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // A reusable card widget for the first option.
            _buildOptionCard(
              context,
              icon: Icons.inventory_2_outlined, // An icon representing having your own items.
              text: 'I Have My Own Fabric',
              onTap: () {
                // When tapped, navigate to the screen where the user enters their fabric details.
                Navigator.pushNamed(context, '/fabric-details');
              },
            ),
            const SizedBox(height: 16), // Spacing between the cards.
            // A card for the second option.
            _buildOptionCard(
              context,
              icon: Icons.store_outlined, // An icon representing a marketplace or store.
              text: 'Buy Fabric from Platform',
              onTap: () {
                // This feature is not yet implemented, as indicated by the TODO comment.
                // TODO: Navigate to the fabric marketplace
              },
            ),
            const SizedBox(height: 16),
            // A card for the third option.
            _buildOptionCard(
              context,
              icon: Icons.person_search_outlined, // An icon representing finding a person (the tailor).
              text: 'Tailor Will Provide Fabric',
              onTap: () {
                // This feature is also not yet implemented.
                // TODO: Navigate to the tailor selection
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A reusable helper widget to build the tappable option cards with a consistent style.
  /// It takes an icon, text, and an `onTap` callback function as parameters.
  Widget _buildOptionCard(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap}) {
    final Color primaryColor = Theme.of(context).primaryColor; // Get the app's primary color for styling.
    return Card(
      elevation: 1, // A very subtle shadow for depth.
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell( // InkWell provides the ripple effect on tap.
        onTap: onTap, // The function to execute when the card is tapped.
        borderRadius: BorderRadius.circular(12), // Ensures the ripple effect has rounded corners.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: primaryColor), // The main icon for the card.
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
