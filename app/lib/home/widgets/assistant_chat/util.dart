import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendMessage(String content, DateTime timestamp, int userID) async {
  String request = jsonEncode({
    "content": content,
    "role": 1,
    "timestamp": timestamp.toIso8601String(),
    "user_id": userID
  });

  await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_message'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );
}