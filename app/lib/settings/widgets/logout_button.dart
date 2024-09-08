import 'package:app/login/login_page.dart';
import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {  // Log the user out
         Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const LoginPage();
        }));
      },

      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.01),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.account_circle,
              color: Colors.red,
              size: 50,
            ),
            Text(
              "Log out",
              style: TextStyle(color: Colors.red, fontSize: 18)
            ),
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