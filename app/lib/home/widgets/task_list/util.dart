import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<int> addTask(String name, String description, int importance, int userID,
                    bool isDeadline, DateTime? deadlineDate, TimeOfDay? deadlineTime,
                    DateTime? startDate, TimeOfDay? startTime, DateTime? endDate, TimeOfDay? endTime, [String? googleCalendarEventID]) async {
  // This function adds a task with the provided information to the database and returns its ID
  
  // Form a task creation request
  Map requestDict = {
    'name': name,
    'importance': importance,
    'user_id': userID
  };

  requestDict['description'] = description;

  if (isDeadline) {
    requestDict['deadline'] = dateTimeToString(deadlineDate!, deadlineTime);  // Add deadline
  }
  else {
    requestDict['start'] = dateTimeToString(startDate!, startTime); // Add start date and time
    requestDict['end'] = dateTimeToString(endDate!, endTime); // Add start date and time
  }

  if (googleCalendarEventID != null) {
    requestDict['google_calendar_event_id'] = googleCalendarEventID;
  }

  // Send the request
  String request = jsonEncode(requestDict);
  http.Response response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_task'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int taskID = jsonDecode(response.body)["id"];

  return taskID;
}

Future<void> updateTask(int taskID, String name, String description, int importance,
                        bool isDeadline, DateTime? deadlineDate, TimeOfDay? deadlineTime,
                        DateTime? startDate, TimeOfDay? startTime, DateTime? endDate, TimeOfDay? endTime, [String? googleCalendarEventID]) async {
  // This procedure updates the task with the provided ID with the provided information

  // Form a task update request
  String url = 'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/update_task';

  Map requestDict = {
    "task_id": taskID,
    "name": name,
    "description": description,
    "importance": importance,
    "google_calendar_event_id": googleCalendarEventID
  };

  if (isDeadline) {
    requestDict["deadline"] = dateTimeToString(deadlineDate!, deadlineTime);  // Add deadline
  }
  else {
    requestDict["start"] = dateTimeToString(startDate!, startTime);  // Add start date and time
    requestDict["end"] = dateTimeToString(endDate!, endTime);  // Add end date and time
  }
  print(requestDict);

  String request = jsonEncode(requestDict);

  // Send the request
  await http.put(
    Uri.parse(url),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: request,
  );
}

Future<int> addTag(String name, int userID) async {
  // This function adds a new tag with the provided information to the database and returns its ID

  String request = jsonEncode({"name": name, "user_id": userID});  // Form the request

  // Send the request
  http.Response response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_tag'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int tagID = jsonDecode(response.body)['id'];

  return tagID;
}

Future<String> getTagName(int tagID) async {
  // This function returns the name of the tag given its ID

  http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_tag?tag_id=$tagID'));  // Send the request
  String tagName = jsonDecode(response.body)['data'][0][1];

  return tagName;
}

Future<int> addTaskToTagRelationship(int taskID, int tagID) async {
  // This function adds a new task to tag relationship to the database and returns its ID

  String request = jsonEncode({"task_id": taskID, "tag_id": tagID});  // Form the request

  // Send the request
  http.Response response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_task_to_tag_relationship'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int taskToTagID = jsonDecode(response.body)['id'];

  return taskToTagID;
}

Future<void> deleteTaskToTagRelationship(int taskID, int tagID) async {
  // This procedure deletes the specified task to tag relationship from the database

  // Send the deletion request
  await http.delete(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_task_to_tag_relationship?task_id=$taskID&tag_id=$tagID'),
    headers: {'Content-Type': 'application/json'}
  );
}

Future<int> addReminder(int taskID, int reminderType) async {
  // This function adds a new reminder to the database and returns its ID

  String request = jsonEncode({"task_id": taskID, "reminder_type": reminderType});  // Form the request

  // Send the request
  http.Response response = await http.post(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_reminder'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int reminderID = jsonDecode(response.body)['id'];

  return reminderID;
}

Future<int> deleteReminder(int taskID, int reminderType) async {
  // This procedure tries to delete the specified reminder from the database.
  // It returns the ID of the reminder if it has been deleted or -1 if the reminder has not been found.

  // Send the deletion request
  http.Response response = await http.delete(
    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_reminder?task_id=$taskID&reminder_type=$reminderType'),
    headers: {'Content-Type': 'application/json'}
  );

  if (response.statusCode == 400) {
    // The reminder has not been found
    return -1;
  }

  int reminderID = jsonDecode(response.body)['id'];
  
  return reminderID;
}

Future<int> getTaskImportancePrediction(String taskName, String taskDescription) async {
  // This function requests the importance LSTM model to predict the importance of the specified task using its name and description

  String request = jsonEncode({"description": "$taskName. $taskDescription"});  // Form the request

  // Send the request
  http.Response response = await http.post(
    Uri.parse('https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws/predict_importance'),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int importance = jsonDecode(response.body)["importance"];

  return importance;
}

String dateTimeToString(DateTime date, TimeOfDay? time) {
  // This function transforms a DateTime date object and a TimeOfDay time object into a string that can be sent in an HTTP request
  // The format of the resulting string is YYYY-MM-DD[T]HH:MM:SS

  String result = date.year.toString();
  result += "-";
  if (date.month < 10) {
    result += "0";
  }
  result += date.month.toString();
  result += "-";
  if (date.day < 10) {
    result += "0";
  }
  result += date.day.toString();
  result += "T";

  if (time != null) {
    if (time.hour < 10) {
      result += "0";
    }
    result += time.hour.toString();
    result += ":";
    if (time.minute < 10) {
      result += "0";
    }
    result += time.minute.toString();
  }
  else {
    result += "00:00";
  }
  result += ":00";

  return result;
}