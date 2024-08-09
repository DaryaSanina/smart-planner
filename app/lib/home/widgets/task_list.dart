import 'package:app/home/widgets/new_task_dialog.dart';
import 'package:app/home/widgets/task.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/home/widgets/filter_button.dart';
import 'package:app/home/widgets/sort_button.dart';
import 'package:app/models/task_list_model.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key, required this.userID});
  final int userID;

  @override
  Widget build(BuildContext context) {
    var taskList = context.watch<TaskListModel>();
    final task = context.watch<TaskModel>();
    final tagList = context.watch<TagListModel>();
    List<Task> tasksToShow = [];
    if (!tagList.filtered.containsValue(true)) {  // If no tags are selected, show all tasks
      tasksToShow = taskList.tasks;
    }
    else {  // If some tags are selected, show only tasks with the selected tags
      for (int i = 0; i < taskList.tasks.length; ++i) {
        for (int j = 0; j < tagList.tags.length; ++j) {
          if (tagList.filtered[tagList.tags[j].tagID]! && taskList.tasks[i].tags.contains(tagList.tags[j].name)) {
            tasksToShow.add(taskList.tasks[i]);
            break;
          }
        }
      }
    }
    return ListView(
      children: [
        Row(
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
                FilterButton(userID: userID),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tasksToShow.cast<Widget>()
          + [Padding(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
            // New task button
            child: IconButton(
              onPressed: () async {
                tagList.update(userID);
                task.clear();
                await showDialog<String>(
                  context: context,
                  builder: (context) => NewTaskDialog(userID: userID),
                );
                taskList.update(userID);
              },
              icon: const Icon(Icons.add),
            ),
          )],
        ),
      ],
    );
  }
}