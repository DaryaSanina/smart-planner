// This module contains subroutines that interact with servers

import 'dart:convert';
import 'package:app/models/message_list_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/passwords.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// This enum represents the four types of reminders - 10 minutes, 1 hour, 1 day
// and 1 week before the deadline or the start of the task
enum ReminderType {tenMinutes, oneHour, oneDay, oneWeek}

// This function returns a list that is empty if the user with this [username]
// does not exist, or contains one element - the user's details - if this user
// exists
Future<List<dynamic>> getUserByUsername(String username) async {
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_user?username=$username'
    )
  );
  return jsonDecode(response.body)['data'];
}

// This function returns a list that is empty if the user with a Google account
// ID that matches the provided [googleIDToken] does not exist, or contains one
// element - the user's details - if this user exists
Future<List<dynamic>> getUserByGoogleIDToken(String googleIDToken) async {
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on'
      '.aws/get_user?google_id_token=$googleIDToken'
    )
  );
  return jsonDecode(response.body);
}

// This procedure adds a user with the specifed [username] and [password] to
// the database
Future<void> addUser(String username, String password) async {
  // Get the SHA-256 hash of the password
  var (passwordHash, passwordSalt) = getPasswordHash(password);
  
  // Form a JSON POST request to the database server to add the user to the
  // database
  String request = jsonEncode(
    <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
      'password_salt': passwordSalt
    }
  );
  // Send the request
  await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_user'
    ),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: request
  );
}

// This procedure updates the username of the current user
// It returns null if the username has been successfully updated,
// or the reason if it has not
Future<String?> updateUsername(int userID, String username) async {
  // Send a PUT request to the database server
  http.Response response = await http.put(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/update_username?user_id=$userID&username=$username'
    ),
    headers: <String, String>{'Content-Type': 'application/json'},
  );

  String? result;
  if (response.statusCode == 400) {
    result = jsonDecode(response.body)["reason"];
  }

  return result;
}

// This procedure updates the username of the current user
// It returns null if the username has been successfully updated,
// or the reason if it has not
Future<String?> updatePassword(int userID, String password) async {
  // Get the password hash
  var (passwordHash, passwordSalt) = getPasswordHash(password);

  // Send a PUT request to the database server
  http.Response response = await http.put(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/update_password?user_id=$userID&password_hash=$passwordHash'
      '&password_salt=$passwordSalt'
    ),
    headers: <String, String>{'Content-Type': 'application/json'},
  );

  String? result;
  if (response.statusCode == 400) {
    result = jsonDecode(response.body)["reason"];
  }

  return result;
}

// This procedure sends the provided [userID] and [googleIDToken] to the
// database server which computes the user's Google ID from the token
// and modifies the user's database record to include this Google ID
Future<void> connectGoogleAccount(int userID, String googleIDToken) async {
  await http.put(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url'
      '.eu-north-1.on.aws/link_google_account'
      '?user_id=$userID&google_id_token=$googleIDToken'
    )
  );
}

// This function returns the user's tasks
Future<List> getTasks(int userID) async {
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_task?user_id=$userID'
    )
  );
  return jsonDecode(response.body)['data'];
}

// This function returns the details of the task with the specified [taskID]
Future<dynamic> getTaskByID(int taskID) async {
  var response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_task?task_id=$taskID'));
  return jsonDecode(response.body)['data'][0];
}

// This function adds a task with the provided details to the database
// and returns its ID
Future<int> addTask(String name,
                    String description,
                    int importance,
                    int userID,
                    bool isDeadline,
                    DateTime? deadlineDate,
                    TimeOfDay? deadlineTime,
                    DateTime? startDate,
                    TimeOfDay? startTime,
                    DateTime? endDate,
                    TimeOfDay? endTime,
                    [String? googleCalendarEventID]
) async {

  // Form a JSON for a task creation POST request
  Map requestDict = {
    'name': name,
    'importance': importance,
    'user_id': userID
  };

  requestDict['description'] = description;

  if (isDeadline) {
    requestDict['deadline'] = dateTimeToString(deadlineDate!, deadlineTime);
  }
  else {
    requestDict['start'] = dateTimeToString(startDate!, startTime);
    requestDict['end'] = dateTimeToString(endDate!, endTime);
  }

  if (googleCalendarEventID != null) {
    requestDict['google_calendar_event_id'] = googleCalendarEventID;
  }

  // Send the request
  String request = jsonEncode(requestDict);
  http.Response response = await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_task'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int taskID = jsonDecode(response.body)["id"];

  return taskID;
}

