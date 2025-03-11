import 'package:app/home/widgets/task_list/filtering_button.dart';
import 'package:app/home/widgets/task_list/new_task_button.dart';
import 'package:app/home/widgets/task_list/sorting_button.dart';
import 'package:app/home/widgets/task_list/task_widget.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A widget that shows the sorting button, the filtering button
// and the task list
class TaskList extends StatefulWidget {
  const TaskList({super.key});
  @override State<StatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {

  @override
  Widget build(BuildContext context) {
    // Load the user, task list and tag list models
    // so that the page can update dynamically
    final UserModel user = context.watch<UserModel>();
    final TaskListModel taskList = context.watch<TaskListModel>();
    final TagListModel tagList = context.watch<TagListModel>();

    // Filter the tasks with the selected tags
    List<TaskWidget> tasksToShow = [];
    // If no tags are selected, show all tasks
    if (!tagList.filtered.containsValue(true)) {

      // Ensure that all tasks are included only once
      Set<String> taskNames = {};
      for (TaskWidget task in taskList.tasks) {
        // Check whether the task has already been added and, if not add it to
        // the list of tasks and add its name to the set of task names
        if (!taskNames.contains(task.name)) {
          tasksToShow.add(task);
          taskNames.add(task.name);
        }
      }
    }
    // If some tags are selected, show only the tasks with the selected tags
    else {
      // Ensure that all tasks are included only once
      Set<String> taskNames = {};

      for (int i = 0; i < taskList.tasks.length; ++i) {
        for (int j = 0; j < tagList.tags.length; ++j) {
          if (tagList.filtered[tagList.tags[j].tagID]!
              && taskList.tasks[i].tags.contains(tagList.tags[j].name)) {

            // Check whether the task has already been added and, if not add it
            // to the list of tasks and add its name to the set of task names
            if (!taskNames.contains(taskList.tasks[i].name)) {
              taskNames.add(taskList.tasks[i].name);
              tasksToShow.add(taskList.tasks[i]);
            }
            break;
          }
        }
      }
    }

    return Column(
      children: [
        // Action bar
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.02
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sorting button
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  const SortingButton(),
                ],
              ),
              
              // Filtering button
              Row(
                children: [
                  FilteringButton(),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              taskList.update(user.id, notifyListenersBoolean: true);
            },
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).colorScheme.tertiary,

            // Task list
            child: ListView(
              children: [
                tasksToShow.isEmpty

                // If there are no tasks, congratulate the user
                ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.05
                  ),
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

                // Otherwise, show the tasks
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasksToShow.cast<Widget>(),
                ),
              ],
            ),
          ),
        ),

        // New task button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.03,
            vertical: MediaQuery.of(context).size.height * 0.02
          ),
          child: NewTaskButton(),
        ),
      ],
    );
  }
}