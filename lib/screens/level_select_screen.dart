import 'package:flutter/material.dart';
import 'puzzle_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Level")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          int level = index + 1;
          return ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PuzzleScreen(level: level),
                ),
              );
            },
            child: Text("Level $level"),
          );
        },
      ),
    );
  }
}
