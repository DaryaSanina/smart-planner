import 'dart:convert';
import 'package:http/http.dart' as http;

const List months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

enum ReminderType {tenMinutes, oneHour, oneDay, oneWeek}

String responseDateToDateString(String responseDateTime) {
  // This function transfors a DateTime string from the HTTP format to the format that is displayed to the user
  // responseDateTime should be in the HTTP format (YYYY-MM-DD[T]HH:MM:SS)

  // day
  String day = responseDateTime.substring(8, 10);

  // month
  String month = months[int.parse(responseDateTime.substring(5, 7)) - 1];

  // year
  String year = responseDateTime.substring(0, 4);

  // hour
  String hour = responseDateTime.substring(11, 13);

  // minute
  String minute = responseDateTime.substring(14, 16);

  // The result is in the format DD Month YYYY, HH:MM or DD Month YYYY (if HH:MM = 00:00)
  if (hour == "00" && minute == "00") {
    return "$day $month $year";
  }
  return "$day $month $year, $hour:$minute";
}

Future<List<int>> getTaskTags(int taskID) async {
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task_to_tag_relationship?task_id=$taskID'));
  List<int> tagIDs = [];
  for (final dynamic tag in jsonDecode(response.body)['data']) {
    tagIDs.add(tag[2]);
  }
  return tagIDs;
}

Future<List<ReminderType>> getTaskReminders(int taskID) async {
  var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_reminder?task_id=$taskID'));
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