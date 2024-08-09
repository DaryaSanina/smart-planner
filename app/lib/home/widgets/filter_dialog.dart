import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterDialog extends StatefulWidget {
  final int userID;
  const FilterDialog({super.key, required this.userID});

  @override State<StatefulWidget> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {

  @override
  Widget build(BuildContext context) {
    final tagList = context.watch<TagListModel>();
    final taskList = context.watch<TaskListModel>();

    return AlertDialog(
      title: const Text("Filter"),

      content: Column(
        children: List.generate(
          tagList.tags.length,
          (i) => CheckboxListTile(
            title: Text(tagList.tags[i].name),
            activeColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            value: tagList.filtered[tagList.tags[i].tagID],
            onChanged: (bool? value) {
              setState(() {
                tagList.updateFilteredValue(tagList.tags[i].tagID, value!);
              });
            },
          )
        ),
      ),

      actions: <Widget>[
        TextButton(
          onPressed: () {
            tagList.resetFilter();
            taskList.refresh();
            Navigator.pop(context);
          },
          child: const Text("Reset"),
        ),
        TextButton(
          onPressed: () {
            taskList.refresh();
            Navigator.pop(context);
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}