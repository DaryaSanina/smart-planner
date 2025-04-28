import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderType { importance, deadline, ai }

// A dialog where the user can choose the order in which the tasks appear
// in the task list
class SortingDialog extends StatefulWidget {
  const SortingDialog({super.key});

  @override State<StatefulWidget> createState() => _SortingDialogState();
}

class _SortingDialogState extends State<SortingDialog> {
  OrderType _orderType = OrderType.importance;

  // Indicates whether the tasks are currently being sorted
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Load the task list
    final tasks = context.watch<TaskListModel>();

    return AlertDialog(
      title: const Text("Sort tasks"),

      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.25,
        child: Column(
          // Task order options
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: const Text("by importance"),
              leading: Radio<OrderType>(
                value: OrderType.importance,
                groupValue: _orderType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (OrderType? value) => setState(
                  () => _orderType = value!
                ),
              ),
            ),
            ListTile(
              title: const Text("by deadline"),
              leading: Radio<OrderType>(
                value: OrderType.deadline,
                groupValue: _orderType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (OrderType? value) => setState(
                  () => _orderType = value!
                ),
              ),
            ),
            ListTile(
              title: const Text("with AI"),
              leading: Radio<OrderType>(
                value: OrderType.ai,
                groupValue: _orderType,
                activeColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (OrderType? value) => setState(
                  () => _orderType = value!
                ),
              ),
            ),
          ],
        ),
      ),

      actions: <Widget>[
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),  // Hide the dialog
          child: Text(
            "Cancel",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),

        // Sort button
        TextButton(
          onPressed: () async {
            // Show a circular progress indicator
            setState(() {
              _isLoading = true;
            });
            
            try {
              // Load the current task order type from cache
              final prefs = await SharedPreferences.getInstance();

              // Sort by importance
              if (_orderType == OrderType.importance) {
                tasks.sortByImportance();
                prefs.setString('order', 'importance');  // Update cache
              }
              // Sort by deadline
              if (_orderType == OrderType.deadline) {
                tasks.sortByDeadline();
                prefs.setString('order', 'deadline');  // Update cache
              }

              // Sort the tasks by importance and deadline by using the K-Means
              // clustering algorithm to divide the tasks into four Eisenhower
              // Matrix categories and then arrange them in the following order:
              // important and urgent -> important but not urgent
              // -> urgent but not important -> not important and not urgent
              if (_orderType == OrderType.ai) {
                if (context.mounted && tasks.tasks.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "There should be at least 4 tasks"
                      )
                    ),
                  );
                }
                await prefs.setString('order', 'ai');  // Update cache
                await tasks.sortWithAI();
              }
              tasks.notify();
            }

            // Display a notification if there was an error
            // and the tasks could not be sorted
            catch (e) {}

            // Hide the circular progress indicator
            setState(() {
              _isLoading = false;
            });

            if (context.mounted) {
              Navigator.pop(context);  // Hide the dialog
            }
          },
          child: Text(
            "Sort",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ),
      ]

      // Show a circular progress indicator while the task list is being sorted
      + (_isLoading
      ? [CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary
        )]
      :[]),
    );
  }
}