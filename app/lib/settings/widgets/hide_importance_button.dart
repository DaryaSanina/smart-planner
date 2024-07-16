import 'package:flutter/material.dart';

class HideImportanceButton extends StatelessWidget {
  const HideImportanceButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.visibility_off,
              color: Theme.of(context).colorScheme.tertiary,
              size: 50,
            ),
            Text(
              "Hide task importance",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18)
            ),
            const ImportanceSwitch(),
          ],
        ),
      ),
    );
  }
}

class ImportanceSwitch extends StatefulWidget {
  const ImportanceSwitch({super.key});

  @override
  State<ImportanceSwitch> createState() => _ImportanceSwitchState();
}

class _ImportanceSwitchState extends State<ImportanceSwitch> {
  bool on = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: on,
      activeTrackColor: Theme.of(context).colorScheme.secondary,
      activeColor: Theme.of(context).colorScheme.tertiary,
      onChanged: (bool value) {
        setState(() {
          on = value;
        });
      },
    );
  }
}