import 'package:flutter/material.dart';

// Task name field that is shown when the user is creating or editing a task
class TaskNameField extends StatefulWidget{
  const TaskNameField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  State<TaskNameField> createState() => _TaskNameFieldState();
}

class _TaskNameFieldState extends State<TaskNameField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        labelText: "Task name",
      ),
      onChanged: (value) => setState(() => widget.controller.text = value),
      cursorColor: Theme.of(context).colorScheme.tertiary,

      // Task name validator
      validator: (value) {
        // Check whether the field is empty
        if (value == null || value.isEmpty) {
          return "Please enter task name";
        }
        // Check whether the task name is between 3 and 32 characters long
        if (value.length < 3) {
          return "Task name has less than 3 characters";
        }
        else if (value.length > 256) {
          return "Task name has more than 256 characters";
        }
        return null;
      },
    );
  }
}