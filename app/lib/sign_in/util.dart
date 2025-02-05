import 'package:app/passwords.dart';
import 'package:app/server_interactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This function tries to find a user in the database based on their [username]
// and [password]. If such a user exists and password hashes match,
// the function updates the cache returns the user's ID.
// Otherwise, the function returns -1.
Future<int> signIn(String username, String password) async {

  // Get the SHA-256 hash of the password
  String passwordHash = getPasswordHash(password);

  List databaseResponse = await getUserByUsername(username);

  // If the sign in information is correct (there is a user with this username
  // and the hash of the provided password matches their password hash),
  // return the user's ID
  if (databaseResponse.isNotEmpty && passwordHash == databaseResponse[0][2]) {
    // Get the user's ID
    int userID = databaseResponse[0][0];

    // Update the cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userID', userID);
    await prefs.setString('username', username);

    // return the user's ID
    return userID;
  }

  // If the sign in information is incorrect
  return -1;
}

// This procedure clears the app's cache on the device
Future<void> clearCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}