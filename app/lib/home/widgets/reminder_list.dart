import 'package:app/models/task_model.dart';
import 'package:app/models/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

List<String> reminderNames = ["10 minutes before", "1 hour before", "1 day before", "1 week before"];

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
      children: List.generate(
        4,
        (i) => CheckboxListTile(
          title: Text(reminderNames[i]),
          value: task.reminders.contains(ReminderType.values[i]),
          activeColor: Theme.of(context).colorScheme.secondary,
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