import 'package:app/sign_in/sign_in_page.dart';
import 'package:flutter/material.dart';

// Sign out tile on the settings page
class SignOutTile extends StatelessWidget {
  const SignOutTile({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Sign the user out
      onPressed: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const SignInPage();
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Account icon
            Icon(
              Icons.account_circle,
              color: Colors.red,
              size: 50,
            ),

            // Button label
            Text(
              "Sign out",
              style: TextStyle(color: Colors.red, fontSize: 18)
            ),

            // Sign out icon
            Icon(
              Icons.logout,
              color: Colors.red,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}