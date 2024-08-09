import 'dart:collection';
import 'dart:convert';
import 'package:app/home/util.dart';
import 'package:app/models/util.dart';
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
  List<Task> _tasks = [];
  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  void add(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> update(int userID) async {
    http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task?user_id=$userID'));
    List responseList = jsonDecode(response.body)['data'];
    _tasks.clear();
    for (int i = 0; i < responseList.length; ++i) {
      int taskID = responseList[i][0];
      String name = responseList[i][1];
      String timings;
      int importance = responseList[i][6];
      List tagIDs = await getTaskTags(taskID);
      List<String> tags = [];
      for (int tagID in tagIDs) {
        tags.add(await getTagName(tagID));
      }
      if (responseList[i][3] != null) {  // There is a deadline
        timings = "Due ${responseDateToDateString(responseList[i][3])}";
        DateTime deadline = DateTime.parse(responseList[i][3]);
        _tasks.add(Task(taskID: taskID, name: name, timings: timings, userID: userID, importance: importance, deadline: deadline, tags: tags));
      }
      else {
        timings = "${responseDateToDateString(responseList[i][4])} - ${responseDateToDateString(responseList[i][5])}";
        DateTime start = DateTime.parse(responseList[i][4]);
        DateTime end = DateTime.parse(responseList[i][5]);
        _tasks.add(Task(taskID: taskID, name: name, timings: timings, userID: userID, importance: importance, start: start, end: end, tags: tags));
      }
    }
    notifyListeners();
  }

  void remove(Task task) async {
    // Remove the task
    await http.delete(
      Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_task?task_id=${task.taskID}'),
      headers: {'Content-Type': 'application/json'}
    );
    _tasks.remove(task);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void sortByImportance() {
    _tasks.sort((Task task1, Task task2) {
      if (-(task1.importance.compareTo(task2.importance)) == 0) {
        int value = 0;
        if (task1.deadline != null && task2.deadline != null) {
          value = task1.deadline!.compareTo(task2.deadline!);
        }
        else if (task1.deadline != null) {
          value = task1.deadline!.compareTo(task2.end!);
        }
        else if (task2.deadline != null) {
          value = task1.end!.compareTo(task2.deadline!);
        }
        else if (task1.end!.isAtSameMomentAs(task2.end!)) {
          value = task1.start!.compareTo(task2.start!);
        }
        else {
          value = task1.end!.compareTo(task2.end!);
        }
        return value;
      }
      else {
        return -(task1.importance.compareTo(task2.importance));
      }
    });
    notifyListeners();
  }

  void sortByDeadline() {
    _tasks.sort((Task task1, Task task2) {
      int value = 0;
      if (task1.deadline != null && task2.deadline != null) {
        value = task1.deadline!.compareTo(task2.deadline!);
      }
      else if (task1.deadline != null) {
        value = task1.deadline!.compareTo(task2.end!);
      }
      else if (task2.deadline != null) {
        value = task1.end!.compareTo(task2.deadline!);
      }
      else if (task1.end!.isAtSameMomentAs(task2.end!)) {
        value = task1.start!.compareTo(task2.start!);
      }
      else {
        value = task1.end!.compareTo(task2.end!);
      }
      if (value == 0) {
        return -(task1.importance.compareTo(task2.importance));
      }
      else {
        return value;
      }
    });
    notifyListeners();
  }

  Future<void> sortWithAI() async {
    sortByDeadline();
    List<List<int>> data = [];
    for (int i = 0; i < _tasks.length; ++i) {
      if (_tasks[i].deadline != null) {
        data.add([_tasks[i].importance, _tasks[i].deadline!.difference(DateTime.now()).inMinutes]);
      }
      else {
        data.add([_tasks[i].importance, _tasks[i].end!.difference(DateTime.now()).inMinutes]);
      }
    }
    var request = jsonEncode({"data": data});
    var response = await http.post(
      Uri.parse('https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws/k_means'),
      headers: {'Content-Type': 'application/json'},
      body: request,
    );
    List<dynamic> order = jsonDecode(response.body);
    List<Task> newTasks = [];
    for (int i = 0; i < order.length; ++i) {
      newTasks.add(_tasks[order[i]]);
    }
    _tasks = newTasks;
    notifyListeners();
  }
}