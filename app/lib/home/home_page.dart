import 'package:app/home/widgets/assistant_button.dart';
import 'package:app/home/widgets/home_app_bar.dart';
import 'package:app/home/widgets/task_list.dart';
import 'package:app/models/task_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.username, required this.userID});

  final String username;
  final int userID;

  @override
  Widget build(BuildContext context) {
    final taskList = context.watch<TaskListModel>();
    final Future<void> loadedTasks = taskList.update(userID);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,

          appBar: HomeAppBar(userID: userID),

          body: FutureBuilder<void>(
            future: loadedTasks,
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.hasData) {
                return TaskList(userID: userID);
              }
              else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red),);
              }
              else {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.tertiary));
              }
            },
          ),
          
          bottomNavigationBar: BottomAppBar(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.43, vertical: 7),
            height: MediaQuery.of(context).size.height * 0.1,
            child: const AssistantButton(),
          ),
        );
      }
    );
  }
}