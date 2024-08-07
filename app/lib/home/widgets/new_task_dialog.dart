import 'dart:convert';
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

class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key, required this.userID});
  final int userID;

  @override State<StatefulWidget> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog>{
  final _formKey = GlobalKey<FormState>();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController importanceController = TextEditingController();
  bool _isLoading = false;
  bool _importanceIsLoading = false;

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TaskModel>();

    final taskList = context.watch<TaskListModel>();

    return AlertDialog(
      title: const Text("Create a new task"),

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    setState(() {
                      _importanceIsLoading = true;
                    });
                    var request = jsonEncode({"description": task.name + '. ' + task.description});
                    var response = await http.post(
                      Uri.parse('https://ejo5jpfxthbv3vdjlwg453xbea0boivt.lambda-url.eu-north-1.on.aws/predict_importance'),
                      headers: {'Content-Type': 'application/json'},
                      body: request
                    );
                    int newImportance = jsonDecode(response.body)["importance"];
                    setState(() => task.setImportance(newImportance));
                    setState(() {
                      _importanceIsLoading = false;
                    });
                  },
                  child: _importanceIsLoading
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Generate with AI", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                      SizedBox(
                        width: 100,
                        height: 3,
                        child: LinearProgressIndicator(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          color: Theme.of(context).colorScheme.tertiary,
                          minHeight: 3,
                        )
                      ),
                    ],
                  )
                  : Text("Generate with AI", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Deadline or start and end picker
            const Text("Time constraints", style: TextStyle(fontSize: 18)),
            Column(
              children: [
                ListTile(
                  title: const Text("Deadline"),
                  leading: Radio<bool>(
                    value: true,
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
                    value: false,
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
                ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: [
                        const Text("Deadline: ", style: TextStyle(fontSize: 18)),
                        TextButton(
                          onPressed: () => setState(() async => task.setDeadlineDate((await showDatePicker(
                            context: context,
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
                            task.deadlineDate == null
                              ? "Select date"
                              : "${task.deadlineDate!.day}/${task.deadlineDate!.month}/${task.deadlineDate!.year}",
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18, decoration: TextDecoration.underline)
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() async => task.setDeadlineTime((await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
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
                        TextButton(
                          onPressed: () => setState(() async => task.setStartDate((await showDatePicker(
                            context: context,
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
                            initialTime: TimeOfDay.now(),
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
                  ),

                  // End date and time picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("End: ", style: TextStyle(fontSize: 18)),
                        TextButton(
                          onPressed: () => setState(() async => task.setEndDate((await showDatePicker(
                            context: context,
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
                            initialTime: TimeOfDay.now(),
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
                  var requestDict = {
                    'name': task.name,
                    'importance': task.importance,
                    'user_id': widget.userID
                  };

                  requestDict['description'] = task.description;

                  if (task.isDeadline) {
                    requestDict['deadline'] = dateTimeToString(task.deadlineDate!, task.deadlineTime);  // Add deadline
                  }
                  else {
                    requestDict['start'] = dateTimeToString(task.startDate!, task.startTime); // Add start date and time
                    requestDict['end'] = dateTimeToString(task.endDate!, task.endTime); // Add start date and time
                  }

                  // Send the request
                  var request = jsonEncode(requestDict);
                  http.Response response = await http.post(
                    Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/add_task'),
                    headers: {'Content-Type': 'application/json'},
                    body: request
                  );

                  if (response.statusCode != 201) {
                    setState(() {
                      _isLoading = false;
                    });
                    return;
                  }

                  if (context.mounted) {
                    // Update the task list
                    taskList.update(widget.userID);
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
          child: Text("Create", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ] + (_isLoading
      ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]
      : []),
    );
  }
}