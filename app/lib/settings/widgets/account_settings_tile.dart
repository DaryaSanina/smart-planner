import 'package:app/models/user_model.dart';
import 'package:app/settings/account_settings/account_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Account settings tile on the settings page
class AccountSettingsTile extends StatelessWidget {
  const AccountSettingsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Load the user model
    final UserModel user = context.watch<UserModel>();

    return ElevatedButton(
      // Go to the account settings page
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return AccountSettingsPage(username: user.username);
        }));
      },

      // Button design
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
            // Account icon
            Icon(
              Icons.account_circle,
              color: Theme.of(context).colorScheme.tertiary,
              size: 50,
            ),
            
            // Button label
            Text(
              "Account settings",
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 18
              )
            ),

            // Arrow icon
            Icon(
              Icons.keyboard_arrow_right,
              color: Theme.of(context).colorScheme.tertiary,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}