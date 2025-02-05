import 'package:app/models/message_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A scrollable widget to view the message history
class MessageList extends StatefulWidget {
  const MessageList({super.key});
  @override State<StatefulWidget> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {

  @override
  Widget build(BuildContext context) {
    MessageListModel messageList = context.watch<MessageListModel>();

    return SingleChildScrollView(
      // Start at the bottom of the message list 
      // (where the most recent messages are)
      reverse: true,

      child: Column(
        // Load the message history
        children: List.generate(
          // If the assistant is currently generating a response,
          // increase the number of messages by 1
          // to account for the "Assistant is typing..." message
          messageList.assistantIsGeneratingResponse 
          ? messageList.messages.length + 1 : messageList.messages.length,
          (index) {
            // If the assistant is currently generating a response,
            // show the "Assistant is typing..." message
            if (index == messageList.messages.length) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 1
                    ),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Assistant is typing...",
                          style: TextStyle(
                            color: Color.fromARGB(255, 170, 170, 170)
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            // Show all other messages
            return Align(
              alignment: messageList.messages[index].role == MessageRole.user
              ? Alignment.centerRight : Alignment.centerLeft, 
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 1
                  ),
                  child: Card(
                    color: messageList.messages[index].role == MessageRole.user
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(messageList.messages[index].content),
                    ),
                  ),
                ),
              )
            );
          }
        )
      ),
    );
  }
}