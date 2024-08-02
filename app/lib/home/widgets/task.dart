import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/models/task_list_model.dart';

class Task extends StatelessWidget {
  final String name;
  final String timings;
  const Task({
    this.name = "Task",
    this.timings = "No deadline",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: MediaQuery.of(context).size.width * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.border_color, size: 20,),
                  ),
                ],
              ),
              Text(
                timings,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              var taskList = context.read<TaskListModel>();
              taskList.remove(this);
            },
            icon: const Icon(Icons.radio_button_unchecked, size: 30,),
          )
        ],
      ),
    );
  }
}