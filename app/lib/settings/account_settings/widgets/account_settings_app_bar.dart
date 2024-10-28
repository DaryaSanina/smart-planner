import 'package:flutter/material.dart';

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
      leading: const BackButton(),
      title: const Text("Account Settings", style: TextStyle(fontSize: 24),),
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}