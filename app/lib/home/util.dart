import 'dart:convert';
import 'package:http/http.dart' as http;

Future<int> addTag(String name, int userID) async {
  var request = jsonEncode({"name": name, "user_id": userID});
  var response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_tag'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );
  return response.statusCode;
}

Future<String> getTagName(int tagID) async {
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_tag?tag_id=$tagID'));
  return jsonDecode(response.body)['data'][0][1];
}

Future<int> addTaskToTagRelationship(int taskID, int tagID) async {
  var request = jsonEncode({"task_id": taskID, "tag_id": tagID});
  var response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_task_to_tag_relationship'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );
  return response.statusCode;
}

Future<int> deleteTaskToTagRelationship(int taskID, int tagID) async {
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task_to_tag_relationship?task_id=$taskID&tag_id=$tagID'));
  int taskToTagID = jsonDecode(response.body)['data'][0][0];
  response = await http.delete(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_task_to_tag_relationship?task_to_tag_id=$taskToTagID'),
    headers: {'Content-Type': 'application/json'}
  );
  return response.statusCode;
}