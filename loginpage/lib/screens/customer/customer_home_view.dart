
// This file defines the main home screen for a "Customer" user.
// It serves as a dashboard, displaying a welcome message, providing navigation to key features
// like creating a new order or viewing order history, showing garment categories, and
// displaying the status of the most recent active order.

import 'package:flutter/material.dart'; // Core Flutter framework for UI.
import '../../models/order_model.dart'; // Data model for an 'Order'.
import '../../services/tailor_service.dart'; // Service class to fetch order data from the server.
import '../order/order_tracking_page.dart'; // The page to show detailed order tracking.
import '../../utils/order_status_helper.dart'; // A helper to get user-friendly status messages.

// The main widget for the Customer's home view. It's a StatefulWidget because its
// content, particularly the list of orders, is dynamic and will change.
class CustomerHomeView extends StatefulWidget {
  // User data passed from the login/home page, containing user details like name and phone.
  final Map<String, dynamic>? userData;
  const CustomerHomeView({super.key, this.userData});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

// This class holds the state and logic for the CustomerHomeView.
class _CustomerHomeViewState extends State<CustomerHomeView> {
  // A Future that will hold the list of orders fetched from the server.
  // Using a FutureBuilder with this allows the UI to show a loading state.
  late Future<List<Order>> _ordersFuture;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Fetch the initial list of orders.
    _refreshOrders();
  }

  // This function fetches the customer's orders from the server.
  // It's called from initState and also when the user performs a "pull-to-refresh".
  void _refreshOrders() {
    // Get the phone number from the user data. It's used as an identifier to fetch orders.
    final phone = widget.userData?['phone'] ?? '';
    if (phone.isNotEmpty) {
      // If the phone number exists, call the service to get the orders.
      setState(() {
        // The result is assigned to _ordersFuture, which will trigger the FutureBuilder to update.
        _ordersFuture = TailorService.getCustomerOrders(phone);
      });
    } else {
      // If there's no phone number, return an empty list of orders.
      _ordersFuture = Future.value([]); // Ensure future is not null to avoid errors.
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get the user's name for the welcome message, defaulting to 'Guest'.
    final String name = widget.userData?['name'] ?? 'Guest';

    return Scaffold(
      backgroundColor: Colors.grey[50], // A light grey background for the page.
      body: SafeArea(
        // RefreshIndicator enables the "pull-to-refresh" functionality.
        child: RefreshIndicator(
          onRefresh: () async => _refreshOrders(), // The function to call on refresh.
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            // The main content is a list of widgets.
            children: [
              _buildHeader(name),
              const SizedBox(height: 32),
              // Action card for creating a new order.
              _buildActionCard(
                context,
                theme: theme,
                icon: Icons.cut_outlined,
                title: "Stitch a New Garment",
                subtitle: "Choose a tailor and let's get started.",
                routeName: '/choose-fabric',
              ),
              const SizedBox(height: 16),
              // Action card for viewing order history.
              _buildActionCard(
                context,
                theme: theme,
                icon: Icons.receipt_long_outlined,
                title: "My Orders",
                subtitle: "Track your active and past orders.",
                routeName: '/order-history',
              ),
              const SizedBox(height: 32),
              _buildSectionHeader("Categories"),
              const SizedBox(height: 12),
              _buildCategoriesList(context, theme),
              const SizedBox(height: 32),
              _buildSectionHeader("Your Recent Order"),
              const SizedBox(height: 12),
              // This widget uses a FutureBuilder to display the most recent order.
              _buildRecentOrder(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  /// Builds the header section with a welcome message and user's name.
  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text("👕", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome Back,", style: TextStyle(color: Colors.grey)),
              Text("$name! 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a reusable, tappable card for major actions on the home screen.
  Widget _buildActionCard(BuildContext context, {required ThemeData theme, required IconData icon, required String title, required String subtitle, required String routeName}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          // When tapped, navigate to the specified route.
          onTap: () => Navigator.pushNamed(context, routeName, arguments: widget.userData),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(children: [
              Icon(icon, size: 36, color: theme.primaryColor),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ]),
          ),
        ),
      ),
    );
  }

  /// Builds a simple text header for different sections of the page.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  /// Builds the horizontal scrolling list of garment categories.
  Widget _buildCategoriesList(BuildContext context, ThemeData theme) {
    // A hardcoded list of categories. This could be fetched from a server in a real app.
    final categories = [
      {"name": "Shirt", "icon": "👔"},
      {"name": "Pant", "icon": "👖"},
      {"name": "Kurta", "icon": "🥻"},
      {"name": "Blouse", "icon": "👚"},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            // When a category is tapped, navigate to the fabric choice screen,
            // passing along user data and the selected garment type.
            onTap: () => Navigator.pushNamed(context, '/choose-fabric', arguments: {
              ...?widget.userData, // Merges the existing user data.
              'garmentType': category['name'], // Adds the selected garment type.
            }),
            child: SizedBox(
              width: 80,
              child: Column(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.primaryColor.withAlpha(13), // A light shade of the primary color.
                  child: Text(category['icon']!, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 8),
                Text(category['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        },
      ),
    );
  }

  /// Builds the widget that displays the user's most recent active order.
  Widget _buildRecentOrder(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      // FutureBuilder handles the asynchronous loading of order data.
      child: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // 1. While waiting for data, show a loading spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
          }
          // Filter the orders to get only the ones that are currently active.
          final activeOrders = snapshot.data?.where((o) => !['DELIVERED', 'CANCELLED', 'REJECTED'].contains(o.status)).toList() ?? [];
          
          // 2. If there are no active orders, show a prompt to create one.
          if (activeOrders.isEmpty) {
            return Card(
              elevation: 0,
              color: theme.primaryColor.withAlpha(13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.primaryColor.withAlpha(51))),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  const Text("You have no active orders.", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Let's change that!", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/choose-fabric', arguments: widget.userData), child: const Text("Stitch Your First Garment")),
                ]),
              ),
            );
          }

          // 3. If there are active orders, display the first one as the "most recent".
          final recentOrder = activeOrders.first;
          // Use a helper to get a more readable status message.
          final statusText = OrderStatusHelper.getUserFriendlyStatus(recentOrder.status);

          return GestureDetector(
              // When tapped, navigate to the detailed order tracking page.
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingPage(order: recentOrder, userData: widget.userData))),
              child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
                title: Text(recentOrder.garmentType, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: $statusText", style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              ),
            ),
          );
        },
      ),
    );
  }
}
