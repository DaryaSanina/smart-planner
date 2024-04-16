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
      title: Text("Hi <username>!"),
      actions: [
        IconButton(onPressed: () {}, icon: Icon(Icons.settings))
      ],
    );
  }
  @override
  Size get preferredSize => Size.fromHeight(height);
}