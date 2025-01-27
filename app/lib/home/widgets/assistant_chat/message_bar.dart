import 'package:app/home/widgets/assistant_chat/util.dart';
import 'package:app/models/message_list_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class MessageBar extends StatefulWidget {
  const MessageBar({super.key});
  @override State<StatefulWidget> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> {
  TextEditingController messageController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();

  void _startListening() async {
    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }
    print("Listening");
    await _speechToText.listen(onResult: _onSpeechResult, listenFor: Duration(minutes: 1));
    print("Finished listening");
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      messageController.text = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    MessageListModel messageList = context.watch<MessageListModel>();

    ButtonStyle buttonStyle = ButtonStyle(
      shape: WidgetStateProperty.all(const CircleBorder()),
      padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
      backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
      iconColor: WidgetStateProperty.all(Theme.of(context).colorScheme.secondary),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Voice message button
        ElevatedButton(
          onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
          style: buttonStyle,
          child: const Icon(Icons.mic_outlined),
        ),

        // Text message field
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: TextField(
            controller: messageController,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 53, 53, 53),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            cursorColor: Theme.of(context).colorScheme.tertiary,
          ),
        ),

        // Send message button
        ElevatedButton(
          onPressed: () async {
            // Get the message content
            String content = messageController.text;

            // Get the current timestamp
            DateTime timestamp = DateTime.now();

            // Send the message and display it to the user
            await sendMessage(content, MessageRole.user, timestamp, messageList.userID);

            // Invoke the LLM, then upload its response to the database and display it to the user
            messageList.assistantIsGeneratingResponse = true;
            invokeLLM(messageList.userID).whenComplete(() async {
              await messageList.updateMessages();
              messageList.assistantIsGeneratingResponse = false;
            });

            await messageList.updateMessages();

            setState(() {
              messageController.text = "";
            });
          },
          style: buttonStyle,
          child: const Icon(Icons.send),
        ),
      ],
    );
  }
}