
// This file defines the `VerificationPendingPage`, a screen shown to a tailor user
// immediately after they have completed the sign-up process.
// It serves as a waiting or informational screen, letting the tailor know that their
// profile is under review by the platform's administration team and is not yet active.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The VerificationPendingPage is a StatelessWidget. Its content is static and simply
// displays information based on the user data passed to it. It does not manage any internal state.
class VerificationPendingPage extends StatelessWidget {
  // `userData` contains the details of the newly signed-up tailor, such as their name.
  final Map<String, dynamic>? userData;
  const VerificationPendingPage({super.key, this.userData});

  // The `build` method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the app's theme for consistent styling.
    // Safely get the tailor's name from the user data, defaulting to 'Tailor' if not found.
    final String name = userData?['name'] ?? 'Tailor';

    return Scaffold(
      backgroundColor: Colors.white, // A clean white background.
      body: SafeArea(
        // `SafeArea` ensures the content is not obscured by system UI like the status bar.
        child: Padding(
          // Horizontal padding to keep content from the screen edges.
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            // Center the content vertically on the screen.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // An icon that visually represents verification.
              const Icon(Icons.verified_user_outlined, size: 100, color: Colors.orange),
              const SizedBox(height: 40), // Spacing.

              // A personalized welcome message to the tailor.
              Text(
                "Hi $name, your profile is under review!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // An informational text explaining the verification process and timeline.
              const Text(
                "Our team is currently verifying your shop details and work photos. This usually takes 24-48 hours.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5), // `height` improves line spacing for readability.
              ),
              const SizedBox(height: 40),

              // A highlighted box containing a key piece of information.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(13), // A very light, transparent orange background.
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade100), // A subtle border.
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "You'll be notified via email once your account is active.",
                        style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // A button to allow the user to log out.
              SizedBox(
                width: double.infinity, // Make the button take up the full available width.
                child: OutlinedButton(
                  // When pressed, this will take the user back to the login screen and clear the navigation history.
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Log Out"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
