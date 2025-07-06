import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';

// Represents the puzzle state
class PuzzleState {
  final List<int?> tiles;
  final int emptyIndex;
  final List<int> path; // Tiles moved to reach this state
  final String id; // Unique identifier for the state
  final List<int> moveOffsets; // Track move offsets for back-and-forth prevention

  PuzzleState(this.tiles, this.emptyIndex, this.path, {this.moveOffsets = const []})
      : id = tiles.join(',');

  // Create a copy of the state with a new move
  PuzzleState copyWithMove(int tile, int newEmptyIndex, int moveOffset) {
    List<int?> newTiles = List.from(tiles);
    newTiles[emptyIndex] = tile;
    newTiles[newEmptyIndex] = null;
    // Keep only the last two move offsets to prevent short-term repetition
    List<int> newOffsets = [...moveOffsets.take(2), moveOffset];
    return PuzzleState(newTiles, newEmptyIndex, [...path, tile], moveOffsets: newOffsets);
  }
}

// Simplify the solution path to remove redundant loops
List<int> simplifyPath(List<int> path, List<int?> tiles, int gridSize) {
  List<int> simplified = [];
  List<int?> currentTiles = List.from(tiles);
  int emptyIndex = tiles.indexOf(null);

  for (int tile in path) {
    int tileIndex = currentTiles.indexOf(tile);
    if (tileIndex != -1 && (tileIndex == emptyIndex - 1 || tileIndex == emptyIndex + 1 ||
        tileIndex == emptyIndex - gridSize || tileIndex == emptyIndex + gridSize)) {
      simplified.add(tile);
      currentTiles[emptyIndex] = tile;
      currentTiles[tileIndex] = null;
      emptyIndex = tileIndex;
    }
  }
  return simplified;
}

// Calculate Manhattan distance for a tile to its goal position
int manhattanDistance(int tile, int index, int gridSize) {
  if (tile == null) return 0;
  int goalIndex = tile - 1;
  if (tile == gridSize * gridSize) goalIndex = gridSize * gridSize - 1; // Empty tile at end
  int currentRow = index ~/ gridSize;
  int currentCol = index % gridSize;
  int goalRow = goalIndex ~/ gridSize;
  int goalCol = goalIndex % gridSize;
  return (currentRow - goalRow).abs() + (currentCol - goalCol).abs();
}

