import 'package:flutter/material.dart';

class TaskTimePicker extends StatefulWidget{
  const TaskTimePicker({
    super.key,
    required this.timeSetter,
    required this.timeGetter
  });

  final void Function(TimeOfDay) timeSetter;
  final TimeOfDay? timeGetter;

  @override
  State<TaskTimePicker> createState() => _TaskTimePickerState();
}

class _TaskTimePickerState extends State<TaskTimePicker> {

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() async
        => widget.timeSetter((await showTimePicker(
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
        ))!)
      ),

      // Show the selected time or "Select time" if no time is selected
      child: Text(
        widget.timeGetter == null
          ? "Select time"
            // Hour (add 0 in front if it is less than 10)
          : "${widget.timeGetter!.hour < 10 ? '0' : ''}"
            "${widget.timeGetter!.hour % 12}"

            // Minute (add 0 in front if it is less than 10)
            ":${widget.timeGetter!.minute < 10 ? '0' : ''}"
            "${widget.timeGetter!.minute}"

            // AM or PM
            " ${widget.timeGetter!.hour < 12 ? 'AM' : 'PM'}",
          
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 18,
          decoration: TextDecoration.underline
        )
      ),
    );
  }
}