import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/viewmodels/settings_viewmodel.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/about_section.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/ar_appearance_section.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/display_section.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/navigation_section.dart';

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
          NavigationSection(vm: vm),
          DisplaySection(vm: vm),
          ArAppearanceSection(vm: vm),
          const AboutSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
