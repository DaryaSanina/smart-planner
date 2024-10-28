import 'package:app/settings/account_settings/account_settings_page.dart';
import 'package:flutter/material.dart';

class AccountSettingsButton extends StatelessWidget {
  const AccountSettingsButton({
    super.key,
    required this.userID,
    required this.username,
  });
  final int userID;
  final String username;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(

      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return AccountSettingsPage(userID: userID, username: username);
        }));
      },

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
              Icons.account_circle,
              color: Theme.of(context).colorScheme.tertiary,
              size: 50,
            ),
            Text(
              "Account settings",
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 18)
            ),
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