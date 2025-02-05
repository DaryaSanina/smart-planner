import 'package:flutter/material.dart';

// Task importance dropdown menu that is shown when the user is creating or
// editing a task
class TaskImportanceDropdownMenu extends StatefulWidget{
  const TaskImportanceDropdownMenu({super.key, required this.controller});
  final TextEditingController controller;

  @override
  State<TaskImportanceDropdownMenu> createState() => _TaskImportanceDropdownMenuState();
}

class _TaskImportanceDropdownMenuState
extends State<TaskImportanceDropdownMenu> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      label: const Text("Importance"),
      initialSelection: int.parse(widget.controller.text),
      controller: widget.controller,
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
      
      onSelected: (int? newValue) 
        => setState(() => widget.controller.text = newValue.toString()),
    );
  }
}