import 'package:app/login/login_page.dart';
import 'package:flutter/material.dart';

import 'package:app/registration/widgets/registration_form.dart';

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
          backgroundColor: Theme.of(context).colorScheme.primary,
          body: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 3,
                child: const Center(
                  child: Text(
                    "Smart Planner",
                    style: TextStyle(
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child: const Center(
                  child: RegistrationForm(),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height / 3 - MediaQuery.of(context).size.height * 0.4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Log in",
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