import 'package:app/home/widgets/settings_button.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    this.height = kToolbarHeight,
    super.key,
    required this.username,
  });

  final double height;
  final String username;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text("Hi $username", style: const TextStyle(fontSize: 24),),
      actions: const [
        SettingsButton()
      ],
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}