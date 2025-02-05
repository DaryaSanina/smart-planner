import 'package:app/models/task_model.dart';
import 'package:app/server_interactions.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<String> reminderTypes = [
  "10 minutes before",
  "1 hour before",
  "1 day before",
  "1 week before"
];

// A list of available reminder types represented by checkboxes
class ReminderList extends StatefulWidget {
  const ReminderList({super.key});
  @override
  State<StatefulWidget> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  @override
  Widget build(BuildContext context) {
    TaskModel task = context.watch<TaskModel>();
    return Column(
      // Generate the list of reminders
      children: List.generate(
        reminderTypes.length,

        (i) => CheckboxListTile(
          title: Text(reminderTypes[i]),

          // The checkbox is selected if the task contains this reminder
          value: task.reminders.contains(ReminderType.values[i]),

          activeColor: Theme.of(context).colorScheme.secondary,

          // Reminder selection/deselection
          onChanged: (bool? value) {
            if (value!) {
              setState(() => task.addReminder(ReminderType.values[i]));
            }
            else {
              setState(() => task.removeReminder(ReminderType.values[i]));
            }
          }
        )
      ),
    );
  }
}