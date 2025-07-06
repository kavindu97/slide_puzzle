import 'package:collection/collection.dart';

/// Input format for compute()
Map<String, Object?> findNextMoveIDAStar(Map<String, Object?> input) {
  final List<dynamic> rawTiles = input['tiles'] as List<dynamic>;
  final List<int?> tiles = rawTiles.map((e) => e as int?).toList();
  final int gridSize = input['gridSize'] as int;

  final goal = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);
  int threshold = _heuristic(tiles, gridSize);

  while (true) {
    final visited = <String>{};
    final path = <List<int?>>[];

    final result = _search(tiles, 0, threshold, visited, path, gridSize, null);
    if (result == -1) {
      if (path.length < 2) return {'result': null}; // No move needed
      final first = path[1];
      final diffIndex = List.generate(tiles.length, (i) => i).firstWhere((i) => tiles[i] != first[i]);
      return {'result': tiles[diffIndex]};
    }
    if (result >= 1 << 30) return {'result': null}; // Treat as "no solution"
    threshold = result;
  }
}

int _search(
    List<int?> node,
    int g,
    int threshold,
    Set<String> visited,
    List<List<int?>> path,
    int gridSize,
    int? prevEmpty,
    ) {
  final f = g + _heuristic(node, gridSize);
  if (f > threshold) return f;
  if (_isGoal(node, gridSize)) return -1;

  visited.add(node.join(','));
  path.add(node);

  int minCost = 1 << 30;
  final empty = node.indexOf(null);
  final directions = [-1, 1, -gridSize, gridSize];

  for (final dir in directions) {
    final newIndex = empty + dir;

    bool isValid = (dir == -1 && empty % gridSize > 0) ||
        (dir == 1 && empty % gridSize < gridSize - 1) ||
        (dir == -gridSize && empty >= gridSize) ||
        (dir == gridSize && empty < gridSize * (gridSize - 1));

    if (!isValid || newIndex < 0 || newIndex >= node.length || newIndex == prevEmpty) continue;

    final newTiles = List<int?>.from(node);
    newTiles[empty] = newTiles[newIndex];
    newTiles[newIndex] = null;

    final key = newTiles.join(',');
    if (visited.contains(key)) continue;

    final t = _search(newTiles, g + 1, threshold, visited, path, gridSize, empty);
    if (t == -1) return -1;
    if (t < minCost) minCost = t;
  }

  visited.remove(node.join(','));
  path.removeLast();
  return minCost;
}

bool _isGoal(List<int?> tiles, int gridSize) {
  final goal = List<int?>.generate(gridSize * gridSize - 1, (i) => i + 1)..add(null);
  return const ListEquality().equals(tiles, goal);
}

int _heuristic(List<int?> tiles, int gridSize) {
  int sum = 0;
  for (int i = 0; i < tiles.length; i++) {
    final val = tiles[i];
    if (val == null) continue;
    final targetRow = (val - 1) ~/ gridSize;
    final targetCol = (val - 1) % gridSize;
    final currRow = i ~/ gridSize;
    final currCol = i % gridSize;
    sum += (targetRow - currRow).abs() + (targetCol - currCol).abs();
  }
  return sum;
}
