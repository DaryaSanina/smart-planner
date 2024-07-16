import 'package:flutter/material.dart';
import 'package:app/settings/settings_page.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const SettingsPage();
        }));
      },
      icon: const Icon(Icons.settings)
    );
  }
}