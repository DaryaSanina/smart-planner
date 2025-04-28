import 'package:app/sign_in/widgets/sign_in_form.dart';
import 'package:app/registration/registration_page.dart';
import 'package:app/sign_in/widgets/google_sign_in.dart';

import 'package:flutter/material.dart';


// Sign in page
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          // Stops the screen from overflowing when the keyboard is shown
          resizeToAvoidBottomInset: false,

          backgroundColor: Theme.of(context).colorScheme.primary,

          body: Column(
            children: [
              // App logo
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: const Image(image: AssetImage('assets/banner.png')),
              ),

              // Sign in form
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: SignInForm(),
                ),
              ),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.03
              ),

              // Google sign in button
              const GoogleSignInButton(),

              // If the user does not have an account yet
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "No account yet?",
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                
                      // Button that navigates the user to the registration
                      // page
                      ElevatedButton(

                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const RegistrationPage();
                            }));
                        },

                        // Button design
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)
                          ),
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          // Button label
                          child: Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              )
            ],
          )
        );
      }
    );
  }
}