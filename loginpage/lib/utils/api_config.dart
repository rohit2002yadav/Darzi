
// This file centralizes all the API endpoints for the application.
// Using a configuration class like this makes it easy to manage and update
// API URLs from a single location, and helps avoid hardcoding URLs throughout the app.
class ApiConfig {
  /// Base URL of the backend server, hosted on Render for global access.
  /// This single URL works across real devices, emulators, and production environments.
  static const String baseUrl = "https://darziapplication.onrender.com";

  /// Auth APIs
  /// Defines the specific paths for all authentication-related endpoints.
  
  // Endpoint for user login.
  static const String login = "$baseUrl/api/auth/login";
  // Endpoint for new user registration.
  static const String signup = "$baseUrl/api/auth/signup";
  // Endpoint to request a One-Time Password for verification.
  static const String sendOtp = "$baseUrl/api/auth/send-otp";
  // Endpoint to submit and verify the received OTP.
  static const String verifyOtp = "$baseUrl/api/auth/verify-otp";
  // Endpoint for the password reset process.
  static const String resetPassword = "$baseUrl/api/auth/reset-password";

  /// Order APIs
  /// Defines the specific paths for all order-related endpoints.
  
  // Endpoint to create a new order.
  static const String createOrder = "$baseUrl/api/orders";
  // Endpoint to fetch a user's history of past and present orders.
  static const String orderHistory = "$baseUrl/api/orders/history";
}
