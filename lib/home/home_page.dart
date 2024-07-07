import 'package:flutter/material.dart';
import 'package:app/home/widgets/home_app_bar.dart';
import 'package:app/home/widgets/sort_button.dart';
import 'package:app/home/widgets/filter_button.dart';
import 'package:app/home/widgets/assistant_button.dart';
import 'package:app/home/widgets/task.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> tasks = List.generate(5, (i) => Task(name: "Task $i", date: "No deadline"));
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: const HomeAppBar(),
          body: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                      const SortButton(),
                    ],
                  ),
                  Row(
                    children: [
                      const FilterButton(),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tasks + [Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.01),
                  child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                )],
              ),
            ],
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