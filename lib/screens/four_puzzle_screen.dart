import 'dart:collection';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class FourPuzzleScreen extends StatefulWidget {
  final int level;
  const FourPuzzleScreen({super.key, required this.level});

  @override
  State<FourPuzzleScreen> createState() => _FourPuzzleScreenState();
}

class _FourPuzzleScreenState extends State<FourPuzzleScreen> {
  static const int gridSize = 4;
  late List<int?> tiles;
  ui.Image? fullImage;
  int moveCount = 0;
  int? hintIndex;

  @override
  void initState() {
    super.initState();
    _resetPuzzle();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final byteData = await rootBundle.load('assets/images/level${widget.level}.jpg');
    final image = await decodeImageFromList(byteData.buffer.asUint8List());
    setState(() => fullImage = image);
  }

  void _resetPuzzle() {
    List<int?> newTiles;
    do {
      newTiles = List<int?>.generate(gridSize * gridSize, (i) => i < gridSize * gridSize - 1 ? i + 1 : null)..shuffle();
    } while (!_isSolvable(newTiles));
    setState(() {
      tiles = newTiles;
      moveCount = 0;
      hintIndex = null;
    });
  }

  bool _isSolvable(List<int?> tiles) {
    List<int> flattened = tiles.whereType<int>().toList();
    int inversions = 0;
    for (int i = 0; i < flattened.length; i++) {
      for (int j = i + 1; j < flattened.length; j++) {
        if (flattened[i] > flattened[j]) inversions++;
      }
    }
    int emptyRowFromBottom = gridSize - (tiles.indexOf(null) ~/ gridSize);
    return (inversions + emptyRowFromBottom) % 2 == 0;
  }

  void _onTileTap(int index) {
    int? emptyIndex = tiles.indexOf(null);
    if (_isAdjacent(index, emptyIndex)) {
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = null;
        moveCount++;
        hintIndex = null;
      });
      checkWin();
    }
  }

  bool _isAdjacent(int i1, int i2) {
    return (i1 % gridSize != 0 && i1 - 1 == i2) ||
        (i1 % gridSize != gridSize - 1 && i1 + 1 == i2) ||
        (i1 >= gridSize && i1 - gridSize == i2) ||
        (i1 < gridSize * (gridSize - 1) && i1 + gridSize == i2);
  }

  void checkWin() {
    final isWinning = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);
    if (const ListEquality().equals(tiles, isWinning)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("🎉 You Win! 🎉"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("You solved the puzzle in $moveCount moves."),
                const SizedBox(height: 16),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridSize * gridSize,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final tile = isWinning[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: tile == null ? const Color(0xFFE0E5EC) : const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: tile == null
                              ? []
                              : [
                            const BoxShadow(
                              color: Colors.blueGrey,
                              offset: Offset(-2, -2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.grey,
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: tile != null && fullImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomPaint(
                            painter: TilePainter(tile, fullImage!, 150, gridSize),
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      });
    }
  }

  void _showHint() {
    int? nextTile = PuzzleSolver.findNextBestMove(tiles, gridSize);
    if (nextTile != null) {
      setState(() => hintIndex = tiles.indexOf(nextTile));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => hintIndex = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFE0E5EC);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Level ${widget.level}"),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: fullImage == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final double puzzleSize = constraints.maxWidth * 0.9;
          final double tileSize = puzzleSize / gridSize;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Moves: $moveCount", style: const TextStyle(fontSize: 18)),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _resetPuzzle,
                          icon: const Icon(Icons.shuffle),
                          label: const Text("Shuffle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ElevatedButton.icon(
                        //   onPressed: _showHint,
                        //   icon: const Icon(Icons.lightbulb_outline),
                        //   label: const Text("Hint"),
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.yellow[100],
                        //     foregroundColor: Colors.black87,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: puzzleSize,
                height: puzzleSize,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridSize * gridSize,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemBuilder: (context, index) {
                    final tile = tiles[index];
                    return Listener(
                      onPointerMove: (event) {
                        int emptyIndex = tiles.indexOf(null);
                        int row = index ~/ gridSize;
                        int col = index % gridSize;
                        int emptyRow = emptyIndex ~/ gridSize;
                        int emptyCol = emptyIndex % gridSize;

                        double dx = event.delta.dx;
                        double dy = event.delta.dy;

                        if (dx.abs() > dy.abs()) {
                          if (dx > 4 && col < gridSize - 1 && index + 1 == emptyIndex) {
                            _onTileTap(index);
                          } else if (dx < -4 && col > 0 && index - 1 == emptyIndex) {
                            _onTileTap(index);
                          }
                        } else {
                          if (dy > 4 && row < gridSize - 1 && index + gridSize == emptyIndex) {
                            _onTileTap(index);
                          } else if (dy < -4 && row > 0 && index - gridSize == emptyIndex) {
                            _onTileTap(index);
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: tile == null ? bgColor : const Color(0xFFE0E5EC),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: tile == null
                              ? []
                              : [
                            const BoxShadow(
                              color: Colors.blueGrey,
                              offset: Offset(-5, -5),
                              blurRadius: 10,
                            ),
                            BoxShadow(
                              color: Colors.grey,
                              offset: const Offset(5, 5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (tile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CustomPaint(
                                  painter: TilePainter(tile, fullImage!, puzzleSize, gridSize),
                                ),
                              ),
                            if (index == hintIndex)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.width * 0.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RawImage(image: fullImage),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TilePainter extends CustomPainter {
  final int tileNumber;
  final ui.Image image;
  final double puzzleSize;
  final int gridSize;

  TilePainter(this.tileNumber, this.image, this.puzzleSize, this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    double tileSize = puzzleSize / gridSize;
    int row = (tileNumber - 1) ~/ gridSize;
    int col = (tileNumber - 1) % gridSize;

    final src = Rect.fromLTWH(
      col * (image.width / gridSize),
      row * (image.height / gridSize),
      image.width / gridSize,
      image.height / gridSize,
    );

    final dst = Rect.fromLTWH(0, 0, tileSize, tileSize);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.tileNumber != tileNumber;
  }
}

class PuzzleSolver {
  static int? findNextBestMove(List<int?> tiles, int gridSize) {
    List<int?> goal = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);
    List<int> directions = [-1, 1, -gridSize, gridSize];

    Queue<List<int?>> queue = Queue();
    Queue<List<int?>> pathQueue = Queue();
    Set<String> visited = {};

    queue.add(List.from(tiles));
    pathQueue.add([]);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final path = pathQueue.removeFirst();
      final key = current.join(',');

      if (visited.contains(key)) continue;
      visited.add(key);

      if (const ListEquality().equals(current, goal)) {
        return path.isNotEmpty ? path.first : null;
      }

      int empty = current.indexOf(null);
      int row = empty ~/ gridSize;
      int col = empty % gridSize;

      for (var dir in directions) {
        int newIndex = empty + dir;
        bool isValid = (dir == -1 && col > 0) ||
            (dir == 1 && col < gridSize - 1) ||
            (dir == -gridSize && row > 0) ||
            (dir == gridSize && row < gridSize - 1);

        if (newIndex >= 0 && newIndex < gridSize * gridSize && isValid) {
          final newTiles = List<int?>.from(current);
          newTiles[empty] = newTiles[newIndex];
          newTiles[newIndex] = null;

          queue.add(newTiles);
          pathQueue.add([...path, newTiles[empty]!]);
        }
      }
    }
    return null;
  }
}