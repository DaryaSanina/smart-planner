import 'package:app/settings/settings_page.dart';

import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.userID,
    required this.username,
  });
  final int userID;
  final String username;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Navigate the user to the settings page
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SettingsPage(userID: userID, username: username);
        }));
      },
      icon: const Icon(Icons.settings)
    );
  }
}