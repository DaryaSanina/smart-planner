import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String username = "";

  void setUsername(String newUsername) {
    username = newUsername;
  }

  void notify() {
    notifyListeners();
  }
}