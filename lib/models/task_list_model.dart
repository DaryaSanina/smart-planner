import 'dart:collection';
import 'package:app/home/widgets/task.dart';
import 'package:flutter/material.dart';

class TaskListModel extends ChangeNotifier {
  final List<Widget> _tasks = List.generate(5, (i) => Task(name: "Task $i", date: "No deadline"));
  UnmodifiableListView<Widget> get tasks => UnmodifiableListView(_tasks);

  void add(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void remove(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }
}