import 'package:app/calendar_api.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_details_form.dart';
import 'package:app/models/user_model.dart';
import 'package:app/server_interactions.dart';
import 'package:app/models/task_model.dart';
import 'package:app/notification_api.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// A dialog in which the user can create a new task
class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key});

  @override State<StatefulWidget> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  final TextEditingController _taskImportanceController = TextEditingController(text: "5");

  // Indicates whether the database server is currently processing
  // a task creation request
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the user model
    final UserModel user = context.watch<UserModel>();

    // Load the task model so that the page can update dynamically
    final TaskModel task = context.watch<TaskModel>();

    return AlertDialog(
      title: const Text("Create a new task"),

      scrollable: true,

      content: TaskDetailsForm(
        formKey: _formKey,
        taskNameController: _taskNameController,
        taskDescriptionController: _taskDescriptionController,
        taskImportanceController: _taskImportanceController,
      ),

      actions: <Widget>[
        // "Cancel" button
        TextButton(
          onPressed: () {
            task.clear();
            Navigator.pop(context);  // Hide the dialog
          },
          child: Text(
            "Cancel",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),

        // "Create" button
        TextButton(
          onPressed: () async {
            // Update the task model with the name and the description
            // from the corresponding text boxes
            task.setName(_taskNameController.text);
            task.setDescription(_taskDescriptionController.text);
            task.setImportance(int.parse(_taskImportanceController.text));

            // Validate the form
            if (_formKey.currentState!.validate()) {

              // If the selected timings are correct
              // (there is either a deadline or a start and an end)
              if (task.deadlineDate != null
                  && (task.startDate == null && task.startTime == null)
                  && (task.endDate == null && task.endTime == null)
                || (task.deadlineDate == null && task.deadlineTime == null) 
                  && task.startDate != null
                  && task.endDate != null) {

                  // If the task has a start and an end, check that the task
                  // ends after it starts
                  if (task.startDate != null && task.endDate != null) {
                    DateTime start = task.startDate;
                    if (task.startTime != null) {
                      start.add(
                        Duration(
                          hours: task.startTime.hour,
                          minutes: task.startTime.minute
                        )
                      );
                    }
                    DateTime end = task.endDate;
                    if (task.endTime != null) {
                      end.add(
                        Duration(
                          hours: task.endTime.hour,
                          minutes: task.endTime.minute
                        )
                      );
                    }
                    if (start.isAfter(end)) {
                      await showDialog<String>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          content: Text(
                            "The task cannot end before it starts"
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);  // Hide the dialog
                              },
                              child: Text(
                                "OK",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary
                                )
                              )
                            )
                          ],
                        ),
                      );
                      return;
                    }
                  }

                  // Check task importance validity
                  if (int.tryParse(_taskImportanceController.text) == null
                      || int.parse(_taskImportanceController.text) < 0
                      || int.parse(_taskImportanceController.text) > 10) {
                    await showDialog<String>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        content: Text(
                          "Task importance should be an integer from 0 to 10"
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);  // Hide the dialog
                            },
                            child: Text(
                              "OK",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary
                              )
                            )
                          )
                        ],
                      ),
                    );
                    return;
                  }

                  // Show a circular progress indicator
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Add the task to the user's Google Calendar
                    // if the user has connected their Google Calendar
                    // and the task has a start and an end rather than a deadline
                    String? googleCalendarEventID;
                    if (CalendarClient.calendar != null && !task.hasDeadline) {
                      googleCalendarEventID = await CalendarClient().add(
                        task.name,
                        task.description,
                        task.startDate,
                        task.startTime,
                        task.endDate,
                        task.endTime
                      );
                    }

                    // Add the task to the database
                    int taskID = await addTask(
                      task.name,
                      task.description,
                      task.importance,
                      user.id,
                      task.hasDeadline,
                      task.deadlineDate,
                      task.deadlineTime,
                      task.startDate,
                      task.startTime,
                      task.endDate,
                      task.endTime,
                      googleCalendarEventID
                    );

                    // Add task to tag relationships to the database
                    for (final int tagID in task.tags) {
                      await addTaskToTagRelationship(taskID, tagID);
                    }

                    // Add task reminders to the database
                    for (final ReminderType reminderType in task.reminders) {
                      int reminderID = await addReminder(
                        taskID,
                        reminderType.index + 1
                      );

                      // Schedule a reminder notification
                      String title = task.name;
                      DateTime scheduledDate = DateTime.now();
                      if (task.hasDeadline) {
                        scheduledDate = DateTime(
                          task.deadlineDate.year,
                          task.deadlineDate.month,
                          task.deadlineDate.day,
                          task.deadlineTime.hour,
                          task.deadlineTime.minute
                        );
                      }
                      else {
                        scheduledDate = DateTime(
                          task.startDate.year,
                          task.startDate.month,
                          task.startDate.day,
                          task.startTime.hour,
                          task.startTime.minute
                        );
                      }

                      if (reminderType == ReminderType.tenMinutes) {
                        title = "in 10 minutes: $title";
                        scheduledDate = scheduledDate.subtract(
                          const Duration(minutes: 10)
                        );
                      }
                      else if (reminderType == ReminderType.oneHour) {
                        title = "in 1 hour: $title";
                        scheduledDate = scheduledDate.subtract(
                          const Duration(hours: 1)
                        );
                      }
                      else if (reminderType == ReminderType.oneDay) {
                        title = "in 1 day: $title";
                        scheduledDate = scheduledDate.subtract(
                          const Duration(days: 1)
                        );
                      }
                      else if (reminderType == ReminderType.oneWeek) {
                        title = "in 1 week: $title";
                        scheduledDate = scheduledDate.subtract(
                          const Duration(days: 7)
                        );
                      }
                      
                      if (task.hasDeadline) {
                        title = "Due $title";
                      }
                      else {
                        title = "Starts $title";
                      }


                      NotificationAPI.scheduleNotification(
                        id: reminderID,
                        title: title,
                        body: task.description,
                        scheduledDate: scheduledDate
                      );
                    }
                  }

                  // Display a notification if there was an error
                  // and the task could not be created
                  catch (e) {
                    if (context.mounted) {
                      await showDialog<String>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          content: Text(
                            "Sorry, there was an error. Please try again."
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);  // Hide the dialog
                              },
                              child: Text(
                                "OK",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary
                                )
                              )
                            )
                          ],
                        ),
                      );
                    }
                  }

                  if (context.mounted) {
                    // Hide the circular progress indicator
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.pop(context);  // Hide the dialog
                  }
                }
              // If the selected timings are incorrect,
              // show the user an error message
              else {
                await showDialog<String>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    content: Text(
                      "There should either be a deadline or a start and an end."
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);  // Hide the dialog
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary
                          )
                        )
                      )
                    ],
                  ),
                );
              }
              return;
            }
          },
          child: Text(
            "Create",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),
      ]
      
      // Show a circular progress indicator while the task is being created
      + (_isLoading
      ? [CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary
        )]
      : []),
    );
  }
}