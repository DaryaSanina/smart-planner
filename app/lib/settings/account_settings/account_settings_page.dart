import 'package:app/settings/account_settings/widgets/account_settings_app_bar.dart';
import 'package:app/settings/account_settings/widgets/connect_google_account.dart';
import 'package:app/settings/account_settings/widgets/password_editing_menu.dart';
import 'package:app/settings/account_settings/widgets/username_editing_menu.dart';

import 'package:flutter/material.dart';

// Account settings page
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.userID,
    required this.username
  });
  final int userID;
  final String username;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          // Page header
          appBar: const AccountSettingsAppBar(),

          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.015,
              vertical: MediaQuery.of(context).size.height * 0.01
            ),

            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Username editing menu
                  UsernameEditingMenu(
                    userID: widget.userID,
                    controller: usernameController
                  ),
              
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              
                  // Password editing menu
                  PasswordEditingMenu(
                    userID: widget.userID,
                    currentPasswordController: currentPasswordController,
                    newPasswordController: newPasswordController,
                    repeatPasswordController: repeatPasswordController
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                  // Button to connect a Google account
                  const ConnectGoogleAccountButton(),
                ]
              ),
            ),
          ),
        );
      }
    );
  }
}