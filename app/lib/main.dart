import 'package:app/home/home_page.dart';
import 'package:app/login/login_page.dart';
import 'package:app/models/importance_visibility_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/task_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  // Load the user data from cache
  final prefs = await SharedPreferences.getInstance();
  final int? userID = prefs.getInt('userID');
  final String? username = prefs.getString('username');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskListModel()),
        ChangeNotifierProvider(create: (context) => TaskModel()),
        ChangeNotifierProvider(create: (context) => ShowImportanceModel()),
        ChangeNotifierProvider(create: (context) => TagListModel()),
      ],
      child: MyApp(userID: userID, username: username),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.userID, this.username});

  final int? userID;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Planner',
      debugShowCheckedModeBanner: false,
      // App theme
      theme: ThemeData(
        // Colour scheme
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF292929),
          primaryContainer: const Color(0xFF3D3D3D),
          onPrimary: const Color(0xFFFFFFFF),
          inversePrimary: const Color(0xFF7132A3),
          secondary: const Color(0xFF7132A3),
          tertiary: const Color(0xFFFFFFFF),
        ),
        // Text button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),  // Text button text colour
          ),
        ),
        // Text selection theme
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF000000),
          selectionColor: Color(0xFF7132A3),
        ),
        useMaterial3: true,
      ),

      // Load the home page if the user data (user ID and username) is in the cache, or the login page otherwise
      home: ((userID != null && username != null) ? HomePage(userID: userID!, username: username!) : const LoginPage()),
    );
  }
}
