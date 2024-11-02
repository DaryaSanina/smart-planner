import 'dart:collection';

import 'package:app/models/util.dart';
import 'package:flutter/material.dart';

enum MessageRole { user, assistant }

class Message {
  Message({required this.messageID, required this.content, required this.role});
  int messageID;
  String content;
  MessageRole role;
}

class MessageListModel extends ChangeNotifier {
  int userID = 0;
  List<Message> _messages = [];
  UnmodifiableListView get messages => UnmodifiableListView(_messages);

  Future<void> updateMessages() async {
    _messages.clear();
    _messages = await getMessages(userID);
    notifyListeners();
  }

  void setUserID(int newUserID) {
    userID = newUserID;
    updateMessages();
  }
}