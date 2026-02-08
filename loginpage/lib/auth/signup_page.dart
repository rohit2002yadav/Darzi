
// This file defines a multi-step signup screen for a mobile app.
// A user can sign up as either a "Customer" or a "Tailor", and the form
// dynamically changes based on the selected role. After completion, it sends the
// data to a server to begin account verification.

import 'dart:convert'; // Used for encoding and decoding data formats like JSON.
import 'dart:io'; // Used for working with Files, like the images the user picks.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI with Material Design widgets.
import 'package:http/http.dart' as http; // A library to make HTTP requests, used here to talk to the server.
import 'package:image_picker/image_picker.dart'; // A plugin to allow the user to pick images from their phone's gallery.
import 'package:geolocator/geolocator.dart'; // A plugin to get the device's current GPS location.
import '../services/location_service.dart'; // Your custom service for handling location-related logic.

// This is the main widget for the Signup page. It's a StatefulWidget, meaning its
// appearance can change based on user interaction (e.g., typing into a form).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// This class holds the "state" for the SignupPage. All the variables that can change
// (like what the user has typed) and the logic for the page live here.
class _SignupPageState extends State<SignupPage> {
  // --- STATE VARIABLES ---
  // These variables store the data and UI state for the signup form.

  // Remembers if the user is signing up as a 'customer' or a 'tailor'.
  String? role;
  // Keeps track of which step of the signup form the user is currently on.
  int step = 0;
  // A flag to know when the app is busy (e.g., waiting for the server). Used to show a loading spinner.
  bool _isLoading = false;
  // Toggles password visibility on and off.
  bool _showPassword = false;
  // Stores the tailor's shop location (latitude and longitude).
  Position? _currentPosition;

  // These "controllers" are attached to text fields to read and manage the text inside them.
  // Shared Data
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Address Data
  final addressController = TextEditingController();
  final landmarkController = TextEditingController();
  final pinController = TextEditingController();
  // Stores the selected city and state from the dropdown menus.
  String? _selectedCity;
  String? _selectedState;

  // Tailor Specific Data
  final shopNameController = TextEditingController();
  final experienceController = TextEditingController();
  final openTimeController = TextEditingController();
  final closeTimeController = TextEditingController();
  final basePriceController = TextEditingController();
  final alterationPriceController = TextEditingController();

  // Lists to store the tailor's selected specializations and work days.
  final List<String> _specializations = [];
  final List<String> _workingDays = [];
  // Booleans to track if the tailor offers these services.
  bool _homePickup = false;
  bool _measurementVisit = false;
  // These variables hold the actual image files picked by the user.
  File? _profileImage;
  File? _shopImage;
  final List<File> _workPhotos = [];

  // Pre-defined lists of states and cities for the address dropdowns.
  final List<String> indianStates = ['Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'];
  final List<String> indianCities = ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Ahmedabad', 'Chennai', 'Kolkata', 'Surat', 'Pune', 'Jaipur', 'Lucknow', 'Kanpur', 'Nagpur', 'Indore', 'Thane'];

  // This is a lifecycle method that Flutter calls when the page is closed.
  // It's important to "dispose" of controllers here to free up memory and prevent errors.
  @override
  void dispose() {
    nameController.dispose(); emailController.dispose(); phoneController.dispose();
    passwordController.dispose(); addressController.dispose(); landmarkController.dispose();
    pinController.dispose(); shopNameController.dispose(); experienceController.dispose();
    openTimeController.dispose(); closeTimeController.dispose();
    basePriceController.dispose(); alterationPriceController.dispose();
    super.dispose();
  }

