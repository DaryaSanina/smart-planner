import 'dart:collection';
import 'package:app/server_interactions.dart';
import 'package:flutter/material.dart';

// This enum has three message role types:
//  - user (if the message was sent by a user)
//  - assistant (if the message was sent by the assistant)
//  - tool (if the message is a response from the database)
enum MessageRole { user, assistant, tool }

// This class represents a message in the chat with the assistant
class Message {
  Message({
    required this.messageID,
    required this.content,
    required this.role
  });
  int messageID;
  String content;
  MessageRole role;
}

// This model represents the conversation history between the user and
// the assistant
class MessageListModel extends ChangeNotifier {
  int userID = 0;
  List<Message> _messages = [];
  UnmodifiableListView get messages => UnmodifiableListView(_messages);
  bool assistantIsGeneratingResponse = false;

  // This method updates the message list in the model by requesting them from
  // the server
  Future<void> updateMessages() async {
    _messages.clear();
    _messages = await getMessages(userID);
    notifyListeners();
  }

  // This method updates the ID of the user whose messages the model needs to
  // contain with [newUserID], and then updates the message list.
  void setUserID(int newUserID) {
    userID = newUserID;
    updateMessages();
  }
}