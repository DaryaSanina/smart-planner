import 'package:app/models/tag_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A dialog where the user can choose tags so that only tasks with the chosen
// tags will be displayed
class FilteringDialog extends StatefulWidget {
  const FilteringDialog({super.key});

  @override State<StatefulWidget> createState() => _FilteringDialogState();
}

class _FilteringDialogState extends State<FilteringDialog> {

  @override
  Widget build(BuildContext context) {
    // Load the tag list model
    final TagListModel tagList = context.watch<TagListModel>();

    return AlertDialog(
      title: const Text("Filter"),

      content: Column(
        // Show the list of available tags as checkboxes
        children: List.generate(
          tagList.tags.length,
          (i) => CheckboxListTile(
            title: Text(tagList.tags[i].name),

            // Checkbox style
            activeColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)
            ),

            // If the checkbox is checked, the tag is selected
            value: tagList.filtered[tagList.tags[i].tagID],

            // Update the list of chosen tags if the checkbox has been checked
            // or unchecked
            onChanged: (bool? value) {
              // Update the filter
              setState(() {
                tagList.updateFilteredValue(tagList.tags[i].tagID, value!);
              });
            },
          )
        ),
      ),

      actions: <Widget>[
        // Filter reset button (to show all tasks)
        TextButton(
          onPressed: () {
            tagList.resetFilter();  // Empty the filter
            Navigator.pop(context);  // Hide the dialog
          },
          child: const Text("Reset"),
        ),

        // Apply button
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