import 'package:app/server_interactions.dart';
import 'package:flutter/material.dart';

// A button to generate task importance using an LSTM model
// (the processing is done on a server)
class TaskImportanceGenerationButton extends StatefulWidget{
  const TaskImportanceGenerationButton({
    super.key,
    required this.controller,
    required this.taskName,
    required this.taskDescription
  });

  final TextEditingController controller;
  final String taskName;
  final String taskDescription;

  @override
  State<TaskImportanceGenerationButton> createState() => _TaskImportanceGenerationButtonState();
}

class _TaskImportanceGenerationButtonState
extends State<TaskImportanceGenerationButton> {

  // Indicates whether the server is currently determining the importance level
  // of the task
  bool _importanceIsLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
      ),

      onPressed: () async {
        // Show a linear progress indicator below the button label
        setState(() {
          _importanceIsLoading = true;
        });

        try {
          // Get the importance level prediction
          int newImportance = await getTaskImportancePrediction(
            widget.taskName,
            widget.taskDescription
          );

          widget.controller.text = newImportance.toString();
        }

        // Display a notification if there was an error
        // and task importance could not be predicted
        catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Sorry, there was an error. Please try again."
                )
              ),
            );
          }
        }

        // Hide the linear progress indicator
        setState(() {
          _importanceIsLoading = false;
        });
      },

      child: _importanceIsLoading
      // If _isLoading is true, show a linear progress indicator
      // below the button label
      ? Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Predict importance with AI",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
          SizedBox(
            width: 150,
            height: 3,
            child: LinearProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              color: Theme.of(context).colorScheme.tertiary,
              minHeight: 3,
            )
          ),
        ],
      )
      // Otherwise, just show the button label
      : Text(
        "Predict importance with AI",
        style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
      ),
    );
  }
}