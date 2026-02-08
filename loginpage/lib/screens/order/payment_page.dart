
// This file defines the final screen in the order creation process: the PaymentPage.
// On this screen, the user reviews the final cost breakdown, including a required deposit,
// selects a payment method for the deposit (currently "Cash on Delivery"), and places the order.
// Upon successful order placement, the app navigates to the real-time order tracking screen.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../../services/tailor_service.dart'; // The service class to post the final order data to the server.
import '../../models/order_model.dart'; // The data model for an 'Order', used to parse the server's response.
import 'order_tracking_page.dart'; // The screen to navigate to after the order is successfully placed.

// The main widget for the PaymentPage. It's a StatefulWidget because its state
// (like the selected payment method and loading status) changes based on user interaction.
class PaymentPage extends StatefulWidget {
  // `userData` is a map containing all the details of the order aggregated from the previous screens.
  final Map<String, dynamic>? userData;
  const PaymentPage({super.key, this.userData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

// This class holds the state and logic for the PaymentPage.
class _PaymentPageState extends State<PaymentPage> {
  // --- STATE VARIABLES ---

  // Stores the currently selected payment method. Defaults to "COD" (Cash on Delivery).
  String _paymentMethod = "COD";
  // A flag to track when the order placement API call is in progress, used to show a loading indicator.
  bool _isPlacingOrder = false;

  // The fixed amount required as a deposit to confirm the order.
  final double _depositAmount = 100.0;

  // This function handles the entire logic of placing the order.
  Future<void> placeOrder() async {
    if (_isPlacingOrder) return; // Prevent multiple submissions.
    setState(() => _isPlacingOrder = true); // Set loading state to true.

    // 1. Validation: Ensure user data is available.
    if (widget.userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: User data is missing.")));
      setState(() => _isPlacingOrder = false);
      return;
    }

    // 2. Send to Server: Use a try-catch block to handle potential network errors.
    try {
      // Safely extract the total amount from user data.
      final double totalAmount = widget.userData!['totalAmount']?.toDouble() ?? 0.0;

      // 3. Construct Payload: Create the JSON payload with all the necessary order details.
      // This object will be sent to the server.
      final payload = {
        'customerName': widget.userData!['name'],
        'customerPhone': widget.userData!['phone'],
        'tailorId': widget.userData!['selectedTailorId'],
        'tailorName': widget.userData!['selectedTailorName'],
        'tailorPhone': widget.userData!['selectedTailorPhone'],
        'tailorAddress': widget.userData!['selectedTailorAddress'],
        'garmentType': widget.userData!['garmentType'],
        'handoverType': widget.userData!['handoverType'],
        'pickup': widget.userData!['pickup'],
        'isTailorProvidingFabric': widget.userData!['isTailorProvidingFabric'] ?? false,
        'fabricDetails': widget.userData!['fabricDetails'],
        'measurements': widget.userData!['measurements'],
        'items': [widget.userData!['garmentType']], // For simplicity, items just contains the garment type.
        // Payment details are structured in a nested object.
        'payment': {
          'totalAmount': totalAmount,
          'depositAmount': _depositAmount,
          'remainingAmount': totalAmount - _depositAmount,
          'depositMode': _paymentMethod == "COD" ? "CASH" : "ONLINE",
          'depositStatus': "PENDING",
          'paymentStatus': "PENDING_DEPOSIT",
        },
      };

      // Make the API call to post the order.
      final data = await TailorService.postOrder(payload);
      // Parse the successful response from the server into an Order object.
      final order = Order.fromJson(data);

      if (!mounted) return; // Safety check before navigating.

      // 4. Handle Response: On success, navigate to the OrderTrackingPage.
      // `pushAndRemoveUntil` clears the previous navigation history (like the order creation flow)
      // up to the first route (usually the home screen), so the user can't go back.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingPage(order: order, userData: widget.userData)),
        (route) => route.isFirst,
      );

    } catch (e) {
      // If an error occurs, show a red snackbar with the error message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error placing order: $e"), backgroundColor: Colors.red));
      }
    } finally {
      // This block always runs. We ensure the loading spinner is turned off.
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    // Extract and calculate price details for display.
    final totalAmount = widget.userData?['totalAmount']?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - _depositAmount;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The main price summary card.
            _buildPriceSummary(totalAmount, _depositAmount, remainingAmount, theme),
            const SizedBox(height: 24),
            // An informational note about the deposit.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text(
                  "A small deposit confirms your order. Remaining amount is payable after service completion.",
                  style: TextStyle(fontSize: 12, color: Colors.black54)
                )),
              ]),
            ),
            const SizedBox(height: 24),
            // The payment option for "Cash on Delivery".
            _buildPaymentOption(
              theme,
              title: "Pay Deposit in Cash on Pickup",
              subtitle: "Pay ₹${_depositAmount.toStringAsFixed(0)} in cash to confirm your order.",
              value: "COD",
            ),
            const SizedBox(height: 16),
            // The payment option for "Online", which is currently disabled.
            _buildPaymentOption(
              theme,
              title: "Pay Deposit Online",
              subtitle: "UPI, Cards, Wallets (Coming Soon)",
              value: "ONLINE",
              enabled: false,
            ),
          ],
        ),
      ),
      // A persistent bottom navigation bar containing the main action button.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          // The button is disabled when an order is being placed.
          onPressed: _isPlacingOrder ? null : placeOrder,
          // Show a spinner when loading, otherwise show the text.
          child: _isPlacingOrder
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Pay Deposit & Place Order"),
        ),
      ),
    );
  }

  /// A helper widget that builds the main price summary card.
  Widget _buildPriceSummary(double total, double deposit, double remaining, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: [
          _priceRow("Total Order Amount", "₹${total.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          // The deposit amount is highlighted.
          _priceRow("Deposit (Pay Now)", "₹${deposit.toStringAsFixed(2)}", isHighlight: true),
          const Divider(height: 24, thickness: 1),
          _priceRow("Remaining (Later)", "₹${remaining.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  /// A small, reusable helper widget for a row in the price summary.
  /// It takes a label and a value and can apply a highlighted style.
  Widget _priceRow(String label, String value, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: isHighlight ? 18 : 14,
      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
      color: isHighlight ? theme.primaryColor : Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [ Text(label, style: style), Text(value, style: style) ],
    );
  }

  /// A reusable helper widget to build a selectable payment option card.
  /// It includes a title, subtitle, and a radio button, and handles selection and disabled states.
  Widget _buildPaymentOption(ThemeData theme, {required String title, required String subtitle, required String value, bool enabled = true}) {
    // Check if this option is the currently selected one to adjust its appearance.
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: enabled ? () => setState(() => _paymentMethod = value) : null,
      child: Opacity(
        // Reduce opacity for disabled options.
        opacity: enabled ? 1.0 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // The background and border color change based on whether the option is selected.
            color: isSelected ? theme.primaryColor.withAlpha(13) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey.shade300, width: 2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            // The radio button provides a clear visual indicator of the selection.
            trailing: Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: enabled ? (val) => setState(() => _paymentMethod = val!) : null,
            ),
          ),
        ),
      ),
    );
  }
}
