import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowImportanceModel extends ChangeNotifier {
  ShowImportanceModel() {
    SharedPreferences.getInstance().then((prefs) {
      showImportance = prefs.getBool('showImportance') ?? false;
      notifyListeners();
    },);
  }

  bool showImportance = false;

  void change(bool newValue) {
    showImportance = newValue;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('showImportance', showImportance);
    },);
    notifyListeners();
  }
}