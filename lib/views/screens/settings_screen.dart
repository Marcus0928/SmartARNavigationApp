import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _sectionHeader('Navigation'),
          // Navigation Mode — locked to AR; 2D coming soon
          ListTile(
            title: const Text('Navigation Mode'),
            subtitle: const Text('2D Map mode coming soon'),
            trailing: IgnorePointer(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'AR', label: Text('AR')),
                  ButtonSegment(value: '2D', label: Text('2D')),
                ],
                selected: const {'AR'},
                showSelectedIcon: false,
                onSelectionChanged: (_) {},
              ),
            ),
          ),
          ListTile(
            title: const Text('Distance Unit'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'km', label: Text('km')),
                ButtonSegment(value: 'miles', label: Text('miles')),
              ],
              selected: {vm.distanceUnit},
              showSelectedIcon: false,
              onSelectionChanged: (s) => vm.setDistanceUnit(s.first),
            ),
          ),
          SwitchListTile(
            title: const Text('Avoid Tolls'),
            subtitle: const Text('Route around toll roads when possible'),
            value: vm.avoidTolls,
            onChanged: vm.setAvoidTolls,
            activeColor: primaryColor,
          ),
          const Divider(height: 1),
          _sectionHeader('Display'),
          SwitchListTile(
            title: const Text('Show Speed'),
            subtitle: const Text('Display current speed during navigation'),
            value: vm.showSpeed,
            onChanged: vm.setShowSpeed,
            activeColor: primaryColor,
          ),
          SwitchListTile(
            title: const Text('Show ETA'),
            subtitle: const Text('Display estimated arrival time'),
            value: vm.showETA,
            onChanged: vm.setShowETA,
            activeColor: primaryColor,
          ),
          const Divider(height: 1),
          _sectionHeader('AR Appearance'),
          ListTile(
            title: const Text('Arrow Size'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Small', label: Text('S')),
                ButtonSegment(value: 'Medium', label: Text('M')),
                ButtonSegment(value: 'Large', label: Text('L')),
              ],
              selected: {vm.arrowSize},
              showSelectedIcon: false,
              onSelectionChanged: (s) => vm.setArrowSize(s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AR Overlay Opacity',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${(vm.overlayOpacity * 100).round()}%',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Slider(
                  value: vm.overlayOpacity,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  label: '${(vm.overlayOpacity * 100).round()}%',
                  activeColor: primaryColor,
                  onChanged: vm.setOverlayOpacity,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _sectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            trailing: Text(
              'Beta 0.0.1',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ListTile(
            title: const Text('Developer'),
            trailing: Text(
              'Marcus Liew',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ListTile(
            title: const Text('Institution'),
            trailing: Text(
              'Sunway University',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _sectionHeader(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
