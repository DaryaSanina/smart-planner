import 'package:app/home/widgets/assistant_chat/chat.dart';
import 'package:app/home/widgets/task_list/home_app_bar.dart';
import 'package:app/home/widgets/task_list/task_list.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Home page
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.username, required this.userID});

  final String username;
  final int userID;

  @override State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPageIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Load the task list model
    final taskList = context.watch<TaskListModel>();

    // Load the tasks from the database and update the task list model
    final Future<void> loadedTasks = taskList.update(widget.userID);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          // Header
          appBar: HomeAppBar(userID: widget.userID),

          // Main body
          body: [
            // Task list screen
            FutureBuilder<void>(
              future: loadedTasks,  // Check whether the tasks have loaded
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                // If the tasks have loaded, show the task list screen
                if (snapshot.hasData) {
                  return TaskList(userID: widget.userID);
                }
                // If there was an error, show an error message
                else if (snapshot.hasError) {
                  return Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)
                  );
                }
                // If the tasks are being loaded,
                // show a circular progress indicator
                else {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.tertiary
                    )
                  );
                }
              },
            ),

            // AI chatbot screen
            const Chat(),

          ][_selectedPageIndex],
          
          // Bottom navigation bar
          bottomNavigationBar: NavigationBar(
            animationDuration: const Duration(milliseconds: 1000),
            backgroundColor: Theme.of(context).colorScheme.primary,
            surfaceTintColor: const Color.fromARGB(255, 27, 27, 27),

            destinations: [
              // Task list destination
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.checklist,
                  color: Theme.of(context).colorScheme.tertiary
                ),
                icon: const Icon(Icons.checklist),
                label: "List",
              ),

              // AI chatbot destination
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.chat_outlined,
                  color: Theme.of(context).colorScheme.tertiary
                ),
                icon: const Icon(Icons.chat_outlined),
                label: "AI",
              ),
            ],
            indicatorColor: Theme.of(context).colorScheme.secondary,
            selectedIndex: _selectedPageIndex,

            // When a destination is tapped on,
            // set the page index to the selected value and update the page
            onDestinationSelected: (index) async {
              setState(() {_selectedPageIndex = index;});
              await taskList.update(widget.userID);
            },
          ),
        );
      }
    );
  }
}