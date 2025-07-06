import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sliding_puzzle/screens/five_level_select_screen.dart';
import 'four_level_select_screen.dart';
import 'level_select_screen.dart';

class DifficultyLevelScreen extends StatefulWidget {
  const DifficultyLevelScreen({super.key});

  @override
  State<DifficultyLevelScreen> createState() => _DifficultyLevelScreenState();
}

class _DifficultyLevelScreenState extends State<DifficultyLevelScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ✅ Reuse your test or real ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Banner failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }
  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFCAD6E2);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Sliding Puzzle',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNeuCard(
              context,
              title: "3x3",
              subtitle: "Easy Start",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildNeuCard(
              context,
              title: "4x4",
              subtitle: "Medium",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FourLevelSelectScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildNeuCard(
              context,
              title: "5x5",
              subtitle: "Coming soon Hardcore!",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("5x5 mode is coming soon!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isBannerAdReady
          ? SizedBox(
        height: _bannerAd.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd),
      )
          : null,
    );
  }

  Widget _buildNeuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color(0xFFA3B1C6),
              offset: Offset(6, 6),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.grid_on_rounded, size: 40, color: Colors.grey[800]),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
