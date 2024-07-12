import 'package:app/home/widgets/task_list.dart';
import 'package:flutter/material.dart';
import 'package:app/home/widgets/home_app_bar.dart';
import 'package:app/home/widgets/assistant_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: const HomeAppBar(),
          body: TaskList(),
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