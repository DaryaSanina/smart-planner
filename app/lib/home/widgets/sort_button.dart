import 'package:flutter/material.dart';

class SortButton extends StatelessWidget {
  const SortButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reorder,
            color: Theme.of(context).colorScheme.tertiary
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          Text(
            "SORT",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}