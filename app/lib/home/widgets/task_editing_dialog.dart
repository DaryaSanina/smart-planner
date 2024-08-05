import 'package:app/home/widgets/task.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

String dateTimeToString(DateTime date, TimeOfDay? time) {
  String result = date.year.toString();
  result += "-";
  if (date.month < 10) {
    result += "0";
  }
  result += date.month.toString();
  result += "-";
  if (date.day < 10) {
    result += "0";
  }
  result += date.day.toString();
  result += "T";

  if (time != null) {
    if (time.hour < 10) {
      result += "0";
    }
    result += time.hour.toString();
    result += ":";
    if (time.minute < 10) {
      result += "0";
    }
    result += time.minute.toString();
  }
  else {
    result += "00:00";
  }
  result += ":00";

  return result;
}

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

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TaskModel>();
    taskNameController.text = task.name;
    descriptionController.text = task.description;

    final taskList = context.watch<TaskListModel>();

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
                counterText: "${32 - task.name.length} character(s) left"
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              onChanged: (text) => setState(() => task.setName(text)),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter the task name";
                }
                if (value.length < 3 || value.length > 32) {
                  return "The length of the task name is not between 3 and 32 characters";
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
                counterText: "${task.description.length} character(s)"
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              onChanged: (text) => setState(() => task.description = text),
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
              dropdownMenuEntries: List.generate(11, (i) => i).map((int item) {
                return DropdownMenuEntry(
                  value: item,
                  label: item.toString(),
                );
              }).toList(),
              onSelected: (int? newValue) => setState(() => task.setImportance(newValue!)),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Deadline or start and end picker
            const Text("Time constraints", style: TextStyle(fontSize: 18)),
            Column(
              children: [
                ListTile(
                  title: const Text("Deadline"),
                  leading: Radio<bool>(
                    value: task.isDeadline,
                    groupValue: task.isDeadline,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: (bool? value) => setState(() {
                      task.isDeadline = value!;
                      task.deadlineDate = null;
                      task.deadlineTime = null;
                      task.startDate = null;
                      task.startTime = null;
                      task.endDate = null;
                      task.endTime = null;
                    }),
                  ),
                ),
                ListTile(
                  title: const Text("Start and end"),
                  leading: Radio<bool>(
                    value: !task.isDeadline,
                    groupValue: task.isDeadline,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: (bool? value) => setState(() {
                      task.isDeadline = value!;
                      task.deadlineDate = null;
                      task.deadlineTime = null;
                      task.startDate = null;
                      task.startTime = null;
                      task.endDate = null;
                      task.endTime = null;
                    }),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            Container(
              child: task.isDeadline
                // Deadline date and time picker
                ? Row(
                    children: [
                      const Text("Deadline: ", style: TextStyle(fontSize: 18)),
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
                        child: Text(
                          task.deadlineDate == null
                            ? "Select date"
                            : "${task.deadlineDate!.day}/${task.deadlineDate!.month}/${task.deadlineDate!.year}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
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
                        child: Text(
                          task.deadlineTime == null
                            ? "Select time"
                            : "${task.deadlineTime!.hour < 10 ? '0' : ''}${task.deadlineTime!.hour % 12}:${task.deadlineTime!.minute < 10 ? '0' : ''}${task.deadlineTime!.minute} ${task.deadlineTime!.hour < 12 ? 'AM' : 'PM'}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
                    ],
                  )
              : Column(
                children: [
                  // Start date and time picker
                  Row(
                    children: [
                      const Text("Start: ", style: TextStyle(fontSize: 18)),
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
                        child: Text(
                          task.startDate == null
                            ? "Select date"
                            : "${task.startDate!.day}/${task.startDate!.month}/${task.startDate!.year}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
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
                        child: Text(
                          task.startTime == null
                            ? "Select time"
                            : "${task.startTime!.hour < 10 ? '0' : ''}${task.startTime!.hour % 12}:${task.startTime!.minute < 10 ? '0' : ''}${task.startTime!.minute} ${task.startTime!.hour < 12 ? 'AM' : 'PM'}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
                    ],
                  ),

                  // End date and time picker
                  Row(
                    children: [
                      const Text("End: ", style: TextStyle(fontSize: 18)),
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
                        child: Text(
                          task.endDate == null
                            ? "Select date"
                            : "${task.endDate!.day}/${task.endDate!.month}/${task.endDate!.year}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
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
                        child: Text(
                          task.endTime == null
                            ? "Select time"
                            : "${task.endTime!.hour < 10 ? '0' : ''}${task.endTime!.hour % 12}:${task.endTime!.minute < 10 ? '0' : ''}${task.endTime!.minute} ${task.endTime!.hour < 12 ? 'AM' : 'PM'}",
                          style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),

        // Create button
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (task.deadlineDate != null && (task.startDate == null && task.startTime == null) && (task.endDate == null && task.endTime == null)
                || (task.deadlineDate == null && task.deadlineTime == null) && task.startDate != null && task.endDate != null) {
                  setState(() {
                    _isLoading = true;
                  });

                  // Form a task creation request
                  String url = 'https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/update_task';
                  url += '?task_id=${widget.taskWidget.taskID}';
                  url += '&task_name=${task.name}';

                  if (task.description.isNotEmpty) {
                    url += '&description=${task.description}';
                  }

                  if (task.isDeadline) {
                    url += '&deadline=${dateTimeToString(task.deadlineDate!, task.deadlineTime)}';  // Add deadline
                  }
                  else {
                    url += '&start=${dateTimeToString(task.startDate!, task.startTime)}';  // Add start date and time
                    url += '&end=${dateTimeToString(task.endDate!, task.endTime)}';  // Add end date and time
                  }

                  // Send the request
                  http.Response response = await http.put(
                    Uri.parse(url),
                  );

                  if (response.statusCode != 201) {
                    setState(() {
                      _isLoading = false;
                    });
                    return;
                  }

                  // Update the task list
                  await taskList.update(widget.userID);

                  if (context.mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    Navigator.pop(context);
                  }
                }
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
      ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]
      : []),
    );
  }
}