// This procedure updates the task with the provided ID with the provided
// details
Future<void> updateTask(int taskID,
                        String name,
                        String description,
                        int importance,
                        bool isDeadline,
                        DateTime? deadlineDate,
                        TimeOfDay? deadlineTime,
                        DateTime? startDate,
                        TimeOfDay? startTime,
                        DateTime? endDate,
                        TimeOfDay? endTime,
                        [String? googleCalendarEventID]
) async {
  // Form a JSON for a task update PUT request
  String url = 'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/update_task';

  Map requestDict = {
    "task_id": taskID,
    "name": name,
    "description": description,
    "importance": importance,
    "google_calendar_event_id": googleCalendarEventID
  };

  if (isDeadline) {
    requestDict["deadline"] = dateTimeToString(deadlineDate!, deadlineTime);
  }
  else {
    requestDict["start"] = dateTimeToString(startDate!, startTime);
    requestDict["end"] = dateTimeToString(endDate!, endTime);
  }

  String request = jsonEncode(requestDict);

  // Send the request
  await http.put(
    Uri.parse(url),
    headers: <String, String>{'Content-Type': 'application/json'},
    body: request,
  );
}

// This function requests the LSTM model on the server to predict the importance
// level of the specified task using its name (represented by the [taskName]
// parameter) and description (represented by the [taskDescription] parameter)
Future<int> getTaskImportancePrediction(
    String taskName,
    String taskDescription
  ) async {

  // Form the request as a JSON
  String request = jsonEncode({"description": "$taskName. $taskDescription"});

  // Send the request
  http.Response response = await http.post(
    Uri.parse(
      'https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws'
      '/predict_importance'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  // Get the importance level
  int importance = jsonDecode(response.body)["importance"];

  return importance;
}

// This procedure deletes the task with the given [taskID]
Future<void> deleteTask(int taskID) async {
  await http.delete(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url'
      '.eu-north-1.on.aws/delete_task?task_id=$taskID'
    ),
    headers: {'Content-Type': 'application/json'}
  );
}

// This function sorts the provided tasks using a K Means-based algorithm on
// the LSTM and K Means inference server and returns the order of their indices.
// [data] is a list where each element is a list of two numbers - the importance
// level of the corresponding task and the number of minutes until its deadline
// or start datetime
Future<List<int>> sortTasksWithKMeans(List<List<int>> data) async {
  // Send a POST request with the data to the LSTM and K-Means inference
  // server to get the order of the tasks
  String request = jsonEncode({"data": data});
  http.Response response = await http.post(
    Uri.parse(
      'https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws'
      '/k_means'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request,
  );

  // Get the order of indices of the tasks in the task list in which they
  // need to be arranged
  return jsonDecode(response.body);
}

// This function returns the tags of the task with the given [taskID]
Future<List<Tag>> getTaskTags(int taskID) async {
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_tags?task_id=$taskID'
    )
  );
  List data = jsonDecode(response.body)['data'];
  return List.generate(
    data.length,
    (i) => Tag(tagID: data[i][0], name: data[i][1])
  );
}

// This function returns the list of tags created by the user
// with the given [userID]
Future<List<dynamic>> getUserTags(int userID) async {
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_tags?user_id=$userID'
    ),
  );
  return jsonDecode(response.body)["data"];
}

// This function adds a new tag with the provided information to the database
// and returns its ID
// [name] is the name of the tag
// [userID] is the ID of the user who wants to create the tag
Future<int> addTag(String name, int userID) async {
  // Form the request as a JSON
  String request = jsonEncode({"name": name, "user_id": userID});

  // Send the request
  http.Response response = await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_tag'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int tagID = jsonDecode(response.body)['id'];  // Get tag ID

  return tagID;
}

// This function adds a new task to tag relationship to the database
//and returns its ID
Future<int> addTaskToTagRelationship(int taskID, int tagID) async {
  // Form a JSON for a task to tag relationship creation POST request
  String request = jsonEncode({"task_id": taskID, "tag_id": tagID});

  // Send the request
  http.Response response = await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_task_to_tag_relationship'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int taskToTagID = jsonDecode(response.body)['id'];

  return taskToTagID;
}

// This procedure deletes the specified task to tag relationship from the
// database
Future<void> deleteTaskToTagRelationship(int taskID, int tagID) async {
  await http.delete(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/delete_task_to_tag_relationship?task_id=$taskID&tag_id=$tagID'
    ),
    headers: {'Content-Type': 'application/json'}
  );
}

