
// This file defines a reusable widget that displays a list of orders for a tailor,
// filtered by a specific status (e.g., "PLACED", "ONGOING", "DELIVERED").
// It's designed to be used within a TabBarView on the tailor's main dashboard.
// The key features include:
// - Fetching and displaying orders based on the given status.
// - Providing a "pull-to-refresh" functionality.
// - Rendering different, specialized card widgets for each order status,
//   optimizing the UI for the actions a tailor needs to take at each stage.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Not used here, but likely kept for future features.
import '../models/order_model.dart'; // The data model for an 'Order'.
import '../services/tailor_service.dart'; // The service class to fetch order data.
import 'order_detail.dart'; // The detailed view for a single order.
import '../../utils/order_status_helper.dart'; // A helper for status-related text and colors.

// The main widget for a single tab in the tailor's order view.
// It's a StatefulWidget because it manages the state of the orders being displayed.
class TailorOrdersTab extends StatefulWidget {
  // The status category that this tab is responsible for (e.g., "PLACED").
  final String status;
  const TailorOrdersTab({super.key, required this.status});

  @override
  State<TailorOrdersTab> createState() => _TailorOrdersTabState();
}

// This class holds the state and logic for the TailorOrdersTab.
class _TailorOrdersTabState extends State<TailorOrdersTab> {
  // A Future that will hold the list of orders fetched from the server.
  // Using a FutureBuilder with this allows the UI to show a loading state.
  late Future<List<Order>> _ordersFuture;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    _refreshOrders(); // Fetch the initial list of orders.
  }

  /// Fetches the tailor's orders from the server for the widget's specific status.
  /// It updates the state, which triggers the FutureBuilder to rebuild.
  void _refreshOrders() {
    if (mounted) { // Safety check to ensure the widget is still on screen.
      setState(() {
        _ordersFuture = TailorService.getTailorOrders(widget.status);
      });
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    // RefreshIndicator provides the "pull-to-refresh" functionality.
    return RefreshIndicator(
      onRefresh: () async => _refreshOrders(), // The function to call on refresh.
      // FutureBuilder handles the asynchronous loading of order data.
      child: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          // 1. While waiting for data, show a loading spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. If an error occurs, display an error message.
          if (snapshot.hasError) {
            return Center(child: Text("An error occurred: ${snapshot.error}"));
          }
          // 3. If there's no data or the list is empty, show a helpful "empty state" message.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No orders in this category", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. If data is successfully fetched, display it in a ListView.
          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Use a switch statement to render the appropriate card widget for the order's status.
              // This is a clean way to handle different UI representations for each tab.
              switch (widget.status) {
                case 'PLACED':
                  return _NewOrderCard(order: order, onAction: _refreshOrders);
                case 'ONGOING':
                  return _InProgressOrderCard(order: order, onAction: _refreshOrders);
                case 'DELIVERED':
                  return _CompletedOrderCard(order: order);
                default:
                  return const SizedBox.shrink(); // Return an empty widget if the status is unknown.
              }
            },
          );
        },
      ),
    );
  }
}

