import 'package:flutter/material.dart';

import 'package:smart_ar_navigation/views/screens/settings/widgets/settings_section_header.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader('About'),
        ListTile(
          title: const Text('App Version'),
          trailing: Text('Beta 0.1.0', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ListTile(
          title: const Text('Developer'),
          trailing: Text('Marcus Liew', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ListTile(
          title: const Text('Institution'),
          trailing: Text('Sunway University', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}
