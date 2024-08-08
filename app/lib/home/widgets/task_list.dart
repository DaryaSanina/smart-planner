import 'package:app/home/widgets/new_task_dialog.dart';
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
                const FilterButton(),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: taskList.tasks + [Padding(
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