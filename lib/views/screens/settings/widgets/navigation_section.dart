import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/settings_section_header.dart';

class NavigationSection extends StatelessWidget {
  const NavigationSection({super.key, required this.vm});

  final SettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader('Navigation'),
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
          activeThumbColor: primaryColor,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
