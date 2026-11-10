class BoardCoordinate {
  final int r;
  final int c;

  const BoardCoordinate(this.r, this.c);

  int get index => r * 10 + c;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCoordinate &&
          runtimeType == other.runtimeType &&
          r == other.r &&
          c == other.c;

  @override
  int get hashCode => r.hashCode ^ (c.hashCode << 4);

  @override
  String toString() => '($r, $c)';
}

class BoardLayout {
  static const int rows = 10;
  static const int cols = 10;

  // The official 10x10 Sequence board layout matrix
  static const List<List<String>> matrix = [
    ["FREE", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "FREE"],
    ["6C",   "5C", "4C", "3C", "2C", "AH", "KH", "QH", "10H", "10S"],
    ["7C",   "AS", "2D", "3D", "4D", "5D", "6D", "7D", "9H",  "QS"],
    ["8C",   "KS", "6C", "5C", "4C", "3C", "2C", "8D", "8H",  "KS"],
    ["9C",   "QS", "7C", "6H", "5H", "4H", "AH", "9D", "7H",  "AS"],
    ["10C",  "10S","8C", "7H", "2H", "3H", "KH", "10D","6H",  "2D"],
    ["QC",   "9S", "9C", "8H", "9H", "10H","QH", "QD", "5H",  "3D"],
    ["KC",   "8S", "10C","QC", "KC", "AC", "AD", "KD", "4H",  "4D"],
    ["AC",   "7S", "6S", "5S", "4S", "3S", "2S", "2H", "3H",  "5D"],
    ["FREE", "AD", "KD", "QD", "10D","9D", "8D", "7D", "6D",  "FREE"],
  ];

  static bool isCorner(int r, int c) {
    return (r == 0 && c == 0) ||
           (r == 0 && c == 9) ||
           (r == 9 && c == 0) ||
           (r == 9 && c == 9);
  }

  // Precomputed mapping from card code (e.g. "2S") to list of coordinates
  static final Map<String, List<BoardCoordinate>> cardToCoords = _initCardCoords();

  static Map<String, List<BoardCoordinate>> _initCardCoords() {
    final map = <String, List<BoardCoordinate>>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final code = matrix[r][c];
        if (code != "FREE") {
          map.putIfAbsent(code, () => []).add(BoardCoordinate(r, c));
        }
      }
    }
    return map;
  }
}
