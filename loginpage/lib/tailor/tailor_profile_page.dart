
// This file defines the profile screen for a single tailor, as viewed by a customer.
// It serves a dual purpose based on the customer's order flow:
// 1. If the customer is providing their own fabric, it shows the tailor's services and details.
// 2. If the customer wants the tailor to provide the fabric, it shows an additional "Fabrics" tab
//    where the customer can browse and select from the tailor's available fabric inventory.
// The page uses a SliverAppBar for a modern, collapsing header effect in the tabbed view.

import 'package:flutter/material.dart';
import '../services/fabric_service.dart'; // The service class to fetch fabric data from the API.

// The main widget for the TailorProfilePage. It's a StatefulWidget because its state
// (like the selected tab and selected fabric) changes based on user interaction.
class TailorProfilePage extends StatefulWidget {
  // `tailorData` contains all the information about the tailor being viewed.
  final Map<String, dynamic> tailorData;
  // `userData` contains the customer's data and choices from previous screens.
  final Map<String, dynamic>? userData;

  const TailorProfilePage({super.key, required this.tailorData, this.userData});

  @override
  State<TailorProfilePage> createState() => _TailorProfilePageState();
}

// This class holds the state and logic for the TailorProfilePage.
// It uses `SingleTickerProviderStateMixin` which is necessary for the TabController's animation.
class _TailorProfilePageState extends State<TailorProfilePage> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  TabController? _tabController; // Manages the state for the "Services" and "Fabrics" tabs.
  late Future<List<Map<String, dynamic>>> _fabricsFuture; // A Future to hold fabric data fetched from the server.
  Map<String, dynamic>? _selectedFabric; // The fabric currently selected by the customer.
  double _selectedQuantity = 1.0; // The quantity (in meters) for the selected fabric.

  // A computed property to easily check if the current flow is for the tailor to provide fabric.
  bool get _isTailorProvidingFabric => widget.userData?['isTailorProvidingFabric'] == true;

  // initState is a lifecycle method called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // The TabController and fabric fetching are only initialized if the user is in the
    // "tailor provides fabric" flow.
    if (_isTailorProvidingFabric) {
      _tabController = TabController(length: 2, vsync: this);
      _fabricsFuture = FabricService.getFabricsForTailor(widget.tailorData['_id']);
    }
  }

  // dispose is a lifecycle method called when the widget is permanently removed.
  // It's important to dispose of the controller to free up resources.
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Displays a modal bottom sheet for the user to select the quantity of a chosen fabric.
  void _showQuantityDialog(Map<String, dynamic> fabric) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Pre-fill the quantity if this fabric was already selected.
        double quantity = _selectedFabric?['_id'] == fabric['_id'] ? _selectedQuantity : 1.0;
        // `StatefulBuilder` allows the dialog's content to be updated independently.
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // The sheet should only be as tall as its content.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select Quantity for ${fabric['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // A row with buttons to increment/decrement the quantity.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => setSheetState(() => quantity = (quantity - 0.5).clamp(0.5, 20.0))), // clamp() sets min/max limits.
                    Text("${quantity.toStringAsFixed(1)} meters", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => setSheetState(() => quantity = (quantity + 0.5).clamp(0.5, 20.0))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: const Text("Confirm"),
                    onPressed: () {
                      // Update the main page's state with the selected fabric and quantity.
                      setState(() {
                        _selectedFabric = fabric;
                        _selectedQuantity = quantity;
                      });
                      Navigator.pop(context); // Close the bottom sheet.
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  /// Displays a dialog that shows a full-screen, zoomable image of the fabric.
  void _showFullScreenImage(BuildContext context, Map<String, dynamic> fabric) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(fabric['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Expanded(
                  // `InteractiveViewer` is a built-in widget that allows for panning and zooming of its child.
                  child: InteractiveViewer(
                    panEnabled: false, // Disables panning.
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 1.0, // Minimum zoom level.
                    maxScale: 4.0, // Maximum zoom level.
                    child: Image.network(
                      fabric['imageUrl'],
                      fit: BoxFit.contain, // Ensures the whole image is visible.
                      // Provides a fallback UI if the image fails to load.
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 100, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(child: const Text('Close'), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        );
      },
    );
  }

  // The main build method, which decides which UI to show based on the order flow.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Safely extract tailor details, providing fallback values.
    final details = widget.tailorData['tailorDetails'] ?? widget.tailorData;
    final String shopName = details['shopName'] ?? widget.tailorData['name'] ?? 'Boutique';

    // This is the main conditional logic for the page.
    if (_isTailorProvidingFabric) {
      // If the tailor provides fabric, build the UI with tabs for "Services" and "Fabrics".
      return _buildTabbedUI(context, shopName, details, theme);
    } else {
      // Otherwise, build a simpler UI that only shows the "Services" information.
      return _buildServicesOnlyUI(context, shopName, details, theme);
    }
  }

  /// Builds the simpler, non-tabbed UI for the "customer has fabric" flow.
  Widget _buildServicesOnlyUI(BuildContext context, String shopName, Map<String, dynamic> details, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: Text(shopName), backgroundColor: theme.primaryColor),
      body: _buildServicesTab(details, widget.tailorData['distance']?.toDouble()),
      // The bottom sheet contains the primary action button.
      bottomSheet: _buildBottomSheet(context, shopName, details),
    );
  }

  /// Builds the more complex, tabbed UI for the "tailor provides fabric" flow.
  Widget _buildTabbedUI(BuildContext context, String shopName, Map<String, dynamic> details, ThemeData theme) {
     return Scaffold(
      // `NestedScrollView` is used to coordinate scrolling between the app bar (SliverAppBar)
      // and the content in the TabBarView.
      body: NestedScrollView(
        // `headerSliverBuilder` builds the scrollable app bar area.
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220, // The height of the app bar when fully expanded.
            pinned: true, // The app bar (and tabs) will remain visible at the top when scrolling.
            // `FlexibleSpaceBar` is what creates the collapsing header effect.
            flexibleSpace: FlexibleSpaceBar(
              title: Text(shopName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              background: _buildHeaderBackground(details, theme), // The content behind the title (image or colored container).
            ),
            // The `bottom` of the SliverAppBar is where the TabBar is placed.
            bottom: TabBar(
              controller: _tabController!,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: "Services"),
                Tab(text: "Fabrics"),
              ],
            ),
          ),
        ],
        // The `body` of the NestedScrollView is the TabBarView, which contains the content for each tab.
        body: TabBarView(
          controller: _tabController!,
          children: [
            _buildServicesTab(details, widget.tailorData['distance']?.toDouble()),
            _buildFabricsTab(),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(context, shopName, details),
    );
  }

  /// Builds the content for the "Fabrics" tab.
  Widget _buildFabricsTab() {
    // `FutureBuilder` handles the asynchronous loading of the tailor's fabrics.
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fabricsFuture,
      builder: (context, snapshot) {
        // 1. While waiting for data, show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. If an error occurs or no data is found, show an appropriate message.
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(snapshot.error?.toString() ?? "This tailor has not uploaded any fabrics yet.", style: const TextStyle(color: Colors.grey)),
          );
        }

        // 3. If data is successfully fetched, display it in a ListView.
        final fabrics = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fabrics.length,
          itemBuilder: (context, index) {
            final fabric = fabrics[index];
            final isSelected = _selectedFabric != null && _selectedFabric!['_id'] == fabric['_id'];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // The border changes color to indicate selection.
                side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: GestureDetector(
                  onTap: () => _showFullScreenImage(context, fabric), // Make the image tappable to view full-screen.
                  child: Image.network(
                    fabric['imageUrl'], width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                title: Text(fabric['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("₹${fabric['pricePerMeter']}/meter - ${fabric['type']}"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.green : null),
                  onPressed: () => _showQuantityDialog(fabric), // Show the quantity dialog on tap.
                  child: Text(isSelected ? "Selected" : "Select"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the primary action button at the bottom of the screen.
  Widget _buildBottomSheet(BuildContext context, String shopName, Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final tailorDisplayName = "${widget.tailorData['name']} (${shopName})";
              // Prepare the data to be passed to the next screen.
              final arguments = {
                  ...?widget.userData, // Pass along all existing user data.
                  'selectedTailorId': widget.tailorData['_id'],
                  'selectedTailorName': tailorDisplayName,
                  'selectedTailorPhone': widget.tailorData['phone'],
                  'selectedTailorAddress': details['address'],
              };

              // If the tailor is providing fabric...
              if (_isTailorProvidingFabric) {
                // ...and a fabric has been selected...
                if (_selectedFabric != null) {
                  final fabricCost = _selectedFabric!['pricePerMeter'] * _selectedQuantity;
                  // ...add the fabric details to the arguments.
                  arguments.addAll({
                    'isTailorProvidingFabric': true,
                    'selectedFabric': _selectedFabric,
                    'fabricQuantity': _selectedQuantity,
                    'fabricCost': fabricCost,
                  });
                  // Then navigate to the next screen.
                  Navigator.pushNamed(context, '/select-garment', arguments: arguments);
                }
                // If no fabric is selected, the button is disabled, so this code path isn't taken.
              } else {
                // If the customer is providing their own fabric, navigate directly.
                Navigator.pushNamed(context, '/select-garment', arguments: arguments);
              }
            },
            // The button is greyed out and disabled if a fabric must be chosen but hasn't been.
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isTailorProvidingFabric && _selectedFabric == null) ? Colors.grey : null
            ),
            // The button text changes dynamically based on the state.
            child: Text(
              _isTailorProvidingFabric 
                ? (_selectedFabric == null ? "Select a Fabric to Continue" : "Proceed to Select Garment")
                : "Select This Tailor & Proceed"
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the background for the collapsing app bar, showing a shop picture or a placeholder.
  Widget _buildHeaderBackground(Map<String, dynamic> details, ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Conditionally show the shop picture if a URL is available.
        if (details['shopPictureUrl'] != null && details['shopPictureUrl'].toString().isNotEmpty)
          Image.network(details['shopPictureUrl'], fit: BoxFit.cover)
        else
          // Otherwise, show a colored container with a placeholder icon.
          Container(
            color: theme.primaryColor,
            child: const Icon(Icons.store, size: 80, color: Colors.white24),
          ),
        // A decorative gradient overlay to make the title text more readable when collapsed.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the content for the "Services" tab. This is a placeholder and should be expanded.
  Widget _buildServicesTab(Map<String, dynamic> details, double? distance) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard("About", details['bio'] ?? "This tailor hasn\'t added a bio yet.", Icons.info_outline),
        _buildInfoCard("Address", details['address'] ?? "Address not available", Icons.location_on_outlined),
        _buildInfoCard("Experience", "${details['experience'] ?? 'N/A'} years", Icons.star_border),
        _buildInfoCard("Specializations", (details['specializations'] as List?)?.join(", ") ?? "N/A", Icons.check_circle_outline),
        if (distance != null) _buildInfoCard("Distance", "${distance.toStringAsFixed(1)} km away", Icons.near_me_outlined),
      ],
    );
  }

  /// A reusable helper widget to create a styled card for displaying information in the "Services" tab.
  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }
}
