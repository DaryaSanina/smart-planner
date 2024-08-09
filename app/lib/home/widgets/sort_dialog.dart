import 'package:app/models/task_list_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              _isLoading = true;
            });
            // Sort by importance
            if (_sortingType == SortingType.importance) {
              tasks.sortByImportance();
            }
            // Sort by deadline
            if (_sortingType == SortingType.deadline) {
              tasks.sortByDeadline();
            }
            // Sort with K Means clustering into 4 Eisenhower matrix categories
            if (_sortingType == SortingType.ai) {
              await tasks.sortWithAI();
            }
            setState(() {
              _isLoading = false;
            });
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text("Sort", style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        ),
      ] + (_isLoading
      ? [CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary)]
      :[]),
    );
  }
}