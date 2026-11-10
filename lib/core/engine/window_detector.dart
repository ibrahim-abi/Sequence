import '../models/board_layout.dart';

class Window5 {
  final int id;
  final List<BoardCoordinate> coords;

  const Window5({required this.id, required this.coords});

  bool contains(int r, int c) {
    for (int i = 0; i < coords.length; i++) {
      if (coords[i].r == r && coords[i].c == c) return true;
    }
    return false;
  }
}

class WindowDetector {
  static final List<Window5> allWindows = _precomputeWindows();
  static final List<List<int>> cellToWindowIndices = _precomputeCellWindows();

  static List<Window5> _precomputeWindows() {
    final list = <Window5>[];
    int idCounter = 0;

    // 1. Horizontal windows (10 rows x 6 windows = 60)
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c <= 5; c++) {
        list.add(Window5(
          id: idCounter++,
          coords: [
            BoardCoordinate(r, c),
            BoardCoordinate(r, c + 1),
            BoardCoordinate(r, c + 2),
            BoardCoordinate(r, c + 3),
            BoardCoordinate(r, c + 4),
          ],
        ));
      }
    }

    // 2. Vertical windows (10 cols x 6 windows = 60)
    for (int c = 0; c < 10; c++) {
      for (int r = 0; r <= 5; r++) {
        list.add(Window5(
          id: idCounter++,
          coords: [
            BoardCoordinate(r, c),
            BoardCoordinate(r + 1, c),
            BoardCoordinate(r + 2, c),
            BoardCoordinate(r + 3, c),
            BoardCoordinate(r + 4, c),
          ],
        ));
      }
    }

    // 3. Main Diagonals (NW to SE, \): r from 0 to 5, c from 0 to 5
    for (int r = 0; r <= 5; r++) {
      for (int c = 0; c <= 5; c++) {
        list.add(Window5(
          id: idCounter++,
          coords: [
            BoardCoordinate(r, c),
            BoardCoordinate(r + 1, c + 1),
            BoardCoordinate(r + 2, c + 2),
            BoardCoordinate(r + 3, c + 3),
            BoardCoordinate(r + 4, c + 4),
          ],
        ));
      }
    }

    // 4. Anti Diagonals (NE to SW, /): r from 0 to 5, c from 4 to 9
    for (int r = 0; r <= 5; r++) {
      for (int c = 4; c < 10; c++) {
        list.add(Window5(
          id: idCounter++,
          coords: [
            BoardCoordinate(r, c),
            BoardCoordinate(r + 1, c - 1),
            BoardCoordinate(r + 2, c - 2),
            BoardCoordinate(r + 3, c - 3),
            BoardCoordinate(r + 4, c - 4),
          ],
        ));
      }
    }

    return list;
  }

  static List<List<int>> _precomputeCellWindows() {
    final table = List.generate(100, (_) => <int>[]);
    for (int i = 0; i < allWindows.length; i++) {
      final w = allWindows[i];
      for (final coord in w.coords) {
        table[coord.index].add(i);
      }
    }
    return table;
  }
}
