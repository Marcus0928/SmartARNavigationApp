import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/core/constants/app_strings.dart';
import 'package:smart_ar_navigation/viewmodels/map_viewmodel.dart';
import 'package:smart_ar_navigation/viewmodels/navigation_viewmodel.dart';
import 'package:smart_ar_navigation/views/widgets/search_bar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Default map centre — Sunway University area
  static const LatLng _defaultCenter = LatLng(3.0738, 101.5077);

  @override
  Widget build(BuildContext context) {
    final mapVM = context.watch<MapViewModel>();
    final navVM = context.watch<NavigationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: const SearchBarWidget(),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: mapVM.currentLocation ?? _defaultCenter,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
          if (mapVM.selectedDestination != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    startNavigation,
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    await navVM.startNavigation(mapVM.selectedDestination!);
                    if (!context.mounted) return;
                    if (navVM.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(navVM.errorMessage!)),
                      );
                    } else {
                      Navigator.of(context).pushNamed('/ar-navigation');
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
