import 'dart:collection';

import 'package:app/calendar_api.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/server_interactions.dart';
import 'package:app/home/widgets/task_list/task_widget.dart';

import 'package:googleapis/calendar/v3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This function transforms a DateTime string in the HTTP format into the format
// that can be displayed to the user ([day] [month name] [year]
// or [day] [month name] [year], [hour]:[minute])
// [responseDateTime] should be a string in the HTTP format (YYYY-MM-DD[T]HH:MM:SS)
String responseDateToDateString(String responseDateTime) {
  String year = responseDateTime.substring(0, 4);  // year

  // month
  const List months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];
  String month = months[int.parse(responseDateTime.substring(5, 7)) - 1];

  String day = responseDateTime.substring(8, 10);  // day

  String hour = responseDateTime.substring(11, 13);  // hour
  String minute = responseDateTime.substring(14, 16);  // minute

  // If time has not been specified
  if (hour == "00" && minute == "00") {
    return "$day $month $year";
  }

  return "$day $month $year, $hour:$minute";
}

// This model represents the list of tasks the user has
class TaskListModel extends ChangeNotifier {
  List<TaskWidget> _tasks = [];
  UnmodifiableListView<TaskWidget> get tasks => UnmodifiableListView(_tasks);

  // This method fetches the user's tasks from the database
  // and their Google Calendar
  Future<bool> update(int userID) async {
    List databaseResponse = await getTasks(userID);
    
    // Update the task list with tasks from the database
    _tasks.clear();
    for (int i = 0; i < databaseResponse.length; ++i) {
      int taskID = databaseResponse[i][0];
      String name = databaseResponse[i][1];
      String timings;
      DateTime? deadline;
      DateTime? start;
      DateTime? end;
      int importance = databaseResponse[i][6];
      List<Tag> tagIDsAndNames = await getTaskTags(taskID);
      List<String> tags = List.generate(
        tagIDsAndNames.length,
        (i) => tagIDsAndNames[i].name
      );

      // If the user has a Google Calendar and the task has
      // a GoogleCalendarEventID, check whether the task is still in
      // the user's Google Calendar, and update the details in the database
      // if needed
      String? googleCalendarEventID = databaseResponse[i][8];
      if (CalendarClient.calendar != null
          && googleCalendarEventID != null
          && googleCalendarEventID != "null") {
        Event event = await CalendarClient().getEvent(googleCalendarEventID);

        // Remove the task (event) from the database if it does not exist
        if (event.summary == null || event.status == "cancelled") {
          await deleteTask(taskID);
          continue;
        }

        // Retrieve the task's name and deadline or start and end
        name = event.summary!;
        if (name.length > 32) {
          name = name.substring(0, 32);
        }

        // If the task has a deadline
        if (event.end == null) {
          // If the deadline has a specific time associated with it
          if (event.start!.dateTime != null) {
            deadline = event.start!.dateTime!;
          }
          // If the deadline only has a date
          else {
            deadline = event.start!.date!;
          }
          timings = "Due ${responseDateToDateString(
            deadline.toIso8601String()
          )}";
        }

        // If there is a start and an end
        else {
          // If the start has a specific time associated with it
          if (event.start!.dateTime != null) {
            start = event.start!.dateTime!;
          }
          // If the start only has a date
          else {
            start = event.start!.date!;
          }

          // If the end has a specific time associated with it
          if (event.end!.dateTime != null) {
            end = event.end!.dateTime!;
          }
          // If the end only has a date
          else {
            end = event.end!.date!;
          }
          timings = "${responseDateToDateString(start.toIso8601String())} "
                    "- ${responseDateToDateString(end.toIso8601String())}";
        }

        // Update task name and timings in the database
        await updateTask(
          taskID,
          name,
          databaseResponse[i][2],  // task description
          databaseResponse[i][6],  // task importance

          deadline != null,  // Whether the task has a deadline

          // The date of the deadline (if the task has a deadline)
          deadline?.subtract(
            Duration(hours: deadline.hour, minutes: deadline.minute)
          ),
          // The time of the deadline (if the task has a deadline)
          deadline != null ? TimeOfDay(
            hour: deadline.hour,
            minute: deadline.minute
          ) : null,

          // The date of the start (if the task has a start and an end)
          start?.subtract(Duration(hours: start.hour, minutes: start.minute)),
          // The time of the start (if the task has a start and an end)
          start != null ? TimeOfDay(
            hour: start.hour,
            minute: start.minute
          ) : null,

          // The date of the end (if there is a start and an end)
          end?.subtract(Duration(hours: end.hour, minutes: end.minute)),
          // The time of the end (if there is a start and an end)
          end != null ? TimeOfDay(hour: end.hour, minute: end.minute) : null,
        );
      }
      else {
        // If the task is not from Google Calendar or the user has not
        // connected their Google account, load task name and timings
        // (deadline or start and end) from the database
        name = databaseResponse[i][1];
        if (databaseResponse[i][3] != null) {  // If the task has a deadline
          timings = "Due ${responseDateToDateString(databaseResponse[i][3])}";
          deadline = DateTime.parse(databaseResponse[i][3]);
        }
        else {  // If the task has a start and an end
          timings = "${responseDateToDateString(databaseResponse[i][4])} "
                    "- ${responseDateToDateString(databaseResponse[i][5])}";
          start = DateTime.parse(databaseResponse[i][4]);
          end = DateTime.parse(databaseResponse[i][5]);
        }
      }

