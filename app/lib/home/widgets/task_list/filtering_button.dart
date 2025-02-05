import 'package:app/home/widgets/task_list/filtering_dialog.dart';
import 'package:app/models/tag_list_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// A button that opens the task filtering dialog where the user can choose tags
// so that only tasks with the chosen tags will be displayed
class FilteringButton extends StatelessWidget {
  final int userID;
  const FilteringButton({
    super.key,
    required this.userID
  });

  @override
  Widget build(BuildContext context) {
    final tagList = context.watch<TagListModel>();  // Load the list of tags
    return ElevatedButton(
      onPressed: () async {
        tagList.update(userID);  // Refresh the list of tags
        await showDialog<String>(  // Show the task filtering dialog
          context: context,
          builder: (context) => FilteringDialog(userID: userID),
        );
      },
      
      // Button style
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      child: Row(
        children: [
          // Filter icon
          Icon(
            Icons.filter_alt,
            color: Theme.of(context).colorScheme.tertiary
          ),

          SizedBox(width: MediaQuery.of(context).size.width * 0.01),

          // Button label
          Text(
            "FILTER",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}