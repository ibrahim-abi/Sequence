import 'dart:math';
import '../models/card.dart';
import '../models/board_layout.dart';
import '../models/game_state.dart';
import '../engine/window_detector.dart';
import '../engine/sequence_rules.dart';
import '../engine/card_tracker.dart';

enum TacticalIntent {
  winningSequence,
  emergencyBlock,
  oneEyedJackStrike,
  doubleThreatFork,
  advanceTeamThreat,
  wingmanCooperation,
  centerGravityHub,
  strategicPositioning,
}

class MoveEvaluationResult {
  final double score;
  final TacticalIntent intent;
  final String strategyReason;

  const MoveEvaluationResult({
    required this.score,
    required this.intent,
    required this.strategyReason,
  });
}

class Aimove {
  final PlayingCard card;
  final BoardCoordinate coord;
  final bool isRemoval; // For One-Eyed Jacks
  final double score;
  final TacticalIntent intent;
  final String strategyReason;
  final String dialogue;

  const Aimove({
    required this.card,
    required this.coord,
    this.isRemoval = false,
    required this.score,
    required this.intent,
    required this.strategyReason,
    required this.dialogue,
  });

  @override
  String toString() =>
      '${card.id} at ${coord.toString()}${isRemoval ? " (Removal)" : ""} [$intent: ${score.toStringAsFixed(1)}]';
}

class MathematicalSequenceAI {
  final Random _rng = Random();

