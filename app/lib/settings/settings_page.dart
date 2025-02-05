import 'package:app/settings/widgets/account_settings_tile.dart';
import 'package:app/settings/widgets/sign_out_tile.dart';
import 'package:app/settings/widgets/settings_app_bar.dart';
import 'package:app/settings/widgets/show_importance_tile.dart';

import 'package:flutter/material.dart';

// Settings page
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.userID, required this.username});
  final int userID;
  final String username;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          appBar: const SettingsAppBar(),

          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
              vertical: MediaQuery.of(context).size.height * 0.02
            ),

            // List of settings
            child: Column(
              children: [
                AccountSettingsTile(
                  userID: widget.userID,
                  username: widget.username
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                const ShowImportanceTile(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                const SignOutTile(),
              ]
            ),
          ),
        );
      }
    );
  }
}