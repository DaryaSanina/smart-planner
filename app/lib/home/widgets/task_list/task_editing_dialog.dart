import 'package:app/calendar_api.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_details_form.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/user_model.dart';
import 'package:app/server_interactions.dart';
import 'package:app/home/widgets/task_list/task_widget.dart';
import 'package:app/models/task_model.dart';
import 'package:app/notification_api.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A dialog in which the user can edit a task
class TaskEditingDialog extends StatefulWidget {
  const TaskEditingDialog({
    super.key,
    required this.taskWidget
  });
  final TaskWidget taskWidget;

  @override State<StatefulWidget> createState() => _TaskEditingDialogState();
}

class _TaskEditingDialogState extends State<TaskEditingDialog>{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  final TextEditingController _taskImportanceController = TextEditingController();

  // Indicates whether the dialog is being built for the first time
  bool firstTimeBuilding = true;

  // Indicates whether the database server is currently processing
  // a task editing request
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the task model so that the page can update dynamically
    final TaskModel task = context.watch<TaskModel>();

    // Load the task list and user models so that the task list can be updated
    // after the dialog closes
    final TaskListModel taskList = context.watch<TaskListModel>();
    final UserModel user = context.watch<UserModel>();

    // When the dialog opens, load the values in the task name, description and
    // importance fields from the details of the task
    if (firstTimeBuilding) {
      _taskNameController.text = task.name;
      _taskDescriptionController.text = task.description;
      _taskImportanceController.text = task.importance.toString();
      firstTimeBuilding = false;
    }

    return AlertDialog(
      title: const Text("Edit task"),

      scrollable: true,

      content: TaskDetailsForm(
        formKey: _formKey,
        taskNameController: _taskNameController,
        taskDescriptionController: _taskDescriptionController,
        taskImportanceController: _taskImportanceController,
      ),

      actions: <Widget>[
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),  // Hide the dialog
          child: Text(
            "Cancel",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),

        // Update button
        TextButton(
          onPressed: () async {
            // Update the task model with the name and the description
            // from the corresponding text boxes
            task.setName(_taskNameController.text);
            task.setDescription(_taskDescriptionController.text);
            if (int.tryParse(_taskImportanceController.text) != null) {
              task.setImportance(int.parse(_taskImportanceController.text));
            }

            // Validate the form
            if (_formKey.currentState!.validate()) {

              // If the selected timings are correct
              // (there is either a deadline or a start and an end)
              if (task.deadlineDate != null
                  && (task.startDate == null && task.startTime == null)
                  && (task.endDate == null && task.endTime == null)
                || (task.deadlineDate == null && task.deadlineTime == null)
                  && task.startDate != null && task.endDate != null) {
                
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
                  // Update the task in the user's Google Calendar if possible
                  if (CalendarClient.calendar != null
                      && task.googleCalendarEventID != null
                      && task.googleCalendarEventID != "null") {

                    // If it is an event (there is a start and an end),
                    // update it in the user's Google Calendar
                    if (!task.hasDeadline) {
                      await CalendarClient().update(
                        task.googleCalendarEventID,
                        task.name, task.description,
                        task.startDate,
                        task.startTime,
                        task.endDate,
                        task.endTime
                      );
                    }

                    // If it was an event (there was a start and an end),
                    // but now it is a task (there is a deadline),
                    // delete it from the user's Google Calendar
                    // and set its Google Calendar Event ID to null
                    else {
                      await CalendarClient().delete(
                        task.googleCalendarEventID
                      );
                      task.setGoogleCalendarEventID("null");
                    }
                  }

                  // If it was a task (there was a deadline),
                  // but now it is an event (there is a start and an end),
                  // add it to the user's Google Calendar
                  else if (CalendarClient.calendar != null
                            && !task.hasDeadline) {
                    task.setGoogleCalendarEventID(
                      await CalendarClient().add(
                        task.name,
                        task.description,
                        task.startDate,
                        task.startTime,
                        task.endDate,
                        task.endTime
                      )
                    );
                  }

                  // Update the task in the database
                  await updateTask(
                    widget.taskWidget.taskID,
                    task.name,
                    task.description,
                    task.importance,
                    task.hasDeadline,
                    task.deadlineDate,
                    task.deadlineTime,
                    task.startDate,
                    task.startTime,
                    task.endDate,
                    task.endTime,
                    task.googleCalendarEventID
                  );

                  // Update the tags of the task
                  List<Tag> tagIDsAndNames = await getTaskTags(
                    widget.taskWidget.taskID
                  );
                  List<int> tagIDs = List.generate(
                    tagIDsAndNames.length,
                    (i) => tagIDsAndNames[i].tagID
                  );
                  for (int tagID in tagIDs) {
                    await deleteTaskToTagRelationship(
                      widget.taskWidget.taskID,
                      tagID
                    );
                  }
                  for (int tagID in task.tags) {
                    await addTaskToTagRelationship(
                      widget.taskWidget.taskID,
                      tagID
                    );
                  }

                  // Remove all existing reminders
                  for (int reminderType = 1; reminderType <= 4; ++reminderType) {
                    // Try to delete this type of reminder for this task
                    int reminderID = await deleteReminder(
                      widget.taskWidget.taskID,
                      reminderType
                    );
                    // If the reminder existed, cancel the notification
                    if (reminderID != -1) {
                      await NotificationAPI.cancelNotification(reminderID);
                    }
                  }
                  
                  // Add the selected reminders
                  for (ReminderType reminderType in task.reminders) {
                    int reminderID = await addReminder(
                      widget.taskWidget.taskID,
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
                        task.deadlineTime != null
                          ? task.deadlineTime.hour : 0,
                        task.deadlineTime != null
                          ? task.deadlineTime.minute : 0
                      );
                    }
                    else {
                      scheduledDate = DateTime(
                        task.startDate.year,
                        task.startDate.month,
                        task.startDate.day,
                        task.startTime != null ? task.startTime.hour : 0,
                        task.startTime != null ? task.startTime.minute : 0
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
                // and the task could not be updated
                catch (e) {
                  if (context.mounted) {
                    print(e);
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
                await taskList.update(user.id);

                // Hide the circular progress indicator
                setState(() {
                  _isLoading = false;
                });
                
                if (context.mounted) {
                  Navigator.pop(context);  // Hide the dialog
                }
              }

              // Display a notification if the selected timings are incorrect
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
            "Update",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),
      ]
      
      // Show a circular progress indicator while the task is being updated
      + (_isLoading
      ? [CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary
        )]
      : []),
    );
  }
}