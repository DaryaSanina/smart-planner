import 'package:app/models/user_model.dart';
import 'package:app/server_interactions.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Username editing menu
class UsernameEditingMenu extends StatefulWidget{
  const UsernameEditingMenu({
    super.key,
    required this.userID,
    required this.controller
  });

  final int userID;
  final TextEditingController controller;

  @override
  State<UsernameEditingMenu> createState() => _UsernameEditingMenuState();
}

class _UsernameEditingMenuState extends State<UsernameEditingMenu> {
  // Indicates whether the database server is currently processing a username
  // update request
  bool _usernameIsUpdating = false;

  

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
                    controller: widget.controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
                      labelText: "Username",
                    ),
                    cursorColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),

                // Button to change the username
                ElevatedButton(
                  onPressed: () async {
                    // Show a circular progress indicator
                    setState(() {
                      _usernameIsUpdating = true;
                    });

                    String? validationError = await updateUsername(
                      widget.userID,
                      widget.controller.text
                    );
            
                    if (validationError != null && context.mounted) {
                      // Show the user a message saying that the username has
                      // not been validated
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(validationError)),
                      );

                      // Hide the circular progress indicator
                      setState(() {
                        _usernameIsUpdating = false;
                      });
                      return;
                    }

                    // Update the cache
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('username', widget.controller.text);
                    
                    // Update the user model
                    user.setUsername(widget.controller.text);
                    user.notify();

                    // Hide the circular progress indicator
                    setState(() {
                      _usernameIsUpdating = false;
                    });
                  },

                  // Button design
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)
                    ),
                  ),

                  child: _usernameIsUpdating
                  // If _usernameIsLoading is true, show a circular progress
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
          ],
        ),
      ),
    );
  }
}