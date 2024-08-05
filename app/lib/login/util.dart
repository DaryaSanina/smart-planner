import 'package:app/util.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<int> login(String username, String password) async {
  String passwordHash = getPasswordHash(password);
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?username=$username'));
  var jsonResponse = jsonDecode(response.body);
  if (jsonResponse['data'].length != 0 && passwordHash == jsonResponse['data'][0][3]) {
    return jsonResponse['data'][0][0];  // return user ID
  }
  return -1;  // Incorrect login information
}