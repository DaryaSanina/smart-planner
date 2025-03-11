import 'package:app/home/home_page.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/server_interactions.dart';
import 'package:app/sign_in/util.dart';
import 'package:app/models/user_model.dart';
import 'package:app/passwords.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Registration form
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  // Create the form
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  // Indicates whether the database already contains a user with the username
  // entered in the username field
  bool _usernameExists = false;

  // Indeicates whether the database server is currently processing
  // a registration request
  bool _isLoading = false;

  // Clears cache
  final Future<void> clearedCache = clearCache();

  @override
  Widget build(BuildContext context) {
    // Load the user and task list models
    UserModel user = context.watch<UserModel>();
    TaskListModel taskList = context.watch<TaskListModel>();

    int userID;

    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.15
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Username field
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30)
                ),
                labelText: "Username",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,

              // Username validator
              validator: (value) {
                // Check whether the field is empty
                if (value == null || value.isEmpty) {
                  return "Please enter your username";
                }
                // Check whether the username has between 3 and 32 characters
                if (value.length < 3) {
                  return "The username is too short";
                }
                else if (value.length > 32) {
                  return "The username is too long";
                }
                // Check whether the username has already been taken
                if (_usernameExists) {
                  return "This username has already been taken";
                }
                return null;
              },

              // When a new username is entered, check whether it has already
              // been taken
              onChanged: (text) async {
                List<dynamic> userList = await getUserByUsername(text);
                setState(() {
                  _usernameExists = userList.isNotEmpty;
                });
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        
            // Password field
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30)
                ),
                labelText: "Password",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              obscureText: true,
              obscuringCharacter: '*',

              // Password validator
              validator: (value) => validatePassword(value)
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            // "Repeat password" field
            TextFormField(
              controller: repeatPasswordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30)
                ),
                labelText: "Repeat password",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              obscureText: true,
              obscuringCharacter: '*',

              // Repeated password validator
              validator: (value) {
                // Check whether the field is empty
                if (value == null || value.isEmpty) {
                  return "Please repeat your password";
                }
                // Check whether the data matches the data in the password field
                if (value != passwordController.text) {
                  return "The passwords do not match";
                }
                return null;
              },

              onChanged: (text) => setState(() {}),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
            // Register button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Show a circular progress indicator
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Register the user
                    await addUser(
                      usernameController.text,
                      passwordController.text
                    );

                    // Sign the user in
                    userID = await signIn(
                      usernameController.text,
                      passwordController.text
                    );

                    // Update the user model
                    user.setID(userID);
                    user.setUsername(usernameController.text);
                    user.notify();
                    await taskList.update(user.id);
                    
                    // Hide the circular progress indicator
                    setState(() {
                      _isLoading = false;
                    });

                    // Navigate the user to the home page
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return HomePage();
                      }));
                    }
                  }

                  // Display a notification if there was an error and the user
                  // could not be registered or signed in
                  catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sorry, there was an error. Please try again."
                          )
                        ),
                      );
                    }
                  }
                }
                return;
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _isLoading
                // If _isLoading is true, show a circular progress indicator
                // next to the "Register" text
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.tertiary
                    ),
                  ],
                )
                // Otherwise, show just the "Register" text
                : Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}