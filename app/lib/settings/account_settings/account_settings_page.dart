import 'package:app/models/user_model.dart';
import 'package:app/settings/account_settings/util.dart';
import 'package:app/settings/account_settings/widgets/account_settings_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.userID, required this.username});
  final int userID;
  final String username;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  TextEditingController usernameController = TextEditingController();
  bool firstBuild = true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();

    if (firstBuild) {
      firstBuild = false;
      usernameController = TextEditingController(text: widget.username);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          appBar: const AccountSettingsAppBar(),

          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.height * 0.02),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          labelText: "Username",
                        ),
                        cursorColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String result = await updateUsername(widget.userID, usernameController.text);
                        // Update the cache
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('username', usernameController.text);
                        user.setUsername(usernameController.text);
                        user.notify();

                        if (result != "OK") {
                          // Show the user a message saying that the username has not been validated
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        "UPDATE",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    )
                  ],
                ),
              ]
            ),
          ),
        );
      }
    );
  }
}