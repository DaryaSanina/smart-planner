import 'package:app/home/widgets/assistant_chat/message_bar.dart';
import 'package:app/home/widgets/assistant_chat/message_list.dart';

import 'package:flutter/material.dart';

// Chatbot screen
class Chat extends StatefulWidget {
  const Chat({super.key});
  @override State<StatefulWidget> createState() => _ChatState();
}

class _ChatState extends State<Chat> {

  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Message history
        Expanded(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: MessageList()
          ),
        ),

        // Message bar with a microphone button, a text box and a send button
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: MessageBar(),
        ),
      ],
    );
  }
}