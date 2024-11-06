import 'dart:convert';

import 'package:app/models/message_list_model.dart';

import 'package:http/http.dart' as http;

Future<void> sendMessage(String content, MessageRole role, DateTime timestamp, int userID) async {
  String request = jsonEncode({
    "content": content,
    "role": role.index + 1,
    "timestamp": timestamp.toIso8601String(),
    "user_id": userID
  });

  await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_message'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );
}

Future<void> invokeLLM(int userID) async {
  http.Response response = await http.get(
    Uri.parse('https://unsvtgzrumeigr72yblvkp7jwq0onuei.lambda-url.eu-north-1.on.aws/get_response?user_id=$userID')
  );

  String messageContent = jsonDecode(response.body)['response'];

  await sendMessage(messageContent, MessageRole.assistant, DateTime.now(), userID);
}