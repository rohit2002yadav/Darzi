
// This file defines the screen where the user decides how to hand over their fabric to the tailor.
// It's a pivotal final step before payment, consolidating all order details into a summary.
// The user can choose between two main options:
// 1. Tailor Pickup: The tailor comes to a specified address to collect the fabric.
//    The user can select from saved addresses, add a new one, and choose a time slot.
// 2. Drop at Shop: The user takes the fabric to the tailor's shop themselves.
//    This option displays the tailor's shop address and working hours.
// A detailed order summary is shown at the bottom, and the user can only proceed
// to payment once all necessary handover details are provided.

import 'package:flutter/material.dart'; // The core Flutter framework for building UI.

// The main widget for the FabricHandoverScreen. It's a StatefulWidget because its state
// changes based on user selections (pickup/drop, address, time slot).
class FabricHandoverScreen extends StatefulWidget {
  // User data aggregated from all previous steps in the order creation process.
  final Map<String, dynamic>? userData;
  const FabricHandoverScreen({super.key, this.userData});

  @override
  State<FabricHandoverScreen> createState() => _FabricHandoverScreenState();
}

// This class holds the state and logic for the FabricHandoverScreen.
class _FabricHandoverScreenState extends State<FabricHandoverScreen> {
  // --- STATE VARIABLES ---

  // Stores the currently selected handover method: "pickup" or "drop".
  String selectedOption = "pickup";
  // The ID of the currently selected address from the `addresses` list.
  String? selectedAddressId;
  // The pickup time slot selected by the user.
  String selectedTime = "";

  // A list to hold all available pickup addresses, including both saved and newly added ones.
  List<Map<String, String>> addresses = [];

