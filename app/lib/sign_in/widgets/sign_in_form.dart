import 'package:app/home/home_page.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/sign_in/util.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Sign in form
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  // Create the form
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Indicates whether the database server is currently processing a sign in
  // request
  bool _isLoading = false;

  // Clears cache
  final Future<void> clearedCache = clearCache();

  @override
  Widget build(BuildContext context) {
    // Load the user and the task list models
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

              // Initial validator (checks whether the field is empty)
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your username";
                }
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
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

              // Initial validator (checks whether the field is empty)
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
            // Sign in button
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.075,
              child: ElevatedButton(

                // Sign the user in
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {

                    // Show a circular progress indicator
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      // Check whether the details are correct
                      // by trying to log the user in
                      userID = await signIn(
                        usernameController.text,
                        passwordController.text
                      );
                
                      // If the details are correct
                      if (userID != -1) {
                
                        // Update the user model
                        user.setID(userID);
                        user.setUsername(usernameController.text);
                        await taskList.update(user.id);
                
                        // Hide the circular progress indicator
                        setState(() {
                          _isLoading = false;
                        });
                
                        // Show the home page
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return HomePage();
                            })
                          );
                        }
                      }
                
                      // If the details are incorrect
                      else if (context.mounted) {

                        // Hide the circular progress indicator
                        setState(() {
                          _isLoading = false;
                        });
                
                        // Show the user a message saying that the details are
                        // incorrect
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Such user does not exist "
                              "or the password is incorrect"
                            )
                          ),
                        );
                      }
                    }

                    // Display a notification if there was an error
                    // and the user could not be signed in
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
              
                // Sign in button design
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
                  // next to the "Sign in" text
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.03
                      ),
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.tertiary
                      ),
                    ],
                  )
                  
                  // Otherwise, show just the "Sign in" text
                  : Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}