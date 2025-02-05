import 'package:app/home/widgets/task_list/sorting_dialog.dart';
import 'package:flutter/material.dart';

// A button that opens the task sorting dialog where the user can choose the
// order in which the tasks appear in the task list
class SortingButton extends StatelessWidget {
  const SortingButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Show the task sorting dialog
        await showDialog<String>(
          context: context,
          builder: (context) => const SortingDialog(),
        );
      },
      
      // Button style
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      child: Row(
        children: [
          // Soting icon
          Icon(
            Icons.sort,
            color: Theme.of(context).colorScheme.tertiary
          ),

          SizedBox(width: MediaQuery.of(context).size.width * 0.01),

          // Button label
          Text(
            "SORT",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}