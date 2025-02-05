import 'package:flutter/material.dart';

// This model represents the user who is currently using the app
class UserModel extends ChangeNotifier {
  int id = -1;
  String username = "";
  String googleAccountID = "";

  // This method updates the username in the model
  void setUsername(String newUsername) {
    username = newUsername;
  }

  // This method updates the User ID in the model
  void setID(int newID) {
    id = newID;
  }

  // This method updates the Google Account ID in the model
  void setGoogleAccountID(String newGoogleAccountID) {
    googleAccountID = newGoogleAccountID;
  }

  // This method updates all widgets that reference the model to match
  // the data that is currently in the model
  void notify() {
    notifyListeners();
  }
}