import 'package:app/calendar_api.dart';
import 'package:app/home/home_page.dart';
import 'package:app/models/message_list_model.dart';
import 'package:app/models/user_model.dart';
import 'package:app/server_interactions.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

// This function authenticates the user using their Google account
Future<dynamic> signInWithGoogle() async {
  try {
    // Authenticate the user
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/calendar',
      ],
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return (
      await FirebaseAuth.instance.signInWithCredential(credential),
      await googleSignIn.authenticatedClient()
    );
  } on Exception {
    return;
  }
}

// Google Sign-In Button
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Load the user and message list models
    final user = context.watch<UserModel>();
    final messageList = context.watch<MessageListModel>();

    return InkWell(
      onTap: () async {
        // Sign in to Google account
        var (userCredential, client) = await signInWithGoogle();
        String googleIDToken = (await userCredential.user!.getIdToken())!;

        // Identify the user based on their ID token
        List databaseResponse = await getUserByGoogleIDToken(googleIDToken);

        int userID = -1;
        String username = "";

        // Check whether the user exists
        if (databaseResponse.isNotEmpty) {
          // Load the user's client ID into the Google Calendar client
          CalendarClient.calendar = calendar_api.CalendarApi(client!);

          // Load the user's data
          userID = databaseResponse[0][0];
          username = databaseResponse[0][1];

          // Update the user model
          user.setID(userID);
          user.setUsername(username);
          user.setGoogleAccountID(userCredential.user!.uid);

          // Update the message list model
          messageList.setUserID(userID);

          // Show the home page
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return HomePage();
            }));
          }
        }
        else {
          // Display a message asking the user to register first
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Please register and then connect your Google account."
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
                  "https://cdn.iconscout.com/icon/free/png-256"
                  "/free-google-1772223-1507807.png",
                  height: 40,
                  width: 40,
                ),
              ),
              
              const SizedBox(
                width: 10.0,
              ),

              // Button label
              const  Text(
                "Sign In with Google",
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