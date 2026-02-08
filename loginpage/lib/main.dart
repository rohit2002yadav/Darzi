import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome_screen.dart'; // Import the new screen
import 'screens/home_page.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'auth/forgot_password_page.dart';
import 'auth/verify_otp_page.dart';
import 'auth/reset_password_page.dart';
import 'profile/profile_page.dart';
import 'profile/edit_profile_page.dart';
import 'profile/measurements_page.dart';
import 'screens/customer/order_history_page.dart';
import 'screens/order/choose_fabric_page.dart';
import 'screens/order/i_have_fabric_page.dart';
import 'screens/order/fabric_handover_page.dart';
import 'screens/order/select_garment_page.dart';
import 'screens/order/add_measurements_page.dart';
import 'screens/order/order_summary_page.dart';
import 'screens/order/payment_page.dart';
import 'screens/order/order_tracking_page.dart';
import 'tailor/tailor_list_page.dart';
import 'tailor/tailor_profile_page.dart';
import 'tailor/verification_pending_page.dart';
import 'tailor/tailor_fabric_management_page.dart';
import 'tailor/tailor_home.dart';
import 'utils/globals.dart';

// This is the main entry point of the app, just like turning the key in a car.
void main() {
  // runApp() tells Flutter to build and run the main app component, which is MyApp.
  runApp(const MyApp());
}

// MyApp is the main widget that holds the entire application.
// Think of it as the main blueprint for your app's foundation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // The build method is like a factory that assembles the visual parts of the app.
  @override
  Widget build(BuildContext context) {
    // This is the main color used throughout the app (the purple theme).
    const Color primaryColor = Color(0xFF6A1B9A);
    final textTheme = Theme.of(context).textTheme;

    // MaterialApp is the main container for all other screens and features.
    // It sets up navigation, theming, and other core functionalities.
    return MaterialApp(
      title: 'Darzi Direct', // The title of the app.
      scaffoldMessengerKey: scaffoldMessengerKey, // A key to manage pop-up messages.
      debugShowCheckedModeBanner: false, // Hides the "debug" banner in the top-right corner.

      // This is the app's "Style Guide" or "Design System".
      // It defines the default look and feel for colors, fonts, buttons, and input fields.
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        // Sets the default fonts for the entire app using Google's "Noto Sans".
        textTheme: GoogleFonts.notoSansTextTheme(textTheme).copyWith(
          displayLarge: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          displaySmall: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          headlineMedium: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          headlineSmall: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          titleLarge: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Defines the default style for all app bars (the top navigation bar).
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // Defines the default style for all elevated buttons.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        // Defines the default style for all text input fields.
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),

      // This is the "starting screen" of the app.
      initialRoute: '/welcome',

      // This section is the app's "GPS" or "Road Map".
      // When the code says "go to /login", this is what decides which screen to show.
      onGenerateRoute: (settings) {
        // 'args' is like a backpack of data that can be passed from one screen to another.
        final args = settings.arguments as Map<String, dynamic>?;

        // This switch statement is like a directory of all possible routes in the app.
        switch (settings.name) {
          // When the app is asked to go to '/welcome'...
          case '/welcome':
            // ...it shows the WelcomeScreen.
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          
          // Shows the login page.
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          // Shows the signup page.
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupPage());

          // Shows the page where a user can enter their email to reset their password.
          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

          // Shows the page where the user enters the One-Time Password (OTP).
          case '/verify-otp':
            return MaterialPageRoute(builder: (_) => VerifyOtpPage(email: (args?['email'] as String?) ?? ''));

          // Shows the page to create a new password.
          case '/reset-password':
             return MaterialPageRoute(builder: (_) => ResetPasswordPage(email: (args?['email'] as String?) ?? ''));

          // Shows the main home page after a user logs in.
          case '/home':
            return MaterialPageRoute(builder: (_) => HomePage(userData: args));

          // Shows the user's profile page.
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfilePage(userData: args));
          
          // Shows the page to edit user profile details.
          case '/edit-profile':
            return MaterialPageRoute(builder: (_) => EditProfilePage(userData: args ?? {}));

          // Shows the page where a user can view and manage their saved measurements.
          case '/measurements':
             return MaterialPageRoute(builder: (_) => MeasurementsPage(userData: args ?? {}));

          // Shows the customer's list of past and active orders.
          case '/order-history':
             return MaterialPageRoute(builder: (_) => OrderHistoryPage(userData: args));

          // Shows the list of available tailors.
          case '/tailor-list':
            return MaterialPageRoute(builder: (_) => TailorListPage(userData: args));
          
          // Shows the detailed profile of a single tailor.
          case '/tailor-profile':
             return MaterialPageRoute(builder: (_) => TailorProfilePage(tailorData: args?['tailorData'] ?? {}, userData: args?['userData']));
          
          // Start of the new order flow: choose how to provide fabric.
          case '/choose-fabric':
            return MaterialPageRoute(builder: (_) => ChooseFabricPage(userData: args));

          // Shows the page for users who already have their own fabric.
          case '/i-have-fabric':
            return MaterialPageRoute(builder: (_) => IHaveFabricPage(userData: args));

          // Shows options for pickup or drop-off of the fabric.
          case '/fabric-handover':
             return MaterialPageRoute(builder: (_) => FabricHandoverScreen(userData: args));

          // Shows the page to select the type of garment (e.g., Shirt, Pant).
          case '/select-garment':
             return MaterialPageRoute(builder: (_) => SelectGarmentPage(userData: args));

          // Shows the page for entering measurements for the selected garment.
          case '/add-measurements':
             return MaterialPageRoute(builder: (_) => AddMeasurementsPage(userData: args));

          // Shows a summary of the order before payment.
          case '/order-summary':
             return MaterialPageRoute(builder: (_) => OrderSummaryPage(userData: args));

          // Shows the final payment page to confirm the order.
          case '/payment':
             return MaterialPageRoute(builder: (_) => PaymentPage(userData: args));

          // Shows the live tracking status of an order.
          case '/order-tracking':
             return MaterialPageRoute(builder: (_) => OrderTrackingPage(order: args!['order'], userData: args['userData']));

          // The main dashboard for a tailor user.
          case '/tailor-home':
             return MaterialPageRoute(builder: (_) => TailorHome(userData: args ?? {}));
          
          // The tailor's page to manage their available fabrics.
          case '/tailor-fabrics':
             return MaterialPageRoute(builder: (_) => TailorFabricManagementPage(userData: args ?? {}));
          
          // Shown to a new tailor whose account is pending verification.
           case '/verification-pending':
             return MaterialPageRoute(builder: (_) => const VerificationPendingPage());
          
          // If the app tries to go to a route that doesn't exist...
          default:
            // ...it will safely redirect to the welcome screen as a fallback.
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
        }
      },
    );
  }
}
