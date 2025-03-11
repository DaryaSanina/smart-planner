import 'package:app/models/importance_visibility_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

// A tile on the settings page that contains the switch that allows the user to
// enable or disable the setting to show task importance levels on the dashboard
class ImportanceVisibilityTile extends StatelessWidget {
  const ImportanceVisibilityTile({
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
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.01
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Show task importance",
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary, fontSize: 18
              )
            ),
            const ImportanceVisibilitySwitch(),
          ],
        ),
      ),
    );
  }
}


// A switch that allows the user to enable or disable the setting to show task
// importance levels on the dashboard
class ImportanceVisibilitySwitch extends StatefulWidget {
  const ImportanceVisibilitySwitch({super.key});

  @override
  State<ImportanceVisibilitySwitch> createState() => _ImportanceVisibilitySwitchState();
}

class _ImportanceVisibilitySwitchState extends State<ImportanceVisibilitySwitch> {
  @override
  Widget build(BuildContext context) {
    // Load the importance visibility model
    final importanceVisibilityModel = context.watch<ImportanceVisibilityModel>();

    return Switch(
      value: importanceVisibilityModel.showImportance,

      activeTrackColor: Theme.of(context).colorScheme.secondary,
      activeColor: Theme.of(context).colorScheme.tertiary,

      // Change task importance visibility
      onChanged: (bool value) {
        importanceVisibilityModel.change(value);
      },
    );
  }
}