import 'package:app/calendar_api.dart';
import 'package:app/home/widgets/task_list/task_editing_dialog.dart';
import 'package:app/models/importance_visibility_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class Task extends StatefulWidget {
  final String name;
  final String timings;
  final int userID;
  final int taskID;
  final int importance;
  final DateTime? deadline;
  final DateTime? start;
  final DateTime? end;
  final List<String> tags;
  final String? googleCalendarEventID;
  const Task({
    super.key,
    required this.name,
    required this.timings,
    required this.userID,
    required this.taskID,
    required this.importance,
    this.deadline,
    this.start,
    this.end,
    required this.tags,
    this.googleCalendarEventID,
  });

  @override
  createState() => _TaskState();
}
class _TaskState extends State<Task> {
  bool checkboxValue = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the models so that the widget can update dynamically
    final taskModel = context.watch<TaskModel>();
    final showImportanceModel = context.watch<ShowImportanceModel>();
    final taskListModel = context.watch<TaskListModel>();
    final tagListModel = context.watch<TagListModel>();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.02),
      child: TextButton(
        // When the user has tapped on the task, open the task editing menu
        onPressed: () async {
          await tagListModel.update(widget.userID);  // Update the tag list model
          await taskModel.getDetails(widget.taskID);  // Update the task model

          // Show the task editing dialog
          await showDialog<String>(
            context: context,
            builder: (context) => TaskEditingDialog(userID: widget.userID, taskWidget: widget),
          );

          setState(() {
            _isLoading = true;  // Show a circular progress indicator
          });
          await taskListModel.update(widget.userID);  // Update the task list model
          taskListModel.notifyListenersFromOutside();
          setState(() {
            _isLoading = false;  // Hide the circular progress indicator
          });
        },

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.width * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task name
                    Row(
                      children: <Widget>[
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w200,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                
                    // Importance
                    ((showImportanceModel.showImportance)
                    ? Text(
                        "Importance: ${widget.importance}",
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      )
                    : const SizedBox.shrink()),
                
                    // Timings
                    Text(
                      widget.timings,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                
                    // Tags
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          widget.tags.length,
                          (i) => Card(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text(widget.tags[i]),
                            )
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              )]

              // A circular progress indicator
              + (_isLoading
              ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary), SizedBox(width: MediaQuery.of(context).size.width * 0.05),]
              : [])

              // A checkbox to remove the task
              + <Widget> [Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  activeColor: Theme.of(context).colorScheme.secondary,
                  shape: const CircleBorder(),
                  value: checkboxValue,

                  // Remove the task when the checkbox is checked
                  onChanged: (value) async {

                    // Check the checkbox
                    setState(() {
                      checkboxValue = value!;
                    });
                    await Future.delayed(const Duration(milliseconds: 1000));  // Wait for 1 second while showing the checkbox animation
                    taskListModel.remove(widget);  // Remove the task

                    // Remove the task from the user's Google Calendar if their Google account is linked
                    if (CalendarClient.calendar != null && widget.googleCalendarEventID != null) {
                      CalendarClient().delete(widget.googleCalendarEventID!);
                    }

                    // Uncheck the checkbox (this prevents the checkbox of the next task from being checked after this one is removed)
                    setState(() {
                      checkboxValue = !value!;
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}