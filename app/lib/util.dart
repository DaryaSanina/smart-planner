import 'dart:convert';

import 'package:crypto/crypto.dart';

String getPasswordHash(String password) {
  // Returns the SHA-256 hash of the provided password
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}