import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This model represents whether the user has turned on the setting to be able
// to see task importance levels on the dashboard
class ImportanceVisibilityModel extends ChangeNotifier {

  // When the model is created, this method loads the setting from cache
  ImportanceVisibilityModel() {
    SharedPreferences.getInstance().then((prefs) {
      _showImportance = prefs.getBool('showImportance') ?? false;
      notifyListeners();
    },);
  }

  bool _showImportance = false;
  get showImportance => _showImportance;

  // This method updates the importance visibility setting.
  // [newValue] is a boolean that is true if the user has turned importance
  // visibility on, and false if the user has turned it off.
  void change(bool newValue) {
    // Update the variable
    _showImportance = newValue;

    // Update the cache
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('showImportance', _showImportance);
    },);
    notifyListeners();
  }
}