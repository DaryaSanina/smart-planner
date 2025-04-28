import 'package:flutter/material.dart';

// Account settings page header
class AccountSettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  const AccountSettingsAppBar({
    this.height = kToolbarHeight,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      // Button to return to the main settings page
      leading: const BackButton(),

      title: const Text("Account Settings", style: TextStyle(fontSize: 24)),
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}