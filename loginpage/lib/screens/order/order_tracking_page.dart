
// This file defines the screen that shows the detailed status and progress of a single order.
// It features a timeline-style UI that visually represents the journey of the garment
// from being placed to being delivered. The page can be refreshed to fetch the latest
// order status from the server.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../../models/order_model.dart'; // The data model for an 'Order'.
import '../../services/tailor_service.dart'; // The service class to fetch order data.
import '../../utils/order_status_helper.dart'; // A helper for status-related text and colors.

// The main widget for the OrderTrackingPage. It's a StatefulWidget because it needs to
// manage and update the state of the order being tracked.
class OrderTrackingPage extends StatefulWidget {
  // The initial order data passed to this page.
  final Order order;
  // User data, used for navigating back to the home screen.
  final Map<String, dynamic>? userData;
  const OrderTrackingPage({super.key, required this.order, this.userData});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

// This class holds the state and logic for the OrderTrackingPage.
class _OrderTrackingPageState extends State<OrderTrackingPage> {
  // --- STATE VARIABLES ---

  // Holds the current state of the order. It's initialized with the widget's order but can be updated.
  late Order _currentOrder;
  // A flag to indicate when a network request to refresh the order is in progress.
  bool _isLoading = false;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    // Immediately refresh the order to get the most up-to-date status.
    _refreshOrder();
  }

