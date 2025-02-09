import 'package:app/home/widgets/task_list/new_task_dialog.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A button that opens the task creation dialog
class NewTaskButton extends StatefulWidget {
  const NewTaskButton({super.key, required this.userID});

  final int userID;

  @override
  State<NewTaskButton> createState() => _NewTaskButtonState();
}

class _NewTaskButtonState extends State<NewTaskButton> {
  // Indicates that the database server is currently processing a request to
  // load the user's tags so that they can be shown in the task creation dialog
  bool _tagListIsUpdating = false;

  // Indicates that the task list is currently being updated
  bool _taskListIsUpdating = false;

  @override
  Widget build(BuildContext context) {
    // Load the task, task list and tag list models
    // so that the page can update dynamically
    TaskModel task = context.watch<TaskModel>();
    TaskListModel taskList = context.watch<TaskListModel>();
    TagListModel tagList = context.watch<TagListModel>();

    return Row(
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: () async {
            // Show a circular progress indicator
            setState(() {
              _tagListIsUpdating = true;
            });

            try {
              // Update the tag list to show it in the task creation dialog
              await tagList.update(widget.userID);

              // Reset the task model
              task.clear();
            }

            // Display a notification if there was an error
            // and the tags could not be loaded
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
              _tagListIsUpdating = false;
            });

            // Open the task creation dialog
            if (context.mounted) {
              await showDialog<String>(
                context: context,
                builder: (context) => NewTaskDialog(userID: widget.userID),
              );
            }

            // Show a circular progress indicator
            setState(() {
              _taskListIsUpdating = true;
            });

            try {
              await taskList.update(widget.userID);  // Update the task list
              taskList.notify();
            }

            // Display a notification if there was an error
            // and the task list could not be loaded
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
              _taskListIsUpdating = false;
            });
          },

          icon: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.tertiary
          ),
          label: Text(
            "ADD",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ]

      // Show a circular progress indicator while the tasks or the tags are
      // being updated
      + (_tagListIsUpdating || _taskListIsUpdating
      ? [CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary
        )]
      : []),
    );
  }
}