import 'package:flutter/material.dart';

// Task date picker (for deadline, start or end) that is shown when the user is
// creating or editing a task
class TaskDatePicker extends StatefulWidget{
  const TaskDatePicker({
    super.key,
    required this.dateSetter,
    required this.dateGetter
  });

  final void Function(DateTime) dateSetter;
  final DateTime? dateGetter;

  @override
  State<TaskDatePicker> createState() => _TaskDatePickerState();
}

class _TaskDatePickerState extends State<TaskDatePicker> {

  @override
  Widget build(BuildContext context) {
    return TextButton(
      // Show a date picker
      onPressed: () => setState(() async 
        => widget.dateSetter((await showDatePicker(
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
        ))!)
      ),

      // Show the selected date or "Select date" if no date is selected
      child: Text(
        widget.dateGetter == null
          ? "Select date"
          : "${widget.dateGetter!.day}/${widget.dateGetter!.month}"
            "/${widget.dateGetter!.year}",
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 18,
          decoration: TextDecoration.underline
        )
      ),
    );
  }
}