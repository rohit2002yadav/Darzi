
// This file defines the "Order History" screen for a customer.
// It displays a list of the user's past and present orders, organized into three tabs:
// "Active", "Completed", and "Cancelled". The page fetches order data from a server
// and provides different views and actions for each order based on its status.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../../services/tailor_service.dart'; // Service class to fetch order data from the server.
import '../../models/order_model.dart'; // Data model representing an 'Order'.
import '../order/order_tracking_page.dart'; // The page to show detailed order tracking.
import '../../utils/order_status_helper.dart'; // A helper to get user-friendly status messages and colors.

// The main widget for the OrderHistory page. It's a StatefulWidget because its
// content is dynamic and depends on data fetched from a server.
class OrderHistoryPage extends StatefulWidget {
  // User data passed from the previous screen, containing user details like their phone number.
  final Map<String, dynamic>? userData;
  const OrderHistoryPage({super.key, this.userData});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

// This class holds the state and logic for the OrderHistoryPage.
// It uses `SingleTickerProviderStateMixin` which is necessary for animations, in this case, for the TabController.
class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  // A Future that will hold the list of orders fetched from the server.
  // Using a FutureBuilder with this allows the UI to show a loading state while data is being fetched.
  late Future<List<Order>> _ordersFuture;
  // A controller to manage the state and animations of the TabBar and TabBarView.
  late TabController _tabController;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 3 tabs.
    _tabController = TabController(length: 3, vsync: this);
    // Fetch the initial list of orders.
    _refreshOrders();
  }

  // dispose is a lifecycle method called when the widget is permanently removed.
  @override
  void dispose() {
    _tabController.dispose(); // It's important to dispose of the controller to free up resources.
    super.dispose();
  }

  // This function fetches the customer's orders from the server.
  void _refreshOrders() {
    // Get the phone number from the user data, which is used to identify the customer.
    final phone = widget.userData?['phone'] ?? '';
    if (phone.isNotEmpty) {
      // If the phone number exists, call the service to get the orders.
      setState(() {
        // The result is assigned to _ordersFuture, which will trigger the FutureBuilder to rebuild.
        _ordersFuture = TailorService.getCustomerOrders(phone);
      });
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // A light background color.
      appBar: AppBar(
        title: const Text("My Orders"),
        // The `bottom` property of the AppBar is a perfect place for a TabBar.
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      // FutureBuilder handles the asynchronous loading of order data.
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // 1. While waiting for data, show a loading spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. If an error occurs, display an error message.
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          // 3. If there's no data or the data list is empty, show a helpful message.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _EmptyState(
              message: "You haven't placed any orders yet.",
              buttonText: "Stitch Your First Garment",
              onPressed: () => Navigator.pushNamed(context, '/choose-fabric', arguments: widget.userData),
            );
          }

          // If data is successfully fetched, filter the orders into their respective categories.
          final allOrders = snapshot.data!;
          
          final activeOrders = allOrders.where((o) => 
              !['DELIVERED', 'CANCELLED', 'REJECTED'].contains(o.status)).toList();
          final completedOrders = allOrders.where((o) => o.status == 'DELIVERED').toList();
          final cancelledOrders = allOrders.where((o) => ["REJECTED", "CANCELLED"].contains(o.status)).toList();

          // TabBarView displays the content for the currently selected tab.
          return TabBarView(
            controller: _tabController,
            children: [
              // Each child of the TabBarView is a list of orders for that category.
              _OrderList(orders: activeOrders, userData: widget.userData, emptyMessage: "You have no active orders."),
              _OrderList(orders: completedOrders, userData: widget.userData, emptyMessage: "You have no completed orders."),
              _OrderList(orders: cancelledOrders, userData: widget.userData, emptyMessage: "No cancelled or rejected orders."),
            ],
          );
        },
      ),
    );
  }
}

/// A reusable widget that displays a list of orders.
/// If the list is empty, it shows a specified message.
class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final Map<String, dynamic>? userData;
  final String emptyMessage;

  const _OrderList({required this.orders, this.userData, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      // If there are no orders in this category, display the empty state widget.
      return _EmptyState(message: emptyMessage);
    }
    // Otherwise, build a list of order cards.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        // Conditionally render a different card widget based on the order's status.
        if (order.status == 'DELIVERED') {
          return _CompletedOrderCard(order: order, userData: userData);
        }
        if (['CANCELLED', 'REJECTED'].contains(order.status)) {
          return _CancelledOrderCard(order: order, userData: userData);
        }
        return _ActiveOrderCard(order: order, userData: userData);
      },
    );
  }
}

