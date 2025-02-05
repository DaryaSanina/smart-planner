import 'dart:convert';
import 'package:crypto/crypto.dart';

// This function returns the SHA-256 hash of the provided password
String getPasswordHash(String password) {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
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
  if (password.length < 8 || password.length > 16) {
    return "The password should be between 8 and 16 characters long";
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