import 'package:app/home/home_page.dart';
import 'package:flutter/material.dart';

class BackButton extends StatelessWidget {
  const BackButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const HomePage();
        }));
      },
      icon: const Icon(Icons.keyboard_arrow_left)
    );
  }
}