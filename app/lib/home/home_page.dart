import 'package:app/home/widgets/assistant_chat/chat.dart';
import 'package:app/home/widgets/task_list/home_app_bar.dart';
import 'package:app/home/widgets/task_list/task_list.dart';
import 'package:app/models/message_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Home page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Load the user, task list and message list models
    final UserModel user = context.watch<UserModel>();
    final TaskListModel taskList = context.watch<TaskListModel>();
    final MessageListModel messageList = context.watch<MessageListModel>();
    print("build");

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          // Header
          appBar: HomeAppBar(),

          // Main body
          body: [
            // Task list screen
            TaskList(),

            // AI chatbot screen
            FutureBuilder<void>(
              future: messageList.setUserID(user.id),  // Check whether the tasks have loaded
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                // If the messages have loaded, show the chatbot screen
                if (snapshot.hasData) {
                  return Chat();
                }
                // If there was an error, show an error message
                else if (snapshot.hasError) {
                  return Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)
                  );
                }
                // If the messages are being loaded,
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
              await taskList.update(user.id);
            },
          ),
        );
      }
    );
  }
}