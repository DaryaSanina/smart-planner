import 'dart:collection';
import 'dart:convert';
import 'package:app/models/util.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TaskModel extends ChangeNotifier {
  String _name = "";
  get name => _name;
  String _description = "";
  get description => _description;
  int _importance = 5;
  get importance => _importance;
  bool _isDeadline = true;
  get isDeadline => _isDeadline;
  DateTime? _deadlineDate;
  get deadlineDate => _deadlineDate;
  TimeOfDay? _deadlineTime;
  get deadlineTime => _deadlineTime;
  DateTime? _startDate;
  get startDate => _startDate;
  TimeOfDay? _startTime;
  get startTime => _startTime;
  DateTime? _endDate;
  get endDate => _endDate;
  TimeOfDay? _endTime;
  get endTime => _endTime;
  String _googleCalendarEventID = "";
  get googleCalendarEventID => _googleCalendarEventID;
  List<int> _tags = [];
  UnmodifiableListView get tags => UnmodifiableListView(_tags);
  List<ReminderType> _reminders = [];
  UnmodifiableListView get reminders => UnmodifiableListView(_reminders);

  void clear() {
    _name = "";
    _description = "";
    _importance = 5;
    _isDeadline = true;
    _deadlineDate = null;
    _deadlineTime = null;
    _startDate = null;
    _startTime = null;
    _endDate = null;
    _endTime = null;
    _googleCalendarEventID = "";
    _tags.clear();
    _reminders.clear();
  }

  void clearTimings() {
    _deadlineDate = null;
    _deadlineTime = null;
    _startDate = null;
    _startTime = null;
    _endDate = null;
    _endTime = null;
    notifyListeners();
  }

  Future<void> getDetails(int taskID) async {
    var response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_task?task_id=$taskID'));
    var details = jsonDecode(response.body)['data'][0];
    _name = details[1];
    _description = details[2].toString();
    _importance = details[6];
    _isDeadline = details[3] != null;
    if (_isDeadline) {
      _deadlineDate = DateTime(int.parse(details[3].toString().substring(0, 4)), int.parse(details[3].toString().substring(5, 7)), int.parse(details[3].toString().substring(8, 10)));
      _deadlineTime = TimeOfDay(hour: int.parse(details[3].toString().substring(11, 13)), minute: int.parse(details[3].toString().substring(14, 16)));
      if (_deadlineTime == const TimeOfDay(hour: 0, minute: 0)) {
        _deadlineTime = null;
      }
    }
    else {
      _startDate = DateTime(int.parse(details[4].toString().substring(0, 4)), int.parse(details[4].toString().substring(5, 7)), int.parse(details[4].toString().substring(8, 10)));
      _startTime = TimeOfDay(hour: int.parse(details[4].toString().substring(11, 13)), minute: int.parse(details[4].toString().substring(14, 16)));
      if (_startTime == const TimeOfDay(hour: 0, minute: 0)) {
        _startTime = null;
      }
      _endDate = DateTime(int.parse(details[5].toString().substring(0, 4)), int.parse(details[5].toString().substring(5, 7)), int.parse(details[5].toString().substring(8, 10)));
      _endTime = TimeOfDay(hour: int.parse(details[5].toString().substring(11, 13)), minute: int.parse(details[5].toString().substring(14, 16)));
      if (_endTime == const TimeOfDay(hour: 0, minute: 0)) {
        _endTime = null;
      }
    }
    _tags = await getTaskTags(taskID);
    _reminders = await getTaskReminders(taskID);
    _googleCalendarEventID = details[8].toString();
    notifyListeners();
  }

  void setName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void setDescription(String newDescription) {
    _description = newDescription;
    notifyListeners();
  }

  void setImportance(int newImportance) {
    _importance = newImportance;
    notifyListeners();
  }

  void setTimeConstraintsMode(bool newIsDeadline) {
    _isDeadline = newIsDeadline;
    notifyListeners();
  }

  void setDeadlineDate(DateTime newDate) {
    _deadlineDate = newDate;
    notifyListeners();
  }

  void setDeadlineTime(TimeOfDay newTime) {
    _deadlineTime = newTime;
    notifyListeners();
  }

  void setStartDate(DateTime newDate) {
    _startDate = newDate;
    notifyListeners();
  }

  void setStartTime(TimeOfDay newTime) {
    _startTime = newTime;
    notifyListeners();
  }

  void setEndDate(DateTime newDate) {
    _endDate = newDate;
    notifyListeners();
  }

  void setEndTime(TimeOfDay newTime) {
    _endTime = newTime;
    notifyListeners();
  }

  void addTag(int tagID) {
    _tags.add(tagID);
    notifyListeners();
  }

  void removeTag(int tagID) {
    _tags.remove(tagID);
    notifyListeners();
  }

  void addReminder(ReminderType reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }

  void removeReminder(ReminderType reminder) {
    _reminders.remove(reminder);
    notifyListeners();
  }
}