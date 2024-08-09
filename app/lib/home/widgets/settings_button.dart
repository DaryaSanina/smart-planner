import 'package:app/settings/settings_page.dart';

import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Navigate the user to the settings page
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const SettingsPage();
        }));
      },
      icon: const Icon(Icons.settings)
    );
  }
}