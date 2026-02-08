
// This file defines the "Forgot Password" screen of the application.
// It provides a simple UI for users to enter their email address to receive
// a One-Time Password (OTP) for resetting their password.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.

// The main widget for the ForgotPassword page. It's a StatefulWidget because its
// state changes when the user types or when a network request is in progress.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

// This class holds the state and logic for the ForgotPasswordPage.
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // --- STATE VARIABLES ---
  
  // A controller to read and manage the text inside the email input field.
  final emailController = TextEditingController();
  // A flag to know when the app is busy waiting for the server response.
  bool _isLoading = false;

  // This function handles the logic for requesting a password reset OTP.
  Future<void> _handlePasswordReset() async {
    // 1. Validation: Check if the email field is empty.
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address."), backgroundColor: Colors.red),
      );
      return; // Stop the function if the email is missing.
    }

    // Set the loading state to true to show a spinner on the button.
    setState(() => _isLoading = true);

    // The API endpoint on your server that handles sending the password reset OTP.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/forgot-password');

    // Use a try-catch block to handle potential network errors.
    try {
      // 2. Send to Server: Make a POST request to the server with the user's email.
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      // Decode the server's JSON response.
      final resBody = jsonDecode(response.body);

      // 3. Handle Response: Check the status code of the response.
      if (response.statusCode == 200) {
        // If successful (200 OK), show a success message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['message'] ?? "An OTP has been sent."),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to the reset password page, passing the email so the next screen knows which account to reset.
        Navigator.of(context).pushNamed('/reset-password', arguments: emailController.text.trim());
      } else {
        // If there's an error, show the error message from the server.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resBody['error'] ?? "Failed to send OTP."),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      // Catch any exceptions during the network call (e.g., no internet) and show a generic error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      // The 'finally' block always runs, regardless of success or failure.
      // We make sure to turn off the loading spinner.
      if (mounted) { // A safety check to ensure the widget is still on screen.
        setState(() => _isLoading = false);
      }
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    // Get the primary color from the app's theme to maintain a consistent look.
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100], // A neutral background color.
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.transparent, // Make app bar transparent to show the body's background.
        elevation: 0, // Remove shadow from the app bar.
        iconTheme: const IconThemeData(color: Colors.black87), // Style for icons in the app bar.
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold), // Style for the title text.
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically.
          children: [
            Icon(Icons.lock_reset_rounded, size: 80, color: primaryColor),
            const SizedBox(height: 30),
            const Text(
              "Enter the email address associated with your account, and we\'ll send you an OTP to reset your password.",
              textAlign: TextAlign.center, // Center-align the instruction text.
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 30),
            // The input field for the user's email.
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress, // Set the keyboard to be optimized for email entry.
              decoration: const InputDecoration(
                labelText: "Your Email Address",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button take the full width.
              child: ElevatedButton(
                // The style is now handled by the global theme in main.dart
                // Disable the button and show a spinner when a request is in progress.
                onPressed: _isLoading ? null : _handlePasswordReset,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        // Show a loading indicator when busy.
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "Send OTP",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // A button to allow the user to go back to the previous screen (e.g., Login).
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // .pop() dismisses the current screen.
              child: Text("Back to Login", style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }
}
