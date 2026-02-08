
// This file defines the screen where a user can reset their password.
// It requires the user to enter the OTP they received via email, along with a new password.
// The screen handles the logic for verifying the OTP and updating the password on the server.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.

// The main widget for the ResetPassword page. It's a StatefulWidget because its state
// changes based on user input and network activity.
class ResetPasswordPage extends StatefulWidget {
  // The email of the user who is resetting their password. This is passed from the previous screen.
  final String? email;
  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

// This class holds the state and logic for the ResetPasswordPage.
class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // --- STATE VARIABLES ---

  // Controllers to read and manage the text inside the input fields.
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Flags to manage the UI state.
  bool _isLoading = false; // True when the main password reset request is in progress.
  bool _showPassword = false; // Toggles visibility for the new password field.
  bool _showConfirmPassword = false; // Toggles visibility for the confirm password field.
  bool _isResending = false; // True when the "resend OTP" request is in progress.

  // This function handles the primary logic for resetting the user's password.
  Future<void> _handleResetPassword() async {
    // 1. Validation: Perform checks on the input fields before making an API call.
    if (widget.email == null || widget.email!.isEmpty) {
      _showError("Email not found. Please go back.");
      return;
    }
    if (otpController.text.length != 6) {
      _showError("Please enter the 6-digit OTP.");
      return;
    }
    if (passwordController.text.isEmpty || passwordController.text != confirmPasswordController.text) {
      _showError("Passwords do not match or are empty.");
      return;
    }

    // Set loading state to true to show a spinner.
    setState(() => _isLoading = true);

    // The API endpoint on your server for resetting the password.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/reset-password');

    // 2. Send to Server: Use a try-catch block to handle potential network errors.
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': otpController.text,
          'newPassword': passwordController.text, // Sending the required data in the request body.
        }),
      );

      final resBody = jsonDecode(response.body);

      // 3. Handle Response: Check the server's response.
      if (response.statusCode == 200) {
        // If successful, show a success message and navigate the user to the login screen.
        _showSuccess(resBody['message'] ?? "Password reset successfully! Please log in.");
        // pushNamedAndRemoveUntil removes all previous screens from the stack, so the user can't go back.
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // If there's an error, show the error message from the server.
        _showError(resBody['error'] ?? "Failed to reset password.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      // This block always runs. We ensure the loading spinner is turned off.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // This function handles the logic for resending the OTP if the user didn't receive it.
  Future<void> _resendOtp() async {
    if (_isResending) return; // Prevent multiple requests.
    if (widget.email == null || widget.email!.isEmpty) {
      _showError("Cannot resend OTP: Email not found.");
      return;
    }
    setState(() => _isResending = true);
    // This uses the same endpoint as the "forgot password" page to trigger a new OTP.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSuccess(resBody['message'] ?? 'A new OTP has been sent.');
      } else {
        _showError(resBody['error'] ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  // Helper function to show a red error message at the bottom of the screen.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Helper function to show a green success message.
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              // Display the email the OTP was sent to.
              "An OTP has been sent to ${widget.email ?? 'your email'}.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // --- Input Fields ---
            _buildTextField(otpController, "Enter 6-Digit OTP", Icons.pin, isOtp: true),
            const SizedBox(height: 16),
            _buildTextField(passwordController, "New Password", Icons.lock_outline, isPassword: true, obscureState: !_showPassword, toggleObscure: () => setState(() => _showPassword = !_showPassword)),
            const SizedBox(height: 16),
            _buildTextField(confirmPasswordController, "Confirm New Password", Icons.lock_outline, isPassword: true, obscureState: !_showConfirmPassword, toggleObscure: () => setState(() => _showConfirmPassword = !_showConfirmPassword)),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              // Show a spinner while resending OTP, otherwise show the button.
              child: _isResending
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                  : TextButton(
                      onPressed: _resendOtp,
                      child: const Text("Resend OTP"),
                    ),
            ),
            const SizedBox(height: 20),
            // --- Main Action Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Disable the button and show a spinner when loading.
                onPressed: _isLoading ? null : _handleResetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Reset Password", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A reusable helper widget to build a standard TextFormField with consistent styling.
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isOtp = false, bool? obscureState, VoidCallback? toggleObscure}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureState ?? false, // Hide text for passwords.
      keyboardType: isOtp ? TextInputType.number : TextInputType.text, // Use number keyboard for OTP.
      maxLength: isOtp ? 6 : null, // Limit OTP input to 6 characters.
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        counterText: "", // Hide the character counter.
        // For password fields, add a button to toggle text visibility.
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureState! ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }
}
