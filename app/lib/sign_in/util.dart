import 'package:app/passwords.dart';
import 'package:app/server_interactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This function tries to find a user in the database based on their [username]
// and [password]. If such a user exists and password hashes match,
// the function updates the cache returns the user's ID.
// Otherwise, the function returns -1.
Future<int> signIn(String username, String password) async {
  List databaseResponse = await getUserByUsername(username);

  // If there is a user with this username
  if (databaseResponse.isNotEmpty) {
    // Get the SHA-256 hash of the password
    String salt = databaseResponse[0][3];
    var (passwordHash, passwordSalt) = getPasswordHash(password, salt);

    // If the hash of the provided password matches the password hash of the
    // user with this username
    if (passwordHash == databaseResponse[0][2]) {
      // Get the user's ID
      int userID = databaseResponse[0][0];

      // Update the cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userID', userID);
      await prefs.setString('username', username);

      // return the user's ID
      return userID;
    }
  }
  

  // If the sign in information is incorrect
  return -1;
}

// This procedure clears the app's cache on the device
Future<void> clearCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}