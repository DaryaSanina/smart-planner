import 'package:flutter/material.dart';
import 'package:app/home/home_page.dart';

void main() {
  runApp(const MyApp());
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
          primaryContainer: Color.fromARGB(255, 61, 61, 61),
          secondary: const Color(0xFF7132A3),
          tertiary: const Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}