  // This function fetches the latest order details from the server.
  Future<void> _refreshOrder() async {
    if (!mounted) return; // Safety check.
    setState(() => _isLoading = true); // Show loading indicator.
    try {
      // Call the service to get all of the customer's orders.
      final orders = await TailorService.getCustomerOrders(_currentOrder.customerPhone);
      // Find the specific order that matches the one being tracked by its ID.
      final updatedOrder = orders.firstWhere((o) => o.id == _currentOrder.id);
      // If the widget is still on screen, update the state with the new order details.
      if (mounted) {
        setState(() {
          _currentOrder = updatedOrder;
        });
      }
    } catch (e) {
      // Handle potential errors (e.g., network issues).
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator.
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // This list defines the structure and text for each step in the order timeline.
    // It's a static representation of the order lifecycle.
    final List<Map<String, dynamic>> steps = [
      {'status': "PLACED", 'label': OrderStatusHelper.getUserFriendlyStatus("PLACED"), "desc": "Please pay the deposit to the tailor."},
      {'status': "ACCEPTED", 'label': OrderStatusHelper.getUserFriendlyStatus("ACCEPTED"), "desc": "Your order is confirmed."},
      {'status': "CUTTING", 'label': OrderStatusHelper.getUserFriendlyStatus("CUTTING"), "desc": "The tailor is preparing your fabric."},
      {'status': "STITCHING", 'label': OrderStatusHelper.getUserFriendlyStatus("STITCHING"), "desc": "Your garment is being created."},
      {'status': "FINISHING", 'label': OrderStatusHelper.getUserFriendlyStatus("FINISHING"), "desc": "Final touches are being added."},
      {'status': "READY", 'label': OrderStatusHelper.getUserFriendlyStatus("READY"), "desc": "Your order is ready for delivery."},
      {'status': "DELIVERED", 'label': OrderStatusHelper.getUserFriendlyStatus("DELIVERED"), "desc": "Enjoy your new garment!"},
    ];

    // Find the index of the current order's status within the `steps` list.
    // This determines how many steps in the timeline are marked as "active" or "completed".
    int currentStepIndex = steps.indexWhere((s) => s['status'] == _currentOrder.status);
    if (currentStepIndex == -1) currentStepIndex = 0; // Default to the first step if the status is unrecognized.

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Order Status"),
        elevation: 0,
        actions: [
          // A button to manually trigger the _refreshOrder function.
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _refreshOrder),
        ],
        // Overrides the default back button to provide a clear "close" action
        // that navigates the user directly back to the main dashboard.
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: widget.userData),
        ),
      ),
      // The RefreshIndicator provides the "pull-to-refresh" functionality.
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Ensures the view is always scrollable, even if content is short.
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Various UI helper widgets.
              _buildSuccessHeader(),
              const SizedBox(height: 24),
              _buildSummaryCard(theme),
              const SizedBox(height: 32),
              const Text("Track Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // The main timeline widget.
              _buildTimeline(steps, currentStepIndex, theme),
              const SizedBox(height: 40),
              // A prominent button to return to the dashboard.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false, arguments: widget.userData),
                  child: const Text("Back to Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section that displays a success or status message.
  Widget _buildSuccessHeader() {
    // Differentiate between a newly placed order and one that's in progress.
    bool isNew = _currentOrder.status == "PLACED" || _currentOrder.status == "PENDING_DEPOSIT";
    return Row(children: [
      CircleAvatar(
        backgroundColor: isNew ? const Color(0xFFE8F5E9) : Colors.blue.shade50,
        child: Icon(isNew ? Icons.check_circle : Icons.info_outline, color: isNew ? Colors.green : Colors.blue)
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isNew ? "Order Placed Successfully!" : "Order in Progress", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        // Display a shortened, more readable version of the order ID.
        Text("Order #${_currentOrder.id.length > 4 ? _currentOrder.id.substring(_currentOrder.id.length - 4).toUpperCase() : _currentOrder.id}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ]),
    ]);
  }

  /// Builds a card that provides a quick summary of the key order details.
  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _summaryRow(Icons.checkroom_rounded, "Garment", _currentOrder.garmentType, theme),
          const Divider(height: 32),
          _summaryRow(Icons.handyman_rounded, "Handover", _currentOrder.handoverType == "pickup" ? "Pickup from Home" : "Drop at Shop", theme),
          const Divider(height: 32),
          _summaryRow(Icons.currency_rupee, "Amount", "₹${_currentOrder.displayTotalAmount.toStringAsFixed(2)}", theme),
        ]),
      ),
    );
  }

  /// A small, reusable helper widget to create a row in the summary card.
  Widget _summaryRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(children: [
      Icon(icon, size: 20, color: theme.primaryColor),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    ]);
  }

  /// Builds the vertical timeline UI.
  Widget _buildTimeline(List<Map<String, dynamic>> steps, int currentStepIndex, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true, // The ListView should only be as tall as its children.
      physics: const NeverScrollableScrollPhysics(), // The ListView itself should not be scrollable.
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        // Determine the state of the current step in the timeline.
        final isCompleted = index < currentStepIndex;
        final isActive = index == currentStepIndex;
        final isLast = index == steps.length - 1;
        // Get a specific color for the status from the helper.
        final color = OrderStatusHelper.getStatusColor(step['status']);

        return IntrinsicHeight(
          child: Row(children: [
            // This column builds the vertical line and circles of the timeline.
            Column(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive ? color : Colors.grey.shade200, // Color changes based on state.
                ),
                // The icon inside the circle also changes based on the state.
                child: isCompleted 
                    ? const Icon(Icons.check, size: 12, color: Colors.white) 
                    : (isActive ? Container(margin: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)) : null),
              ),
              // The vertical connecting line. It's not drawn for the very last step.
              if (!isLast) Expanded(child: Container(width: 2, color: isCompleted ? color : Colors.grey.shade200)),
            ]),
            const SizedBox(width: 20),
            // This column displays the text (label and description) for the step.
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                step['label'], 
                // The style of the text changes based on the state.
                style: TextStyle(fontSize: 15, fontWeight: isActive ? FontWeight.bold : FontWeight.w600, color: isActive ? color : (isCompleted ? Colors.black87 : Colors.grey))
              ),
              Text(step['desc'], style: TextStyle(fontSize: 12, color: isActive ? Colors.black54 : Colors.grey)),
              const SizedBox(height: 24),
            ])),
          ]),
        );
      },
    );
  }
}