      // Add the task to the list
      _tasks.add(
        TaskWidget(
          taskID: taskID,
          name: name,
          timings: timings,
          userID: userID,
          importance: importance,
          deadline: deadline,
          start: start,
          end: end,
          tags: tags,
          googleCalendarEventID: googleCalendarEventID
        )
      );
    }

    // Remove any duplicate tasks and get a list of task names
    List<TaskWidget> newTasks = [];
    List<String> taskNames = [];
    for (TaskWidget task in _tasks) {
      if (!taskNames.contains(task.name)) {
        newTasks.add(task);
        taskNames.add(task.name);
      }
    }
    _tasks = newTasks;

    // Add new tasks from the user's Google Calendar to the task list
    // and to the database
    if (CalendarClient.calendar != null) {
      Events events = await CalendarClient().getEvents();
      for (Event event in events.items!) {
        // Check whether the Google Calendar event is not null
        // and whether it has not already happened
        if (event.summary != null && event.start != null
            && (event.end!.dateTime != null
                    && event.end!.dateTime!.isAfter(DateTime.now())
                || event.end!.date != null
                    && event.end!.date!.isAfter(DateTime.now()))) {
            
          // Retrieve the task's data
          String name = event.summary!;
          if (name.length > 32) {
            name = name.substring(0, 32);
          }
          String description = event.description != null
                                ? event.description! : "";
          int importance = 5;  // Default importance value
          List<String> tags = [];
          String timings = "";
          DateTime? deadline;
          DateTime? start;
          DateTime? end;
          String googleCalendarEventID = event.id!;

          // Retrieve the task's timings (deadline or start and end)

          // If the task has a deadline
          if (event.end == null) {
            // If the deadline has a specific time associated with it
            if (event.start!.dateTime != null) {
              deadline = event.start!.dateTime!;
            }
            // If the deadline only has a date
            else {
              deadline = event.start!.date!;
            }
            timings = "Due ${responseDateToDateString(
              deadline.toIso8601String()
            )}";
          }

          // If there is a start and an end
          else {
            // If the start has a specific time associated with it
            if (event.start!.dateTime != null) {
              start = event.start!.dateTime!;
            }
            // If the start only has a date
            else {
              start = event.start!.date!;
            }

            // If the end has a specific time associated with it
            if (event.end!.dateTime != null) {
              end = event.end!.dateTime!;
            }
            // If the end only has a date
            else {
              end = event.end!.date!;
            }
            timings = "${responseDateToDateString(start.toIso8601String())} "
                      "- ${responseDateToDateString(end.toIso8601String())}";
          }

          // Check whether the task is already in the user's task list.
          // If it is, skip it
          if (taskNames.contains(name)) {
            continue;
          }
          // Add the name of the task to the list
          taskNames.add(name);

          // Add the task to the database
          int taskID = await addTask(
            name,
            description,
            importance,
            userID,

            deadline != null,  // Whether the task has a deadline

            // The date of the deadline (if the task has a deadline)
            deadline?.subtract(
              Duration(hours: deadline.hour, minutes: deadline.minute)
            ),
            // The time of the deadline (if the task has a deadline)
            deadline != null ? TimeOfDay(
              hour: deadline.hour,
              minute: deadline.minute
            ) : null,

            // The date of the start (if the task has a start and an end)
            start?.subtract(Duration(hours: start.hour, minutes: start.minute)),
            // The time of the start (if the task has a start and an end)
            start != null ? TimeOfDay(
              hour: start.hour,
              minute: start.minute
            ) : null,

            // The date of the end (if the task has a start and an end)
            end?.subtract(Duration(hours: end.hour, minutes: end.minute)),
            // The time of the end (if the task has a start and an end)
            end != null ? TimeOfDay(hour: end.hour, minute: end.minute) : null,

            googleCalendarEventID,
          );

          // Add the task to the list
          _tasks.add(
            TaskWidget(
              taskID: taskID,
              name: name,
              timings: timings,
              userID: userID,
              importance: importance,
              deadline: deadline,
              start: start,
              end: end,
              tags: tags,
              googleCalendarEventID: googleCalendarEventID
            )
          );
        }
      }
    }

    // Sort the task list using cached information about the order they should
    // appear in (if it exists)
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

  // This procedure removes the specified task from the database
  // and from the task list
  void remove(TaskWidget task) async {
    deleteTask(task.taskID);
    _tasks.remove(task);
    notifyListeners();
  }

  // This method sorts the tasks in the decreasing order of their importance
  // levels
  // Tasks with the same importance levels are sorted in the increasing order
  // of their deadlines or end datetimes
  // Tasks with the same importance levels and end datetimes are sorted
  // in the increasing order of their start datetimes
  void sortByImportance() {
    _tasks.sort((TaskWidget task1, TaskWidget task2) {
      // Compare two tasks and return a negative value if the first task
      // should be before the second one, or a positive value if the first task
      // should be after the second one

      // If the importance of the two tasks is the same
      if (-(task1.importance.compareTo(task2.importance)) == 0) {

        // If both tasks have deadlines
        if (task1.deadline != null && task2.deadline != null) {
          // Compare the deadlines
          return task1.deadline!.compareTo(task2.deadline!);
        }

        // If the first task has a deadline and the second task has a start
        // datetime and an end datetime
        else if (task1.deadline != null) {
          // Compare the first task's deadline with the second task's end
          // datetime
          return task1.deadline!.compareTo(task2.end!);
        }

        // If the first task has a start datetime and an end datetime
        // and the second task has a deadline
        else if (task2.deadline != null) {
          // Compare the first task's end datetime with the second task's
          // deadline
          return task1.end!.compareTo(task2.deadline!);
        }

        // If both tasks have a start datetime and an end datetime

        // If the end datetimes of both tasks are at the same time
        else if (task1.end!.isAtSameMomentAs(task2.end!)) {
          // Compare the tasks' start datetimes
          return task1.start!.compareTo(task2.start!);
        }
        else {
          // Compare the tasks' end datetimes
          return task1.end!.compareTo(task2.end!);
        }
      }

      // If the importance levels of the two tasks are different
      else {
        // Compare the tasks' importance levels (in reverse order)
        return -(task1.importance.compareTo(task2.importance));
      }
    });

    notifyListeners();
  }

  // This method sorts the tasks in the increasing order of their deadlines
  // or end datetimes
  // Tasks with the same end datetimes are sorted in the increasing order
  // of their start datetimes
  // Tasks with the same deadlines or start and end datetimes are sorted
  // in the decreasing order of their importance levels
  void sortByDeadline() {
    _tasks.sort((TaskWidget task1, TaskWidget task2) {
      // Compare two tasks and return a negative value if the first task
      // should be before the second one, or a positive value if the first task
      // should be after the second one

      int value = 0;

      // If both tasks have deadlines
      if (task1.deadline != null && task2.deadline != null) {
        // Compare the deadlines
        value = task1.deadline!.compareTo(task2.deadline!);
      }

      // If the first task has a deadline and the second task has a start
      // datetime and an end datetime
      else if (task1.deadline != null) {
        // Compare the first task's deadline with the second task's end datetime
        value = task1.deadline!.compareTo(task2.end!);
      }

      // If the first task has a start datetime and an end datetime
      // and the second task has a deadline
      else if (task2.deadline != null) {
        // Compare the first task's end datetime with the second task's deadline
        value = task1.end!.compareTo(task2.deadline!);
      }

      // If both tasks have a start datetime and an end datetime

      // If the end datetimes of both tasks are at the same time
      else if (task1.end!.isAtSameMomentAs(task2.end!)) {
        // Compare the tasks' start datetimes
        value = task1.start!.compareTo(task2.start!);
      }
      else {
        // Compare the tasks' end datetimes
        value = task1.end!.compareTo(task2.end!);
      }

      // If there is a tie
      if (value == 0) {
        // Compare the tasks' importance levels
        return -(task1.importance.compareTo(task2.importance));
      }

      else {
        return value;
      }
    });

    notifyListeners();
  }

  // This method sorts the tasks by importance and deadline (or start and
  // end) by using the K-Means clustering algorithm to divide the tasks into
  // four Eisenhower Matrix categories and then arrange them in the following
  // order:
  // important and urgent -> important but not urgent
  // -> urgent but not important -> not important and not urgent
  Future<void> sortWithAI() async {
    // First, sort the tasks by their deadline
    sortByDeadline();

    // Then get a list of pairs of integers that will be passed to the K-Means
    // clustering algorithm
    // For each task, the list of pairs of integer contains:
    // 1. The importance of the task
    // 2. The difference between the deadline or the end datetime of the task
    //    and the current time in minutes
    List<List<int>> data = [];
    for (int i = 0; i < _tasks.length; ++i) {
      // If the task has a deadline
      if (_tasks[i].deadline != null) {
        data.add(
          [
            _tasks[i].importance,
            _tasks[i].deadline!.difference(DateTime.now()).inMinutes
          ]
        );
      }
      // If the task has a start datetime and an end datetime
      else {
        data.add(
          [
            _tasks[i].importance,
            _tasks[i].end!.difference(DateTime.now()).inMinutes
          ]
        );
      }
    }

    List<int> order = await sortTasksWithKMeans(data);

    // Sort the tasks
    List<TaskWidget> newTasks = [];
    for (int i = 0; i < order.length; ++i) {
      newTasks.add(_tasks[order[i]]);
    }
    _tasks = newTasks;

    notifyListeners();
  }
}