  /// Evaluates and selects the mathematically optimal move with explicit tactical brain reasoning
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
                final eval = _evaluateCandidateMove(
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
                final dialogue = _generateDialogue(aiPlayer, eval.intent, BoardCoordinate(r, c), card, false);
                candidateMoves.add(Aimove(
                  card: card,
                  coord: BoardCoordinate(r, c),
                  isRemoval: false,
                  score: eval.score - 2500.0,
                  intent: eval.intent,
                  strategyReason: eval.strategyReason,
                  dialogue: dialogue,
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
                  final eval = _evaluateCandidateMove(
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
                  final dialogue = _generateDialogue(aiPlayer, eval.intent, BoardCoordinate(r, c), card, true);
                  candidateMoves.add(Aimove(
                    card: card,
                    coord: BoardCoordinate(r, c),
                    isRemoval: true,
                    score: eval.score - 1800.0,
                    intent: eval.intent,
                    strategyReason: eval.strategyReason,
                    dialogue: dialogue,
                  ));
                }
              }
            }
          }
        }
      } else {
        // Regular card
        final coords = BoardLayout.cardToCoords[card.id];
        if (coords != null) {
          for (final coord in coords) {
            if (board.getChip(coord.r, coord.c) == TeamId.none) {
              final eval = _evaluateCandidateMove(
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
              final dialogue = _generateDialogue(aiPlayer, eval.intent, coord, card, false);
              candidateMoves.add(Aimove(
                card: card,
                coord: coord,
                isRemoval: false,
                score: eval.score,
                intent: eval.intent,
                strategyReason: eval.strategyReason,
                dialogue: dialogue,
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

  MoveEvaluationResult _evaluateCandidateMove({
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
        return MoveEvaluationResult(
          score: 150000.0 * newSeqs.length,
          intent: TacticalIntent.winningSequence,
          strategyReason: "Completing 5-chip sequence at $coord!",
        );
      }
    }

    double totalUtility = 0.0;
    int advancingThreatCount = 0;
    int blockedEnemyThreats = 0;
    TacticalIntent primaryIntent = TacticalIntent.strategicPositioning;
    String strategyReason = "Expanding board coverage at $coord";

    for (final window in WindowDetector.allWindows) {
      int T = 0;
      int E = 0;
      int O = 0;
      final openCells = <BoardCoordinate>[];

      int originalE = 0;
      for (final c in window.coords) {
        if (!BoardLayout.isCorner(c.r, c.c) &&
            board.getChip(c.r, c.c) != TeamId.none &&
            board.getChip(c.r, c.c) != team) {
          originalE++;
        }
      }

      for (final c in window.coords) {
        final isCnr = BoardLayout.isCorner(c.r, c.c);
        if (isCnr) {
          T++;
          E++;
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

      // Check One-Eyed Jack removal
      if (isRemoval && window.contains(coord.r, coord.c)) {
        if (originalE >= 4) {
          totalUtility += 55000.0;
          primaryIntent = TacticalIntent.oneEyedJackStrike;
          strategyReason = "Dismantled lethal 4-in-a-row threat at $coord";
        } else if (originalE == 3) {
          totalUtility += 12000.0;
          if (primaryIntent != TacticalIntent.oneEyedJackStrike) {
            primaryIntent = TacticalIntent.oneEyedJackStrike;
            strategyReason = "Broke 3-chip enemy cluster at $coord";
          }
        }
      }

      // Blocked window check
      if (T > 0 && E > 0) {
        if (!isRemoval && window.contains(coord.r, coord.c) && originalE >= 4) {
          totalUtility += 60000.0;
          blockedEnemyThreats++;
          primaryIntent = TacticalIntent.emergencyBlock;
          strategyReason = "Emergency intercept of opponent win at $coord!";
        } else if (!isRemoval && window.contains(coord.r, coord.c) && originalE == 3) {
          totalUtility += 8500.0;
          blockedEnemyThreats++;
          if (primaryIntent != TacticalIntent.emergencyBlock) {
            primaryIntent = TacticalIntent.emergencyBlock;
            strategyReason = "Preemptive block of 3-chip enemy line at $coord";
          }
        } else {
          totalUtility += 5.0 * (0.15 * pRemove);
        }
        continue;
      }

      // Offensive Window Viability (E == 0)
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
            if (primaryIntent != TacticalIntent.emergencyBlock) {
              primaryIntent = TacticalIntent.advanceTeamThreat;
              strategyReason = "Advancing sequence to 4 chips (1 away from win!)";
            }
            break;
          case 3:
            baseWeight = 1200.0 * phi;
            advancingThreatCount++;
            if (primaryIntent == TacticalIntent.strategicPositioning) {
              primaryIntent = TacticalIntent.wingmanCooperation;
              strategyReason = "Building 3-chip cluster at $coord";
            }
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

      // Defensive Threat Urgency
      final nonCornerT = window.coords
          .where((c) => !BoardLayout.isCorner(c.r, c.c) && simBoard.getChip(c.r, c.c) == team)
          .length;
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
            primaryIntent = TacticalIntent.emergencyBlock;
            strategyReason = "Blocked opponent sequence path at $coord";
          }
        } else if (E == 3 && O == 2) {
          if (!isRemoval && openCells.contains(coord)) {
            totalUtility += 4500.0 * psi;
          }
        }
      }
    }

    // Multi-Line Threat / Fork Creation Bonus
    if (advancingThreatCount >= 2) {
      totalUtility *= 1.6;
      if (primaryIntent != TacticalIntent.emergencyBlock) {
        primaryIntent = TacticalIntent.doubleThreatFork;
        strategyReason = "Created lethal 2-way fork at $coord!";
      }
    }
    if (blockedEnemyThreats >= 2) {
      totalUtility *= 1.4;
    }

    // Center Control Gravity
    final centerDist = (coord.r - 4.5).abs() + (coord.c - 4.5).abs();
    final centerPrior = 18.0 - (2.2 * centerDist);
    totalUtility += max(0.0, centerPrior);
    if (centerDist <= 2.0 && primaryIntent == TacticalIntent.strategicPositioning) {
      primaryIntent = TacticalIntent.centerGravityHub;
      strategyReason = "Securing central board control at $coord";
    }

    return MoveEvaluationResult(
      score: totalUtility,
      intent: primaryIntent,
      strategyReason: strategyReason,
    );
  }

  String _generateDialogue(
    Player player,
    TacticalIntent intent,
    BoardCoordinate coord,
    PlayingCard card,
    bool isRemoval,
  ) {
    final seat = player.seatIndex;

    // Seat 2: AI Partner (Supportive Wingman for Human)
    if (seat == 2) {
      switch (intent) {
        case TacticalIntent.winningSequence:
          return "BOOM! Sequence complete! Great game, partner!";
        case TacticalIntent.emergencyBlock:
          return "Hold tight partner! I blocked their winning spot at $coord!";
        case TacticalIntent.oneEyedJackStrike:
          return "Using my One-Eyed Jack to dismantle their line. We're safe!";
        case TacticalIntent.doubleThreatFork:
          return "I set up a 2-way fork! Finish it on your turn, partner!";
        case TacticalIntent.advanceTeamThreat:
          return "Linking with your chips at $coord! Just 1 more for a sequence!";
        case TacticalIntent.wingmanCooperation:
          return "I've got your back on this flank, partner.";
        case TacticalIntent.centerGravityHub:
          return "Securing the center so we have multiple avenues to attack.";
        case TacticalIntent.strategicPositioning:
          return "Placing ${card.id} at $coord to open up our lines.";
      }
    }

    // Seat 1: AI Alpha (Aggressive, Confident Competitor)
    if (seat == 1) {
      switch (intent) {
        case TacticalIntent.winningSequence:
          return "Sequence locked! That's how Team Green plays.";
        case TacticalIntent.emergencyBlock:
          return "Did you really think I wouldn't spot that 4-in-a-row? Blocked!";
        case TacticalIntent.oneEyedJackStrike:
          return "Say goodbye to your blue chip. Your sequence is ruined!";
        case TacticalIntent.doubleThreatFork:
          return "Double threat deployed. Good luck stopping both lines!";
        case TacticalIntent.advanceTeamThreat:
          return "One more chip and we take another sequence.";
        case TacticalIntent.wingmanCooperation:
          return "Alpha setting up Beta for the kill.";
        case TacticalIntent.centerGravityHub:
          return "The center board belongs to Team Green.";
        case TacticalIntent.strategicPositioning:
          return "Expanding our territory at $coord.";
      }
    }

    // Seat 3: AI Beta (Cold Analytical Strategist)
    switch (intent) {
      case TacticalIntent.winningSequence:
        return "Optimal sequence formed. Victory probability: 96.4%.";
      case TacticalIntent.emergencyBlock:
        return "Critical threat at $coord intercepted. Risk neutralized.";
      case TacticalIntent.oneEyedJackStrike:
        return "Target excised at $coord. Opponent win vector eliminated.";
      case TacticalIntent.doubleThreatFork:
        return "Dual-vector state initialized. Defense mathematically improbable.";
      case TacticalIntent.advanceTeamThreat:
        return "Vector at $coord escalated to state T=4. Sequence imminent.";
      case TacticalIntent.wingmanCooperation:
        return "Synergizing with Alpha's vector.";
      case TacticalIntent.centerGravityHub:
        return "Maximizing spatial window intersection coefficient.";
      case TacticalIntent.strategicPositioning:
        return "Calculating hypergeometric draw distribution...";
    }
  }
}
