import 'package:app/models/message_list_model.dart';
import 'package:app/server_interactions.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


// Message bar (with a microphone button, a text box and a send button)
class MessageBar extends StatefulWidget {
  const MessageBar({super.key});
  @override State<StatefulWidget> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> {

  // Create a controller that stores the data in the text message field
  TextEditingController messageController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();

  // This method starts recording sound for speech recognition
  void _startListening() async {
    // If the user has not given permission to use the microphone yet
    if (!_speechToText.isAvailable) {
      // Initialise the voice recognition service
      await _speechToText.initialize();
    }

    // Start recording, with the maximum recording duration of 1 minute
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(minutes: 1)
      );
    } finally {
      setState(() {});
    }
  }

  // This method stops recording sound for speech recofnition
  void _stopListening() async {
    try {
      await _speechToText.stop();
    }
    finally {
      setState(() {});
    }
  }

  // This method is called while performing speech recognition every time a word
  // is recognised. It updates the text in the text message field to match the
  // transcription.
  //
  // [result] is the transcribed sequence of words
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      messageController.text = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Load the list of messages
    MessageListModel messageList = context.watch<MessageListModel>();

    // Microphone and send button design
    ButtonStyle buttonStyle = ButtonStyle(
      shape: WidgetStateProperty.all(const CircleBorder()),
      padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
      backgroundColor: WidgetStateProperty.all(
        Theme.of(context).colorScheme.primary
      ),
      iconColor: WidgetStateProperty.all(
        Theme.of(context).colorScheme.secondary
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Voice message button
        ElevatedButton(
          onPressed:
            _speechToText.isNotListening ? _startListening : _stopListening,
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
            // Text message field design
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 53, 53, 53),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
            cursorColor: Theme.of(context).colorScheme.tertiary,
          ),
        ),

        // Send message button
        ElevatedButton(
          onPressed: () async {
            String content = messageController.text;  // Get the message content
            DateTime timestamp = DateTime.now();  // Get the current timestamp
            if (content == "") {
              return;
            }

            try {
              // Send the message and display it to the user
              await sendMessage(
                content,
                MessageRole.user,
                timestamp,
                messageList.userID
              );
              await messageList.updateMessages();
              messageList.notify();

              // Invoke the LLM and upload its response to the database
              try {
                messageList.setAssistantResponseGenerationStatus(true);
                await invokeLLM(messageList.userID).whenComplete(() async {
                  messageList.setAssistantResponseGenerationStatus(false);
                });
              }
              
              // Send an error message if the LLM has encountered an error
              catch (e) {
                await sendMessage(
                  "Sorry, there was an error. Please try again.",
                  MessageRole.assistant,
                  timestamp,
                  messageList.userID
                );
              }

              // Display the response to the user
              messageList.updateMessages().then((value) => messageList.notify());
              messageList.notify();

              // Clear the text message field
              setState(() {
                messageController.text = "";
              });
            }
            
            // Display a notification if there was an error
            // and the message could not be sent
            catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Sorry, there was an error. Please try again."
                    )
                  ),
                );
              }
              // Clear the text message field
              setState(() {
                messageController.text = "";
              });
            }
          },
          style: buttonStyle,
          child: const Icon(Icons.send),
        ),
      ],
    );
  }
}