
// This file defines the main dashboard screen for a user with the "tailor" role.
// It serves as the primary interface for tailors to manage their workflow.
// The screen is composed of a bottom navigation bar that allows switching between three main sections:
// 1. Dashboard: A tabbed view to see new, in-progress, and completed orders.
// 2. My Fabrics: A screen to manage fabric inventory (defined in `tailor_fabric_management_page.dart`).
// 3. Profile: The user's profile screen (defined in `profile_page.dart`).

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../profile/profile_page.dart'; // The user's profile screen.
import 'tailor_orders_tab.dart'; // A reusable widget that displays a list of orders for a given status.
import '../services/tailor_service.dart'; // The service class for fetching analytics and order data.
import 'tailor_fabric_management_page.dart'; // The screen for managing fabrics.

// The main widget for the tailor's home screen. It's a StatefulWidget because its state
// (selected tab, selected bottom nav item, analytics data) is dynamic.
class TailorHome extends StatefulWidget {
  // `userData` contains the logged-in tailor's details.
  final Map<String, dynamic> userData;
  const TailorHome({super.key, required this.userData});

  @override
  State<TailorHome> createState() => _TailorHomeState();
}

// This class holds the state and logic for the TailorHome screen.
// It uses `SingleTickerProviderStateMixin` which is necessary for the TabController's animation.
class _TailorHomeState extends State<TailorHome> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---

  late TabController _tabController; // Manages the state for the order status tabs (New, In Progress, etc.).
  late Future<Map<String, dynamic>> _analyticsFuture; // A Future to hold analytics data fetched from the server.
  int _bottomNavIndex = 0; // Keeps track of the currently selected item in the bottom navigation bar.

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 3 tabs.
    _tabController = TabController(length: 3, vsync: this);
    // Fetch the initial analytics data.
    _refreshAnalytics();
  }

  /// Fetches the latest analytics data from the server and updates the state.
  void _refreshAnalytics() {
    if (mounted) { // A safety check to ensure the widget is still on screen.
      setState(() {
        _analyticsFuture = TailorService.getAnalytics();
      });
    }
  }

  // dispose is a lifecycle method called when the widget is permanently removed.
  // It's important to dispose of controllers to free up resources.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// A callback function that is executed when a user taps on a bottom navigation bar item.
  void _onBottomNavTapped(int index) {
    if (_bottomNavIndex == index) return; // Do nothing if the same tab is tapped again.
    setState(() {
      _bottomNavIndex = index; // Update the state to the newly selected index.
    });
  }

  /// A helper widget that builds the main dashboard view, including the app bar with order tabs.
  Widget _buildTailorDashboard() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Don't show a back button.
        title: _buildHeader(), // The header contains the welcome message and analytics.
        // The `bottom` property of the AppBar is used to display the TabBar.
        bottom: TabBar(
          controller: _tabController,
          // Colors are explicitly set to ensure visibility against the AppBar's background.
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white, // The line that indicates the active tab.
          tabs: const [
            Tab(text: "New"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      // `TabBarView` displays the content for the currently selected tab.
      body: TabBarView(
        controller: _tabController,
        // Each child corresponds to a tab and is a reusable widget that fetches orders for a specific status.
        children: const [
          TailorOrdersTab(status: "PLACED"),
          TailorOrdersTab(status: "ONGOING"),
          TailorOrdersTab(status: "DELIVERED"),
        ],
      ),
    );
  }

  // The build method describes the main UI structure of the page.
  @override
  Widget build(BuildContext context) {
    // A list of the different pages that the bottom navigation bar can switch between.
    final List<Widget> pages = [
      _buildTailorDashboard(), // The main order management view (Index 0).
      TailorFabricManagementPage(userData: widget.userData), // The fabric inventory screen (Index 1).
      ProfilePage(userData: widget.userData), // The user profile screen (Index 2).
    ];

    return Scaffold(
      // `IndexedStack` is used as the body. It keeps all the pages in memory
      // but only shows the one corresponding to `_bottomNavIndex`.
      // This preserves the state of each page (e.g., scroll position) when switching tabs.
      body: IndexedStack(
        index: _bottomNavIndex,
        children: pages,
      ),
      // The main navigation bar at the bottom of the screen.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex, // Binds the active tab to our state variable.
        onTap: _onBottomNavTapped, // Sets the function to be called when a tab is tapped.
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'My Fabrics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// A helper widget that builds the custom header for the dashboard's app bar.
  /// It includes a welcome message and a summary of today's orders.
  Widget _buildHeader() {
    // Safely get the tailor's name from the user data.
    final name = widget.userData['name'] ?? 'Tailor';
    return Row(
      children: [
        // A circular avatar with the first letter of the tailor's name.
        CircleAvatar(
          backgroundColor: Colors.white.withAlpha(51), // A semi-transparent white background.
          child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi, $name! 👋", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            // `FutureBuilder` is used to display the analytics data once it's fetched.
            FutureBuilder<Map<String, dynamic>>(
              future: _analyticsFuture, // The future that this builder listens to.
              builder: (context, snapshot) {
                // If the future has completed with data...
                if (snapshot.hasData) {
                  final count = snapshot.data!['todayOrders'] ?? 0;
                  return Text("Today's Orders: $count", style: const TextStyle(fontSize: 14, color: Colors.white70));
                } else {
                  // While waiting for data or if there's an error, show a default value.
                  return const Text("Today's Orders: 0", style: TextStyle(fontSize: 14, color: Colors.white70));
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
