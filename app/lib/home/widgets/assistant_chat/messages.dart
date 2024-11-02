import 'package:app/models/message_list_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});
  @override State<StatefulWidget> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {

  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MessageListModel messageList = context.watch<MessageListModel>();

    return Column(
      children: List.generate(
        messageList.messages.length,
        (index) => Align(
          alignment: messageList.messages[index].role == MessageRole.user ? Alignment.centerRight : Alignment.centerLeft, 
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              child: Card(
                color: messageList.messages[index].role == MessageRole.user ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(messageList.messages[index].content),
                ),
              ),
            ),
          )
        )
      )
    );
  }
}