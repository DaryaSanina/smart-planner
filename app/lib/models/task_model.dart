import 'dart:collection';

import 'package:app/models/tag_list_model.dart';
import 'package:app/server_interactions.dart';

import 'package:flutter/material.dart';

// This model represents a task that is currently being created or edited
class TaskModel extends ChangeNotifier {
  String _name = "";
  get name => _name;
  String _description = "";
  get description => _description;
  int _importance = 5;
  get importance => _importance;
  bool _hasDeadline = true;
  get hasDeadline => _hasDeadline;
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
  String? _googleCalendarEventID;
  get googleCalendarEventID => _googleCalendarEventID;
  List<int> _tags = [];
  UnmodifiableListView get tags => UnmodifiableListView(_tags);
  List<ReminderType> _reminders = [];
  UnmodifiableListView get reminders => UnmodifiableListView(_reminders);

  // This method sets all attributes to their default values
  void clear() {
    _name = "";
    _description = "";
    _importance = 5;
    _hasDeadline = true;
    _deadlineDate = null;
    _deadlineTime = null;
    _startDate = null;
    _startTime = null;
    _endDate = null;
    _endTime = null;
    _googleCalendarEventID = null;
    _tags.clear();
    _reminders.clear();
  }

  // This method sets the deadline, start and end attributes to their default
  // values
  void clearTimings() {
    _deadlineDate = null;
    _deadlineTime = null;
    _startDate = null;
    _startTime = null;
    _endDate = null;
    _endTime = null;
    notifyListeners();
  }

  // This method gets the details of the task with the given [taskID] and
  // sets the attributes of the model to match those details
  Future<void> getDetails(int taskID) async {
    dynamic details = await getTaskByID(taskID);

    // Update the model's attributes
    _name = details[1];
    _description = details[2].toString();
    _importance = details[6];

    _hasDeadline = details[3] != null;
    if (_hasDeadline) {
      int deadlineYear = int.parse(details[3].toString().substring(0, 4));
      int deadlineMonth = int.parse(details[3].toString().substring(5, 7));
      int deadlineDay = int.parse(details[3].toString().substring(8, 10));
      _deadlineDate = DateTime(deadlineYear, deadlineMonth, deadlineDay);

      int deadlineHour = int.parse(details[3].toString().substring(11, 13));
      int deadlineMinute = int.parse(details[3].toString().substring(14, 16));
      _deadlineTime = TimeOfDay(hour: deadlineHour, minute: deadlineMinute);
      if (_deadlineTime == const TimeOfDay(hour: 0, minute: 0)) {
        _deadlineTime = null;
      }
    }

    else {
      int startYear = int.parse(details[4].toString().substring(0, 4));
      int startMonth = int.parse(details[4].toString().substring(5, 7));
      int startDay = int.parse(details[4].toString().substring(8, 10));
      _startDate = DateTime(startYear, startMonth, startDay);

      int startHour = int.parse(details[4].toString().substring(11, 13));
      int startMinute = int.parse(details[4].toString().substring(14, 16));
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      if (_startTime == const TimeOfDay(hour: 0, minute: 0)) {
        _startTime = null;
      }

      int endYear = int.parse(details[5].toString().substring(0, 4));
      int endMonth = int.parse(details[5].toString().substring(5, 7));
      int endDay = int.parse(details[5].toString().substring(8, 10));
      _endDate = DateTime(endYear, endMonth, endDay);

      int endHour = int.parse(details[5].toString().substring(11, 13));
      int endMinute = int.parse(details[5].toString().substring(14, 16));
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
      if (_endTime == const TimeOfDay(hour: 0, minute: 0)) {
        _endTime = null;
      }
    }

    // Get the IDs of the task's tags
    List<Tag> tagIDsAndNames = await getTaskTags(taskID);
    _tags = List.generate(
      tagIDsAndNames.length,
      (i) => tagIDsAndNames[i].tagID
    );

    _reminders = await getTaskReminders(taskID);
    _googleCalendarEventID = details[8].toString();
    notifyListeners();
  }

  // This method updates the name of the task represented by the model
  void setName(String newName) {
    _name = newName;
    notifyListeners();
  }

  // This method updates the description of the task represented by the model
  void setDescription(String newDescription) {
    _description = newDescription;
    notifyListeners();
  }

  // This method updates the importance level of the task represented by the
  // model
  void setImportance(int newImportance) {
    _importance = newImportance;
    notifyListeners();
  }

  // This method updates the boolean that indicates whether the task
  // represented by the model has a deadline (as opposed to a start and an end)
  void setTimeConstraintsMode(bool newIsDeadline) {
    _hasDeadline = newIsDeadline;
    notifyListeners();
  }

  // This method updates the deadline date of the task represented by the model
  void setDeadlineDate(DateTime newDate) {
    _deadlineDate = newDate;
    notifyListeners();
  }

  // This method updates the deadline time of the task represented by the model
  void setDeadlineTime(TimeOfDay newTime) {
    _deadlineTime = newTime;
    notifyListeners();
  }

  // This method updates the start date of the task represented by the model
  void setStartDate(DateTime newDate) {
    _startDate = newDate;
    notifyListeners();
  }

  // This method updates the start time of the task represented by the model
  void setStartTime(TimeOfDay newTime) {
    _startTime = newTime;
    notifyListeners();
  }

  // This method updates the end date of the task represented by the model
  void setEndDate(DateTime newDate) {
    _endDate = newDate;
    notifyListeners();
  }

  // This method updates the end time of the task represented by the model
  void setEndTime(TimeOfDay newTime) {
    _endTime = newTime;
    notifyListeners();
  }

  // This method adds a tag to the task represented by the model
  void addTag(int tagID) {
    _tags.add(tagID);
    notifyListeners();
  }

  // This method removes a tag from the task represented by the model
  void removeTag(int tagID) {
    _tags.remove(tagID);
    notifyListeners();
  }

  // This method adds a reminder to the task represented by the model
  void addReminder(ReminderType reminder) {
    _reminders.add(reminder);
    notifyListeners();
  }

  // This method removes a reminder from the task represented by the model
  void removeReminder(ReminderType reminder) {
    _reminders.remove(reminder);
    notifyListeners();
  }

  // This method updates the Google Calendar Event ID of the task represented
  // by the model
  void setGoogleCalendarEventID(String googleCalendarEventID) {
    _googleCalendarEventID = googleCalendarEventID;
    notifyListeners();
  }
}