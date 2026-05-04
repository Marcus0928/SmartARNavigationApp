import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';

class WazeDrawer extends StatelessWidget {
  const WazeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: const Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Marcus',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Smart AR Navigator',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          _DrawerMenuItem(
            icon: Icons.directions_outlined,
            label: 'Plan a drive',
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerMenuItem(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerMenuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          _DrawerMenuItem(
            icon: Icons.help_outline,
            label: 'Help & Feedback',
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Divider(height: 1, thickness: 1),
          _DrawerMenuItem(
            icon: Icons.power_settings_new,
            label: 'Shut Down',
            iconColor: Colors.red.shade400,
            labelColor: Colors.red.shade400,
            onTap: () {
              Navigator.of(context).pop();
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Shut Down'),
                  content:
                      const Text('Are you sure you want to exit the app?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: Text(
                        'Exit',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey.shade700,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: labelColor ?? Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      horizontalTitleGap: 4,
      onTap: onTap,
    );
  }
}
