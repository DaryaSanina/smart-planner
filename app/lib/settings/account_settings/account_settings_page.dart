import 'package:app/login/util.dart';
import 'package:app/models/user_model.dart';
import 'package:app/registration/util.dart';
import 'package:app/settings/account_settings/util.dart';
import 'package:app/settings/account_settings/widgets/account_settings_app_bar.dart';
import 'package:app/settings/account_settings/widgets/link_google_account.dart';
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
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();
  bool firstBuild = true;
  bool _usernameIsLoading = false;
  bool _passwordIsLoading = false;

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
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.015, vertical: MediaQuery.of(context).size.height * 0.01),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Username editing menu
                  Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.015, vertical: MediaQuery.of(context).size.height * 0.015),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username editing menu label
                          Text(
                            "Change Username",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 18,
                            ),
                          ),
              
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Username editing text box
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

                              // Button to change the username
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    _usernameIsLoading = true;  // Show a circular progress indicator
                                  });
              
                                  String? result = await updateUsername(widget.userID, usernameController.text);
                          
                                  if (result != null) {
                                    // Show the user a message saying that the username has not been validated
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result)),
                                    );
              
                                    setState(() {
                                      _usernameIsLoading = false;  // Hide the circular progress indicator
                                    });
                                    return;
                                  }
              
                                  // Update the cache
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('username', usernameController.text);
                                  
                                  user.setUsername(usernameController.text);
                                  user.notify();
              
                                  setState(() {
                                    _usernameIsLoading = false;  // Hide the circular progress indicator
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: _usernameIsLoading
                                // If _usernameIsLoading is true, show a circular progress indicator next to the "SAVE" text
                                ? Row(
                                  children: [
                                    Text(
                                      "SAVE",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.tertiary,
                                      ),
                                    ),
                                    CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary),
                                  ],
                                )
                                : Text(
                                  "SAVE",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              
                  // Password editing menu
                  Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.015, vertical: MediaQuery.of(context).size.height * 0.015),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Password editing menu label
                          Text(
                            "Change Password",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 18,
                            ),
                          ),
              
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              
                          // Current password text box
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: currentPasswordController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                labelText: "Current password",
                              ),
                              cursorColor: Theme.of(context).colorScheme.tertiary,
                              obscureText: true,
                              obscuringCharacter: '*',
                            ),
                          ),
                      
                          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                      
                          // New password text box
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: TextField(
                              controller: newPasswordController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                labelText: "New password",
                              ),
                              cursorColor: Theme.of(context).colorScheme.tertiary,
                              obscureText: true,
                              obscuringCharacter: '*',
                            ),
                          ),
                      
                          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                      
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Text box to repeat the new password
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: TextField(
                                  controller: repeatPasswordController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                    labelText: "Repeat new password",
                                  ),
                                  cursorColor: Theme.of(context).colorScheme.tertiary,
                                  obscureText: true,
                                  obscuringCharacter: '*',
                                ),
                              ),

                              // Button to update the password
                              ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    _passwordIsLoading = true;  // Show a circular progress indicator
                                  });
              
                                  // Check the current password
                                  if (await login(user.username, currentPasswordController.text) == -1) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("The current password is incorrect")),
                                    );
                                    setState(() {
                                      _passwordIsLoading = false;  // Hide the circular progress indicator
                                    });
                                    return;
                                  }
              
                                  // Check whether the new password and the repeated new password match
                                  if (newPasswordController.text != repeatPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("The new passwords don't match")),
                                    );
                                    setState(() {
                                      _passwordIsLoading = false;  // Hide the circular progress indicator
                                    });
                                    return;
                                  }
              
                                  // Validate the password
                                  String? validationError = validatePassword(newPasswordController.text);
                                  if (validationError != null) {
                                    // Show the user a message saying that the password has not been updated
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(validationError)),
                                    );
                                    setState(() {
                                      _passwordIsLoading = false;  // Hide the circular progress indicator
                                    });
                                    return;
                                  }
              
                                  // Update the password
                                  String? result = await updatePassword(widget.userID, newPasswordController.text);
              
                                  if (result != null) {
                                    // Show the user a message saying that the password has not been updated
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(result)),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: _passwordIsLoading
                                // If _passwordIsLoading is true, show a circular progress indicator next to the "SAVE" text
                                ? Row(
                                  children: [
                                    Text(
                                      "SAVE",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.tertiary,
                                      ),
                                    ),
                                    CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary),
                                  ],
                                )
                                : Text(
                                  "SAVE",
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
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                  // Button to link a Google account
                  const LinkGoogleAccountButton(),
                ]
              ),
            ),
          ),
        );
      }
    );
  }
}