import 'package:flutter/material.dart';

class ShowImportanceModel extends ChangeNotifier {
  bool showImportance = false;

  void change(bool newValue) {
    showImportance = newValue;
    notifyListeners();
  }
}