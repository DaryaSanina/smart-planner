import 'package:app/calendar_api.dart';
import 'package:app/home/widgets/task_list/task_editing_dialog.dart';
import 'package:app/models/importance_visibility_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// A widget that shows the name, the deadline (or start and end), the tags
// and, optionally, the importance of a task. It also has a button that marks
// the task as complete and deletes it.
class TaskWidget extends StatefulWidget {
  final String name;
  final String timings;
  final int taskID;
  final int importance;
  final DateTime? deadline;
  final DateTime? start;
  final DateTime? end;
  final List<String> tags;
  final String? googleCalendarEventID;
  const TaskWidget({
    super.key,
    required this.name,
    required this.timings,
    required this.taskID,
    required this.importance,
    this.deadline,
    this.start,
    this.end,
    required this.tags,
    this.googleCalendarEventID,
  });

  @override
  createState() => _TaskWidgetState();
}
class _TaskWidgetState extends State<TaskWidget> {
  // Indicates whether the task completion checkbox has been selected
  // and the task completion animation is currently being performed or
  // the task is currently being deleted from the database
  bool checkboxValue = false;

  // Indicates whether the details of the task are currently updating
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the user, task, task list, tag list and importance visibility models
    // so that the widget can update dynamically
    final UserModel user = context.watch<UserModel>();
    TaskModel taskModel = context.watch<TaskModel>();
    TaskListModel taskListModel = context.watch<TaskListModel>();
    TagListModel tagListModel = context.watch<TagListModel>();
    ImportanceVisibilityModel importanceVisibilityModel = context.watch<ImportanceVisibilityModel>();

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.width * 0.02
      ),
      child: TextButton(
        // When the user has tapped on the task, open the task editing menu
        onPressed: () async {
          try {
            // Refresh the tag list model
            await tagListModel.load(user.id);

            // Refresh the task model
            await taskModel.loadDetails(widget.taskID);

            // Show the task editing dialog
            if (context.mounted) {
              await showDialog<String>(
                context: context,
                builder: (context) => TaskEditingDialog(
                  taskWidget: widget
                ),
              );
            }
          }

          // Display a notification if there was an error
          // and the information about the task could not be loaded
          catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Sorry, there was an error. Please try again."
                  )
                ),
              );
              return;
            }
          }

          // Show a circular progress indicator
          setState(() {
            _isLoading = true;
          });

          try {
            // Update the task list model
            await taskListModel.update(user.id);
            taskListModel.notify();
          }

          // Display a notification if there was an error
          // and the task could not be updated
          catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Sorry, there was an error. Please try again."
                  )
                ),
              );
            }
          }

          // Hide the circular progress indicator
          setState(() {
            _isLoading = false;
          });
        },

        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.width * 0.02
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task name
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w200,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                
                    // Task importance
                    ((importanceVisibilityModel.showImportance)
                    ? Text(
                        "Importance: ${widget.importance}",
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      )
                    : const SizedBox.shrink()),
                
                    // Task deadline or start and end
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)
                            ),
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

              // A circular progress indicator to show that the task is updating
              + (_isLoading
              ? [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.tertiary
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05)
                ]
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

                    // Wait for 1 second while showing the checkbox animation
                    await Future.delayed(const Duration(milliseconds: 1000));
                    taskListModel.remove(widget);  // Remove the task

                    // Remove the task from the user's Google Calendar
                    // if they have linked their Google account
                    if (CalendarClient.calendar != null
                        && widget.googleCalendarEventID != null) {
                      CalendarClient().delete(widget.googleCalendarEventID!);
                    }

                    // Uncheck the checkbox (this prevents the checkbox of the
                    // next task from being checked after this one is removed)
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