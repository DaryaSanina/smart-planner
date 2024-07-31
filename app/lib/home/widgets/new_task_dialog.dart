import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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

class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key});

  @override State<StatefulWidget> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog>{
  final _formKey = GlobalKey<FormState>();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController importanceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final task = context.watch<TaskModel>();
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
                counterText: '${task.name.toString().length} character(s)'
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              onChanged: (text) => setState(() => task.setName(text)),
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
                counterText: '${task.description.length.toString()} character(s)'
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
              onChanged: (text) => setState(() => task.description = text),
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
                    value: true,
                    groupValue: task.isDeadline,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: (bool? value) => setState(() => task.isDeadline = value!),
                  ),
                ),
                ListTile(
                  title: const Text("Start and end"),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: task.isDeadline,
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    onChanged: (bool? value) => setState(() => task.isDeadline = value!),
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
                            : "${task.deadlineTime!.hour % 12}:${task.deadlineTime!.minute} ${task.deadlineTime!.hour < 12 ? 'AM' : 'PM'}",
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
                            : "${task.startTime!.hour % 12}:${task.startTime!.minute} ${task.startTime!.hour < 12 ? 'AM' : 'PM'}",
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
                            : "${task.endTime!.hour % 12}:${task.endTime!.minute} ${task.endTime!.hour < 12 ? 'AM' : 'PM'}",
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
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Create", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ]
    );
  }
}