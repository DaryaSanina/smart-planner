import 'dart:collection';
import 'dart:convert';

import 'package:app/home/widgets/task_list/util.dart';
import 'package:app/home/widgets/task_list/task.dart';
import 'package:app/models/util.dart';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskListModel extends ChangeNotifier {
  List<Task> _tasks = [];
  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  void notifyListenersFromOutside() {
    notifyListeners();
  }

  Future<bool> update(int userID) async {  // This procedure fetches the user's tasks from the database

    // Send the request
    http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task?user_id=$userID'));
    List responseList = jsonDecode(response.body)['data'];
    
    // Update the task list
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
      if (responseList[i][3] != null) {  // If there is a deadline
        timings = "Due ${responseDateToDateString(responseList[i][3])}";
        DateTime deadline = DateTime.parse(responseList[i][3]);
        _tasks.add(Task(taskID: taskID, name: name, timings: timings, userID: userID, importance: importance, deadline: deadline, tags: tags));
      }
      else {  // If there is a start and an end
        timings = "${responseDateToDateString(responseList[i][4])} - ${responseDateToDateString(responseList[i][5])}";
        DateTime start = DateTime.parse(responseList[i][4]);
        DateTime end = DateTime.parse(responseList[i][5]);
        _tasks.add(Task(taskID: taskID, name: name, timings: timings, userID: userID, importance: importance, start: start, end: end, tags: tags));
      }
    }

    // Sort the task list using cached data (if it exists)
    final prefs = await SharedPreferences.getInstance();
    String? order = prefs.getString('order');
    if (order == "deadline") {
      sortByDeadline();
    }
    else if (order == "importance") {
      sortByImportance();
    }
    else if (order == "ai") {
      await sortWithAI();
    }

    return true;
  }

  void remove(Task task) async {  // This procedure removes the specified task from the database and from the task list
    await http.delete(
      Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/delete_task?task_id=${task.taskID}'),
      headers: {'Content-Type': 'application/json'}
    );
    _tasks.remove(task);
    notifyListeners();
  }

  void sortByImportance() {
    // This procedure sorts the tasks in the decreasing order of their importance
    // Tasks with the same importance are sorted in the increasing order of their deadline or end date
    // Tasks with the same importance and end date are sorted in the increasing order of their start date

    _tasks.sort((Task task1, Task task2) {
      if (-(task1.importance.compareTo(task2.importance)) == 0) {  // If the importance is the same
        int value = 0;
        if (task1.deadline != null && task2.deadline != null) {  // If both tasks have deadlines
          value = task1.deadline!.compareTo(task2.deadline!);  // Compare the deadlines
        }
        else if (task1.deadline != null) {  // If the first task has a deadline and the second task has a start date and an end date
          value = task1.deadline!.compareTo(task2.end!);  // Compare the first task's deadline with the second task's end date
        }
        else if (task2.deadline != null) {  // If the first task has a start date and an end date and the second task has a deadline
          value = task1.end!.compareTo(task2.deadline!);  // Compare the first task's end date with the second task's deadline
        }
        // If both tasks have a start date and an end date
        else if (task1.end!.isAtSameMomentAs(task2.end!)) {  // If the end dates of both tasks are at the same time
          value = task1.start!.compareTo(task2.start!);  // Compare the tasks' start dates
        }
        else {
          value = task1.end!.compareTo(task2.end!);  // Compare the tasks' end dates
        }
        return value;
      }
      else {  // If the importance is not the same
        return -(task1.importance.compareTo(task2.importance));  // Compare the tasks' importances
      }
    });
  }

  void sortByDeadline() {
    // This procedure sorts the tasks in the increasing order of their deadline or end date
    // Tasks with the same end dates are sorted in the increasing order of their start date
    // Tasks with the same deadlines or start and end dates are sorted in the decreasing order of their importance

    _tasks.sort((Task task1, Task task2) {
      int value = 0;
      if (task1.deadline != null && task2.deadline != null) {  // If both tasks have deadlines
        value = task1.deadline!.compareTo(task2.deadline!);  // Compare the deadlines
      }
      else if (task1.deadline != null) {  // If the first task has a deadline and the second task has a start date and an end date
        value = task1.deadline!.compareTo(task2.end!);  // Compare the first task's deadline with the second task's end date
      }
      else if (task2.deadline != null) {  // If the first task has a start date and an end date and the second task has a deadline
        value = task1.end!.compareTo(task2.deadline!);  // Compare the first task's end date with the second task's deadline
      }
      // If both tasks have a start date and an end date
      else if (task1.end!.isAtSameMomentAs(task2.end!)) {  // If the end dates of both tasks are at the same time
        value = task1.start!.compareTo(task2.start!);  // Compare the tasks' start dates
      }
      else {
        value = task1.end!.compareTo(task2.end!);  // Compare the tasks' end dates
      }

      if (value == 0) {  // If there is a tie
        return -(task1.importance.compareTo(task2.importance));  // Compare the tasks' importances
      }
      else {
        return value;
      }
    });
  }

  Future<void> sortWithAI() async {
    // This procedure sorts the tasks by importance and deadline
    // by using the K-Means clustering algorithm to divide the tasks into 4 Eisenhower Matrix categories
    // and then arrange them in the following order:
    // important and urgent -> important but not urgent -> urgent but not important -> not important and not urgent

    sortByDeadline();  // First, sort the tasks by their deadline

    // Then get a list of pairs of integers that will be passed to the K-Means clustering algorithm
    // For each task, the list contains:
    // 1. The importance of the task
    // 2. The difference between the deadline or the end of the task and the current time in minutes
    List<List<int>> data = [];
    for (int i = 0; i < _tasks.length; ++i) {
      if (_tasks[i].deadline != null) {
        data.add([_tasks[i].importance, _tasks[i].deadline!.difference(DateTime.now()).inMinutes]);
      }
      else {
        data.add([_tasks[i].importance, _tasks[i].end!.difference(DateTime.now()).inMinutes]);
      }
    }

    // Send the request to the server
    String request = jsonEncode({"data": data});
    http.Response response = await http.post(
      Uri.parse('https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws/k_means'),
      headers: {'Content-Type': 'application/json'},
      body: request,
    );
    List<dynamic> order = jsonDecode(response.body);  // This is the order of indices of the task list in which it needs to be arranged

    // Sort the tasks
    List<Task> newTasks = [];
    for (int i = 0; i < order.length; ++i) {
      newTasks.add(_tasks[order[i]]);
    }
    _tasks = newTasks;
  }
}