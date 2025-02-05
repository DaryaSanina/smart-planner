import 'package:flutter/material.dart';

// Task description field that is shown when the user is creating or editing
// a task
class TaskDescriptionField extends StatefulWidget{
  const TaskDescriptionField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  State<TaskDescriptionField> createState() => _TaskDescriptionFieldState();
}

class _TaskDescriptionFieldState extends State<TaskDescriptionField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        labelText: "Description",
        counterText: "${widget.controller.text.length} character(s)"
      ),
      cursorColor: Theme.of(context).colorScheme.tertiary,
      onChanged: (value) => setState(() => widget.controller.text = value),

      // Task description validator (any description is valid)
      validator: (value) {
        return null;
      },
    );
  }
}