import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<int>> getTaskTags(int taskID) async {
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task_to_tag_relationship?task_id=$taskID'));
  List<int> tagIDs = [];
  for (final dynamic tag in jsonDecode(response.body)['data']) {
    tagIDs.add(tag[2]);
  }
  return tagIDs;
}