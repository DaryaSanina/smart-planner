import 'package:app/home/widgets/task_list/task_editing_form/tag_creation_form.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_date_picker.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_description_field.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_importance_dropdown_menu.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_importance_generation_button.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_name_field.dart';
import 'package:app/home/widgets/task_list/task_editing_form/task_time_picker.dart';
import 'package:app/home/widgets/task_list/task_editing_form/deadline_vs_start_and_end_picker.dart';
import 'package:app/home/widgets/task_list/task_editing_form/reminder_list.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// A form that the user can fill in to create or edit a task
class TaskDetailsForm extends StatefulWidget {
  const TaskDetailsForm({
    super.key,
    required this.formKey,
    required this.taskNameController,
    required this.taskDescriptionController,
    required this.taskImportanceController
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController taskNameController;
  final TextEditingController taskDescriptionController;
  final TextEditingController taskImportanceController;

  @override State<StatefulWidget> createState() => _TaskDetailsFormState();
}

class _TaskDetailsFormState extends State<TaskDetailsForm>{

  final TextEditingController newTagNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Load the task and tag list models so that the page can update dynamically
    final TaskModel task = context.watch<TaskModel>();
    final TagListModel tagList = context.watch<TagListModel>();

    return Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskNameField(controller: widget.taskNameController),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            TaskDescriptionField(controller: widget.taskDescriptionController),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            TaskImportanceDropdownMenu(
              controller: widget.taskImportanceController
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.03),

            // A button to generate task importance using an LSTM model
            // (the processing is done on a server)
            TaskImportanceGenerationButton(
              taskImportanceController: widget.taskImportanceController,
              taskNameController: widget.taskNameController,
              taskDescriptionController: widget.taskDescriptionController
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // A list of two radio checkboxes to choose whether the task has
            // a deadline or a start and an end
            const Text("Time constraints", style: TextStyle(fontSize: 18)),
            const DeadlineVsStartAndEndPicker(),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Date and time pickers
            Container(
              child: task.hasDeadline
                // Deadline date and time picker
                ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: [
                        const Text(
                          "Deadline: ",
                          style: TextStyle(fontSize: 18)
                        ),
                        TaskDatePicker(
                          dateSetter: task.setDeadlineDate,
                          dateGetter: task.deadlineDate
                        ),
                        TaskTimePicker(
                          timeSetter: task.setDeadlineTime,
                          timeGetter: task.deadlineTime
                        )
                      ],
                    ),
                )
              
              // Start and end date and time pickers
              : Column(
                children: [
                  // Start date and time picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("Start: ", style: TextStyle(fontSize: 18)),
                        TaskDatePicker(
                          dateSetter: task.setStartDate,
                          dateGetter: task.startDate
                        ),
                        TaskTimePicker(
                          timeSetter: task.setStartTime,
                          timeGetter: task.startTime
                        )
                      ],
                    ),
                  ),

                  // End date and time picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("End: ", style: TextStyle(fontSize: 18)),
                        TaskDatePicker(
                          dateSetter: task.setEndDate,
                          dateGetter: task.endDate
                        ),
                        TaskTimePicker(
                          timeSetter: task.setEndTime,
                          timeGetter: task.endTime
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Reminders for the new task
            const Text("Reminders", style: TextStyle(fontSize: 18)),
            const ReminderList(),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // List of tags for the new task
            const Text("Tags", style: TextStyle(fontSize: 18)),
            Column(
              // Show the list of available tags as checkboxes
              children: List.generate(
                tagList.tags.length,

                (i) => CheckboxListTile(
                  title: Text(
                    tagList.tags[i].name,
                    overflow: TextOverflow.ellipsis
                  ),

                  // Checkbox style
                  activeColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)
                  ),

                  // If the checkbox is checked, the tag is selected
                  value: task.tags.contains(tagList.tags[i].tagID),

                  // Update the list of chosen tags in the task model
                  // if the checkbox has been checked or unchecked
                  onChanged: (bool? value) {
                    if (value!) {
                      setState(() {
                        task.addTag(tagList.tags[i].tagID);
                      });
                    }
                    else {
                      setState(() {
                        task.removeTag(tagList.tags[i].tagID);
                      });
                    }
                  },
                )
              ),
            ),
            
            // Form to add a new tag
            TagCreationForm(
              tagNameController: newTagNameController
            )
          ],
        ),
      );
  }
}