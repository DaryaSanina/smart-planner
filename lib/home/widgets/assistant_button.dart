import 'package:flutter/material.dart';

class AssistantButton extends StatelessWidget {
  const AssistantButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Icon(Icons.mic, color: Theme.of(context).colorScheme.primary, size: 25,),
    );
  }
}