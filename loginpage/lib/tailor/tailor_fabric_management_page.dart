
// This file defines the screen where a tailor can manage their inventory of fabrics.
// It allows a tailor to view a list of all their available fabrics, see their details,
// and add new fabrics to their collection through a dialog form.

import 'dart:io'; // Used for File operations, though not fully implemented here yet.
import 'package:flutter/material.dart'; // The core Flutter framework for building UI.
import '../services/fabric_service.dart'; // The service class to handle API calls for fabric data.
import 'package:image_picker/image_picker.dart'; // A plugin to allow picking images, though the logic is a placeholder.

// The main widget for the TailorFabricManagementPage. It's a StatefulWidget because
// its content (the list of fabrics) is dynamic and can be updated.
class TailorFabricManagementPage extends StatefulWidget {
  // `userData` contains the logged-in tailor's details, specifically their ID.
  final Map<String, dynamic> userData;

  const TailorFabricManagementPage({super.key, required this.userData});

  @override
  State<TailorFabricManagementPage> createState() => _TailorFabricManagementPageState();
}

// This class holds the state and logic for the TailorFabricManagementPage.
class _TailorFabricManagementPageState extends State<TailorFabricManagementPage> {
  // --- STATE VARIABLE ---
  // A Future that will hold the list of fabrics fetched from the server.
  // Using a FutureBuilder with this allows the UI to show a loading state while data is being fetched.
  late Future<List<Map<String, dynamic>>> _fabricsFuture;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Fetch the initial list of fabrics for the tailor.
    _refreshFabrics();
  }

  /// Fetches the tailor's fabrics from the server and updates the state.
  /// This triggers the FutureBuilder to rebuild with the new data.
  void _refreshFabrics() {
    setState(() {
      _fabricsFuture = FabricService.getFabricsForTailor(widget.userData['_id']);
    });
  }

  /// Displays a dialog box with a form for adding a new fabric.
  void _showAddFabricDialog() {
    // Controllers to manage the text in the form fields.
    final nameController = TextEditingController();
    final colorController = TextEditingController();
    final priceController = TextEditingController();
    // State variables specific to the dialog.
    String? selectedType = 'Cotton';
    bool isAvailable = true;
    // File? _image; // Placeholder for image file logic.

    showDialog(
      context: context,
      builder: (context) {
        // AlertDialog provides a standard popup dialog.
        return AlertDialog(
          title: const Text("Add New Fabric"),
          // `StatefulBuilder` is used here to allow the dialog's own content (like the dropdown and switch)
          // to be updated without rebuilding the entire page.
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // The dialog should only be as tall as its content.
                  children: [
                    // Placeholder UI for image picking.
                    Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Fabric Name")),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: ['Cotton', 'Silk', 'Linen', 'Wool', 'Mixed'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) {
                        // Use the StateSetter from the StatefulBuilder to update only the dialog's state.
                        setDialogState(() => selectedType = newValue);
                      },
                      decoration: const InputDecoration(labelText: "Fabric Type"),
                    ),
                    TextField(controller: colorController, decoration: const InputDecoration(labelText: "Color")),
                    TextField(
                      controller: priceController, 
                      decoration: const InputDecoration(labelText: "Price per Meter (₹)"), 
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Show a numeric keyboard.
                    ),
                    SwitchListTile(
                      title: const Text("In Stock"),
                      value: isAvailable,
                      onChanged: (bool value) {
                        setDialogState(() => isAvailable = value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // The action buttons at the bottom of the dialog.
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                // 1. Validation: Check if all required fields are filled correctly.
                final price = double.tryParse(priceController.text);
                if (nameController.text.isEmpty || selectedType == null || price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields correctly."), backgroundColor: Colors.red));
                  return;
                }

                // 2. Construct Payload: Create the map of data to be sent to the server.
                final data = {
                  'tailorId': widget.userData['_id'],
                  'name': nameController.text,
                  'type': selectedType,
                  'color': colorController.text,
                  'pricePerMeter': price,
                  'isAvailable': isAvailable,
                  // Using a placeholder image URL. In a real app, this would be the URL
                  // returned after uploading the selected image to a storage service.
                  'imageUrl': 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200',
                };

                // 3. Send to Server: Make the API call to add the fabric.
                try {
                  await FabricService.addFabric(data);
                  _refreshFabrics(); // Refresh the main list to show the new fabric.
                  Navigator.pop(context); // Close the dialog.
                } catch (e) {
                  // Show an error message if the API call fails.
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Save Fabric"),
            ),
          ],
        );
      },
    );
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Fabrics"),
      ),
      // FutureBuilder handles the asynchronous loading of fabric data.
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fabricsFuture,
        builder: (context, snapshot) {
          // 1. While waiting for data, show a loading spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. If an error occurs, or if there's no data, show an empty state message.
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("You haven't added any fabrics yet.", style: TextStyle(color: Colors.grey)),
            );
          }

          // 3. If data is successfully fetched, display it in a ListView.
          final fabrics = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding to avoid the FAB.
            itemCount: fabrics.length,
            itemBuilder: (context, index) {
              final fabric = fabrics[index];
              final bool inStock = fabric['isAvailable'] ?? false;
              // Each fabric is displayed in a styled Card.
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  // Display the fabric image, with a fallback icon if it fails to load.
                  leading: Image.network(fabric['imageUrl'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 60)),
                  title: Text(fabric['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${fabric['type']} - ${fabric['color']}\n₹${fabric['pricePerMeter']}/meter"),
                  isThreeLine: true, // Allows the subtitle to have two lines.
                  // A styled `Chip` to clearly show the stock status.
                  trailing: Chip(
                    label: Text(inStock ? "In Stock" : "Out of Stock"),
                    backgroundColor: inStock ? Colors.green.shade100 : Colors.red.shade100,
                    labelStyle: TextStyle(color: inStock ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              );
            },
          );
        },
      ),
      // The Floating Action Button is used to trigger the `_showAddFabricDialog`.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFabricDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Fabric"),
      ),
    );
  }
}
