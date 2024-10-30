import 'package:app/home/widgets/task_list/filter_button.dart';
import 'package:app/home/widgets/task_list/new_task_dialog.dart';
import 'package:app/home/widgets/task_list/sort_button.dart';
import 'package:app/home/widgets/task_list/task.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key, required this.userID});
  final int userID;
  @override State<StatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the models so that the page can update dynamically
    final taskList = context.watch<TaskListModel>();
    final task = context.watch<TaskModel>();
    final tagList = context.watch<TagListModel>();

    // Filter the tasks with the selected tags
    List<Task> tasksToShow = [];
    // If no tags are selected, show all tasks
    if (!tagList.filtered.containsValue(true)) {
      tasksToShow = taskList.tasks;
    }
    // If some tags are selected, show only the tasks with the selected tags
    else {
      for (int i = 0; i < taskList.tasks.length; ++i) {
        for (int j = 0; j < tagList.tags.length; ++j) {
          if (tagList.filtered[tagList.tags[j].tagID]! && taskList.tasks[i].tags.contains(tagList.tags[j].name)) {
            tasksToShow.add(taskList.tasks[i]);
            break;
          }
        }
      }
    }

    return Column(
      children: [
        // Action bar
        Padding(
          padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height ) * 0.02,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sort button
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  const SortButton(),
                ],
              ),
              
              // Filter button
              Row(
                children: [
                  FilterButton(userID: widget.userID),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await taskList.update(widget.userID),
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: ListView(
              children: [
                // Tasks
                tasksToShow.isEmpty
                ? Padding(
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.05),
                  child: Center(
                    child: Text(
                      "🎉 All done! 🎉",
                      style: TextStyle(
                        fontSize: 30,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                )
                :  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tasksToShow.cast<Widget>(),
                  ),
              ],
            ),
          ),
        ),
        // New task button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.height * 0.02),
          child: Row(
            children: <Widget>[
              // New task button
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;  // Show a circular progress indicator
                  });
                  await tagList.update(widget.userID);  // Update the tag list to show it in the task creation dialog
                  task.clear();
                  setState(() {
                    _isLoading = false;  // Hide the circular progress indicator
                  });

                  // Open the task creation dialog
                  await showDialog<String>(
                    context: context,
                    builder: (context) => NewTaskDialog(userID: widget.userID),
                  );

                  setState(() {
                    _isLoading = true;  // Show a circular progress indicator
                  });
                  await taskList.update(widget.userID);  // Update the task list
                  setState(() {
                    _isLoading = false;  // Hide the circular progress indicator
                  });
                },
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.tertiary,),
                label: Text("ADD", style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ]
            // Circular progress indicator
            + (_isLoading
            ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]
            : []),
          ),
        ),
      ],
    );
  }
}