import 'package:app/server_interactions.dart';
import 'package:app/sign_in/util.dart';
import 'package:app/models/user_model.dart';
import 'package:app/passwords.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


// Password editing menu
class PasswordEditingMenu extends StatefulWidget{
  const PasswordEditingMenu({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.repeatPasswordController
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController repeatPasswordController;

  @override
  State<PasswordEditingMenu> createState() => _PasswordEditingMenuState();
}

class _PasswordEditingMenuState extends State<PasswordEditingMenu> {
  // Indicates whether the database server is currently processing a password
  // update request
  bool _passwordIsUpdating = false;

  @override
  Widget build(BuildContext context) {
    // Load the user model
    UserModel user = context.watch<UserModel>();

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.015,
          vertical: MediaQuery.of(context).size.height * 0.015
        ),
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
                controller: widget.currentPasswordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),
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
                controller: widget.newPasswordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30)
                  ),
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
                    controller: widget.repeatPasswordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
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
                    // Show a circular progress indicator
                    setState(() {
                      _passwordIsUpdating = true;
                    });

                    // Check the current password
                    if (await signIn(
                        user.username, widget.currentPasswordController.text)
                        == -1
                        && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "The current password is incorrect "
                            "or something went wrong. Please try again"
                          )
                        ),
                      );

                      // Hide the circular progress indicator
                      setState(() {
                        _passwordIsUpdating = false;
                      });
                      return;
                    }

                    // Check whether the new password and the repeated
                    // new password match
                    if (widget.newPasswordController.text
                        != widget.repeatPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("New passwords don't match")
                        ),
                      );

                      // Hide the circular progress indicator
                      setState(() {
                        _passwordIsUpdating = false;
                      });
                      return;
                    }

                    // Validate the new password
                    String? validationError = validatePassword(
                      widget.newPasswordController.text
                    );
                    
                    if (validationError != null) {
                      // Show the user a message saying that the password
                      // has not been updated
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "The password has not been updated. "
                            "$validationError"
                          )
                        ),
                      );

                      // Hide the circular progress indicator
                      setState(() {
                        _passwordIsUpdating = false;
                      });
                      return;
                    }

                    // Update the password
                    String? errorMessage = await updatePassword(
                      user.id,
                      widget.newPasswordController.text
                    );

                    if (errorMessage != null && context.mounted) {
                      // Show the user a message saying that the password
                      // has not been updated
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "The password has not been updated. $errorMessage"
                          )
                        ),
                      );
                    }
                  },

                  // Button design
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                    ),
                  ),

                  child: _passwordIsUpdating
                  // If _passwordIsLoading is true, show a circular progress
                  // indicator next to the "SAVE" text
                  ? Row(
                    children: [
                      Text(
                        "SAVE",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.tertiary
                      ),
                    ],
                  )

                  // Otherwise, show just the "SAVE" text
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
    );
  }
}