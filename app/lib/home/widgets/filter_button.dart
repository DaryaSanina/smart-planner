import 'package:app/home/widgets/filter_dialog.dart';
import 'package:app/models/tag_list_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class FilterButton extends StatelessWidget {
  final int userID;
  const FilterButton({
    super.key,
    required this.userID
  });

  @override
  Widget build(BuildContext context) {
    final tagList = context.watch<TagListModel>();
    return ElevatedButton(
      // When the button is pressed
      onPressed: () async {
        tagList.update(userID);  // Update the tag list
        // Show the task filtering dialog
        await showDialog<String>(
          context: context,
          builder: (context) => FilterDialog(userID: userID),
        );
      },
      
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            color: Theme.of(context).colorScheme.tertiary
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          Text(
            "FILTER",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}