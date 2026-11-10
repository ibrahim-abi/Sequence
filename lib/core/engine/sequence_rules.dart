import '../models/card.dart';
import '../models/board_layout.dart';
import '../models/game_state.dart';
import 'window_detector.dart';

class SequenceRecord {
  final int windowId;
  final TeamId team;
  final List<BoardCoordinate> coords;

  const SequenceRecord({
    required this.windowId,
    required this.team,
    required this.coords,
  });
}

class BoardState {
  // 10x10 array of occupied chips (TeamId.none, blue, green, red)
  final List<TeamId> chips;

  // Set of coordinate indices locked into completed sequences
  final Set<int> lockedIndices;

  // Registered sequences per team
  final Map<TeamId, List<SequenceRecord>> completedSequences;

  BoardState({
    List<TeamId>? chips,
    Set<int>? lockedIndices,
    Map<TeamId, List<SequenceRecord>>? completedSequences,
  })  : chips = chips ?? List.filled(100, TeamId.none),
        lockedIndices = lockedIndices ?? <int>{},
        completedSequences = completedSequences ??
            {
              TeamId.blue: [],
              TeamId.green: [],
              TeamId.red: [],
            };

  BoardState clone() {
    return BoardState(
      chips: List<TeamId>.from(chips),
      lockedIndices: Set<int>.from(lockedIndices),
      completedSequences: {
        TeamId.blue: List<SequenceRecord>.from(completedSequences[TeamId.blue] ?? []),
        TeamId.green: List<SequenceRecord>.from(completedSequences[TeamId.green] ?? []),
        TeamId.red: List<SequenceRecord>.from(completedSequences[TeamId.red] ?? []),
      },
    );
  }

  TeamId getChip(int r, int c) => chips[r * 10 + c];

  void setChip(int r, int c, TeamId team) {
    chips[r * 10 + c] = team;
  }

  bool isLocked(int r, int c) => lockedIndices.contains(r * 10 + c);

  bool isCellEffectiveForTeam(int r, int c, TeamId team) {
    if (BoardLayout.isCorner(r, c)) return true; // Corners are wild for all
    return getChip(r, c) == team;
  }

  /// Checks if playing this non-Jack card is dead (both board spaces occupied)
  bool isCardDead(PlayingCard card) {
    if (card.isJack) return false;
    final coords = BoardLayout.cardToCoords[card.id];
    if (coords == null || coords.isEmpty) return false;

    // A card is dead if every board location where it appears is occupied by any chip
    for (final coord in coords) {
      if (getChip(coord.r, coord.c) == TeamId.none) {
        return false;
      }
    }
    return true;
  }

  /// Check whether playing at targetCoord forms one or more new valid sequences for [team].
  /// According to Official Rules:
  /// - A sequence is 5 in a row of team chips (corners count for all).
  /// - Two sequences of the same team can share AT MOST ONE common non-corner chip.
  List<SequenceRecord> checkNewSequences(BoardCoordinate targetCoord, TeamId team) {
    final newSequences = <SequenceRecord>[];
    final existingSeqs = completedSequences[team] ?? [];
    final candidateWindowIndices = WindowDetector.cellToWindowIndices[targetCoord.index];

    for (final winIdx in candidateWindowIndices) {
      final window = WindowDetector.allWindows[winIdx];

      // Check if all 5 cells in this window belong to this team or are corners
      bool allMatch = true;
      for (final c in window.coords) {
        if (!isCellEffectiveForTeam(c.r, c.c, team)) {
          allMatch = false;
          break;
        }
      }

      if (!allMatch) continue;

      // Check if this window was already recorded
      final alreadyRecorded = existingSeqs.any((seq) => seq.windowId == window.id) ||
          newSequences.any((seq) => seq.windowId == window.id);
      if (alreadyRecorded) continue;

      // Overlap rule validation:
      // A new sequence may share AT MOST 1 non-corner cell with any already completed sequence
      bool validOverlap = true;
      final currentNonCornerIndices = window.coords
          .where((c) => !BoardLayout.isCorner(c.r, c.c))
          .map((c) => c.index)
          .toSet();

      for (final existing in existingSeqs.followedBy(newSequences)) {
        final existingNonCornerIndices = existing.coords
            .where((c) => !BoardLayout.isCorner(c.r, c.c))
            .map((c) => c.index)
            .toSet();

        final sharedCount = currentNonCornerIndices.intersection(existingNonCornerIndices).length;
        if (sharedCount > 1) {
          // Sharing more than 1 non-corner cell is illegal (e.g. 6-in-a-row overlapping by 4)
          validOverlap = false;
          break;
        }
      }

      if (validOverlap) {
        newSequences.add(SequenceRecord(
          windowId: window.id,
          team: team,
          coords: List.from(window.coords),
        ));
      }
    }

    return newSequences;
  }

  /// Lock new sequences into state
  void registerSequences(List<SequenceRecord> newSeqs, TeamId team) {
    if (newSeqs.isEmpty) return;
    completedSequences.putIfAbsent(team, () => []).addAll(newSeqs);

    for (final seq in newSeqs) {
      for (final c in seq.coords) {
        if (!BoardLayout.isCorner(c.r, c.c)) {
          lockedIndices.add(c.index);
        }
      }
    }
  }
}
