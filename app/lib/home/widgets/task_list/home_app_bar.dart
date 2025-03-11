import 'package:app/home/widgets/task_list/settings_button.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Header for the chat and dashboard pages
class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({
    this.height = kToolbarHeight,
    super.key,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _HomeAppBarState extends State<HomeAppBar> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();  // Load the user's data
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      surfaceTintColor: const Color.fromARGB(255, 27, 27, 27),
      automaticallyImplyLeading: false,

      // Greet the user with the text displayed on the app bar
      title: Text(
        "Hi ${user.username}",
        style: const TextStyle(fontSize: 24, overflow: TextOverflow.ellipsis)
      ),

      actions: [
        SettingsButton(),
      ],
    );
  }
}