import 'package:flutter/material.dart';
import 'level_select_screen.dart';

class DifficultyLevelScreen extends StatelessWidget {
  const DifficultyLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sliding Puzzle Home')),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen(),
                    ),
                  );
                },
                child: const Text('3x3'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Placeholder for future 4x4 version
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('4x4 coming soon!')),
                  );
                },
                child: const Text('4x4'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Placeholder for future 5x5 version
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('5x5 coming soon!')),
                  );
                },
                child: const Text('5x5'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