// BFS-based algorithm for finding the full solution path
Map<String, Object?> findNextMove(Map<String, Object?> input) {
  final List<dynamic> rawTiles = input['tiles'] as List<dynamic>;
  final List<int?> tiles = rawTiles.map((e) => e as int?).toList();
  final int gridSize = (input['gridSize'] as num).toInt();
  final goal = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);

  debugPrint("🔍 BFS Input Tiles: $tiles");
  Queue<PuzzleState> queue = Queue();
  Set<String> visited = {};
  int emptyIndex = tiles.indexOf(null);
  var initialState = PuzzleState(tiles, emptyIndex, []);

  queue.add(initialState);
  visited.add(initialState.id);

  // Possible moves: left, right, up, down with their opposites
  const List<Map<String, dynamic>> moves = [
    {'offset': -1, 'opposite': 1},   // Left
    {'offset': 1, 'opposite': -1},   // Right
    {'offset': -5, 'opposite': 5},   // Up
    {'offset': 5, 'opposite': -5},   // Down
  ];
  const int maxIterations = 100000;

  int iterations = 0;
  while (queue.isNotEmpty && iterations < maxIterations) {
    var current = queue.removeFirst();
    iterations++;

    if (const ListEquality().equals(current.tiles, goal)) {
      debugPrint("🔍 BFS: Goal reached, Path: ${current.path}");
      List<int> simplifiedPath = simplifyPath(current.path, tiles, gridSize);
      debugPrint("🔍 BFS: Simplified Path: $simplifiedPath");
      return {
        'result': simplifiedPath.isNotEmpty
            ? simplifiedPath
            : [tiles[emptyIndex - 1] ?? tiles[emptyIndex + 1] ?? tiles[emptyIndex - 5] ?? tiles[emptyIndex + 5]]
      };
    }

    int row = current.emptyIndex ~/ gridSize;
    int col = current.emptyIndex % gridSize;

    // Sort moves by Manhattan distance to prioritize goal-oriented moves
    var sortedMoves = List.from(moves);
    sortedMoves.sort((a, b) {
      int newEmptyIndexA = current.emptyIndex + (a['offset'] as int);
      int newEmptyIndexB = current.emptyIndex + (b['offset'] as int);
      if (newEmptyIndexA < 0 || newEmptyIndexA >= gridSize * gridSize) return 1;
      if (newEmptyIndexB < 0 || newEmptyIndexB >= gridSize * gridSize) return -1;
      int tileA = current.tiles[newEmptyIndexA] ?? gridSize * gridSize;
      int tileB = current.tiles[newEmptyIndexB] ?? gridSize * gridSize;
      return manhattanDistance(tileA, newEmptyIndexA, gridSize) -
          manhattanDistance(tileB, newEmptyIndexB, gridSize);
    });

    for (var move in sortedMoves) {
      int moveOffset = move['offset'] as int;
      int newEmptyIndex = current.emptyIndex + moveOffset;
      bool isValid = (moveOffset == -1 && col > 0) ||
          (moveOffset == 1 && col < gridSize - 1) ||
          (moveOffset == -5 && row > 0) ||
          (moveOffset == 5 && row < gridSize - 1);

      if (newEmptyIndex >= 0 && newEmptyIndex < gridSize * gridSize && isValid) {
        int tile = current.tiles[newEmptyIndex]!;
        // Avoid repetitive moves (same tile or back-and-forth)
        bool isBackAndForth = current.moveOffsets.isNotEmpty &&
            (move['opposite'] == current.moveOffsets.last ||
                (current.moveOffsets.length >= 2 && move['offset'] == current.moveOffsets[current.moveOffsets.length - 2]));
        if ((current.path.isEmpty || tile != current.path.last) && !isBackAndForth) {
          var newState = current.copyWithMove(tile, newEmptyIndex, moveOffset);
          if (!visited.contains(newState.id)) {
            visited.add(newState.id);
            queue.add(newState);
            debugPrint("🔍 BFS: Exploring move of tile $tile, New tiles=${newState.tiles}, Path length=${newState.path.length}");
          }
        }
      }
    }
  }

  // Fallback: Return the first valid move
  debugPrint("🔍 BFS: No solution found within $maxIterations iterations, returning first valid move");
  for (var move in moves) {
    int newEmptyIndex = emptyIndex + (move['offset'] as int);
    bool isValid = (move['offset'] == -1 && emptyIndex % gridSize > 0) ||
        (move['offset'] == 1 && emptyIndex % gridSize < gridSize - 1) ||
        (move['offset'] == -5 && emptyIndex >= gridSize) ||
        (move['offset'] == 5 && emptyIndex < gridSize * (gridSize - 1));
    if (newEmptyIndex >= 0 && newEmptyIndex < gridSize * gridSize && isValid) {
      return {'result': [tiles[newEmptyIndex]!]};
    }
  }
  debugPrint("🔍 BFS: No valid moves found");
  return {'result': []};
}

class FivePuzzleScreen extends StatefulWidget {
  final int level;
  const FivePuzzleScreen({super.key, required this.level});

