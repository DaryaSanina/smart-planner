import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

// This function computes the SHA-256 hash of the provided password. If no salt
// has been provided, the function also generates a random salt that is added to
// the end of the password before hashing it.
// The function returns the hashed password and the salt
(String, String) getPasswordHash(String password, [String? salt]) {
  if (salt == null) {
    // Generate a salt
    String hexDigits = "0123456789abcdef";
    Random random = Random();
    salt = "";
    int saltLength = random.nextInt(65) + 1;
    for (int i = 0; i < saltLength; i++) {
      salt = salt! + hexDigits[random.nextInt(16)];
    }
  }

  // Add the salt to the end of the password
  password += salt!;

  // Hash the password
  Uint8List bytes = utf8.encode(password);
  Digest digest = sha256.convert(bytes);

  return (digest.toString(), salt);
}

// This function checks whether the password is not empty, is between 8 and 16
// characters long and contains lowercase and uppercase letters, digits and
// special symbols (e.g., !, -, #, etc.)
String? validatePassword(String? password) {
  // Check whether the password is empty
  if (password == null || password.isEmpty) {
    return "Please enter your password";
  }

  // Check whether the password is between 8 and 16 characters long
  if (password.length < 8) {
    return "The password has less than 8 characters";
  }
  else if (password.length > 16) {
    return "The password has more than 16 characters";
  }

  // Check whether the password contains lowercase and uppercase letters,
  // digits and special symbols (e.g., !, -, #, etc.)
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
    return "The password has no lowercase letters";
  }
  if (!hasUpperCase) {
    return "The password has no uppercase letters";
  }
  if (!hasDigits) {
    return "The password has no digits";
  }
  if (!hasSymbols) {
    return "The password has no special symbols";
  }
  return null;
}