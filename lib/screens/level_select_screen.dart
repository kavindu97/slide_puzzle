import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  List<bool> unlockedLevels = List.generate(50, (index) => index == 0); // First level unlocked by default

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevels();



    _bannerAd = BannerAd(
      // adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Replace with real ID in production
      adUnitId:'ca-app-pub-7234661059951095/5511225206',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    );

    _bannerAd.load(); // Load after initialization
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
      bottomNavigationBar: _isBannerAdReady
          ? SizedBox(
        height: _bannerAd.size.height.toDouble(),
        width: _bannerAd.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd),
      )
          : null,

    );
  }
}