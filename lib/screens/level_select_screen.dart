import 'package:flutter/material.dart';
import 'puzzle_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCAD6E2),
      appBar: AppBar(
        title: const Text("Select Level"),
        backgroundColor: const Color(0xFFCAD6E2),
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // General padding
        itemCount: 100,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          int level = index + 1;

          final isFirstInRow = index % 3 == 0;
          final isLastInRow = index % 3 == 2;

          return Padding(
            padding: EdgeInsets.only(
              left: isFirstInRow ? 8 : 4,
              right: isLastInRow ? 8 : 4,
              top: 6,
              bottom: 6,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzleScreen(level: level),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E5EC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Color(0xFFA3B1C6),
                      offset: Offset(4, 4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Level $level",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
