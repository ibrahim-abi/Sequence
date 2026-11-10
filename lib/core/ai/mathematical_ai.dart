import 'dart:math';
import '../models/card.dart';
import '../models/board_layout.dart';
import '../models/game_state.dart';
import '../engine/window_detector.dart';
import '../engine/sequence_rules.dart';
import '../engine/card_tracker.dart';

class Aimove {
  final PlayingCard card;
  final BoardCoordinate coord;
  final bool isRemoval; // For One-Eyed Jacks
  final double score;

  const Aimove({
    required this.card,
    required this.coord,
    this.isRemoval = false,
    required this.score,
  });

  @override
  String toString() =>
      '${card.id} at ${coord.toString()}${isRemoval ? " (Removal)" : ""} [score: ${score.toStringAsFixed(1)}]';
}

class MathematicalSequenceAI {
  final Random _rng = Random();

  /// Evaluates and selects the mathematically optimal move according to Section 4 of spec
  Aimove? chooseMove({
    required Player aiPlayer,
    required BoardState board,
    required CardTracker cardTracker,
    required int deckRemaining,
    required int totalOtherPlayersCards,
  }) {
    final hand = aiPlayer.hand;
    if (hand.isEmpty) return null;

    final candidateMoves = <Aimove>[];
    final totalUnseen = cardTracker.getTotalUnseenCards(deckRemaining, totalOtherPlayersCards);
    final pWild = cardTracker.pWild(hand, totalUnseen);
    final pRemove = cardTracker.pRemove(hand, totalUnseen);

    for (final card in hand) {
      if (card.isJack) {
        if (card.jackType == JackType.twoEyed) {
          // Can play on any empty non-corner cell
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              if (BoardLayout.isCorner(r, c)) continue;
              if (board.getChip(r, c) == TeamId.none) {
                final score = _evaluateCandidateMove(
                  card: card,
                  coord: BoardCoordinate(r, c),
                  isRemoval: false,
                  team: aiPlayer.team,
                  board: board,
                  cardTracker: cardTracker,
                  hand: hand,
                  totalUnseen: totalUnseen,
                  pWild: pWild,
                  pRemove: pRemove,
                );
                // Two-Eyed Jack penalty of -2500 so it can be deployed aggressively to block lethal threats or create win
                candidateMoves.add(Aimove(
                  card: card,
                  coord: BoardCoordinate(r, c),
                  isRemoval: false,
                  score: score - 2500.0,
                ));
              }
            }
          }
        } else if (card.jackType == JackType.oneEyed) {
          // Can remove any opponent chip that is NOT in a locked sequence
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              if (BoardLayout.isCorner(r, c)) continue;
              final chip = board.getChip(r, c);
              if (chip != TeamId.none && chip != aiPlayer.team) {
                if (!board.isLocked(r, c)) {
                  final score = _evaluateCandidateMove(
                    card: card,
                    coord: BoardCoordinate(r, c),
                    isRemoval: true,
                    team: aiPlayer.team,
                    board: board,
                    cardTracker: cardTracker,
                    hand: hand,
                    totalUnseen: totalUnseen,
                    pWild: pWild,
                    pRemove: pRemove,
                  );
                  // One-Eyed Jack penalty of -1800 so it breaks enemy 3/4 threats aggressively
                  candidateMoves.add(Aimove(
                    card: card,
                    coord: BoardCoordinate(r, c),
                    isRemoval: true,
                    score: score - 1800.0,
                  ));
                }
              }
            }
          }
        }
      } else {
        // Regular card: can place on matching empty coordinates
        final coords = BoardLayout.cardToCoords[card.id];
        if (coords != null) {
          for (final coord in coords) {
            if (board.getChip(coord.r, coord.c) == TeamId.none) {
              final score = _evaluateCandidateMove(
                card: card,
                coord: coord,
                isRemoval: false,
                team: aiPlayer.team,
                board: board,
                cardTracker: cardTracker,
                hand: hand,
                totalUnseen: totalUnseen,
                pWild: pWild,
                pRemove: pRemove,
              );
              candidateMoves.add(Aimove(
                card: card,
                coord: coord,
                isRemoval: false,
                score: score,
              ));
            }
          }
        }
      }
    }

    if (candidateMoves.isEmpty) {
      return null;
    }

    // Sort descending by score
    candidateMoves.sort((a, b) => b.score.compareTo(a.score));

    // For Master Pro AI: strictly pick the absolute maximum utility move or top 1% variance
    final topScore = candidateMoves.first.score;
    final threshold = topScore - (topScore.abs() * 0.01 + 2.0);
    final topTier = candidateMoves.where((m) => m.score >= threshold).toList();

    if (topTier.length == 1) {
      return topTier.first;
    }

    double bestJitterScore = -double.infinity;
    Aimove bestMove = topTier.first;
    for (final m in topTier) {
      final u1 = _rng.nextDouble().clamp(1e-7, 1.0);
      final u2 = _rng.nextDouble();
      final z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
      final jitteredScore = m.score + z * 0.5;
      if (jitteredScore > bestJitterScore) {
        bestJitterScore = jitteredScore;
        bestMove = m;
      }
    }

    return bestMove;
  }

  double _evaluateCandidateMove({
    required PlayingCard card,
    required BoardCoordinate coord,
    required bool isRemoval,
    required TeamId team,
    required BoardState board,
    required CardTracker cardTracker,
    required List<PlayingCard> hand,
    required int totalUnseen,
    required double pWild,
    required double pRemove,
  }) {
    // Clone board state to simulate the move
    final simBoard = board.clone();

    if (isRemoval) {
      simBoard.setChip(coord.r, coord.c, TeamId.none);
    } else {
      simBoard.setChip(coord.r, coord.c, team);
    }

    // Check instant sequence completion
    if (!isRemoval) {
      final newSeqs = simBoard.checkNewSequences(coord, team);
      if (newSeqs.isNotEmpty) {
        return 150000.0 * newSeqs.length;
      }
    }

    double totalUtility = 0.0;
    int advancingThreatCount = 0;
    int blockedEnemyThreats = 0;

    // Check before-move enemy status to see how many threats were neutralized by removal or placement
    for (final window in WindowDetector.allWindows) {
      int T = 0; // Team chips
      int E = 0; // Enemy chips
      int O = 0; // Open cells
      final openCells = <BoardCoordinate>[];

      // Also count original enemy chips in this window
      int originalE = 0;
      for (final c in window.coords) {
        if (!BoardLayout.isCorner(c.r, c.c) && board.getChip(c.r, c.c) != TeamId.none && board.getChip(c.r, c.c) != team) {
          originalE++;
        }
      }

      for (final c in window.coords) {
        final isCnr = BoardLayout.isCorner(c.r, c.c);
        if (isCnr) {
          T++;
          E++; // Corner acts as occupied for everyone
        } else {
          final chip = simBoard.getChip(c.r, c.c);
          if (chip == team) {
            T++;
          } else if (chip != TeamId.none) {
            E++;
          } else {
            O++;
            openCells.add(c);
          }
        }
      }

      // Check if this move successfully broke an enemy threat using One-Eyed Jack removal
      if (isRemoval && window.contains(coord.r, coord.c)) {
        if (originalE >= 4) {
          totalUtility += 55000.0; // Huge reward for dismantling 4-in-a-row enemy threat
        } else if (originalE == 3) {
          totalUtility += 12000.0; // High reward for dismantling 3-in-a-row enemy threat
        }
      }

      // 1. Blocked window check
      if (T > 0 && E > 0) {
        // If we just placed a chip to block an enemy window where E was >= 3:
        if (!isRemoval && window.contains(coord.r, coord.c) && originalE >= 4) {
          totalUtility += 60000.0; // Immediate interception of winning enemy move
          blockedEnemyThreats++;
        } else if (!isRemoval && window.contains(coord.r, coord.c) && originalE == 3) {
          totalUtility += 8500.0; // Early blocking of 3-in-a-row enemy threat
          blockedEnemyThreats++;
        } else {
          totalUtility += 5.0 * (0.15 * pRemove);
        }
        continue;
      }

      // 2. Offensive Window Viability (E == 0)
      if (E == 0) {
        double phi = 1.0;
        for (final s in openCells) {
          final cardCode = BoardLayout.matrix[s.r][s.c];
          final pLive = cardTracker.pLive(cardCode, hand, totalUnseen);
          final fillProb = max(0.12, pLive + pWild);
          phi *= fillProb;
        }

        double baseWeight = 0.0;
        switch (T) {
          case 5:
            baseWeight = 150000.0;
            break;
          case 4:
            baseWeight = 7500.0 * phi;
            advancingThreatCount++;
            break;
          case 3:
            baseWeight = 1200.0 * phi;
            advancingThreatCount++;
            break;
          case 2:
            baseWeight = 120.0 * phi;
            break;
          case 1:
            baseWeight = 15.0 * phi;
            break;
        }
        totalUtility += baseWeight;
      }

      // 3. Defensive Threat Urgency (T == 0, E > 0 non-corner)
      final nonCornerT = window.coords.where((c) => !BoardLayout.isCorner(c.r, c.c) && simBoard.getChip(c.r, c.c) == team).length;
      if (nonCornerT == 0 && E > 0) {
        double psi = 1.0;
        for (final s in openCells) {
          final cardCode = BoardLayout.matrix[s.r][s.c];
          final pLive = cardTracker.pLive(cardCode, hand, totalUnseen);
          psi *= max(0.12, pLive + pWild);
        }

        if (E == 4 && O == 1 && openCells.isNotEmpty) {
          if (!isRemoval && coord == openCells.first) {
            totalUtility += 45000.0 * psi;
          }
        } else if (E == 3 && O == 2) {
          if (!isRemoval && openCells.contains(coord)) {
            totalUtility += 4500.0 * psi;
          }
        }
      }
    }

    // 4. Multi-Line Threat / Fork Creation Bonus
    if (advancingThreatCount >= 2) {
      totalUtility *= 1.6;
    }
    if (blockedEnemyThreats >= 2) {
      totalUtility *= 1.4;
    }

    // 5. Center Control Gravity Prior: C(r,c) = 15 - 2*(|r - 4.5| + |c - 4.5|)
    final centerDist = (coord.r - 4.5).abs() + (coord.c - 4.5).abs();
    final centerPrior = 18.0 - (2.2 * centerDist);
    totalUtility += max(0.0, centerPrior);

    return totalUtility;
  }
}
