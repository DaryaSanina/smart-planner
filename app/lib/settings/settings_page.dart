import 'package:app/settings/widgets/account_settings_button.dart';
import 'package:app/settings/widgets/logout_button.dart';
import 'package:app/settings/widgets/settings_app_bar.dart';
import 'package:app/settings/widgets/show_importance_button.dart';

import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.height * 0.02),
            child: Column(
              children: [
                const AccountSettingsButton(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                const ShowImportanceButton(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                const LogoutButton(),
              ]
            ),
          ),
        );
      }
    );
  }
}