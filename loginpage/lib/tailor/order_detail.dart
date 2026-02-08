
// This file defines the screen that allows a tailor to view the comprehensive details of a single order.
// It serves as a command center for managing an order, displaying customer information, pickup details,
// measurements, and fabric specifications. Crucially, it provides context-aware action buttons
// at the bottom to move the order through the workflow (e.g., confirm deposit, mark as cutting, etc.).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // A plugin to launch external URLs, used for making phone calls and opening maps.
import '../models/order_model.dart'; // The data model for an 'Order'.
import '../services/tailor_service.dart'; // The service class to make API calls for order actions.

// The OrderDetailScreen is a StatelessWidget because its primary role is to display the data
// of the `order` object passed to it. State changes (like updating the order status)
// are handled by making API calls and then popping the screen, expecting the previous screen to refresh.
class OrderDetailScreen extends StatelessWidget {
  // The `order` object containing all the details to be displayed.
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  /// A helper function to determine the next logical status in the order workflow.
  /// It takes the current status and returns the next one as a string.
  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'ACCEPTED': return 'CUTTING';
      case 'CUTTING': return 'STITCHING';
      case 'STITCHING': return 'FINISHING';
      case 'FINISHING': return 'READY';
      case 'READY': return 'OUT FOR DELIVERY';
      default: return ''; // If there is no next status, return an empty string.
    }
  }

  /// A generic handler for performing an action (like an API call).
  /// It wraps the action in a try-catch block, shows a SnackBar on error,
  //  and pops the screen on success, signaling a need for a refresh.
  Future<void> _handleAction(BuildContext context, Future<void> action) async {
    try {
      await action;
      // Pop the screen and return `true` to indicate success.
      // The previous screen (e.g., the order list) can use this result to refresh its data.
      Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) { // Check if the widget is still on screen before showing a SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  /// Launches the default map application on the device to show the pickup address.
  Future<void> _launchMaps() async {
    final address = order.pickupAddress ?? "";
    if (address.isEmpty) return;
    // Encode the address to make it a valid URL query parameter.
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    // Check if the URL can be launched before attempting to launch it.
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Launches the default phone dialer with the customer's phone number.
  Future<void> _makeCall() async {
    final url = Uri.parse("tel:${order.customerPhone}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Display a shortened, more readable version of the order ID in the app bar.
        title: Text("Order #${order.id.length > 6 ? order.id.substring(order.id.length - 6).toUpperCase() : order.id}"),
        actions: [
          // A quick-action button to call the customer.
          IconButton(icon: const Icon(Icons.phone), onPressed: _makeCall),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A highlighted banner showing the order's current status.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(26), // A light shade of the primary color.
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Current Status: ${order.status}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Customer Information Section ---
            _buildSectionTitle("Customer Information"),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(order.customerPhone),
                trailing: IconButton(
                  icon: const Icon(Icons.directions, color: Colors.blue),
                  onPressed: _launchMaps, // Button to open the pickup address in maps.
                  tooltip: 'Open in Maps',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Pickup Details Section (Conditional) ---
            // This section is only shown if the order handover type is 'pickup' and details are available.
            if (order.handoverType == 'pickup' && order.pickup != null) ...[
              _buildSectionTitle("Pickup Details"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.location_on_outlined, label: "Address", value: order.pickup!['address'] ?? 'Not provided'),
                      const Divider(height: 20),
                      _InfoRow(icon: Icons.access_time_outlined, label: "Time Slot", value: order.pickup!['timeSlot'] ?? 'Not provided'),
                    ],
                  ),
                )
              ),
              const SizedBox(height: 24),
            ],

            // --- Measurements Section ---
            _buildSectionTitle("Measurements (${order.garmentType})"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  // Dynamically create a row for each measurement entry in the order's measurements map.
                  children: (order.measurements?.entries ?? []).map((entry) {
                    return _MeasurementRow(label: entry.key, value: entry.value.toString());
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Fabric Details Section ---
            _buildSectionTitle("Fabric Details"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.isTailorProvidingFabric ? "Provided by: Tailor" : "Provided by: Customer",
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const Divider(height: 20),
                    // Conditionally display different fabric fields based on who provided the fabric.
                    if (order.isTailorProvidingFabric) ...[
                      _InfoRow(icon: Icons.style_outlined, label: "Fabric Name", value: order.fabricDetails?.name ?? 'N/A'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.square_foot_outlined, label: "Quantity", value: "${order.fabricDetails?.quantity?.toString() ?? '0'} meters"),
                    ] else ...[
                      _InfoRow(icon: Icons.style_outlined, label: "Fabric Type", value: order.fabricDetails?.type ?? 'N/A'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.color_lens_outlined, label: "Color", value: order.fabricDetails?.color ?? 'N/A'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.square_foot_outlined, label: "Length", value: "${order.fabricDetails?.length ?? 'N/A'} meters"),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Extra space to prevent the action sheet from obscuring content.
          ],
        ),
      ),
      // The bottom navigation bar is used to display the main action button for the order.
      bottomNavigationBar: _buildActionSheet(context),
    );
  }

  /// A helper widget that builds the bottom action sheet.
  /// It determines which button to show based on the order's current status.
  Widget _buildActionSheet(BuildContext context) {
    final nextStatus = _getNextStatus(order.status);

    Widget? actionButton;

    // If the deposit is pending, the action is to confirm payment.
    if (order.status == 'PENDING_DEPOSIT') {
      actionButton = ElevatedButton(
        onPressed: () => _handleAction(context, TailorService.confirmDeposit(order.id)),
        child: const Text("Mark Deposit as PAID & Accept"),
      );
    // If there is a valid next status, the action is to move the order to that status.
    } else if (nextStatus.isNotEmpty) {
      actionButton = ElevatedButton(
        onPressed: () => _handleAction(context, TailorService.updateStatus(order.id)),
        child: Text("Mark as $nextStatus"),
      );
    }

    // If no action is applicable for the current status, return an empty, zero-sized box.
    if (actionButton == null) {
      return const SizedBox.shrink();
    }

    // Return the action button wrapped in a styled container.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: actionButton,
        ),
      ),
    );
  }

  /// A simple helper widget to create a styled section title.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// A reusable widget to display a single row in the measurements card.
class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;
  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}

/// A reusable widget to display a row of information with an icon, label, and value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
