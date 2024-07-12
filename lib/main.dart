import 'package:app/home/widgets/task_list.dart';
import 'package:flutter/material.dart';
import 'package:app/home/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (context) => TaskListModel(),
    child: const MyApp(),)
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
          secondary: const Color(0xFF7132A3),
          tertiary: const Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}