  // A predefined list of available time slots for tailor pickup.
  final timeSlots = [
    "9:00 AM - 11:00 AM", "11:00 AM - 1:00 PM", "2:00 PM - 4:00 PM",
    "4:00 PM - 6:00 PM", "6:00 PM - 8:00 PM",
  ];

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Initialize the addresses list with the user's default address from their profile.
    final defaultAddress = widget.userData?['customerDetails']?['address'];
    if (defaultAddress != null) {
      addresses.add({'id': 'default', 'address': defaultAddress, 'label': 'Default'});
      // Pre-select the default address.
      selectedAddressId = 'default';
    }
  }

  // A computed property (a getter) to determine if the user has provided enough information to proceed.
  // This is used to enable or disable the "Proceed to Payment" button.
  bool get canContinue => selectedOption == 'drop' || (selectedOption == 'pickup' && selectedAddressId != null && selectedTime.isNotEmpty);

  // This function displays a modal bottom sheet that contains a form for adding a new pickup address.
  void _showAddAddressSheet() {
    // Controllers to manage the text in the address form fields.
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final pincodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more screen height and avoid being covered by the keyboard.
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        // Adjust padding to keep content visible when the keyboard is open.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // The sheet should only be as tall as its content.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Add Pickup Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (e.g., Home, Office)')),
            const SizedBox(height: 12),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Full Address')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: pincodeController, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Basic validation.
                if (addressController.text.isNotEmpty && cityController.text.isNotEmpty) {
                  // Create a new address map.
                  final newAddress = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(), // Use a timestamp for a unique ID.
                    'address': "${addressController.text}, ${cityController.text}, ${pincodeController.text}",
                    'label': labelController.text,
                  };
                  // Update the state to add the new address and automatically select it.
                  setState(() {
                    addresses.add(newAddress);
                    selectedAddressId = newAddress['id'];
                  });
                  Navigator.pop(context); // Close the bottom sheet.
                }
              },
              child: const Text("Save & Select"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // The build method describes the UI of the page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FA), // A light lavender background color.
      appBar: AppBar(title: const Text("Confirm Handover & Order")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // The card for the "Pickup" option.
                  _buildOptionCard(
                    title: "Tailor Pickup From Home",
                    subtitle: "Tailor will visit you for fabric & measurements.",
                    icon: Icons.home_outlined,
                    isSelected: selectedOption == 'pickup',
                    onTap: () => setState(() => selectedOption = 'pickup'),
                    // The detailed content for this option is passed as a child.
                    child: _buildPickupDetails(theme),
                  ),
                  const SizedBox(height: 12),
                  // The card for the "Drop off" option.
                  _buildOptionCard(
                    title: "Drop at Tailor's Shop",
                    subtitle: "Visit the shop to hand over fabric personally.",
                    icon: Icons.store_outlined,
                    isSelected: selectedOption == 'drop',
                    onTap: () => setState(() => selectedOption = 'drop'),
                    child: _buildDropOffDetails(theme),
                  ),
                  const SizedBox(height: 24),
                  // The card that summarizes the entire order.
                  _buildOrderSummaryCard(theme),
                ],
              ),
            ),
          ),
          // The persistent button at the bottom of the screen.
          _buildConfirmButton(),
        ],
      ),
    );
  }

  /// Builds the expandable details section for the "Pickup" option.
  /// This includes the address selector and time slot chips.
  Widget _buildPickupDetails(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pickup Address", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _showAddAddressSheet, icon: const Icon(Icons.add, size: 16), label: const Text("Add New")),
            ],
          ),
          // If there are addresses available, show them in a dropdown.
          if (addresses.isNotEmpty)
            DropdownButtonFormField<String>(
              value: selectedAddressId,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              items: addresses.map((addr) {
                return DropdownMenuItem<String>(
                  value: addr['id'],
                  child: Text(addr['address']!, overflow: TextOverflow.ellipsis), // Prevent long addresses from overflowing.
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedAddressId = val),
            )
          else
            // If no addresses are available, prompt the user to add one.
            const Text("Please add a pickup address.", style: TextStyle(color: Colors.red)),

          const SizedBox(height: 24),
          Text("Select Time Slot", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // `Wrap` allows the ChoiceChips to flow to the next line if there isn't enough horizontal space.
          Wrap(
            spacing: 8.0, // Horizontal space between chips.
            runSpacing: 8.0, // Vertical space between lines of chips.
            children: timeSlots.map((slot) {
              final isSelected = selectedTime == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                labelStyle: TextStyle(fontSize: 12, color: isSelected ? theme.primaryColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? theme.primaryColor : Colors.grey.shade200)),
                onSelected: (selected) => setState(() => selectedTime = selected ? slot : ""), // If a chip is deselected, clear the selection.
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  /// Builds the expandable details section for the "Drop off" option.
  /// This displays the selected tailor's shop details.
  Widget _buildDropOffDetails(ThemeData theme) {
    // Retrieve tailor details from the userData map.
    final tailorName = widget.userData?['selectedTailorName'] ?? 'the tailor';
    final tailorAddress = widget.userData?['selectedTailorAddress'] ?? 'Please check the tailor\'s profile for their address.';

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Please drop the fabric at the following location:", style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          _infoRow(theme, Icons.store, "Shop Name", tailorName),
          const Divider(height: 20),
          _infoRow(theme, Icons.location_on, "Address", tailorAddress),
          const Divider(height: 20),
          _infoRow(theme, Icons.access_time, "Working Hours", "10:00 AM - 8:00 PM (Mon-Sat)"), // Hardcoded for now.
        ],
      ),
    );
  }

  /// A small, reusable helper widget to display a row of information (icon, label, value).
  Widget _infoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.grey, size: 18),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]))
    ]);
  }

  /// A reusable helper widget for building the main option cards ("Pickup" and "Drop off").
  Widget _buildOptionCard({ required String title, required String subtitle, required IconData icon, required bool isSelected, required VoidCallback onTap, Widget? child}) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // The border changes to indicate selection.
        side: BorderSide(color: isSelected ? theme.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap, // The onTap callback handles selecting the option.
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon, color: theme.primaryColor),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
              // The trailing icon indicates whether the card is expanded or collapsed.
              trailing: Icon(isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: isSelected ? theme.primaryColor : Colors.grey),
            ),
            // Conditionally display the child content only if the card is selected.
            if (isSelected && child != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the persistent "Proceed to Payment" button at the bottom of the screen.
  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SafeArea( // Ensures the button is not obstructed by system UI (like the home bar).
        child: ElevatedButton(
          // The button is only enabled if `canContinue` is true.
          onPressed: canContinue ? () {
            // Calculate costs.
            final double stitchingCost = widget.userData?['basePrice']?.toDouble() ?? 0.0;
            final double fabricCost = widget.userData?['fabricCost']?.toDouble() ?? 0.0;
            final double totalAmount = stitchingCost + fabricCost;

            // Navigate to the payment screen, passing along all accumulated order data.
            Navigator.pushNamed(context, '/payment', arguments: {
              ...?widget.userData, // Pass all existing data.
              'totalAmount': totalAmount,
              'handoverType': selectedOption,
              // Conditionally add pickup details if that option was selected.
              'pickup': selectedOption == "pickup" ? {
                "address": addresses.firstWhere((e) => e["id"] == selectedAddressId)['address']!,
                "date": DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0], // Set pickup for the next day.
                "timeSlot": selectedTime,
              } : null,
              // Pass tailor identifiers.
              'selectedTailorId': widget.userData?['selectedTailorId'],
              'selectedTailorName': widget.userData?['selectedTailorName'],
            });
          } : null, // A null onPressed callback automatically disables the button.
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: const Text("Proceed to Payment"),
        ),
      ),
    );
  }

  /// Builds the card that displays a comprehensive summary of the order.
  Widget _buildOrderSummaryCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildSectionHeader("Tailor Details"),
            _summaryInfoRow("Shop Name", widget.userData?['selectedTailorName'] ?? 'N/A'),
            const SizedBox(height: 20),
            _buildSectionHeader("Garment & Measurements"),
            _summaryInfoRow("Garment", widget.userData?['garmentType'] ?? 'N/A'),
            const SizedBox(height: 20),
            _buildSectionHeader("Fabric Details"),
            _buildFabricSummary(), // Helper for fabric summary.
            const SizedBox(height: 20),
            _buildSectionHeader("Handover Details"),
            _buildHandoverSummary(), // Helper for handover summary.
            const SizedBox(height: 20),
            _buildSectionHeader("Price Summary"),
            _buildPriceSummary(), // Helper for price summary.
          ],
        ),
      ),
    );
  }

  /// A small, reusable helper widget for section headers within the summary card.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
    );
  }

  /// Builds the part of the summary related to fabric details.
  Widget _buildFabricSummary() {
    // The content differs based on who is providing the fabric.
    if (widget.userData?['isTailorProvidingFabric'] == true) {
      return Column(
        children: [
          _summaryInfoRow("Provided By", "Tailor"),
          _summaryInfoRow("Selected Fabric", widget.userData?['selectedFabric']?['name'] ?? 'N/A'),
          _summaryInfoRow("Quantity", "${widget.userData?['fabricQuantity'] ?? 0.0} meters"),
        ],
      );
    } else {
      return Column(
        children: [
          _summaryInfoRow("Provided By", "Customer"),
          _summaryInfoRow("Type", widget.userData?['fabricDetails']?['type'] ?? 'N/A'),
          _summaryInfoRow("Color", widget.userData?['fabricDetails']?['color'] ?? 'N/A'),
        ],
      );
    }
  }

  /// Builds the part of the summary related to handover details.
  /// The content changes dynamically based on the selected handover option.
  Widget _buildHandoverSummary() {
    if (selectedOption == 'pickup') {
      // Find the selected address from the list to display its full text.
      final address = addresses.firstWhere((e) => e['id'] == selectedAddressId, orElse: () => {'address': 'N/A'});
      return Column(
        children: [
          _summaryInfoRow("Method", "Pickup from Home"),
          _summaryInfoRow("Address", address['address']!),
          _summaryInfoRow("Time Slot", selectedTime),
        ],
      );
    } else {
      final tailorAddress = widget.userData?['selectedTailorAddress'] ?? 'N/A';
      return Column(
        children: [
          _summaryInfoRow("Method", "Drop at Tailor's Shop"),
          _summaryInfoRow("Shop Address", tailorAddress),
        ],
      );
    }
  }

  /// Builds the final price breakdown section of the summary.
  Widget _buildPriceSummary() {
    final double stitchingCost = widget.userData?['basePrice']?.toDouble() ?? 0.0;
    final double fabricCost = widget.userData?['fabricCost']?.toDouble() ?? 0.0;
    final double totalAmount = stitchingCost + fabricCost;
    return Column(
      children: [
        _priceRow("Stitching Cost", "₹${stitchingCost.toStringAsFixed(2)}"),
        // Only show fabric cost if it's greater than zero.
        if (fabricCost > 0) _priceRow("Fabric Cost", "₹${fabricCost.toStringAsFixed(2)}"),
        const Divider(thickness: 1, height: 20),
        _priceRow("Total", "₹${totalAmount.toStringAsFixed(2)}", isTotal: true),
      ],
    );
  }

  /// A small helper for a key-value row in the summary card.
  Widget _summaryInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(children: [
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
    );
  }

  /// A small helper for a row in the price breakdown.
  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
      ]),
    );
  }
}
