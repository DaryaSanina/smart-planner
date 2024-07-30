import 'package:flutter/material.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  const SettingsAppBar({
    this.height = kToolbarHeight,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: const BackButton(),
      title: const Text("Settings", style: TextStyle(fontSize: 24),),
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}