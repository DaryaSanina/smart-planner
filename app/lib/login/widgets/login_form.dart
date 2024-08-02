import 'dart:convert';

import 'package:app/encryption.dart';
import 'package:app/models/task_list_model.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:app/home/home_page.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameText = "";
  final _passwordText = "";
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final taskList = context.watch<TaskListModel>();
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
                if (value == null || value.isEmpty) {
                  return "Please enter your username";
                }
                return null;
              },
              onChanged: (text) => setState(() => _usernameText),
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
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                return null;
              },
              onChanged: (text) => setState(() => _passwordText),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
            // Log in button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Check whether the user exists and that the password hashes match
                  String passwordHash = getPasswordHash(passwordController.text);
                  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=${usernameController.text}'));
                  var jsonResponse = jsonDecode(response.body);
                  if (jsonResponse['data'].length != 0 && passwordHash == jsonResponse['data'][0][3] && context.mounted) {
                    // Update the task list
                    taskList.update(jsonResponse['data'][0][0]);

                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return HomePage(username: usernameController.text, userID: jsonResponse['data'][0][0]);
                    }));
                  }
                  else if (context.mounted) {
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
                child: Text(
                  "Log in",
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