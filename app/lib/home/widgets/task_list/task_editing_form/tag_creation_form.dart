import 'package:app/models/tag_list_model.dart';
import 'package:app/server_interactions.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A form which the user can fill in to add a new tag
class TagCreationForm extends StatefulWidget{
  const TagCreationForm({
    super.key,
    required this.userID,
    required this.tagNameController
  });

  final int userID;
  final TextEditingController tagNameController;

  @override
  State<TagCreationForm> createState() => _TagCreationFormState();
}

class _TagCreationFormState extends State<TagCreationForm> {
  
  // Indicates whether the database server is currently processing
  // a tag creation request
  bool _isLoadingTag = false;

  @override
  Widget build(BuildContext context) {
    TagListModel tagList = context.watch<TagListModel>();

    return Row(
      children: [
        IconButton(
          onPressed: () async {
            // Check whether the name of the tag has between 3 and 32 characters
            if (widget.tagNameController.text.length >= 3
                && widget.tagNameController.text.length <= 32) {
              // Show a circular progress indicator
              setState(() {
                _isLoadingTag = true;
              });

              try {
                // Add the tag to the database
                await addTag(widget.tagNameController.text, widget.userID);

                // Update the the tag list model
                tagList.update(widget.userID);
              }

              // Display a notification if there was an error
              // and the tag could not be created
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

              // Hide the circular progress indicator
              setState(() {
                _isLoadingTag = false;
              });
            }
            else {
              // Show the user a notification
              // saying that the tag name is incorrect
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Tag name should be between 3 and 32 characters long."
                  )
                ),
              );
            }
          },
          icon: const Icon(Icons.add),
        ),

        // New tag name input field
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          height: 50,
          child: TextField(
            controller: widget.tagNameController,
            decoration: const InputDecoration(
              hintText: "Add a new tag",
            ),
            cursorColor: Theme.of(context).colorScheme.tertiary,
            onChanged: (text) => setState(
              () => widget.tagNameController.text = text
            ),
          ),
        ),
      ]

      // Show a circular progress indicator while the new tag is being created
      + (_isLoadingTag
      ? [CircularProgressIndicator(
          color: Theme.of(context).colorScheme.tertiary
        )]
      : []),
    );
  }
}