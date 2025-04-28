import 'package:flutter/material.dart';

// Settings page header
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

      // Button to return to the dashboard page or the chat page
      leading: BackButton(),
      
      title: const Text("Settings", style: TextStyle(fontSize: 24),),
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}