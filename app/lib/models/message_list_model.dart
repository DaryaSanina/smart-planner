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
    required this.id,
    required this.content,
    required this.role
  });
  int id;
  String content;
  MessageRole role;
}

// This model represents the conversation history between the user and
// the assistant
class MessageListModel extends ChangeNotifier {
  int _userID = 0;
  get userID => _userID;
  List<Message> _messages = [];
  UnmodifiableListView get messages => UnmodifiableListView(_messages);
  bool _assistantIsGeneratingResponse = false;
  get assistantIsGeneratingResponse => _assistantIsGeneratingResponse;

  // This method updates the message list in the model by requesting them from
  // the server
  Future<void> updateMessages() async {
    _messages.clear();
    _messages = await getMessages(userID);
  }

  // This method updates the ID of the user whose messages the model needs to
  // contain with [newUserID], and then updates the message list.
  Future<bool> setUserID(int newUserID) async {
    _userID = newUserID;
    await updateMessages();
    return true;
  }

  void setAssistantResponseGenerationStatus(bool newValue) {
    _assistantIsGeneratingResponse = newValue;
  }

  void notify() {
    notifyListeners();
  }
}