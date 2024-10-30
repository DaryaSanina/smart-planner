import 'package:app/home/widgets/task_list/settings_button.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({
    this.appBarHeight = kToolbarHeight,
    super.key,
    required this.userID,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  final double appBarHeight;
  final int userID;

  @override
  Size get preferredSize => Size.fromHeight(appBarHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      surfaceTintColor: const Color.fromARGB(255, 27, 27, 27),
      automaticallyImplyLeading: false,
      title: Text("Hi ${user.username}", style: const TextStyle(fontSize: 24),),
      actions: [
        SettingsButton(userID: widget.userID, username: user.username),
      ],
    );
  }
}