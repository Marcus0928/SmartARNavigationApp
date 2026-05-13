import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/settings_section_header.dart';

class ArAppearanceSection extends StatelessWidget {
  const ArAppearanceSection({super.key, required this.vm});

  final SettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader('AR Appearance'),
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
                  const Text('AR Overlay Opacity', style: TextStyle(fontSize: 16)),
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
                  Text('50%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text('100%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
