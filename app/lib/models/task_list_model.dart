import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/home/widgets/task.dart';
import 'package:flutter/material.dart';

const List months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

String responseDateToDateString(String responseDate) {
  // responseDate is in the format YYYY-MM-DD[T]HH:MM:SS

  // day
  String day = responseDate.substring(8, 10);

  // month
  String month = months[int.parse(responseDate.substring(5, 7)) - 1];

  // year
  String year = responseDate.substring(0, 4);

  // hour
  String hour = responseDate.substring(11, 13);

  // minute
  String minute = responseDate.substring(14, 16);

  // The result is in the format DD Month YYYY, HH:MM or DD Month YYYY (if HH:MM = 00:00)
  if (hour == "00" && minute == "00") {
    return "$day $month $year";
  }
  return "$day $month $year, $hour:$minute";
}

class TaskListModel extends ChangeNotifier {
  List<Widget> _tasks = [];
  UnmodifiableListView<Widget> get tasks => UnmodifiableListView(_tasks);

  void add(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void update(int userID) async {
    http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task?user_id=$userID'));
    List responseList = jsonDecode(response.body)['data'];
    _tasks.clear();
    for (int i = 0; i < responseList.length; ++i) {
      String name = responseList[i][1];
      String timings;
      if (responseList[i][3] != null) {  // There is a deadline
        timings = "Due ${responseDateToDateString(responseList[i][3])}";
      }
      else {
        timings = "${responseDateToDateString(responseList[i][4])} - ${responseDateToDateString(responseList[i][5])}";
      }
      _tasks.add(Task(name: name, timings: timings));
    }
    notifyListeners();
  }

  void remove(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }
}