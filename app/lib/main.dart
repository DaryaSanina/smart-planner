import 'package:app/home/home_page.dart';
import 'package:app/sign_in/sign_in_page.dart';
import 'package:app/models/importance_visibility_model.dart';
import 'package:app/models/message_list_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:app/models/user_model.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  // Ensure that all widgets are initialised
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase for signing in with Google
  await Firebase.initializeApp();

  // Get the local timezone
  tz.initializeTimeZones();

  // Load the user's details from cache
  final prefs = await SharedPreferences.getInstance();
  final int? userID = prefs.getInt('userID');
  final String? username = prefs.getString('username');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskListModel()),
        ChangeNotifierProvider(create: (context) => TaskModel()),
        ChangeNotifierProvider(create: (context) => ImportanceVisibilityModel()),
        ChangeNotifierProvider(create: (context) => TagListModel()),
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) => MessageListModel()),
      ],
      child: App(userID: userID, username: username),
    )
  );
}

class App extends StatefulWidget {
  const App({super.key, this.userID, this.username});

  final int? userID;
  final String? username;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool firstBuild = true;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final messageList = context.watch<MessageListModel>();
    if (firstBuild && widget.userID != null && widget.username != null) {
      firstBuild = false;
      user.setID(widget.userID!);
      user.setUsername(widget.username!);
      messageList.setUserID(widget.userID!);
    }
    else if (firstBuild) {
      firstBuild = false;
    }
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
            foregroundColor: const Color(0xFFFFFFFF),
          ),
        ),
        // Text selection theme
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF000000),
          selectionColor: Color(0xFF7132A3),
        ),
        useMaterial3: true,
      ),

      // Load the home page if the user data (user ID and username) is in the
      // cache, or the login page otherwise
      home: (
        (widget.userID != null && widget.username != null)
        ? HomePage(userID: widget.userID!, username: widget.username!)
        : const SignInPage()
      ),
    );
  }
}
