import 'package:app/models/user_model.dart';
import 'package:app/login/widgets/google_sign_in.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

class LinkGoogleAccountButton extends StatefulWidget {
  const LinkGoogleAccountButton({super.key});

  @override
  State<LinkGoogleAccountButton> createState() => _LinkGoogleAccountButtonState();
}

class _LinkGoogleAccountButtonState extends State<LinkGoogleAccountButton> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();

    return InkWell(
      onTap: () async {
        UserCredential userCredential = await signInWithGoogle();
        String idToken = (await userCredential.user!.getIdToken())!;
        await http.put(Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/link_google_account?user_id=${user.id}&google_id_token=$idToken'));
        user.setGoogleAccountID(userCredential.user!.uid);
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
              const  Text("Link Google Account", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, height: 0),)
            ],
          ),
        ),
      ),
    );
  }
}