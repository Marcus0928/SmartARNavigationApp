import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_ar_navigation/core/constants/app_colors.dart';
import 'package:smart_ar_navigation/views/screens/settings/widgets/settings_section_header.dart';

const String _supportEmail = 'support@smartarnavigation.app';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  Future<void> _launchFeedbackEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Smart AR Navigation App Feedback')}',
    );

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Feedback'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
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
          const SettingsSectionHeader('How to Use'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FaqBullet(
                  'Tap the search bar on the home screen, choose a destination, '
                  'then tap "Start AR Navigation" to begin turn-by-turn AR guidance.',
                ),
                SizedBox(height: 10),
                _FaqBullet(
                  'Save frequent destinations like Home or Work from your Profile '
                  'screen so they are one tap away next time.',
                ),
                SizedBox(height: 10),
                _FaqBullet(
                  'Open the drawer menu and select Settings to change navigation, '
                  'display, and AR appearance preferences.',
                ),
                SizedBox(height: 10),
                _FaqBullet(
                  'Use "Plan a drive" from the drawer menu to preview a route '
                  'before you start driving.',
                ),
              ],
            ),
          ),
          const SettingsSectionHeader('Contact / Feedback'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: OutlinedButton.icon(
              onPressed: () => _launchFeedbackEmail(context),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email Us Feedback'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqBullet extends StatelessWidget {
  const _FaqBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
          ),
        ),
      ],
    );
  }
}
