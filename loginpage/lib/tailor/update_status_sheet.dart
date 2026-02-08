
// This file defines a modal bottom sheet widget that allows a tailor to update the progress of an order.
// It displays a list of possible order statuses as buttons. The tailor can select the next status,
// which triggers an API call to update the order in the database.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../services/tailor_service.dart'; // The service class to make the API call to update the status.

// The main widget for the UpdateStatusSheet. It's a StatefulWidget because it needs to manage
// a loading state (`_isLoading`) while the API call is in progress.
class UpdateStatusSheet extends StatefulWidget {
  // The unique identifier for the order that is being updated.
  final String orderId;
  // The current status of the order, used to disable the corresponding button.
  final String currentStatus;
  // A callback function that is executed after a successful update.
  // This is typically used to trigger a refresh of the previous screen (e.g., the order list).
  final VoidCallback onUpdate;

  const UpdateStatusSheet({
    super.key,
    required this.orderId,
    required this.currentStatus,
    required this.onUpdate,
  });

  @override
  State<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

// This class holds the state and logic for the UpdateStatusSheet.
class _UpdateStatusSheetState extends State<UpdateStatusSheet> {
  // --- STATE VARIABLE ---
  // A flag to track when the update API call is in progress.
  bool _isLoading = false;

  // A hardcoded list of the possible statuses an order can be updated to through this sheet.
  // This represents the main stages of the garment creation process.
  final List<String> _statuses = [
    "CUTTING",
    "STITCHING",
    "FINISHING",
    "READY",
    "DELIVERED",
  ];

  /// This function handles the logic for updating the order status.
  /// The `status` parameter is currently unused because the API endpoint
  /// (`/orders/{orderId}/update-status`) is designed to automatically advance
  /// the order to the next logical step, rather than a specific one chosen here.
  Future<void> _updateStatus(String status) async {
    // Set loading state to true to show a spinner.
    setState(() => _isLoading = true);
    try {
      // Make the API call to update the status of the order.
      await TailorService.updateStatus(widget.orderId);
      // On success, call the `onUpdate` callback to notify the parent widget.
      widget.onUpdate();
    } catch (e) {
      // If an error occurs, show a red snackbar with the error message.
      if (mounted) { // Safety check to ensure the widget is still on screen.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    } finally {
      // This block always runs. We ensure the loading spinner is turned off.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // The build method describes the UI of the bottom sheet.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The main container for the sheet's content.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // The sheet should only be as tall as its content.
        crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take up the full width.
        children: [
          const Text(
            "Update Progress",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Conditionally show a loading indicator or the list of status buttons.
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else
            // Use the spread operator `...` to insert the list of buttons into the Column's children.
            ..._statuses.map((status) {
              // Check if the status in the list is the order's current status.
              final isCurrent = widget.currentStatus == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  // The button is disabled if it represents the current status.
                  onPressed: isCurrent ? null : () => _updateStatus(status),
                  style: ElevatedButton.styleFrom(
                    // The button has a different color when disabled to provide a clear visual cue.
                    backgroundColor: isCurrent ? Colors.grey.shade300 : theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    status, // The text on the button.
                    style: TextStyle(
                      color: isCurrent ? Colors.black38 : Colors.white,
                      letterSpacing: 1.5, // Increased spacing for a stylized look.
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(), // `.toList()` converts the mapped iterable into a list of widgets.
          
          const SizedBox(height: 8),
          // A button to close the bottom sheet without taking any action.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16), // Bottom padding.
        ],
      ),
    );
  }
}
