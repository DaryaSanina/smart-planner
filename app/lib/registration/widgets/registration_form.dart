import 'dart:convert';

import 'package:app/home/home_page.dart';
import 'package:app/login/util.dart';
import 'package:app/registration/util.dart';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _usernameExists = false;
  bool _emailExists = false;
  bool _isLoading = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                if (value.length < 3 || value.length > 32) {  // Check whether the username is between 3 and 32 characters long
                  return "The username is not between 3 and 32 characters long";
                }
                if (_usernameExists) {  // Check whether the username has already been taken
                  return "This username has already been taken";
                }
                return null;
              },
              onChanged: (text) async {
                // Check whether the username has already been taken
                final response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=$text'));
                setState(() => _usernameExists = jsonDecode(response.body)['data'].length != 0);
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

             // Email field
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Email",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              validator: (value) {
                if (value == null || value.isEmpty) {  // Check whether the field is empty
                  return "Please enter your email";
                }
                if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(value)) {  // Check whether the email matches the format address@example.com
                  return "The email is not in a correct format";
                }
                if (_emailExists) {  // Check whether the email is already being used by another account
                  return "This email is already being used by another account";
                }
                return null;
              },
              onChanged: (text) async {
                // Check whether the email is already being used by another account
                final response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?email=$text'));
                setState(() => _emailExists = jsonDecode(response.body)['data'].length != 0);
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        
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
                if (value.length < 8 || value.length > 16) {  // Check whether the password is between 8 and 16 characters long
                  return "The password should be between 8 and 16 characters long";
                }

                // Check whether the password contains lowercase and uppercase letters, digits and special symbols (e.g., !, -, #, etc.)
                bool hasLowerCase = false;
                bool hasUpperCase = false;
                bool hasDigits = false;
                bool hasSymbols = false;
                for (int i = 0; i < value.length; i++) {
                  if ("abcdefghijklmnopqrstuvwxyz".contains(value[i])) {
                    hasLowerCase = true;
                  }
                  if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(value[i])) {
                    hasUpperCase = true;
                  }
                  if ("1234567890".contains(value[i])) {
                    hasDigits = true;
                  }
                  if ("!£\"\$%^&*()-_+=[]{}#~;:'@,.<>/?\\|".contains(value[i])) {
                    hasSymbols = true;
                  }
                }
                if (!hasLowerCase) {
                  return "The password should contain lowercase letters";
                }
                if (!hasUpperCase) {
                  return "The password should contain uppercase letters";
                }
                if (!hasDigits) {
                  return "The password should contain digits";
                }
                if (!hasSymbols) {
                  return "The password should contain special symbols";
                }
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            // Repeat password field
            TextFormField(
              controller: repeatPasswordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Repeat password",
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              obscureText: true,
              obscuringCharacter: '*',
              validator: (value) {
                if (value == null || value.isEmpty) {  // Check whether the field is empty
                  return "Please repeat your password";
                }
                if (value != passwordController.text) {  // Check whether the data matches the data in the password field
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
                  setState(() {
                    _isLoading = true;  // Show a circular progress indicator
                  });
                  await register(usernameController.text, emailController.text, passwordController.text);  // Register the user
                  userID = await login(usernameController.text, passwordController.text);  // Log the user in
                  setState(() {
                    _isLoading = false; // Hide the circular progress indicator
                  });

                  // Navigate the user to the home page
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return HomePage(username: usernameController.text, userID: userID);
                    }));
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
                // If _isLoading is true, show a circular progress indicator next to the "Register" text
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
                    CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary),
                  ],
                )
                // Otherwise, just show the "Register" text
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