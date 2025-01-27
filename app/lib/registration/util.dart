import 'dart:convert';

import 'package:app/util.dart';

import 'package:http/http.dart' as http;

Future<void> register(String username, String password) async {
  // The procedure adds a user with the provided username and password to the database
  
  String passwordHash = getPasswordHash(password);  // Get the SHA-256 hash of the password
  String request = jsonEncode(<String, dynamic>{'username': username, 'password_hash': passwordHash});  // Form the request body
  // Send the request
  await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_user'),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: request
  );
}

String? validatePassword(String? password) {
  // This function checks whether the password is not empty,
  // is between 8 and 16 characters long
  // and contains lowercase and uppercase letters, digits and special symbols (e.g., !, -, #, etc.)

  if (password == null || password.isEmpty) {  // Check whether the field is empty
    return "Please enter your password";
  }
  if (password.length < 8 || password.length > 16) {  // Check whether the password is between 8 and 16 characters long
    return "The password should be between 8 and 16 characters long";
  }

  // Check whether the password contains lowercase and uppercase letters, digits and special symbols (e.g., !, -, #, etc.)
  bool hasLowerCase = false;
  bool hasUpperCase = false;
  bool hasDigits = false;
  bool hasSymbols = false;
  for (int i = 0; i < password.length; i++) {
    if ("abcdefghijklmnopqrstuvwxyz".contains(password[i])) {
      hasLowerCase = true;
    }
    if ("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(password[i])) {
      hasUpperCase = true;
    }
    if ("1234567890".contains(password[i])) {
      hasDigits = true;
    }
    if ("!£\"\$%^&*()-_+=[]{}#~;:'@,.<>/?\\|".contains(password[i])) {
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
}