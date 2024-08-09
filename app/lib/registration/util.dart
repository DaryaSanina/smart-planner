import 'dart:convert';

import 'package:app/util.dart';

import 'package:http/http.dart' as http;

Future<void> register(String username, String email, String password) async {
  // The procedure adds a user with the provided username, email and password to the database
  
  String passwordHash = getPasswordHash(password);  // Get the SHA-256 hash of the password
  String request = jsonEncode(<String, dynamic>{'username': username, 'email': email, 'password_hash': passwordHash});  // Form the request body
  // Send the request
  await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_user'),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: request
  );
}