// --- CARD WIDGET FOR NEW ORDERS ('PLACED' TAB) ---
// This widget is highly optimized to show a lot of information in a compact, expandable format.
class _NewOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAction; // A callback to refresh the list after an action.
  const _NewOrderCard({required this.order, required this.onAction});

  /// A generic handler for performing an action (like accepting/rejecting an order).
  /// It wraps the API call in a try-catch block and shows a success/error snackbar.
  Future<void> _handleAction(BuildContext context, Future<void> action) async {
    try {
      await action; // Perform the API call.
      onAction();   // Trigger the refresh callback on success.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order status updated!"), backgroundColor: Colors.green));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  /// A helper to create a very short summary of measurements (e.g., "L:30 C:40").
  /// Returns "Not Provided" if measurements are missing or all zero.
  String _getMeasurementSummary(Map<String, dynamic>? measurements) {
    if (measurements == null || measurements.isEmpty || measurements.values.every((v) => v == 0.0)) return "Not Provided";
    // Maps each measurement to its first letter and value, then joins them.
    return measurements.entries.map((e) => "${e.key[0]}:${e.value}").join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias, // Ensures the ExpansionTile's background respects the card's rounded corners.
      // ExpansionTile is perfect for showing a summary and hiding details until they are needed.
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // Custom padding for the un-expanded tile.
        // The `title` of the ExpansionTile is the main compact summary.
        title: _buildCompactSummary(),
        // The `subtitle` is cleverly used here to display the main action buttons directly below the summary.
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _buildActionButtons(context, theme),
        ),
        // The `children` are the widgets that appear when the tile is expanded.
        children: [_buildExpansionDetails()],
      ),
    );
  }

  /// Builds the main summary view shown when the tile is collapsed.
  Widget _buildCompactSummary() {
    final isPickup = order.handoverType == 'pickup';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(order.garmentType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Display a shortened, more readable version of the order ID.
            Text("#${order.id.substring(order.id.length - 6).toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        // A series of reusable info rows to display key details concisely.
        _CompactInfoRow(icon: Icons.person_outline, text: "${order.customerName} • ${order.customerPhone}"),
        _CompactInfoRow(icon: isPickup ? Icons.home_outlined : Icons.store_outlined, text: "${isPickup ? 'Pickup' : 'Drop'} • ${isPickup ? (order.pickupTimeSlot ?? 'N/A') : 'At Shop'}"),
        _CompactInfoRow(icon: Icons.style_outlined, text: "Fabric: ${order.isTailorProvidingFabric ? 'By Tailor' : 'Customer (${order.fabricDetails?.type ?? 'N/A'})'}"),
        _CompactInfoRow(icon: Icons.straighten_outlined, text: "Measurements: ${_getMeasurementSummary(order.measurements)}"),
        const SizedBox(height: 8),
        // A row dedicated to payment information.
        Row(
          children: [
            const Icon(Icons.currency_rupee, size: 16, color: Colors.green),
            Text(" ${order.displayTotalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            const Text("  |  ", style: TextStyle(color: Colors.grey)),
            const Icon(Icons.wallet_outlined, size: 14, color: Colors.orange),
            Text(" Deposit: ₹${order.payment?.depositAmount.toStringAsFixed(0)} "),
            Text("(${order.payment?.depositStatus ?? 'PENDING'})", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  /// Builds the detailed view shown when the tile is expanded.
  Widget _buildExpansionDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          _buildDetailSection("Handover Details", [
            _DetailRow("Method", order.handoverType),
            // Conditionally show pickup address and time slot.
            if (order.handoverType == 'pickup') ...[
              _DetailRow("Address", order.pickupAddress ?? 'N/A'),
              _DetailRow("Time Slot", order.pickupTimeSlot ?? 'N/A'),
            ]
          ]),
          const Divider(height: 20),
          _buildDetailSection("Fabric Details", [
            _DetailRow("Provided By", order.isTailorProvidingFabric ? "Tailor" : "Customer"),
            // Conditionally show customer fabric details.
            if (!order.isTailorProvidingFabric && order.fabricDetails != null) ...[
              _DetailRow("Type", order.fabricDetails!.type ?? 'N/A'),
              _DetailRow("Color", order.fabricDetails!.color ?? 'N/A'),
            ]
          ]),
          // Conditionally show the full measurements section only if they were provided.
           if (order.measurements != null && order.measurements!.isNotEmpty && order.measurements!.values.every((v) => v != 0.0)) ...[
            const Divider(height: 20),
            _buildDetailSection("Full Measurements (inches)", 
              // Map over the measurements to create a list of _DetailRow widgets.
              order.measurements!.entries.map((e) => _DetailRow(e.key, e.value.toString())).toList()
            ),
          ]
        ],
      ),
    );
  }

  /// Builds the "Reject" and "Accept" action buttons.
  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => _handleAction(context, TailorService.rejectOrder(order.id)), style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text("Reject"))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: () => _handleAction(context, TailorService.acceptOrder(order.id)), child: const Text("Accept"))),
      ],
    );
  }

  /// A helper widget to create a titled section with a list of detail rows.
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      ...children, // Use the spread operator to insert the list of child widgets.
    ]);
  }
}

// --- CARD WIDGET FOR IN-PROGRESS ORDERS ('ONGOING' TAB) ---
// This card is simpler, providing a summary and a single primary action to advance the order status.
class _InProgressOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAction; // Callback to refresh the list.
  const _InProgressOrderCard({required this.order, required this.onAction});

   /// A generic handler for performing the status update action.
   Future<void> _handleAction(BuildContext context, Future<void> action) async {
    try {
      await action;
      onAction();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order status updated!"), backgroundColor: Colors.green));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  /// A helper to determine the text for the action button based on the order's current status.
  String _getNextActionText(String status) {
    switch (status) {
      case 'ACCEPTED': return 'Start Cutting';
      case 'CUTTING': return 'Start Stitching';
      case 'STITCHING': return 'Move to Finishing';
      case 'FINISHING': return 'Mark as Ready for Delivery';
      case 'READY': return 'Mark as Delivered';
      default: return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        // The whole card is tappable to navigate to the full detail screen.
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: Text("${order.garmentType} - ${order.customerName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                // A styled `Chip` to display the current status.
                Chip(
                  label: Text(OrderStatusHelper.getUserFriendlyStatus(order.status), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: OrderStatusHelper.getStatusColor(order.status).withOpacity(0.1),
                  labelStyle: TextStyle(color: OrderStatusHelper.getStatusColor(order.status)),
                )
              ]),
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // The button triggers the API call to update the status to the next step.
                  onPressed: () => _handleAction(context, TailorService.updateStatus(order.id)),
                  child: Text(_getNextActionText(order.status)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- CARD WIDGET FOR COMPLETED ORDERS ('DELIVERED' TAB) ---
// A simple, read-only card that summarizes the key details of a finished order.
class _CompletedOrderCard extends StatelessWidget {
  final Order order;
  const _CompletedOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade50, // A muted background color for a non-interactive card.
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(order),
            const Divider(height: 20),
            _CompactInfoRow(icon: Icons.person_outline, text: "Customer: ${order.customerName}"),
            _CompactInfoRow(icon: Icons.event_available, text: "Completed: ${order.updatedAt?.toIso8601String().split('T').first ?? 'N/A'}"),
            _CompactInfoRow(icon: Icons.currency_rupee_outlined, text: "Amount Earned: ₹${order.displayTotalAmount.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }
}

// --- REUSABLE HELPER WIDGETS ---

/// A helper widget to build the header row for a card, showing garment type and order ID.
Widget _buildHeader(Order order) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(order.garmentType, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text("ID: #${order.id.substring(order.id.length - 6).toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

/// A small, reusable helper for creating a compact row with an icon and text.
/// This is used extensively for building the summary views.
class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CompactInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

/// A small, reusable helper for creating a key-value pair row, used in the expanded detail view.
class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  const _DetailRow(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade700))),
        ],
      ),
    );
  }
}
