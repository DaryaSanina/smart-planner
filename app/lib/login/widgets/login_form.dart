import 'package:app/home/home_page.dart';
import 'package:app/login/util.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final taskList = context.watch<TaskListModel>();
    int userID;
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Username field
            TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Username",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              validator: (value) {
                if (value == null || value.isEmpty) {  // Check whether the field is empty
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Password",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              obscureText: true,
              obscuringCharacter: '*',
              validator: (value) {
                if (value == null || value.isEmpty) {  // Check whether the field is empty
                  return "Please enter your password";
                }
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
            // Log in button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _isLoading = true;  // Show a circular progress indicator
                  });

                  // Check whether the details are correct by trying to log the user in
                  userID = await login(usernameController.text, passwordController.text);

                  // If the details are correct
                  if (userID != -1) {

                    // Update the task list
                    await taskList.update(userID);

                    setState(() {
                      _isLoading = false;  // Hide the circular progress indicator
                    });

                    // Show the home page
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return HomePage(username: usernameController.text, userID: userID);
                      }));
                    }
                  }

                  // If the details are incorrect
                  else if (context.mounted) {
                    setState(() {
                      _isLoading = false;  // Hide the circular progress indicator
                    });

                    // Show the user a message saying that the details are incorrect
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Such user does not exist or the password is incorrect')),
                    );
                  }
                }
                return;
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),

              child: Padding(
                padding: const EdgeInsets.all(8.0),

                child: _isLoading
                // If _isLoading is true, show a circular progress indicator next to the "Log in" text
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Log in",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary),
                  ],
                )
                // Otherwise, just show the "Log in" text
                : Text(
                  "Log in",
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.tertiary,
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