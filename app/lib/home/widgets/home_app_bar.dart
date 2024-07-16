import 'package:app/home/widgets/settings_button.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  const HomeAppBar({
    this.height = kToolbarHeight,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: const Text("Hi <username>!", style: TextStyle(fontSize: 24),),
      actions: const [
        SettingsButton()
      ],
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}