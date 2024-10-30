import 'package:app/home/widgets/assistant_chat/message_bar.dart';
import 'package:flutter/material.dart';

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
        Expanded(
          child: SizedBox(height: MediaQuery.of(context).size.height * 0.8),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: MessageBar(),
        ),
      ],
    );
  }
}