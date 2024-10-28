import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> updateUsername(int userID, String username) async {
  // This procedure updates the username of the current user
  // It returns "OK" if the username has been successfully updated, and the reason if it has not been updated

  // Form a task update request
  String url = 'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/update_username?user_id=$userID&username=$username';

  // Send the request
  http.Response response = await http.post(
    Uri.parse(url),
    headers: <String, String>{'Content-Type': 'application/json'},
  );

  String result = "OK";
  if (response.statusCode == 400) {
    result = jsonDecode(response.body)["reason"];
  }

  return result;
}