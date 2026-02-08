
// This file defines the "Order Summary" screen. It's one of the final steps in the order creation process.
// This page is not a very active part of the flow anymore and has been mostly superseded by the summary
// view integrated into the `FabricHandoverScreen`. However, it can still be used to display a
// consolidated view of all the order details before the user proceeds to payment.

import 'package:flutter/material.dart';

// The OrderSummaryPage is a StatelessWidget because its content is static; it simply displays
// the data that is passed to it and does not change its own state.
class OrderSummaryPage extends StatelessWidget {
  // `userData` is a map that holds all the information about the order that has been
  // collected from the previous screens (garment type, tailor selection, fabric details, etc.).
  final Map<String, dynamic>? userData;
  const OrderSummaryPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    // --- Data Extraction and Calculation ---
    // Safely extract cost details from the userData map.
    // The `?.` is the null-aware operator, which prevents errors if `userData` or the nested keys are null.
    // `?? 0.0` provides a default value of 0.0 if the data is not found.
    final double stitchingCost = userData?['basePrice']?.toDouble() ?? 0.0;
    final double fabricCost = userData?['fabricCost']?.toDouble() ?? 0.0;
    final double totalAmount = stitchingCost + fabricCost;

    return Scaffold(
      appBar: AppBar(title: const Text("Order Summary")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Main Order Details ---
            Text("Tailor: ${userData?['selectedTailorName'] ?? 'N/A'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Garment: ${userData?['garmentType'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // --- Fabric Details Section ---
            const Text("Fabric Details:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // Display fabric details, with 'N/A' (Not Applicable) as a fallback.
            Text("  Name: ${userData?['selectedFabric']?['name'] ?? 'N/A'}"),
            Text("  Quantity: ${userData?['fabricQuantity'] ?? 0.0} meters"),
            const SizedBox(height: 24),
            
            // --- Cost Breakdown Card ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cost Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    // Use a helper widget to create consistently styled rows for the price breakdown.
                    _buildSummaryRow("Stitching Cost", "₹${stitchingCost.toStringAsFixed(2)}"),
                    _buildSummaryRow("Fabric Cost", "₹${fabricCost.toStringAsFixed(2)}"),
                    const Divider(height: 20),
                    _buildSummaryRow("Total Amount", "₹${totalAmount.toStringAsFixed(2)}", isTotal: true),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      // A persistent bottom navigation bar containing the main action button.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          onPressed: () {
            // When pressed, navigate to the payment screen.
            // All the existing user data is passed along, with the calculated total amount included.
            Navigator.pushNamed(context, '/payment', arguments: {
              ...?userData,
              'totalAmount': totalAmount,
            });
          },
          child: const Text("Proceed to Payment"),
        ),
      ),
    );
  }

  /// A reusable helper widget to build a row in the summary card.
  /// It takes a `title` and an `amount` and displays them on opposite ends of the row.
  /// The optional `isTotal` flag makes the text bold.
  Widget _buildSummaryRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(amount, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
