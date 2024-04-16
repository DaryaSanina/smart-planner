import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({
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
            Icons.filter_alt,
            color: Theme.of(context).colorScheme.tertiary
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          Text(
            "FILTER",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)
          ),
        ],
      ),
    );
  }
}