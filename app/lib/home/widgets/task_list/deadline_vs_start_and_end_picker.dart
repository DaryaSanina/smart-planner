import 'package:app/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeadlineVsStartAndEndPicker extends StatefulWidget {
  const DeadlineVsStartAndEndPicker({super.key});
  @override
  State<StatefulWidget> createState() => _DeadlineVsStartAndEndPickerState();
}

class _DeadlineVsStartAndEndPickerState extends State<DeadlineVsStartAndEndPicker> {
  @override
  Widget build(BuildContext context) {
    TaskModel task = context.watch<TaskModel>();
    return Column(
      children: [
        ListTile(
          title: const Text("Deadline"),
          leading: Radio<bool>(
            value: true,
            groupValue: task.isDeadline,
            activeColor: Theme.of(context).colorScheme.tertiary,
            onChanged: (bool? value) {
              task.setTimeConstraintsMode(value!);
              task.clearTimings();
            },
          ),
        ),
        ListTile(
          title: const Text("Start and end"),
          leading: Radio<bool>(
            value: false,
            groupValue: task.isDeadline,
            activeColor: Theme.of(context).colorScheme.tertiary,
            onChanged: (bool? value) {
              task.setTimeConstraintsMode(value!);
              task.clearTimings();
            },
          ),
        ),
      ],
    );
  }
}