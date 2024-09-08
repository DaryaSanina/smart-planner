import 'dart:convert';

import 'package:app/util.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<int> login(String username, String password) async {
  // This function tries to find the user with the provided details in the database.
  // If such a user exists, the function updates the cache returns the user's ID.
  // Otherwise, the function returns -1

  String passwordHash = getPasswordHash(password);  // Get the SHA-256 hash of the password
  http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=$username'));  // Send the data
  var jsonResponse = jsonDecode(response.body);

  // Correct login information, there is a user with this username and the password hashes match, return this user's ID
  if (jsonResponse['data'].length != 0 && passwordHash == jsonResponse['data'][0][3]) {

    // Get user ID
    int userID = jsonResponse['data'][0][0];

    // Update the cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userID', userID);
    await prefs.setString('username', username);

    // return user ID
    return userID;
  }

  // Incorrect login information
  return -1;
}

Future<void> clearCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}