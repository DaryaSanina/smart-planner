import 'package:app/home/widgets/task_list/sort_dialog.dart';
import 'package:flutter/material.dart';

class SortButton extends StatelessWidget {
  const SortButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // When the button is pressed
      onPressed: () async {
        // Show the task sorting dialog
        await showDialog<String>(
          context: context,
          builder: (context) => const SortDialog(),
        );
      },
      
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            color: Theme.of(context).colorScheme.tertiary
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          Text(
            "SORT",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}