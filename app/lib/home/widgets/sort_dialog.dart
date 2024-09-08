import 'package:app/models/task_list_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortingType { importance, deadline, ai }

class SortDialog extends StatefulWidget {
  const SortDialog({super.key});

  @override State<StatefulWidget> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  SortingType _sortingType = SortingType.importance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the task list model
    final tasks = context.watch<TaskListModel>();

    return AlertDialog(
      title: const Text("Sort tasks"),

      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.25,
        child: Column(  // Sorting options
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: const Text("by importance"),
              leading: Radio<SortingType>(
                value: SortingType.importance,
                groupValue: _sortingType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (SortingType? value) => setState(() => _sortingType = value!),
              ),
            ),
            ListTile(
              title: const Text("by deadline"),
              leading: Radio<SortingType>(
                value: SortingType.deadline,
                groupValue: _sortingType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (SortingType? value) => setState(() => _sortingType = value!),
              ),
            ),
            ListTile(
              title: const Text("with AI"),
              leading: Radio<SortingType>(
                value: SortingType.ai,
                groupValue: _sortingType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (SortingType? value) => setState(() => _sortingType = value!),
              ),
            ),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),

        // Sort button
        TextButton(
          onPressed: () async {
            setState(() {
              _isLoading = true;  // Show a circular progress indicator
            });

            final prefs = await SharedPreferences.getInstance();

            // Sort by importance
            if (_sortingType == SortingType.importance) {
              tasks.sortByImportance();
              prefs.setString('order', 'importance');  // Update cache
            }
            // Sort by deadline
            if (_sortingType == SortingType.deadline) {
              tasks.sortByDeadline();
              prefs.setString('order', 'deadline');  // Update cache
            }
            // Sort the tasks by importance and deadline
            // by using the K-Means clustering algorithm to divide the tasks into 4 Eisenhower Matrix categories
            // and then arrange them in the following order:
            // important and urgent -> important but not urgent -> urgent but not important -> not important and not urgent
            if (_sortingType == SortingType.ai) {
              await tasks.sortWithAI();
              prefs.setString('order', 'ai');  // Update cache
            }
            tasks.notifyListenersFromOutside();
            setState(() {
              _isLoading = false;  // Hide the circular progress indicator
            });
            if (context.mounted) {
              Navigator.pop(context);  // Hide the dialog
            }
          },
          child: Text("Sort", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ] + (_isLoading
      ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]  // Show a circular progress indicator while the task list is being sorted
      :[]),
    );
  }
}