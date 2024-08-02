import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:app/home/home_page.dart';
import 'package:app/encryption.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameText = "";
  final _emailText = "";
  final _passwordText = "";
  final _repeatPasswordText = "";
  bool _usernameExists = false;
  bool _emailExists = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                if (value.length < 3 || value.length > 32) {
                  return "The username is not between 3 and 32 characters long";
                }
                if (_usernameExists) {
                  return "This username is already being used";
                }
                return null;
              },
              onChanged: (text) async {
                final response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=$text'));
                setState(() => _usernameExists = jsonDecode(response.body)['data'].length != 0);
                setState(() => _usernameText);
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
                if (value == null || value.isEmpty) {
                  return "Please enter your email";
                }
                if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(value)) {
                  return "The email is not in a correct format";
                }
                if (_emailExists) {
                  return "This email is already being used";
                }
                return null;
              },
              onChanged: (text) async {
                final response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?email=$text'));
                setState(() => _emailExists = jsonDecode(response.body)['data'].length != 0);
                setState(() => _emailText);
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
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                if (value.length < 8 || value.length > 16) {
                  return "The password should be between 8 and 16 characters long";
                }
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
              onChanged: (text) => setState(() => _passwordText),
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
                if (value == null || value.isEmpty) {
                  return "Please repeat your password";
                }
                if (value != passwordController.text) {
                  return "The passwords do not match";
                }
                return null;
              },
              onChanged: (text) => setState(() => _repeatPasswordText),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        
            // Register button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  var request = jsonEncode(<String, dynamic>{'username': usernameController.text, 'email': emailController.text, 'password_hash': getPasswordHash(passwordController.text)});
                  final response = await http.post(
                    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_user'),
                    headers: <String, String>{'Content-Type': 'application/json'},
                    body: request
                  );
                  int userID = jsonDecode((await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=${usernameController.text}'))).body)['data'][0][0];
                  if (response.statusCode != 201) {
                    return;
                  }
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
                child: Text(
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