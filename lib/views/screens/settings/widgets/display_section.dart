import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/settings_section_header.dart';

class DisplaySection extends StatelessWidget {
  const DisplaySection({super.key, required this.vm});

  final SettingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader('Display'),
        SwitchListTile(
          title: const Text('Show Speed'),
          subtitle: const Text('Display current speed during navigation'),
          value: vm.showSpeed,
          onChanged: vm.setShowSpeed,
          activeThumbColor: primaryColor,
        ),
        SwitchListTile(
          title: const Text('Show ETA'),
          subtitle: const Text('Display estimated arrival time'),
          value: vm.showETA,
          onChanged: vm.setShowETA,
          activeThumbColor: primaryColor,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