// This function returns the types of reminders for a task given its [taskID]
Future<List<ReminderType>> getTaskReminders(int taskID) async {
  // Send a GET request to the database server to get the task's reminder types
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_reminders?task_id=$taskID'
    )
  );

  // Get the types of the task's reminders
  List<ReminderType> reminders = [];
  for (final dynamic reminder in jsonDecode(response.body)['data']) {
    if (reminder[2] == 1) {
      reminders.add(ReminderType.tenMinutes);
    }
    else if (reminder[2] == 2) {
      reminders.add(ReminderType.oneHour);
    }
    else if (reminder[2] == 3) {
      reminders.add(ReminderType.oneDay);
    }
    else if (reminder[2] == 4) {
      reminders.add(ReminderType.oneWeek);
    }
  }
  return reminders;
}

// This function adds a new reminder to the database and returns its ID
Future<int> addReminder(int taskID, int reminderType) async {
  // For a JSON for a reminder creation POST request
  String request = jsonEncode({
    "task_id": taskID,
    "reminder_type": reminderType
  });

  // Send the request
  http.Response response = await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_reminder'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );

  int reminderID = jsonDecode(response.body)['id'];

  return reminderID;
}

// This function tries to delete the specified reminder from the database.
// It returns the ID of the reminder if it has been deleted or -1 if the
// reminder has not been found.
Future<int> deleteReminder(int taskID, int reminderType) async {
  http.Response response = await http.delete(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/delete_reminder?task_id=$taskID&reminder_type=$reminderType'
    ),
    headers: {'Content-Type': 'application/json'}
  );

  // If the reminder has not been found
  if (response.statusCode == 400) {
    return -1;
  }

  int reminderID = jsonDecode(response.body)['id'];
  
  return reminderID;
}

// This function returns the messages in the conversation history between the
// user with the given ID and the assistant
Future<List<Message>> getMessages(int userID) async {
  // Send a GET request to the database server to get the user's messages
  http.Response response = await http.get(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/get_messages?user_id=$userID'
    )
  );

  // Get the user's messages
  List<Message> messages = [];
  for (final dynamic message in jsonDecode(response.body)['data']) {
    messages.add(
      Message(
        messageID: int.parse(message[0].toString()),
        content: message[1],
        role: MessageRole.values[int.parse(message[2].toString()) - 1],
      )
    );
  }
  return messages;
}

// This procedure uploads a message to the database.
// [content] is the content of the message
// [role] describes who has sent the message. It can be:
//         - the user (MessageRole.user)
//         - the assistant (MessageRole.assistant)
//         - a tool, such as when data loaded from the database
//           (MessageRole.tool)
// [timestamp] is the date and time when the message was created
// [userID] is the ID of the user in whose conversation the message should be
// sent
Future<void> sendMessage(
    String content,
    MessageRole role,
    DateTime timestamp,
    int userID
  ) async {
  // Form a JSON request to the database server
  String request = jsonEncode({
    "content": content,
    "role": role.index + 1,
    "timestamp": timestamp.toIso8601String(),
    "user_id": userID
  });

  // Send the JSON in an HTTP POST request to add the message to the database
  await http.post(
    Uri.parse(
      'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws'
      '/add_message'
    ),
    headers: {'Content-Type': 'application/json'},
    body: request
  );
}

// This procedure sends a request to the server with a large language model.
// It then receives a response generated by the LLM and uploads it to the
// database.
// [userID] is the ID of the user to whom the response should be sent
Future<void> invokeLLM(int userID) async {
  // Send an HTTP GET request to get the LLM's response
  http.Response response = await http.get(
    Uri.parse(
      'https://unsvtgzrumeigr72yblvkp7jwq0onuei.lambda-url.eu-north-1.on.aws'
      '/get_response?user_id=$userID'
    )
  );

  // Load the content of the response (a text message)
  String messageContent = jsonDecode(response.body)['response'];

  // Upload the LLM's response to the database
  await sendMessage(
    messageContent,
    MessageRole.assistant,
    DateTime.now(),
    userID
  );
}

// This function transforms a DateTime date object and a TimeOfDay time object
// into a string that can be sent in an HTTP request. The format of the
// resulting string is YYYY-MM-DD[T]HH:MM:SS
String dateTimeToString(DateTime date, TimeOfDay? time) {
  // Year
  String result = date.year.toString();

  // Month
  result += "-";
  if (date.month < 10) {
    result += "0";
  }
  result += date.month.toString();

  // Day
  result += "-";
  if (date.day < 10) {
    result += "0";
  }
  result += date.day.toString();

  result += "T";
  if (time != null) {
    // Hour
    if (time.hour < 10) {
      result += "0";
    }
    result += time.hour.toString();

    // Minute
    result += ":";
    if (time.minute < 10) {
      result += "0";
    }
    result += time.minute.toString();
  }

  // If the time is not specified, set it to 00:00
  else {
    result += "00:00";
  }

  // Always 0 seconds
  result += ":00";

  return result;
}