  // A simple helper function to show a red snackbar at the bottom of the screen with an error message.
  void _showError(String msg) {
    if (!mounted) return; // A safety check to ensure the widget is still on screen.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // This function is called when the user taps on an image selection box.
  // It uses the ImagePicker plugin to open the phone's gallery.
  // Once an image is picked, it's stored in the corresponding state variable.
  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // setState is called to notify Flutter that a variable has changed, so it can redraw the UI.
      setState(() {
        if (type == 'profile') _profileImage = File(image.path);
        else if (type == 'shop') _shopImage = File(image.path);
        else if (type == 'work') _workPhotos.add(File(image.path));
      });
    }
  }

  // This is the main function that handles the signup logic.
  // It gathers all the user's data and sends it to the server to get an OTP.
  Future<void> _handleSendOtp() async {
    // --- 1. VALIDATION ---
    // First, check for essential information before proceeding.
    if (emailController.text.isEmpty || phoneController.text.isEmpty || passwordController.text.isEmpty) {
      _showError("Email, Phone, and Password are required.");
      return; // Stop the function if validation fails.
    }
    if (role == 'tailor' && _currentPosition == null) {
      _showError("Shop location capture is compulsory for tailors");
      return;
    }

    // Set the loading state to true to show a spinner on the button.
    setState(() => _isLoading = true);

    // The API endpoint on your server that handles sending the OTP.
    final url = Uri.parse('https://darziapplication.onrender.com/api/auth/send-otp');

    // --- 2. GATHER DATA ---
    // Create a map (a key-value data structure) to hold all the user's information.
    // This map will be converted to JSON and sent to the server.
    final Map<String, dynamic> body = {
      'role': role,
      'name': nameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'password': passwordController.text,
      'location': (role == 'tailor' && _currentPosition != null) 
          ? {'type': 'Point', 'coordinates': [_currentPosition!.longitude, _currentPosition!.latitude]} 
          : null,
    };

    // Conditionally add 'customerDetails' or 'tailorDetails' based on the selected role.
    if (role == 'customer') {
      body['customerDetails'] = {
        'address': addressController.text, 'city': _selectedCity, 'state': _selectedState, 'landmark': landmarkController.text, 'pin': pinController.text,
      };
    } else {
      body['tailorDetails'] = {
        'shopName': shopNameController.text,
        'experience': int.tryParse(experienceController.text),
        'specializations': _specializations,
        'workingDays': _workingDays,
        'workingHours': {'open': openTimeController.text, 'close': closeTimeController.text},
        'pricing': {'basePrice': double.tryParse(basePriceController.text), 'alterationPrice': double.tryParse(alterationPriceController.text)},
        'homePickup': _homePickup,
        'measurementVisit': _measurementVisit,
        'address': addressController.text, 'city': _selectedCity, 'state': _selectedState, 'zipCode': pinController.text, 'landmark': landmarkController.text,
      };
    }

    // --- 3. SEND TO SERVER ---
    // Use a try-catch block to handle potential network errors (e.g., no internet connection).
    try {
      // Send the data as a JSON payload in the body of a POST request.
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      // The server's response is decoded from JSON.
      final data = jsonDecode(res.body);

      // If the status code is 200 (which means 'OK'), the request was successful.
      if (res.statusCode == 200) {
        // Navigate to the OTP verification page, passing the user's email.
        Navigator.of(context).pushNamed('/verify-otp', arguments: {'email': emailController.text.trim()});
      } else {
        // If the server returns an error, show it to the user.
        _showError(data['error'] ?? "Failed to send OTP.");
      }
    } catch (e) { 
      _showError("Error: $e"); 
    }
    // The 'finally' block always runs, whether there was an error or not.
    // Here, we ensure the loading spinner is turned off.
    finally { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  // The build method is the most important one. It describes what the UI looks like.
  // Flutter calls this method whenever the state changes (e.g., via setState) to redraw the screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show a back button in the app bar only after the first step.
      appBar: step > 0 ? AppBar(elevation: 0, backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.black)) : null,
      // SingleChildScrollView allows the content to be scrolled if it's too long for the screen.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        // It uses the 'step' variable to conditionally show the widget for the current step.
        child: Column(children: [
          if (step == 0) _buildRoleSelection(),
          if (step == 1) _buildNameStep(),
          if (step == 2) _buildContactStep(),
          if (step == 3) _buildPasswordStep(),
          if (step == 4) _buildAddressStep(),
          // These steps are only shown if the user selected the 'tailor' role.
          if (role == 'tailor') ...[
            if (step == 5) _buildShopStep(),
            if (step == 6) _buildPhotosStep(),
            if (step == 7) _buildPricingStep(),
          ],
        ]),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---
  // The following methods are helpers that build specific parts of the UI.
  // Breaking the UI into smaller methods like this makes the code easier to read and manage.

  /// Builds the first screen where the user chooses between 'Customer' and 'Tailor'.
  Widget _buildRoleSelection() {
    return Column(children: [
      const SizedBox(height: 40),
      const Text("What are you?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 40),
      _roleCard("Customer", "customer", Icons.person),
      const SizedBox(height: 20),
      _roleCard("Tailor", "tailor", Icons.cut),
    ]);
  }

  /// A reusable widget for the role selection cards.
  Widget _roleCard(String title, String val, IconData icon) {
    bool sel = role == val; // Check if this card's role is the currently selected one.
    return InkWell(
      // When tapped, update the role and move to the next step.
      onTap: () => setState(() { role = val; step = 1; }),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        // Change color based on whether it's selected or not.
        decoration: BoxDecoration(color: sel ? Theme.of(context).primaryColor : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
        child: Row(children: [
          Icon(icon, color: sel ? Colors.white : Colors.black, size: 32),
          const SizedBox(width: 20),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sel ? Colors.white : Colors.black)),
        ]),
      ),
    );
  }

  /// Builds the step for entering the user's full name.
  Widget _buildNameStep() {
    return Column(children: [
      const Text("Enter your full name", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      _field("Full Name", Icons.person, nameController),
      const SizedBox(height: 30),
      _btn("Continue", () {
        // Basic validation: only proceed if the name is not empty.
        if (nameController.text.isNotEmpty) setState(() => step++);
        else _showError("Name is required");
      })
    ]);
  }

  /// Builds the step for entering email and phone number.
  Widget _buildContactStep() {
    return Column(children: [
      const Text("Contact Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      _field("Email", Icons.email, emailController, kb: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _field("Phone Number", Icons.phone, phoneController, kb: TextInputType.phone),
      const SizedBox(height: 30),
      _btn("Continue", () {
        // Basic validation for email and phone.
        if (emailController.text.contains('@') && phoneController.text.length >= 10) setState(() => step++);
        else _showError("Enter valid email and phone number");
      })
    ]);
  }

  /// Builds the step for creating a password.
  Widget _buildPasswordStep() {
    return Column(children: [
      const Text("Create Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text("Use this password to login later", style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 30),
      TextFormField(
        controller: passwordController,
        obscureText: !_showPassword, // Hides the password text if _showPassword is false.
        decoration: InputDecoration(
          labelText: "Password",
          prefixIcon: const Icon(Icons.lock),
          // An icon button to toggle password visibility.
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 30),
      _btn("Continue", () {
        if (passwordController.text.length >= 6) setState(() => step++);
        else _showError("Password must be at least 6 characters");
      })
    ]);
  }

  /// Builds the step for entering address details.
  /// This step also includes a special location capture for tailors.
  Widget _buildAddressStep() {
    return Column(children: [
      const Text("Address Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _field("Full Address", Icons.home, addressController),
      const SizedBox(height: 12),
      _drop("City", _selectedCity, indianCities, (v) => setState(() => _selectedCity = v)),
      const SizedBox(height: 12),
      _drop("State", _selectedState, indianStates, (v) => setState(() => _selectedState = v)),
      const SizedBox(height: 12),
      _field("Landmark", Icons.place, landmarkController),
      const SizedBox(height: 12),
      _field("Pin Code", Icons.pin_drop, pinController, kb: TextInputType.number),
      const SizedBox(height: 20),
      // This section is only shown for tailors.
      if (role == 'tailor') 
        Container(
          padding: const EdgeInsets.all(12),
          // The container style changes based on whether the location has been set.
          decoration: BoxDecoration(
            color: _currentPosition == null ? Colors.red.withAlpha(13) : Colors.green.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _currentPosition == null ? Colors.red.shade200 : Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: _currentPosition == null ? Colors.red : Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentPosition == null ? "Set Shop Location (COMPULSORY)" : "Shop Location Set ✓",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _currentPosition == null ? Colors.red.shade700 : Colors.green.shade700),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Calls the location service to get the current GPS position.
                  final pos = await LocationService.getCurrentLocation();
                  if (pos != null) {
                    setState(() => _currentPosition = pos);
                  } else {
                    _showError("Could not capture location. Please check GPS settings.");
                  }
                },
                child: Text(_currentPosition == null ? "SET" : "RE-SET"),
              ),
            ],
          ),
        ),
      const SizedBox(height: 30),
      _btn("Continue", () {
        if (addressController.text.isEmpty || _selectedCity == null) {
          _showError("Address and City are required");
          return;
        }
        if (role == 'tailor' && _currentPosition == null) {
          _showError("Please set your shop location to continue");
          return;
        }
        
        // For customers, this is the final step, so we call _handleSendOtp.
        // For tailors, we just move to the next step.
        if (role == 'customer') _handleSendOtp();
        else setState(() => step++);
      }, loading: role == 'customer' && _isLoading) // Show loading spinner only for customers on this step.
    ]);
  }

  /// Builds the step for tailor-specific shop details.
  Widget _buildShopStep() {
    return Column(children: [
      const Text("Shop Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _field("Shop Name", Icons.store, shopNameController),
      const SizedBox(height: 12),
      _field("Years of Experience", Icons.history, experienceController, kb: TextInputType.number),
      const SizedBox(height: 20),
      const Align(alignment: Alignment.centerLeft, child: Text("Specialization", style: TextStyle(fontWeight: FontWeight.bold))),
      // Wrap allows the chips to flow to the next line if there isn't enough space.
      Wrap(spacing: 8, children: ["Shirt", "Pant", "Kurta", "Blouse", "Suit"].map((s) => FilterChip(
        label: Text(s), 
        selected: _specializations.contains(s),
        // Add or remove the specialization from the list when the chip is selected/deselected.
        onSelected: (b) => setState(() => b ? _specializations.add(s) : _specializations.remove(s)),
      )).toList()),
      const SizedBox(height: 30),
      _btn("Continue", () => setState(() => step++))
    ]);
  }

  /// Builds the step for uploading profile, shop, and work photos.
  Widget _buildPhotosStep() {
    return Column(children: [
      const Text("Upload Work Photos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text("This improves trust & ranking", style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 30),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _photoBox("Shop", _shopImage, () => _pickImage('shop')),
        _photoBox("Profile", _profileImage, () => _pickImage('profile')),
      ]),
      const SizedBox(height: 20),
      const Align(alignment: Alignment.centerLeft, child: Text("Stitched Clothes Photos", style: TextStyle(fontWeight: FontWeight.bold))),
      const SizedBox(height: 10),
      // A horizontal ListView for the work photos.
      SizedBox(height: 80, child: ListView(scrollDirection: Axis.horizontal, children: [
        // Display already picked photos.
        ..._workPhotos.map((f) => Container(width: 80, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(image: DecorationImage(image: FileImage(f), fit: BoxFit.cover)))),
        // The "add photo" button.
        InkWell(onTap: () => _pickImage('work'), child: Container(width: 80, color: Colors.grey[200], child: const Icon(Icons.add_a_photo))),
      ])),
      const SizedBox(height: 30),
      _btn("Continue", () => setState(() => step++))
    ]);
  }

  /// Builds the final step for tailors to set pricing and services.
  Widget _buildPricingStep() {
    return Column(children: [
      const Text("Pricing & Services", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _field("Base price (e.g. Shirt ₹300)", Icons.currency_rupee, basePriceController, kb: TextInputType.number),
      const SizedBox(height: 12),
      _field("Alteration price", Icons.build, alterationPriceController, kb: TextInputType.number),
      // Checkboxes for boolean services.
      CheckboxListTile(title: const Text("Home pickup available?"), value: _homePickup, onChanged: (v) => setState(() => _homePickup = v!)),
      CheckboxListTile(title: const Text("Measurement visit available?"), value: _measurementVisit, onChanged: (v) => setState(() => _measurementVisit = v!)),
      const SizedBox(height: 30),
      // This is the final step for tailors, so this button calls the main signup function.
      _btn("Send OTP", _handleSendOtp, loading: _isLoading)
    ]);
  }

  // --- REUSABLE WIDGET HELPERS ---
  // These are small, reusable functions to create common widgets with a consistent style.
  // This avoids repeating the same styling code over and over again.

  /// A helper to create a standard TextFormField.
  Widget _field(String l, IconData i, TextEditingController c, {TextInputType? kb}) => TextFormField(controller: c, keyboardType: kb, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  
  /// A helper to create a standard DropdownButtonFormField.
  Widget _drop(String h, String? v, List<String> i, ValueChanged<String?> o) => DropdownButtonFormField<String>(value: v, items: i.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: o, decoration: InputDecoration(hintText: h, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  
  /// A helper to create a standard full-width ElevatedButton.
  Widget _btn(String t, VoidCallback o, {bool loading = false}) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: loading ? null : o, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : Text(t)));
  
  /// A helper to create the photo selection boxes.
  Widget _photoBox(String t, File? f, VoidCallback o) => InkWell(onTap: o, child: Column(children: [Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.grey[200], image: f != null ? DecorationImage(image: FileImage(f), fit: BoxFit.cover) : null), child: f == null ? const Icon(Icons.camera_alt) : null), const SizedBox(height: 8), Text(t)]));
}

