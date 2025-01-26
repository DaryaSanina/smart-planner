import 'dart:convert';

import 'package:app/calendar_api.dart';
import 'package:app/home/home_page.dart';
import 'package:app/models/message_list_model.dart';
import 'package:app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

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

    // Load the user's client ID into the Google Calendar client
    final client = await googleSignIn.authenticatedClient();
    CalendarClient.calendar = calendar_api.CalendarApi(client!);

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } on Exception catch (e) {
    // TODO
    print('exception->$e');
  }
}

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final messageList = context.watch<MessageListModel>();

    return InkWell(
      onTap: () async {
        // Sign in
        UserCredential userCredential = await signInWithGoogle();
        String idToken = (await userCredential.user!.getIdToken())!;
        http.Response response = await http.get(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_user?google_id_token=$idToken'));
        var jsonResponse = jsonDecode(response.body);

        int userID = -1;
        String username = "";

        // Check whether the user exists
        if (jsonResponse['data'].length != 0) {
          // Load the user's data
          userID = jsonResponse['data'][0][0];
          username = jsonResponse['data'][0][1];

          // Update the user model
          user.setID(userID);
          user.setUsername(username);
          user.setGoogleAccountID(userCredential.user!.uid);

          // Update the message list model
          messageList.setUserID(userID);

          // Show the home page
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return HomePage(username: username, userID: userID);
            }));
          }
        }
        else {
          // Display a message asking the user to register first
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please register and then link your Google account.")),
          );
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.075,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
                color: Colors.black.withOpacity(0.2)
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
                child: Image.network(
                  "https://cdn.iconscout.com/icon/free/png-256/free-google-1772223-1507807.png",
                  height: 40,
                  width: 40,
                ),
              ),
              const SizedBox(
                width: 10.0,
              ),
              const  Text("Sign In with Google", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, height: 0),)
            ],
          ),
        ),
      ),
    );
  }
}