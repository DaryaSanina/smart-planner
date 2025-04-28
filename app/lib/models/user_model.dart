import 'package:flutter/material.dart';

// This model represents the user who is currently using the app
class UserModel extends ChangeNotifier {
  int _id = -1;
  get id => _id;
  String _username = "";
  get username => _username;
  String _googleAccountID = "";
  get googleAccountID => _googleAccountID;

  // This method updates the username in the model
  void setUsername(String newUsername) {
    _username = newUsername;
  }

  // This method updates the User ID in the model
  void setID(int newID) {
    _id = newID;
  }

  // This method updates the Google Account ID in the model
  void setGoogleAccountID(String newGoogleAccountID) {
    _googleAccountID = newGoogleAccountID;
  }

  // This method updates all widgets that reference the model to match
  // the data that is currently in the model
  void notify() {
    notifyListeners();
  }
}