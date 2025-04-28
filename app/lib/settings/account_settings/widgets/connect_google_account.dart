import 'package:app/calendar_api.dart';
import 'package:app/models/user_model.dart';
import 'package:app/server_interactions.dart';
import 'package:app/sign_in/widgets/google_sign_in.dart';

import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

class ConnectGoogleAccountButton extends StatelessWidget {
  const ConnectGoogleAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Load the user model
    final user = context.watch<UserModel>();

    return InkWell(
      onTap: () async {
        try {
          // Connect a Google account
          var (userCredential, client) = await signInWithGoogle();
          String googleIDToken = (await userCredential.user!.getIdToken())!;

          // Load the user's client ID into the Google Calendar client
          CalendarClient.calendar = calendar_api.CalendarApi(client!);

          // Add the ID token to the database
          await connectGoogleAccount(user.id, googleIDToken);

          // Update the user model
          user.setGoogleAccountID(userCredential.user!.uid);
        }
        
        // Display a notification if there was an error
        // and a Google account has not been connected
        catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Sorry, there was an error. Please try again."
                )
              ),
            );
          }
        }
      },

      // Button design
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.075,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: Colors.black.withValues(alpha: 0.2)
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 30,
                width: 30,

                // Google logo
                child: Image.network(
                  "https://cdn.iconscout.com/icon/free/png-256/"
                  "free-google-1772223-1507807.png",
                  height: 40,
                  width: 40,
                ),
              ),

              // Button label
              const SizedBox(
                width: 10.0,
              ),
              const Text(
                "Connect Google Account",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 0
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}