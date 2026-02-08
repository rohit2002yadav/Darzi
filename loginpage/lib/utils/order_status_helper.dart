
// This file defines the `OrderStatusHelper` class, a utility that provides helper methods
// related to order statuses. It centralizes the logic for converting raw backend status codes
// into user-friendly, readable text and for assigning a specific color to each status.
// This is useful for displaying consistent status information across different parts of the UI.

import 'package:flutter/material.dart'; // The core Flutter framework, used here for the `Color` class.

/// A utility class with static methods to help with displaying order statuses.
/// Using a helper class like this prevents duplicating the same switch statements
/// in multiple UI widgets.
class OrderStatusHelper {
  
  /// Converts a raw status string from the backend into a more descriptive, human-readable string.
  /// 
  /// For example, the backend might use 'PENDING_DEPOSIT', which this method will translate
  /// to 'Deposit Pending' for display in the user interface.
  /// [status]: The raw status string (e.g., 'PLACED', 'STITCHING').
  /// Returns a user-friendly string.
  static String getUserFriendlyStatus(String status) {
    switch (status) {
      case 'PENDING_DEPOSIT':
        return 'Deposit Pending';
      case 'PLACED':
        return 'Waiting for Tailor Confirmation';
      case 'ACCEPTED':
        return 'Tailor Accepted - Work Starting';
      case 'CUTTING':
        return 'Fabric is being cut';
      case 'STITCHING':
        return 'Stitching in Progress';
      case 'FINISHING':
        return 'Finishing Touches';
      case 'READY':
        return 'Ready for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
      case 'REJECTED': // Both rejected and cancelled orders are shown as 'Cancelled' to the user.
        return 'Cancelled';
      default:
        // If the status is not recognized, return the raw status string itself as a fallback.
        return status;
    }
  }

  /// Assigns a specific color to each order status.
  /// 
  /// This is useful for color-coding UI elements like status chips or timeline indicators
  /// to provide quick visual cues to the user about the order's state (e.g., orange for pending,
  /// blue for in-progress, green for ready).
  /// [status]: The raw status string.
  /// Returns a `Color` object.
  static Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING_DEPOSIT':
      case 'PLACED':
        return Colors.orange;
      case 'ACCEPTED':
      case 'CUTTING':
      case 'STITCHING':
      case 'FINISHING':
        return Colors.blue;
      case 'READY':
        return Colors.green;
      case 'DELIVERED':
        return Colors.grey.shade700;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        // Return a default color for any unrecognized status.
        return Colors.black;
    }
  }
}
