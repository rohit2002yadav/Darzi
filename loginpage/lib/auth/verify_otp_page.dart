
// This file defines the screen for verifying a user's account with a One-Time Password (OTP).
// After a user signs up, they are directed here to enter the OTP sent to their email.
// This page handles OTP verification with the server and, upon success, completes the
// registration, saves the user's session, and navigates them to the home screen.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.
import 'package:shared_preferences/shared_preferences.dart'; // A plugin to store simple key-value data locally (like session tokens).

// The main widget for the VerifyOtpPage. It's a StatefulWidget because its state
// changes based on user input and network activity.
class VerifyOtpPage extends StatefulWidget {
  // The email of the user who is verifying their account. This is passed from the previous screen.
  final String? email;
  const VerifyOtpPage({super.key, this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

// This class holds the state and logic for the VerifyOtpPage.
class _VerifyOtpPageState extends State<VerifyOtpPage> {
  // --- STATE VARIABLES ---

  // A controller to read and manage the text inside the OTP input field.
  final otpController = TextEditingController();
  // Flags to manage the UI state.
  bool _isLoading = false; // True when the main verification request is in progress.
  bool _isResending = false; // True when the "resend OTP" request is in progress.

  // This function handles the primary logic for verifying the OTP and completing the user's registration.
  Future<void> _verifyOtpAndRegister() async {
    // 1. Validation: Perform checks on the input fields before making an API call.
    if (widget.email == null || widget.email!.isEmpty) {
      _showSnackBar("Email not found. Please try again.", isError: true);
      return;
    }
    if (otpController.text.length != 6) {
      _showSnackBar("Please enter a valid 6-digit OTP.", isError: true);
      return;
    }

    // Set loading state to true to show a spinner.
    setState(() => _isLoading = true);

    // The API endpoint on your server for verifying the OTP and registering the user.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/verify-and-register');

    // 2. Send to Server: Use a try-catch block to handle potential network errors.
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': otpController.text,
        }),
      );

      final resBody = jsonDecode(response.body);

      // 3. Handle Response: Check the server's response.
      if (response.statusCode == 201) { // 201 Created indicates successful registration.
        // On success, save the session token and user ID to the device's local storage.
        final prefs = await SharedPreferences.getInstance();
        if (resBody['token'] != null) await prefs.setString('token', resBody['token']);
        if (resBody['user'] != null && resBody['user']['_id'] != null) await prefs.setString('userId', resBody['user']['_id']);

        _showSnackBar(resBody['message'] ?? "Registration successful!", isError: false);
        
        if (!mounted) return;
        // --- REDIRECT EVERYONE TO HOME ---
        // Navigate to the home screen and remove all previous screens from the navigation stack.
        // This prevents the user from going back to the auth flow (login, signup, etc.).
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home', 
          (route) => false, 
          arguments: resBody['user']
        );
      } else {
        // If there's an error, show the error message from the server.
        _showSnackBar(resBody['error'] ?? "Verification failed.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      // This block always runs. We ensure the loading spinner is turned off.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // This function handles the logic for resending the OTP if the user didn't receive it.
  Future<void> _resendOtp() async {
    if (_isResending) return; // Prevent multiple requests.
    setState(() => _isResending = true);
    // The API endpoint for resending the OTP.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/resend-otp');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': widget.email}));
      final resBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar(resBody['message'] ?? "New OTP sent!", isError: false);
      } else {
        _showSnackBar(resBody['error'] ?? "Failed to resend OTP.", isError: true);
      }
    } catch (e) { _showSnackBar("Error: $e", isError: true); }
    finally { if (mounted) setState(() => _isResending = false); }
  }

  // Helper function to show a message at the bottom of the screen.
  // It can be styled as an error (red) or success (green) message.
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return; // Safety check: ensures the widget is still on screen.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green));
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    // A fallback UI in case the email was not passed correctly to this screen.
    if (widget.email == null || widget.email!.isEmpty) return const Scaffold(body: Center(child: Text('Could not retrieve email. Please go back.')));

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Account"), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black), titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(children: [
          const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          const Text("Verification Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("An OTP has been sent to ${widget.email}. Please enter it below to complete your registration.", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black54)),
          const SizedBox(height: 40),
          // --- OTP Input Field ---
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6, // OTP is 6 digits.
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold), // Large, spaced-out text for OTP.
            decoration: InputDecoration(
              counterText: "", // Hide the default character counter.
              hintText: "000000",
              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
          const SizedBox(height: 30),
          // --- Main Action Button ---
          SizedBox(
            width: double.infinity, 
            height: 55, 
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtpAndRegister, // Disable button when loading.
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Verify & Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            )
          ),
          const SizedBox(height: 20),
          // --- Resend OTP Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              const Text("Didn't receive the code?"), 
              // Show a spinner while resending, otherwise show the button.
              _isResending 
                ? const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))) 
                : TextButton(onPressed: _resendOtp, child: const Text("Resend OTP", style: TextStyle(fontWeight: FontWeight.bold)))
            ]
          ),
        ]),
      ),
    );
  }
}
