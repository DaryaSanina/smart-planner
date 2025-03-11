import 'package:app/registration/widgets/registration_form.dart';
import 'package:flutter/material.dart';

// Registration page
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationState();
}

class _RegistrationState extends State<RegistrationPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(

          // Stops the screen from overflowing when the keyboard is shown
          resizeToAvoidBottomInset: false,

          backgroundColor: Theme.of(context).colorScheme.primary,

          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // App logo
              const SizedBox(
                child: Center(
                  child: Image(image: AssetImage('assets/banner.png')),
                ),
              ),

              // Registration form
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: RegistrationForm(),
                ),
              ),

              // If the user already has an account
              SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    // Button that navigates the user to the login page
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Sign in",
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              )
            ],
          )
        );
      }
    );
  }
}