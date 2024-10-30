import 'package:app/home/widgets/assistant_chat/chat.dart';
import 'package:app/home/widgets/task_list/home_app_bar.dart';
import 'package:app/home/widgets/task_list/task_list.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

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
    final taskList = context.watch<TaskListModel>();
    final Future<void> loadedTasks = taskList.update(widget.userID);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          // Header
          appBar: HomeAppBar(userID: widget.userID),

          // Main body
          body: [
            // Task list view
            FutureBuilder<void>(
              future: loadedTasks,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.hasData) {
                  return TaskList(userID: widget.userID);
                }
                else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red),);
                }
                else {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary));
                }
              },
            ),

            // AI chatbot view
            Chat(),

            // Calendar view
            SizedBox(),

          ][_selectedPageIndex],
          
          // Bottom navigation bar
          bottomNavigationBar: NavigationBar(
            animationDuration: Duration(milliseconds: 1000),
            backgroundColor: Theme.of(context).colorScheme.primary,
            surfaceTintColor: const Color.fromARGB(255, 27, 27, 27),
            destinations: [
              NavigationDestination(
                selectedIcon: Icon(Icons.checklist, color: Theme.of(context).colorScheme.tertiary),
                icon: const Icon(Icons.checklist),
                label: "List",
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.chat_outlined, color: Theme.of(context).colorScheme.tertiary),
                icon: const Icon(Icons.chat_outlined),
                label: "AI",
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.tertiary),
                icon: const Icon(Icons.calendar_month_outlined),
                label: "Calendar",
              ),
            ],
            indicatorColor: Theme.of(context).colorScheme.secondary,
            selectedIndex: _selectedPageIndex,
            onDestinationSelected: (index) => setState(() {_selectedPageIndex = index;}),  // When an item is tapped, set the page index to the selected value and update the page
          ),
        );
      }
    );
  }
}