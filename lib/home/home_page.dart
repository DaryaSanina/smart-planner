import 'package:flutter/material.dart';
import 'package:app/home/widgets/home_app_bar.dart';
import 'package:app/home/widgets/sort_button.dart';
import 'package:app/home/widgets/filter_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: const HomeAppBar(),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  const SortButton(),
                ],
              ),
              Row(
                children: [
                  const FilterButton(),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}