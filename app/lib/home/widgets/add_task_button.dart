import 'package:app/home/widgets/new_task_dialog.dart';
import 'package:flutter/material.dart';

class AddTaskButton extends StatelessWidget {
  const AddTaskButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showDialog<String>(
        context: context,
        builder: (context) => const NewTaskDialog(),
      ),
      icon: const Icon(Icons.add),
    );
  }
}