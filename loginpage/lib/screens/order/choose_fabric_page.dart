
// This file defines a screen that allows the user to choose how they will provide
// the fabric for their garment order. This is one of the initial steps in the order creation process.
// The user is presented with several options, and their choice determines the next step in the flow.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The main widget for the ChooseFabricPage. It's a StatefulWidget because its state
// (the selected option) changes based on user interaction.
class ChooseFabricPage extends StatefulWidget {
  // User data passed from the previous screen, which will be passed along to the next screen.
  final Map<String, dynamic>? userData;
  const ChooseFabricPage({super.key, this.userData});

  @override
  State<ChooseFabricPage> createState() => _ChooseFabricPageState();
}

// This class holds the state and logic for the ChooseFabricPage.
class _ChooseFabricPageState extends State<ChooseFabricPage> {
  // --- STATE VARIABLE ---
  // Stores the value of the currently selected fabric option.
  // It defaults to 'have_fabric', making it the pre-selected option when the page loads.
  String _selectedOption = 'have_fabric';

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access the app's theme for consistent styling.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose Fabric'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How will you provide fabric?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Select an option to continue.", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 32),
            // Each of these `_buildOption` widgets represents a selectable choice.
            _buildOption(
              title: 'I already have fabric',
              subtitle: 'Tailor will collect it from your location.',
              value: 'have_fabric',
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildOption(
              title: 'Buy fabric from app',
              subtitle: 'Browse our collection of materials.',
              value: 'buy_from_app',
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildOption(
              title: 'Let tailor provide fabric',
              subtitle: 'Tailor will suggest and provide material.',
              value: 'tailor_provides',
              theme: theme,
            ),
          ],
        ),
      ),
      // A persistent bottom navigation bar containing the main action button.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))], // A subtle shadow for depth.
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // The logic here is determined by the `_selectedOption`.
              if (_selectedOption == 'have_fabric') {
                // If the user has fabric, navigate to the screen that handles that flow.
                Navigator.pushNamed(context, '/i-have-fabric', arguments: widget.userData);
              } else if (_selectedOption == 'tailor_provides') {
                // If the tailor provides fabric, navigate to the tailor list with an extra parameter.
                 Navigator.pushNamed(context, '/tailor-list', arguments: {
                  ...?widget.userData, // Pass along all existing user data.
                  'isTailorProvidingFabric': true, // Add a flag to indicate this choice.
                });
              } else {
                // For any other option (like 'buy_from_app'), show a "coming soon" message.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This option is coming soon!')),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }

  /// A reusable helper widget to build a selectable option card.
  /// It includes a title, subtitle, and a radio button, all within a styled container.
  Widget _buildOption({required String title, required String subtitle, required String value, required ThemeData theme}) {
    // Check if this option is the currently selected one to adjust its appearance.
    final bool isSelected = _selectedOption == value;

    return GestureDetector(
      // When the user taps anywhere on the container, update the state to select this option.
      onTap: () => setState(() => _selectedOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Animate changes to the container's appearance.
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // The background and border color change based on whether the option is selected.
          color: isSelected ? theme.primaryColor.withAlpha(13) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? theme.primaryColor : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            // A radio button provides a clear visual indicator of the selected option.
            Radio<String>(
              value: value,
              groupValue: _selectedOption, // The groupValue links all radio buttons together.
              onChanged: (val) => setState(() => _selectedOption = val!), // The radio button can also be tapped to change the selection.
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
