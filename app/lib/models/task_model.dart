import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TaskModel extends ChangeNotifier {
  String name = "";
  String description = "";
  int importance = 5;
  bool isDeadline = true;
  DateTime? deadlineDate;
  TimeOfDay? deadlineTime;
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;

  void clear() {
    name = "";
    description = "";
    importance = 5;
    isDeadline = true;
    deadlineDate = null;
    deadlineTime = null;
    startDate = null;
    startTime = null;
    endDate = null;
    endTime = null;
  }

  Future<void> getDetails(int taskID) async {
    var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task?task_id=$taskID'));
    var details = jsonDecode(response.body)['data'][0];
    print(details[2]);
    name = details[1];
    description = details[2].toString();
    importance = details[6];
    isDeadline = details[3] != null;
    if (isDeadline) {
      deadlineDate = DateTime(int.parse(details[3].toString().substring(0, 4)), int.parse(details[3].toString().substring(5, 7)), int.parse(details[3].toString().substring(8, 10)));
      deadlineTime = TimeOfDay(hour: int.parse(details[3].toString().substring(11, 13)), minute: int.parse(details[3].toString().substring(14, 16)));
    }
    else {
      startDate = DateTime(int.parse(details[4].toString().substring(0, 4)), int.parse(details[4].toString().substring(5, 7)), int.parse(details[4].toString().substring(8, 10)));
      startTime = TimeOfDay(hour: int.parse(details[4].toString().substring(11, 13)), minute: int.parse(details[4].toString().substring(14, 16)));
      endDate = DateTime(int.parse(details[5].toString().substring(0, 4)), int.parse(details[5].toString().substring(5, 7)), int.parse(details[5].toString().substring(8, 10)));
      endTime = TimeOfDay(hour: int.parse(details[5].toString().substring(11, 13)), minute: int.parse(details[5].toString().substring(14, 16)));
    }
    notifyListeners();
  }

  void setName(String newName) {
    name = newName;
    notifyListeners();
  }

  void setDescription(String newDescription) {
    description = newDescription;
    notifyListeners();
  }

  void setImportance(int newImportance) {
    importance = newImportance;
    notifyListeners();
  }

  void setTimeConstraintsMode(bool newIsDeadline) {
    isDeadline = newIsDeadline;
    notifyListeners();
  }

  void setDeadlineDate(DateTime newDate) {
    deadlineDate = newDate;
    notifyListeners();
  }

  void setDeadlineTime(TimeOfDay newTime) {
    deadlineTime = newTime;
    notifyListeners();
  }

  void setStartDate(DateTime newDate) {
    startDate = newDate;
    notifyListeners();
  }

  void setStartTime(TimeOfDay newTime) {
    startTime = newTime;
    notifyListeners();
  }

  void setEndDate(DateTime newDate) {
    endDate = newDate;
    notifyListeners();
  }

  void setEndTime(TimeOfDay newTime) {
    endTime = newTime;
    notifyListeners();
  }
}