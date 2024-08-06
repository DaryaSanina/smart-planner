import 'package:app/home/widgets/task_editing_dialog.dart';
import 'package:app/models/show_importance_model.dart';
import 'package:app/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/models/task_list_model.dart';

class Task extends StatelessWidget {
  final String name;
  final String timings;
  final int userID;
  final int taskID;
  final int importance;
  final DateTime? deadline;
  final DateTime? start;
  final DateTime? end;
  const Task({
    super.key,
    required this.name,
    required this.timings,
    required this.userID,
    required this.taskID,
    required this.importance,
    this.deadline,
    this.start,
    this.end
  });

  @override
  Widget build(BuildContext context) {
    final taskModel = context.watch<TaskModel>();
    final showImportanceModel = context.watch<ShowImportanceModel>();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.02),
      child: TextButton(
        onPressed: () async {
          await taskModel.getDetails(taskID);
          await showDialog<String>(
            context: context,
            builder: (context) => TaskEditingDialog(userID: userID, taskWidget: this),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.width * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task name
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ],
                  ),

                  // Importance
                  ((showImportanceModel.showImportance)
                  ? Text(
                      "Importance: $importance",
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink()),

                  // Timings
                  Text(
                    timings,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Remove task button
              IconButton(
                onPressed: () {
                  var taskList = context.read<TaskListModel>();
                  taskList.remove(this);
                },
                icon: const Icon(Icons.radio_button_unchecked, size: 30,),
              )
            ],
          ),
        ),
      ),
    );
  }
}