/// A card widget to display the details of an active order.
class _ActiveOrderCard extends StatelessWidget {
  final Order order;
  final Map<String, dynamic>? userData;
  const _ActiveOrderCard({required this.order, this.userData});

  @override
  Widget build(BuildContext context) {
    // Use helper functions to get user-friendly status text and corresponding color.
    final statusText = OrderStatusHelper.getUserFriendlyStatus(order.status);
    final statusColor = OrderStatusHelper.getStatusColor(order.status);

    // Only show the tailor's contact details if the order is past the 'PLACED' status.
    final bool showContactDetails = !['PLACED'].contains(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // Make the entire card tappable to navigate to the detailed tracking page.
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingPage(order: order, userData: userData))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order.garmentType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  // A styled `Chip` to display the order status.
                  Chip(
                    label: Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: statusColor.withAlpha(26),
                    labelStyle: TextStyle(color: statusColor),
                    padding: EdgeInsets.zero,
                  )
                ],
              ),
              const Divider(height: 24),
              _InfoRow(icon: Icons.store, title: "Tailor", subtitle: order.tailorName),
              // Conditionally display tailor's address and phone.
              if (showContactDetails && order.tailorAddress != null) 
                _InfoRow(icon: Icons.location_on_outlined, title: "Address", subtitle: order.tailorAddress!),
              if (showContactDetails && order.tailorPhone != null) 
                _InfoRow(icon: Icons.phone_outlined, title: "Phone", subtitle: order.tailorPhone!),
              _InfoRow(icon: Icons.calendar_today, title: "Ordered On", subtitle: order.createdAt?.toIso8601String().split('T').first ?? 'N/A'),
              const SizedBox(height: 16),
              // A prominent button to track the order.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingPage(order: order, userData: userData))),
                  icon: const Icon(Icons.track_changes),
                  label: const Text("Track Full Order"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// A card widget to display the details of a completed order.
class _CompletedOrderCard extends StatelessWidget {
  final Order order;
  final Map<String, dynamic>? userData;
  const _CompletedOrderCard({required this.order, this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(order.garmentType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Chip(
                  label: const Text('DELIVERED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green.withAlpha(26),
                  labelStyle: const TextStyle(color: Colors.green),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const Divider(height: 24),
            _InfoRow(icon: Icons.store, title: "Tailor", subtitle: order.tailorName),
            _InfoRow(icon: Icons.calendar_today, title: "Delivered On", subtitle: order.updatedAt?.toIso8601String().split('T').first ?? 'N/A'),
            _InfoRow(icon: Icons.currency_rupee, title: "Final Amount", subtitle: "₹${order.displayTotalAmount.toStringAsFixed(2)}"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text("View Details"))),
                const SizedBox(width: 12),
                // The "Reorder" button is currently disabled.
                const Expanded(child: ElevatedButton(onPressed: null, child: Text("Reorder"))), 
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// A card widget to display the details of a cancelled or rejected order.
class _CancelledOrderCard extends StatelessWidget {
  final Order order;
  final Map<String, dynamic>? userData;
  const _CancelledOrderCard({required this.order, this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                Expanded(child: Text(order.garmentType, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                Chip(
                  label: const Text('CANCELLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.red.withAlpha(26),
                  labelStyle: const TextStyle(color: Colors.red),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const Divider(height: 24),
            _InfoRow(icon: Icons.store, title: "Tailor", subtitle: order.tailorName),
            _InfoRow(icon: Icons.calendar_today, title: "Cancelled On", subtitle: order.updatedAt?.toIso8601String().split('T').first ?? 'N/A'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {}, child: const Text("Order Again"))
            )
          ],
        ),
      ),
    );
  }
}

/// A widget displayed when a list is empty.
/// It shows an icon, a message, and an optional call-to-action button.
class _EmptyState extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;
  const _EmptyState({required this.message, this.buttonText, this.onPressed});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.grey)),
        // Conditionally show the button only if text and a callback are provided.
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onPressed, child: Text(buttonText!))
        ]
      ],
    ),
  );
}

/// A small, reusable helper widget to display a row of information with a consistent style.
/// It consists of an icon, a title, and a subtitle.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text("$title: ", style: TextStyle(color: Colors.grey.shade800)),
        const Spacer(), // A spacer pushes the subtitle to the far right.
        Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
