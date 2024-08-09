import 'package:app/home/widgets/task_editing_dialog.dart';
import 'package:app/models/show_importance_model.dart';
import 'package:app/models/tag_list_model.dart';
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
  final List<String> tags;
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
  });

  @override
  Widget build(BuildContext context) {
    final taskModel = context.watch<TaskModel>();
    final showImportanceModel = context.watch<ShowImportanceModel>();
    final taskListModel = context.watch<TaskListModel>();
    final tagListModel = context.watch<TagListModel>();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width * 0.02),
      child: TextButton(
        onPressed: () async {
          await tagListModel.update(userID);
          await taskModel.getDetails(taskID);
          await showDialog<String>(
            context: context,
            builder: (context) => TaskEditingDialog(userID: userID, taskWidget: this),
          );
          await taskListModel.update(userID);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.width * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
                
                    // Tags
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          tags.length,
                          (i) => Card(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text(tags[i]),
                            )
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Remove task button
              SizedBox(
                child: IconButton(
                  onPressed: () {
                    var taskList = context.read<TaskListModel>();
                    taskList.remove(this);
                  },
                  icon: const Icon(Icons.radio_button_unchecked, size: 30,),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}