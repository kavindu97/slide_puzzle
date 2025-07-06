import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  List<bool> unlockedLevels = List.generate(50, (index) => index == 0); // First level unlocked by default

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevels();
  }

  Future<void> _loadUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList('unlockedLevels') ?? ['1'];
    setState(() {
      unlockedLevels = List.generate(50, (index) => unlocked.contains('${index + 1}'));
    });
  }

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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        itemCount: 50,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          int level = index + 1;
          bool isUnlocked = unlockedLevels[index];

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
              onTap: isUnlocked
                  ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PuzzleScreen(level: level),
                  ),
                );
                if (result == true && level < 50) {
                  setState(() {
                    unlockedLevels[level] = true; // Unlock next level
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                    'unlockedLevels',
                    unlockedLevels
                        .asMap()
                        .entries
                        .where((entry) => entry.value)
                        .map((entry) => '${entry.key + 1}')
                        .toList(),
                  );
                }
              }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFE0E5EC) : Colors.grey[400],
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isUnlocked ? Colors.black87 : Colors.grey[600],
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