  @override
  State<FivePuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<FivePuzzleScreen> {
  static const int gridSize = 5;
  late List<int?> tiles;
  ui.Image? fullImage;
  int moveCount = 0;
  int? hintIndex;
  bool _hintLoading = false;
  List<int> solutionPath = [];
  int solutionStep = 0;
  String? lastTileState; // Track last state to detect lack of progress

  @override
  void initState() {
    super.initState();
    _resetPuzzle();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/level${widget.level}.jpg');
      final image = await decodeImageFromList(byteData.buffer.asUint8List());
      if (mounted) {
        setState(() => fullImage = image);
      }
    } catch (e) {
      debugPrint("🔍 Image load failed: $e");
      if (mounted) {
        setState(() => fullImage = null);
      }
    }
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
      solutionPath = [];
      solutionStep = 0;
      lastTileState = null;
    });
    debugPrint("🔍 Puzzle reset: tiles=$tiles");
  }

  bool _isSolvable(List<int?> tiles) {
    List<int> flattened = tiles.whereType<int>().toList();
    int inversions = 0;
    for (int i = 0; i < flattened.length; i++) {
      for (int j = i + 1; j < flattened.length; j++) {
        if (flattened[i] > flattened[j]) inversions++;
      }
    }
    debugPrint("🔍 Inversions: $inversions, Solvable: ${inversions % 2 == 0}");
    return inversions % 2 == 0;
  }

  void _onTileTap(int index) {
    int? emptyIndex = tiles.indexOf(null);
    debugPrint("🚀 Tile tapped: index=$index, emptyIndex=$emptyIndex, tiles=$tiles");
    if (emptyIndex == null) {
      debugPrint("🚀 Error: No empty tile found");
      return;
    }
    if (_isAdjacent(index, emptyIndex)) {
      setState(() {
        tiles[emptyIndex] = tiles[index];
        tiles[index] = null;
        moveCount++;
        hintIndex = null;
        solutionPath = []; // Invalidate solution path on user move
        solutionStep = 0;
        lastTileState = tiles.join(',');
        debugPrint("🚀 Tile moved: new tiles=$tiles, moveCount=$moveCount");
      });
      checkWin();
    } else {
      debugPrint("🚀 Invalid move: tile at $index is not adjacent to empty tile at $emptyIndex");
    }
  }

  bool _isAdjacent(int i1, int i2) {
    bool isAdjacent = (i1 % gridSize != 0 && i1 - 1 == i2) || // Left
        (i1 % gridSize != gridSize - 1 && i1 + 1 == i2) || // Right
        (i1 >= gridSize && i1 - gridSize == i2) || // Up
        (i1 < gridSize * (gridSize - 1) && i1 + gridSize == i2); // Down
    debugPrint("🚀 Adjacency check: i1=$i1, i2=$i2, isAdjacent=$isAdjacent");
    return isAdjacent;
  }

  void checkWin() {
    final goal = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);
    if (const ListEquality().equals(tiles, goal)) {
      debugPrint("🏆 Win condition met: tiles=$tiles");
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🎉 You Win! 🎉"),
              content: Text("You solved the puzzle in $moveCount moves."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      });
    }
  }

  void _showHint() async {
    if (_hintLoading) {
      debugPrint("🔑 Hint: Already processing a hint, skipping");
      return;
    }
    setState(() => _hintLoading = true);

    try {
      // Compute new solution path if none exists, was invalidated, is repetitive, or no progress
      String currentState = tiles.join(','); // Define currentState locally
      bool noProgress = lastTileState == currentState && solutionStep > 0;
      if (solutionPath.isEmpty || solutionStep >= solutionPath.length || _isRepetitivePath() || noProgress) {
        debugPrint("🔑 Hint: Computing new solution path (noProgress=$noProgress)");
        final Map<String, Object?> result = await compute(findNextMove, {
          'tiles': tiles,
          'gridSize': gridSize,
        });
        debugPrint("🔑 Hint Result: $result");
        solutionPath = (result['result'] as List<dynamic>?)?.cast<int>() ?? [];
        solutionStep = 0;
        lastTileState = currentState;
      }

      if (solutionPath.isNotEmpty && solutionStep < solutionPath.length) {
        final int hintValue = solutionPath[solutionStep];
        final index = tiles.indexOf(hintValue);
        debugPrint("🔑 Hint: Step=$solutionStep, Value=$hintValue, Index=$index, Path=$solutionPath");

        if (index != -1 && mounted && _isValidHint(index)) {
          setState(() {
            hintIndex = index;
            solutionStep++;
            lastTileState = tiles.join(','); // Update after hint
          });
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => hintIndex = null);
          }
        } else {
          debugPrint("🔑 Hint Error: Tile $hintValue not found or invalid at index=$index, tiles=$tiles");
          solutionPath = [];
          solutionStep = 0;
          lastTileState = currentState;
          // Retry with a new path
          final Map<String, Object?> result = await compute(findNextMove, {
            'tiles': tiles,
            'gridSize': gridSize,
          });
          solutionPath = (result['result'] as List<dynamic>?)?.cast<int>() ?? [];
          solutionStep = 0;
          lastTileState = currentState;
          if (solutionPath.isNotEmpty) {
            final int newHintValue = solutionPath[solutionStep];
            final newIndex = tiles.indexOf(newHintValue);
            debugPrint("🔑 Hint Retry: Step=$solutionStep, Value=$newHintValue, Index=$newIndex");
            if (newIndex != -1 && mounted && _isValidHint(newIndex)) {
              setState(() {
                hintIndex = newIndex;
                solutionStep++;
                lastTileState = tiles.join(','); // Update after hint
              });
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                setState(() => hintIndex = null);
              }
            } else {
              debugPrint("🔑 Hint Error: Retry failed, no valid hint available");
            }
          }
        }
      } else {
        debugPrint("🔑 Hint Error: Solution path empty or step exceeded, path=$solutionPath, step=$solutionStep");
        solutionPath = [];
        solutionStep = 0;
        lastTileState = currentState;
      }
    } catch (e) {
      debugPrint("🔑 Hint Error: Compute failed: $e");
      solutionPath = [];
      solutionStep = 0;
      lastTileState = tiles.join(',');
    }

    setState(() => _hintLoading = false);
  }

  // Detect repetitive patterns in the solution path
  bool _isRepetitivePath() {
    if (solutionPath.length < 4) return false;
    for (int i = 3; i < solutionPath.length; i++) {
      if (solutionPath[i] == solutionPath[i - 2] && solutionPath[i - 1] == solutionPath[i - 3]) {
        debugPrint("🔑 Hint: Detected repetitive path pattern at index $i: $solutionPath");
        return true;
      }
    }
    return false;
  }

  // Ensure the hint is valid (adjacent to empty tile)
  bool _isValidHint(int index) {
    int? emptyIndex = tiles.indexOf(null);
    if (emptyIndex == null) return false;
    return _isAdjacent(index, emptyIndex);
  }

  void _setTestPuzzle() {
    setState(() {
      tiles = [
        23, 20, 22, 2, 13,
        11, 19, 4, 15, 9,
        1, 6, 16, 14, 24,
        10, 12, 8, 21, 17,
        5, null, 18, 7, 3
      ];
      moveCount = 0;
      hintIndex = null;
      solutionPath = [];
      solutionStep = 0;
      lastTileState = null;
      debugPrint("🔍 Test puzzle set: tiles=$tiles");
    });
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
      body: tiles.isEmpty
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
                        ElevatedButton.icon(
                          onPressed: _showHint,
                          icon: const Icon(Icons.lightbulb_outline),
                          label: const Text("Hint"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[100],
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _setTestPuzzle,
                          icon: const Icon(Icons.bug_report),
                          label: const Text("Test"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                          ),
                        ),
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
                        if (emptyIndex == -1) {
                          debugPrint("🚀 Swipe: No empty tile found");
                          return;
                        }
                        int row = index ~/ gridSize;
                        int col = index % gridSize;
                        int emptyRow = emptyIndex ~/ gridSize;
                        int emptyCol = emptyIndex % gridSize;

                        double dx = event.delta.dx;
                        double dy = event.delta.dy;
                        debugPrint("🚀 Swipe: index=$index, emptyIndex=$emptyIndex, dx=$dx, dy=$dy");

                        if (dx.abs() > dy.abs()) {
                          if (dx > 4 && col < gridSize - 1 && index + 1 == emptyIndex) {
                            debugPrint("🚀 Swipe right: Moving tile at $index");
                            _onTileTap(index);
                          } else if (dx < -4 && col > 0 && index - 1 == emptyIndex) {
                            debugPrint("🚀 Swipe left: Moving tile at $index");
                            _onTileTap(index);
                          }
                        } else {
                          if (dy > 4 && row < gridSize - 1 && index + gridSize == emptyIndex) {
                            debugPrint("🚀 Swipe down: Moving tile at $index");
                            _onTileTap(index);
                          } else if (dy < -4 && row > 0 && index - gridSize == emptyIndex) {
                            debugPrint("🚀 Swipe up: Moving tile at $index");
                            _onTileTap(index);
                          }
                        }
                      },
                      child: GestureDetector(
                        onTap: () => _onTileTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: tile == null ? bgColor : const Color(0xFFE0E5EC),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: tile == null
                                ? []
                                : [
                              const BoxShadow(
                                  color: Colors.blueGrey, offset: Offset(-5, -5), blurRadius: 10),
                              BoxShadow(
                                  color: Colors.grey.shade500, offset: const Offset(5, 5), blurRadius: 10),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (tile != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: fullImage != null
                                      ? CustomPaint(
                                    painter: TilePainter(tile, fullImage!, puzzleSize, gridSize),
                                  )
                                      : Center(
                                    child: Text(
                                      '$tile',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (fullImage != null)
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