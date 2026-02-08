
// This file defines the Welcome Screen, which is the first screen a new user sees when they open the app.
// It serves as a landing page, providing a brief introduction to the app and offering clear
// navigation options to either log in to an existing account or sign up for a new one.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The WelcomeScreen is a StatelessWidget. This means its content is static and doesn't
// change on its own. All the UI elements it displays are defined once and do not depend on any internal state.
class WelcomeScreen extends StatelessWidget {
  // The constructor for the widget. `const` means it can be created at compile-time,
  // which is a performance optimization.
  const WelcomeScreen({super.key});

  // The `build` method is the core of any Flutter widget. It describes how to display the widget
  // in terms of other, lower-level widgets. It's called by the framework whenever the widget
  // needs to be rendered.
  @override
  Widget build(BuildContext context) {
    // `Theme.of(context)` gives access to the app's global theme settings, like primary color and font styles.
    final theme = Theme.of(context);
    // `MediaQuery.of(context)` provides information about the device's screen, like its height and width.
    final screenHeight = MediaQuery.of(context).size.height;

    // `Scaffold` is a basic Material Design layout structure. It provides a framework
    // to implement the basic material design layout of the application.
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5).withAlpha(128), // A light, slightly transparent lavender background color.
      // `SafeArea` ensures that the content is not obscured by system intrusions like the status bar or the notch on a phone.
      body: SafeArea(
        child: Padding(
          // Uniform padding on all sides of the screen content.
          padding: const EdgeInsets.all(24.0),
          // `Column` is a layout widget that arranges its children vertically.
          child: Column(
            // `mainAxisAlignment: MainAxisAlignment.center` centers the children vertically.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // `Spacer` is a flexible widget that takes up any available space.
              // Using two spacers with content in between helps push the content to the center.
              const Spacer(),

              // Displays an image from the project's asset folder.
              Image.asset(
                'assets/images/unnamed.jpg', // The path to the image file.
                height: screenHeight * 0.3, // The image height is set to 30% of the screen height.
                // The `errorBuilder` is a callback that provides a fallback UI
                // in case the image asset fails to load.
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: screenHeight * 0.3,
                    color: Colors.grey.shade200,
                    child: const Center(child: Text('Illustration not found')),
                  );
                },
              ),
              const SizedBox(height: 40), // A fixed-size box for spacing.

              // The first line of the welcome text.
              const Text(
                "WELCOME TO",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5, // Increases the space between characters.
                ),
              ),
              const SizedBox(height: 8),

              // The main app title.
              Text(
                "Darzi Direct",
                style: TextStyle(
                  color: theme.primaryColor, // Uses the primary color from the app's theme.
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // The app's tagline or slogan.
              const Text(
                "Tailored to your style, stitched to perfection — right at your doorstep.",
                textAlign: TextAlign.center, // Centers the text horizontally.
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),

              const Spacer(),
              const Spacer(),

              // The LOGIN button.
              SizedBox(
                width: double.infinity, // Makes the button take up the full available width.
                child: ElevatedButton(
                  onPressed: () {
                    // When pressed, navigate to the '/login' route defined in the app's routing table.
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text("LOGIN"),
                ),
              ),
              const SizedBox(height: 16),

              // The SIGN UP button.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor, // The color of the button's text and icon.
                    side: BorderSide(color: theme.primaryColor, width: 2), // Defines the border style.
                    padding: const EdgeInsets.symmetric(vertical: 16), // Vertical padding inside the button.
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30), // Gives the button rounded corners.
                     ),
                  ),
                  onPressed: () {
                    // When pressed, navigate to the '/signup' route.
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text("SIGN UP"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
