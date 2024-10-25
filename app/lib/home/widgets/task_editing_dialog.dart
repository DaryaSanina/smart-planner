import 'package:app/home/util.dart';
import 'package:app/home/widgets/deadline_vs_start_and_end_picker.dart';
import 'package:app/home/widgets/reminder_list.dart';
import 'package:app/home/widgets/task.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:app/models/util.dart';
import 'package:app/notification_api.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaskEditingDialog extends StatefulWidget {
  const TaskEditingDialog({super.key, required this.userID, required this.taskWidget});
  final int userID;
  final Task taskWidget;

  @override State<StatefulWidget> createState() => _TaskEditingDialogState();
}

class _TaskEditingDialogState extends State<TaskEditingDialog>{
  final _formKey = GlobalKey<FormState>();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController importanceController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingTag = false;
  bool _importanceIsLoading = false;
  TextEditingController newTagController = TextEditingController();
  String newTagName = "";
  String _taskName = "";
  String _taskDescription = "";
  bool firstTimeLoading = true;

  @override
  Widget build(BuildContext context) {
    // Load the models so that the page can update dynamically
    final task = context.watch<TaskModel>();
    if (firstTimeLoading) {
      taskNameController.text = task.name;
      descriptionController.text = task.description;
      firstTimeLoading = false;
    }
    final tagList = context.watch<TagListModel>();

    return AlertDialog(
      title: const Text("Edit task"),

      scrollable: true,

      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task name field
            TextFormField(
              controller: taskNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Task name",
                counterText: "${50 - _taskName.length} character(s) left"
              ),
              onChanged: (value) => setState(() => _taskName = value),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              validator: (value) {
                if (value == null || value.isEmpty) {  // Check whether the field is empty
                  return "Please enter the task name";
                }
                if (value.length < 3 || value.length > 50) {  // Check whether the task name is between 3 and 32 characters long
                  return "The length of the task name is not between 3 and 50 characters";
                }
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            // Description field
            TextFormField(
              controller: descriptionController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                labelText: "Description",
                counterText: "${_taskDescription.length} character(s)"
              ),
              onChanged: (value) => setState(() => _taskDescription = value),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              validator: (value) {
                return null;
              },
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            // Importance field
            DropdownMenu<int>(
              label: const Text("Importance"),
              initialSelection: task.importance,
              controller: importanceController,
              requestFocusOnTap: true,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              // List all possible importance levels - numbers from 0 to 10
              dropdownMenuEntries: List.generate(11, (i) => i).map((int item) {
                return DropdownMenuEntry(
                  value: item,
                  label: item.toString(),
                );
              }).toList(),
              onSelected: (int? newValue) => setState(() => task.setImportance(newValue!)),  // Update the task model
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Button to generate task importance using a LSTM model on a server
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                setState(() {
                  _importanceIsLoading = true;  // Show a linear progress indicator
                });
                int newImportance = await getTaskImportancePrediction(taskNameController.text, descriptionController.text);  // Get a new importance prediction
                setState(() => task.setImportance(newImportance));  // Update the task model
                setState(() {
                  _importanceIsLoading = false;  // Hide the linear progress indicator
                });
              },
              child: _importanceIsLoading
              // If _isLoading is true, show a linear progress indicator below the "Generate with AI" text
              ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Predict importance with AI", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                  SizedBox(
                    width: 150,
                    height: 3,
                    child: LinearProgressIndicator(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      color: Theme.of(context).colorScheme.tertiary,
                      minHeight: 3,
                    )
                  ),
                ],
              )
              // Otherwise, just show the "Generate with AI" text
              : Text("Predict importance with AI", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Deadline or start and end picker
            const Text("Time constraints", style: TextStyle(fontSize: 18)),
            const DeadlineVsStartAndEndPicker(),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            Container(
              child: task.isDeadline
                // Deadline date and time picker
                ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: [
                        const Text("Deadline: ", style: TextStyle(fontSize: 18)),

                        // Deadline date picker
                        TextButton(
                          onPressed: () => setState(() async => task.setDeadlineDate((await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000), lastDate: DateTime(2100),
                            initialDate: task.deadlineDate,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primary: Theme.of(context).colorScheme.secondary,
                                    onPrimary: Theme.of(context).colorScheme.tertiary,
                                    onSurface: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected date or "Select date" if no date is selected
                          child: Text(
                            task.deadlineDate == null
                              ? "Select date"
                              : "${task.deadlineDate!.day}/${task.deadlineDate!.month}/${task.deadlineDate!.year}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),

                        // Deadline time picker
                        TextButton(
                          onPressed: () => setState(() async => task.setDeadlineTime((await showTimePicker(
                            context: context,
                            initialTime: (task.deadlineTime != const TimeOfDay(hour: 0, minute: 0) ? task.deadlineTime! : TimeOfDay.now()),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primaryContainer: Theme.of(context).colorScheme.secondary,
                                    tertiaryContainer: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected time or "Select time" if no time is selected
                          child: Text(
                            task.deadlineTime == null
                              ? "Select time"
                              : "${task.deadlineTime!.hour < 10 ? '0' : ''}${task.deadlineTime!.hour % 12}:${task.deadlineTime!.minute < 10 ? '0' : ''}${task.deadlineTime!.minute} ${task.deadlineTime!.hour < 12 ? 'AM' : 'PM'}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),
                      ],
                    ),
                )
              
              : Column(
                children: [
                  // Start date and time picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("Start: ", style: TextStyle(fontSize: 18)),

                        // Start date picker
                        TextButton(
                          onPressed: () => setState(() async => task.setStartDate((await showDatePicker(
                            context: context,
                            initialDate: task.startDate,
                            firstDate: DateTime(2000), lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primary: Theme.of(context).colorScheme.secondary,
                                    onPrimary: Theme.of(context).colorScheme.tertiary,
                                    onSurface: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected date or "Select date" if no date is selected
                          child: Text(
                            task.startDate == null
                              ? "Select date"
                              : "${task.startDate!.day}/${task.startDate!.month}/${task.startDate!.year}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),

                        // Start time picker
                        TextButton(
                          onPressed: () => setState(() async => task.setStartTime((await showTimePicker(
                            context: context,
                            initialTime: (task.startTime != const TimeOfDay(hour: 0, minute: 0) ? task.startTime! : TimeOfDay.now()),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primaryContainer: Theme.of(context).colorScheme.secondary,
                                    tertiaryContainer: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected time or "Select time" if no time is selected
                          child: Text(
                            task.startTime == null
                              ? "Select time"
                              : "${task.startTime!.hour < 10 ? '0' : ''}${task.startTime!.hour % 12}:${task.startTime!.minute < 10 ? '0' : ''}${task.startTime!.minute} ${task.startTime!.hour < 12 ? 'AM' : 'PM'}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),
                      ],
                    ),
                  ),

                  // End date and time picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("End: ", style: TextStyle(fontSize: 18)),

                        // End date picker
                        TextButton(
                          onPressed: () => setState(() async => task.setEndDate((await showDatePicker(
                            context: context,
                            initialDate: task.endDate,
                            firstDate: DateTime(2000), lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primary: Theme.of(context).colorScheme.secondary,
                                    onPrimary: Theme.of(context).colorScheme.tertiary,
                                    onSurface: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected date or "Select date" if no date is selected
                          child: Text(
                            task.endDate == null
                              ? "Select date"
                              : "${task.endDate!.day}/${task.endDate!.month}/${task.endDate!.year}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),

                        // End time picker
                        TextButton(
                          onPressed: () => setState(() async => task.setEndTime((await showTimePicker(
                            context: context,
                            initialTime: (task.endTime != const TimeOfDay(hour: 0, minute: 0) ? task.endTime! : TimeOfDay.now()),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark().copyWith(
                                    primaryContainer: Theme.of(context).colorScheme.secondary,
                                    tertiaryContainer: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                child: child!,
                              );
                            }
                          ))!)),
                          // Show the selected time or "Select time" if no time is selected
                          child: Text(
                            task.endTime == null
                              ? "Select time"
                              : "${task.endTime!.hour < 10 ? '0' : ''}${task.endTime!.hour % 12}:${task.endTime!.minute < 10 ? '0' : ''}${task.endTime!.minute} ${task.endTime!.hour < 12 ? 'AM' : 'PM'}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Reminders for the task
            const Text("Reminders", style: TextStyle(fontSize: 18)),
            const ReminderList(),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Tags for the selected task
            const Text("Tags", style: TextStyle(fontSize: 18)),
            Column(
              // Generate the list of available tags and indicate which tags have already been selected for this task
              children: List.generate(
                tagList.tags.length,
                (i) => CheckboxListTile(
                  title: Text(tagList.tags[i].name),
                  activeColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  value: task.tags.contains(tagList.tags[i].tagID),
                  onChanged: (bool? value) {
                    // Update the task model
                    if (value!) {
                      setState(() {
                        task.addTag(tagList.tags[i].tagID);
                      });
                    }
                    else {
                      setState(() {
                        task.removeTag(tagList.tags[i].tagID);
                      });
                    }
                  },
                )
              ),
            ),
            
            // Add a new tag
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (newTagName.length >= 3 && newTagName.length <= 32) {  // Check whether the name of the tag is between 3 and 32 characters long
                      setState(() {
                        _isLoadingTag = true;  // Show a circular progress indicator
                      });
                      await addTag(newTagName, widget.userID);  // Add the tag to the database on the server
                      tagList.update(widget.userID);  // Update the the tag list model
                      setState(() {
                        _isLoadingTag = false;  // Hide the circular progress indicator
                      });
                    }
                    else {
                      // Show the user a message saying that the tag name is incorrect
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tag name should be between 3 and 32 characters long.")),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                ),

                // New tag name input field
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 50,
                  child: TextField(
                    controller: newTagController,
                    decoration: const InputDecoration(
                      hintText: "Add a new tag",
                    ),
                    cursorColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: (text) => setState(() => newTagName = text),
                  ),
                ),
              ]+ (_isLoadingTag
              ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]  // Show a circular progress indicator while the new tag is being created
              : []),
            ),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),  // Hide the dialog
          child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),

        // Update button
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              task.setName(taskNameController.text);
              task.setDescription(descriptionController.text);
              // If the selected timings are correct (there is either a deadline or a start and an end)
              if (task.deadlineDate != null && (task.startDate == null && task.startTime == null) && (task.endDate == null && task.endTime == null)
                || (task.deadlineDate == null && task.deadlineTime == null) && task.startDate != null && task.endDate != null) {
                  setState(() {
                    _isLoading = true;  // Show a circular progress indicator
                  });

                  await updateTask(widget.taskWidget.taskID, task.name, task.description, task.importance,
                            task.isDeadline, task.deadlineDate, task.deadlineTime,
                            task.startDate, task.startTime, task.endDate, task.endTime);

                  // Update the tags of the task
                  for (int tagID in await getTaskTags(widget.taskWidget.taskID)) {
                    await deleteTaskToTagRelationship(widget.taskWidget.taskID, tagID);
                  }
                  for (int tagID in task.tags) {
                    await addTaskToTagRelationship(widget.taskWidget.taskID, tagID);
                  }

                  // Update the reminders of the task
                  for (int reminderType = 1; reminderType <= 4; ++reminderType) {
                    int reminderID = await deleteReminder(widget.taskWidget.taskID, reminderType);  // Try to delete this type of reminder for this task
                    if (reminderID != -1) {  // If the reminder existed
                      await NotificationAPI.cancelNotification(reminderID);  // Cancel the notification
                    }
                  }
                  
                  for (ReminderType reminderType in task.reminders){
                    int reminderID = await addReminder(widget.taskWidget.taskID, reminderType.index + 1);

                    // Schedule a reminder notification
                    String title = task.name;
                    DateTime scheduledDate = DateTime.now();
                    if (task.isDeadline) {
                      scheduledDate = DateTime(task.deadlineDate.year, task.deadlineDate.month, task.deadlineDate.day, task.deadlineTime.hour, task.deadlineTime.minute);
                    }
                    else {
                      scheduledDate = DateTime(task.startDate.year, task.startDate.month, task.startDate.day, task.startTime.hour, task.startTime.minute);
                    }

                    if (reminderType == ReminderType.tenMinutes) {
                      title = "in 10 minutes: $title";
                      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));
                    }
                    else if (reminderType == ReminderType.oneHour) {
                      title = "in 1 hour: $title";
                      scheduledDate = scheduledDate.subtract(const Duration(hours: 1));
                    }
                    else if (reminderType == ReminderType.oneDay) {
                      title = "in 1 day: $title";
                      scheduledDate = scheduledDate.subtract(const Duration(days: 1));
                    }
                    else if (reminderType == ReminderType.oneWeek) {
                      title = "in 1 week: $title";
                      scheduledDate = scheduledDate.subtract(const Duration(days: 7));
                    }
                    
                    if (task.isDeadline) {
                      title = "Due $title";
                    }
                    else {
                      title = "Starts $title";
                    }

                    NotificationAPI.scheduleNotification(id: reminderID, title: title, body: task.description, scheduledDate: scheduledDate);
                  }

                  if (context.mounted) {
                    setState(() {
                      _isLoading = false;  // Hide the circular progress indicator
                    });
                    Navigator.pop(context);  // Hide the dialog
                  }
                }
              // If the selected timings are incorrect, show the user an error message
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("There should either be a deadline or a start and an end.")),
                );
              }
              return;
            }
          },
          child: Text("OK", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ] + (_isLoading
      ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]  // Show a circular progress indicator while the task is being updated
      : []),
    );
  }
}