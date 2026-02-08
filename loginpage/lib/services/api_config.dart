
// This file defines a configuration class for managing API base URLs.
// It provides a centralized place to store and switch between different server environments,
// such as a local development server and a live production server.

class ApiConfig {
  // This is the base URL for running the app against a local server on the same machine.
  // The IP address 10.0.2.2 is a special alias to the host loopback interface (i.e., 127.0.0.1 on your computer)
  // that is automatically provided by the Android emulator.
  static const String localBaseUrl = "http://10.0.2.2:5000";

  // This is the base URL for the live production server hosted on Render.
  // This is the server that the final, published version of the app will communicate with.
  static const String productionBaseUrl = "https://darziapplication.onrender.com";

  // This is the main URL that the rest of the application should use when making API calls.
  // To switch between the local development environment and the live production server,
  // you only need to change which variable is assigned to `baseUrl` here.
  // For example, to test locally, you would change this line to:
  // static const String baseUrl = localBaseUrl;
  static const String baseUrl = productionBaseUrl;
}
