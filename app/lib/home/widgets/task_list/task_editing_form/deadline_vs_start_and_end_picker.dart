import 'package:app/models/task_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A list of two radio checkboxes to choose whether the task that is being
// created or edited has a deadline or a start and an end
class DeadlineVsStartAndEndPicker extends StatefulWidget {
  const DeadlineVsStartAndEndPicker({super.key});
  @override
  State<StatefulWidget> createState() => _DeadlineVsStartAndEndPickerState();
}

class _DeadlineVsStartAndEndPickerState 
extends State<DeadlineVsStartAndEndPicker> {
  @override
  Widget build(BuildContext context) {
    TaskModel task = context.watch<TaskModel>();  // Load the current task data
    return Column(
      children: [
        // The deadline option
        ListTile(
          title: const Text("Deadline"),
          leading: Radio<bool>(
            value: true,
            groupValue: task.hasDeadline,
            activeColor: Theme.of(context).colorScheme.tertiary,
            onChanged: (bool? value) {
              // If the groupValue has changed, update the task data
              task.setTimeConstraintsMode(value!);
              task.clearTimings();
            },
          ),
        ),

        // The start and end option
        ListTile(
          title: const Text("Start and end"),
          leading: Radio<bool>(
            value: false,
            groupValue: task.hasDeadline,
            activeColor: Theme.of(context).colorScheme.tertiary,
            onChanged: (bool? value) {
              // If the groupValue has changed, update the task data
              task.setTimeConstraintsMode(value!);
              task.clearTimings();
            },
          ),
        ),
      ],
    );
  }
}