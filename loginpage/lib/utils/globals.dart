
// This file defines globally accessible variables and utility functions that can be used
// from anywhere in the application. This helps in reducing code duplication and provides
// a centralized way to manage global state, like showing snackbars or accessing user data.

import 'package:flutter/material.dart';

/// A global key for the `ScaffoldMessenger`.
///
/// This key provides a way to show a `SnackBar` from anywhere in the app, even from
/// business logic classes (like services or controllers) that do not have direct access
/// to a `BuildContext`. To use this, the `ScaffoldMessenger` in the `MaterialApp`
/// must be assigned this key.
///
/// Example: `MaterialApp(scaffoldMessengerKey: scaffoldMessengerKey, ...)`
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// A utility function to display a success message in a green `SnackBar`.
///
/// It uses the global `scaffoldMessengerKey` to show the snackbar.
/// [message]: The text to display in the snackbar.
void showSuccess(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green, // A green background indicates success.
    ),
  );
}

/// A utility function to display an error message in a red `SnackBar`.
///
/// It uses the global `scaffoldMessengerKey` to show the snackbar.
/// [message]: The text to display in the snackbar.
void showError(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red, // A red background indicates an error.
    ),
  );
}

/// A global variable to hold the data of the currently logged-in user.
///
/// This map can be populated after a successful login and accessed from various parts
/// of the app to get user details like name, role, or ID without needing to
/// repeatedly fetch it or pass it through widget constructors.
/// It is nullable (`?`) because no user is logged in when the app first starts.
Map<String, dynamic>? currentUser;
