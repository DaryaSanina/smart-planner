import 'package:app/models/show_importance_model.dart';
import 'package:app/models/tag_list_model.dart';
import 'package:app/models/task_model.dart';
import 'package:flutter/material.dart';

import 'package:app/login/login_page.dart';
import 'package:provider/provider.dart';
import 'package:app/models/task_list_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskListModel()),
        ChangeNotifierProvider(create: (context) => TaskModel()),
        ChangeNotifierProvider(create: (context) => ShowImportanceModel()),
        ChangeNotifierProvider(create: (context) => TagListModel()),
      ],
      child: const MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF292929),
          primaryContainer: const Color(0xFF3D3D3D),
          onPrimary: const Color(0xFFFFFFFF),
          inversePrimary: const Color(0xFF7132A3),
          secondary: const Color(0xFF7132A3),
          tertiary: const Color(0xFFFFFFFF),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF), // button text color
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF000000),
          selectionColor: Color(0xFF7132A3),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
