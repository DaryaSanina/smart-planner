import 'package:app/models/tag_list_model.dart';

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
    // Load the tag list model
    final tagList = context.watch<TagListModel>();

    return AlertDialog(
      title: const Text("Filter"),

      content: Column(
        // Show all the available tags as checkboxes
        children: List.generate(
          tagList.tags.length,
          (i) => CheckboxListTile(
            title: Text(tagList.tags[i].name),
            activeColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            value: tagList.filtered[tagList.tags[i].tagID],
            onChanged: (bool? value) {
              setState(() {
                tagList.updateFilteredValue(tagList.tags[i].tagID, value!);  // Update the filter
              });
            },
          )
        ),
      ),

      actions: <Widget>[
        TextButton(
          onPressed: () {
            tagList.resetFilter();  // Empty the filter
            Navigator.pop(context);  // Hide the dialog
          },
          child: const Text("Reset"),
        ),

        TextButton(
          onPressed: () {
            Navigator.pop(context);  // Hide the dialog
          },
          child: const Text("Apply"),
        ),
      ],
    );
  }
}