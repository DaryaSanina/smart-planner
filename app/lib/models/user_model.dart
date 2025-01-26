import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  int id = -1;
  String username = "";
  String googleAccountID = "";

  void setUsername(String newUsername) {
    username = newUsername;
  }

  void setID(int newID) {
    id = newID;
  }

  void setGoogleAccountID(String newGoogleAccountID) {
    googleAccountID = newGoogleAccountID;
  }

  void notify() {
    notifyListeners();
  }
}