
// This file defines the screen where a user selects the type of garment they want to have stitched.
// It's a key starting point in the order creation flow. The screen displays a grid of garment options.
// It also has a special behavior: if a garment type is already specified in the user data passed to it
// (e.g., from a shortcut on the home screen), it will automatically skip this selection screen
// and navigate directly to the next step.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The main widget for the SelectGarmentPage. It's a StatefulWidget because its state
// (the currently selected garment) changes based on user interaction.
class SelectGarmentPage extends StatefulWidget {
  // `userData` is a map that holds information collected from previous screens,
  // like customer details. It might also contain a pre-selected 'garmentType'.
  final Map<String, dynamic>? userData;
  const SelectGarmentPage({super.key, this.userData});

  @override
  State<SelectGarmentPage> createState() => _SelectGarmentPageState();
}

// This class holds the state and logic for the SelectGarmentPage.
class _SelectGarmentPageState extends State<SelectGarmentPage> {
  // --- STATE VARIABLES ---

  // Stores the name of the garment the user has tapped on (e.g., "Shirt").
  String? _selectedGarment;

  // A hardcoded list of available garments. Each garment is a map containing its
  // name, a display icon, and its base stitching price.
  final List<Map<String, dynamic>> _garments = [
    {"name": "Shirt", "icon": Icons.checkroom, "price": 400},
    {"name": "Pant", "icon": Icons.shopping_bag, "price": 500},
    {"name": "Kurta", "icon": Icons.accessibility_new, "price": 600},
    {"name": "Suit", "icon": Icons.business_center, "price": 2500},
  ];

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback` ensures that the code inside it runs after the first frame
    // of the UI has been built. This is the correct and safe way to perform navigation
    // from within `initState`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if a 'garmentType' was passed in the user data.
      final preselectedGarment = widget.userData?['garmentType'] as String?;
      // If a pre-selected garment exists and it's a valid garment from our list...
      if (preselectedGarment != null && _garments.any((g) => g['name'] == preselectedGarment)) {
        // ...automatically navigate to the next screen without showing this one.
        _navigateToNext(preselectedGarment);
      }
    });
  }

  // This helper function handles the logic for navigating to the next screen.
  void _navigateToNext(String garment) {
    // Find the full data map for the selected garment to get its price.
    final selectedData = _garments.firstWhere((e) => e['name'] == garment);
    // Use `pushReplacementNamed` to replace the current screen in the navigation stack.
    // This prevents the user from being able to go "back" to this selection screen.
    Navigator.pushReplacementNamed(context, '/add-measurements', arguments: {
      ...?widget.userData, // Pass along all the existing user data.
      'garmentType': garment, // Add the selected garment type.
      'basePrice': selectedData['price'], // Add the base price for the garment.
    });
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If a garment type was pre-selected, the `initState` logic will handle navigation.
    // While that is happening (which is almost instantaneous), we show a simple loading indicator
    // to avoid a brief flash of the main UI.
    if (widget.userData?['garmentType'] != null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // This is the main UI for the screen when no garment is pre-selected.
    return Scaffold(
      appBar: AppBar(title: const Text("Select Garment")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "What would you like to stitch?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          // The main grid view that displays the garment options.
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // Defines the layout of the grid: 2 columns, with spacing.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9, // Adjusts the height-to-width ratio of the grid items.
              ),
              itemCount: _garments.length,
              itemBuilder: (context, index) {
                final g = _garments[index];
                final isSelected = _selectedGarment == g['name'];

                // Each grid item is wrapped in a GestureDetector to make it tappable.
                return GestureDetector(
                  onTap: () => setState(() => _selectedGarment = g['name']), // Update the state when an item is tapped.
                  child: Container(
                    decoration: BoxDecoration(
                      // The appearance of the container changes based on whether it is selected.
                      color: isSelected ? theme.primaryColor.withAlpha(26) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.primaryColor : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(g['icon'], size: 48, color: isSelected ? theme.primaryColor : Colors.grey),
                        const SizedBox(height: 12),
                        Text(g['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Starts ₹${g['price']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // The persistent "Continue" button at the bottom of the screen.
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                // The button is disabled (`onPressed` is null) if no garment has been selected.
                onPressed: _selectedGarment == null 
                  ? null 
                  : () => _navigateToNext(_selectedGarment!), // When pressed, navigate to the next screen.
                child: const Text("Continue"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
