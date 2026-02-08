
// This file defines the main home page of the application, which acts as a navigator
// and container for the primary user interface after they have logged in.
// The key feature of this page is that it dynamically displays a different UI
// based on the user's role (either "customer" or "tailor").

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// Import the different screens that this home page can display.
import 'customer/customer_home_view.dart'; // The customer's main dashboard.
import 'customer/order_history_page.dart'; // The customer's list of orders.
import '../tailor/tailor_list_page.dart'; // The page for browsing tailors.
import '../tailor/tailor_home.dart'; // The main dashboard for a tailor user.
import '../profile/profile_page.dart'; // The user's profile screen.

// The main widget for the HomePage. It's a StatefulWidget because its state
// (the selected navigation index) changes based on user interaction.
class HomePage extends StatefulWidget {
  // `userData` contains the logged-in user's details, including their role.
  final Map<String, dynamic>? userData;
  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

// This class holds the state and logic for the HomePage.
class _HomePageState extends State<HomePage> {
  // --- STATE VARIABLE ---
  // `_selectedIndex` keeps track of which tab is currently active in the BottomNavigationBar.
  // It defaults to 0, which corresponds to the 'Home' tab.
  int _selectedIndex = 0;

  // This function is called when a user taps on an item in the BottomNavigationBar.
  void _onItemTapped(int index) {
    // If the tapped item is already the selected one, do nothing to prevent unnecessary rebuilds.
    if (_selectedIndex == index) return;
    // Update the state to the new index, which will trigger a rebuild of the widget.
    setState(() {
      _selectedIndex = index;
    });
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the app's theme for consistent styling.
    // Safely get the user's role from the userData, defaulting to 'customer' if it's not found.
    final String role = widget.userData?['role'] ?? 'customer';

    // --- ROLE-BASED UI LOGIC ---
    // If the user's role is 'tailor', we completely bypass the customer UI
    // and show the dedicated TailorHome screen instead.
    if (role == 'tailor') {
      return TailorHome(userData: widget.userData ?? {});
    }

    // --- CUSTOMER UI ---
    // This is the UI that will be built for users with the 'customer' role.

    // A list of the different pages that the customer can navigate between using the bottom bar.
    final List<Widget> customerPages = [
      CustomerHomeView(userData: widget.userData), // Index 0
      OrderHistoryPage(userData: widget.userData), // Index 1
      TailorListPage(userData: widget.userData),   // Index 2
      ProfilePage(userData: widget.userData),      // Index 3
    ];

    return Scaffold(
      // The `IndexedStack` is a crucial widget for this type of navigation.
      // It keeps all the pages in the `customerPages` list in memory and mounted in the widget tree,
      // but it only shows the single child specified by `index`. This preserves the state
      // of each page as the user switches between them (e.g., scroll position).
      body: IndexedStack(
        index: _selectedIndex,
        children: customerPages,
      ),
      // The main navigation bar at the bottom of the screen.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Binds the active tab to our state variable.
        onTap: _onItemTapped, // Sets the function to be called when a tab is tapped.
        type: BottomNavigationBarType.fixed, // Ensures all items are always visible with their labels.
        selectedItemColor: theme.primaryColor, // The color of the icon and label for the active tab.
        unselectedItemColor: Colors.grey.shade600, // The color for inactive tabs.
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold), // A bolder font for the active tab's label.
        items: [
          BottomNavigationBarItem(
            // Using Text widgets with emojis for icons provides a simple, custom look.
            icon: const Text('🏠', style: TextStyle(fontSize: 24)),
            // The `activeIcon` is a special icon shown only when the item is selected.
            // Here, it places a colored circle behind the emoji for a nice visual effect.
            activeIcon: CircleAvatar(
              radius: 18,
              backgroundColor: theme.primaryColor.withAlpha(26), // A light, transparent version of the primary color.
              child: const Text('🏠', style: TextStyle(fontSize: 24)),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Text('📦', style: TextStyle(fontSize: 24)),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Text('✂️', style: TextStyle(fontSize: 24)),
            label: 'Tailors',
          ),
          const BottomNavigationBarItem(
            icon: Text('👤', style: TextStyle(fontSize: 24)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
