
// This file defines the login screen for the application.
// It allows users to log in using either their email or phone number and a password.
// The page handles making API calls to a server to authenticate the user, saves the
// session token upon successful login, and provides options for password recovery
// and account verification if needed.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import 'package:http/http.dart' as http; // A library to make HTTP requests to the server.
import 'package:shared_preferences/shared_preferences.dart'; // A plugin to store simple key-value data locally (like session tokens).

// The main widget for the Login page. It's a StatefulWidget because its
// appearance changes based on user input and network responses.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// This class holds the state and logic for the LoginPage.
class _LoginPageState extends State<LoginPage> {
  // --- STATE VARIABLES ---
  
  // Tracks whether the user has selected the 'Email' or 'Phone' login tab.
  bool isEmailSelected = true;
  // Stores the state of the "Remember me" checkbox.
  bool rememberMe = false;
  // A flag to know when the app is busy (e.g., waiting for the server). Used to show a loading spinner.
  bool _isLoading = false;
  // Toggles password visibility on and off.
  bool _showPassword = false;

  // Controllers to read and manage the text inside the input fields.
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // This is a lifecycle method that Flutter calls when the page is removed.
  // It's important to "dispose" of controllers here to free up memory.
  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // A helper function to show a feedback message to the user at the bottom of the screen.
  void _showSnackBar(String message, {bool isError = true, String? actionLabel, VoidCallback? onActionPressed}) {
    if (!mounted) return; // Safety check: ensures the widget is still on screen before showing the snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green, // Red for errors, green for success.
        // Optionally, an action button can be shown (e.g., "RESEND OTP").
        action: actionLabel != null
            ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onActionPressed!)
            : null,
      ),
    );
  }

  // This function is called when the user needs to resend their One-Time Password (OTP).
  Future<void> _resendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email to resend OTP.");
      return;
    }
    setState(() => _isLoading = true); // Show loading indicator.
    try {
      const String apiUrl = "https://darziapplication.onrender.com/api/auth/resend-otp";
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar(data["message"] as String? ?? "New OTP sent!", isError: false);
        // Navigate to the OTP verification screen.
        Navigator.pushNamed(context, '/verify-otp', arguments: email);
      } else {
        _showSnackBar(data["error"] as String? ?? "Failed to resend OTP.");
      }
    } catch (e) {
      _showSnackBar("Network Error: $e");
    } finally {
      if(mounted) setState(() => _isLoading = false); // Hide loading indicator.
    }
  }

  // The primary function to handle the user login process.
  Future<void> _loginUser() async {
    if (_isLoading) return; // Prevent multiple login attempts while one is already in progress.

    // Determine whether to use the email or phone number based on the selected tab.
    String identifier = isEmailSelected ? emailController.text.trim() : phoneController.text.trim();
    String password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill all fields.");
      return;
    }

    setState(() => _isLoading = true); // Show loading indicator.

    try {
      const String apiUrl = "https://darziapplication.onrender.com/api/auth/login";
      // Send the login credentials to the server.
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          isEmailSelected ? "email" : "phone": identifier,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // On successful login, save the session token and user ID locally.
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        if (data['user'] != null && data['user']['_id'] != null) {
          await prefs.setString('userId', data['user']['_id']);
        }

        _showSnackBar("Login successful!", isError: false);
        // Replace the current page with the home page, so the user can't go back to the login screen.
        Navigator.pushReplacementNamed(context, '/home', arguments: data['user']);

      } else if (response.statusCode == 403 && data['needsVerification'] == true) {
        // If the account is not verified, show an error with an action to resend the OTP.
        _showSnackBar(
            data["error"] as String? ?? "Account not verified.",
            actionLabel: "RESEND OTP",
            onActionPressed: _resendOtp
        );
      } else {
        _showSnackBar(data["error"] as String? ?? "Login failed");
      }
    } catch (e) {
      _showSnackBar("Network Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator.
    }
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome Back!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 8),
              const Text("Please log in to your account", style: TextStyle(color: Colors.black54, fontSize: 15)),
              const SizedBox(height: 40),
              // The Email/Phone toggle button container.
              Container(
                decoration: BoxDecoration(color: primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(25)),
                child: Row(
                  children: [
                    _buildToggleButton("Email", isEmailSelected, () => setState(() => isEmailSelected = true)),
                    _buildToggleButton("Phone", !isEmailSelected, () => setState(() => isEmailSelected = false)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Conditionally show either the email or phone input field.
              if (isEmailSelected)
                _buildInputField("Enter Your Email", Icons.email_outlined, emailController)
              else
                _buildInputField("Enter Your Phone", Icons.phone, phoneController, kb: TextInputType.phone),
              const SizedBox(height: 15),
              _buildInputField("Enter Your Password", Icons.lock_outline, passwordController, isPassword: true, onSubmitted: (_) => _loginUser()),
              const SizedBox(height: 10),
              // "Remember me" and "Forgot Password" row.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(value: rememberMe, activeColor: primaryColor, onChanged: (v) => setState(() => rememberMe = v ?? false)),
                      const Text("Remember me"),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: Text("Forgot Password?", style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              // The main login button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  // Disable the button and show a spinner when loading.
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Log In", style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 30),
              // The link to navigate to the Sign Up page.
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/signup'),
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.black54),
                    children: [TextSpan(text: "Sign Up", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE WIDGET HELPERS ---
  
  /// A helper to build the toggle buttons for "Email" and "Phone".
  Widget _buildToggleButton(String text, bool active, VoidCallback onTap) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          // The button style changes based on whether it is 'active'.
          decoration: BoxDecoration(color: active ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(25)),
          alignment: Alignment.center,
          child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  /// A helper to build a standard TextFormField with consistent styling.
  Widget _buildInputField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, Function(String)? onSubmitted, TextInputType? kb}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_showPassword : false, // Hide text for passwords.
      onFieldSubmitted: onSubmitted, // Allows submitting the form from the keyboard.
      keyboardType: kb,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        // For password fields, add a button to toggle text visibility.
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        )
            : null,
      ),
    );
  }
}

