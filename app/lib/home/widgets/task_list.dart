import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/home/widgets/add_task_button.dart';
import 'package:app/home/widgets/filter_button.dart';
import 'package:app/home/widgets/sort_button.dart';
import 'package:app/models/task_list_model.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    var taskList = context.watch<TaskListModel>();
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                const SortButton(),
              ],
            ),
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
            child: const AddTaskButton(),
          )],
        ),
      ],
    );
  }
}