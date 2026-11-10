import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/models/card.dart';
import '../../core/models/board_layout.dart';
import '../../core/models/game_state.dart';
import '../../core/engine/sequence_rules.dart';
import '../../core/engine/card_tracker.dart';
import '../../core/ai/mathematical_ai.dart';
import '../../core/audio_haptics/haptics_service.dart';

class MoveLogEntry {
  final String playerName;
  final String description;
  final String timestamp;

  const MoveLogEntry({
    required this.playerName,
    required this.description,
    required this.timestamp,
  });
}

class GameController extends ChangeNotifier {
  GameMode mode = GameMode.twoVsTwoHumanAi;
  final Deck deck = Deck();
  final BoardState board = BoardState();
  final CardTracker cardTracker = CardTracker();
  final MathematicalSequenceAI aiEngine = MathematicalSequenceAI();

  final List<Player> players = [];
  int currentTurnIndex = 0;
  bool isAiThinking = false;
  TeamId? winningTeam;

  PlayingCard? hoveredCard;
  PlayingCard? selectedCard;
  BoardCoordinate? lastMoveCoord;

  final List<PlayingCard> discardPile = [];
  final List<MoveLogEntry> moveLogs = [];

  // Turn Countdown Timer (20 seconds)
  static const int turnMaxSeconds = 20;
  int remainingTurnSeconds = turnMaxSeconds;
  Timer? _turnTimer;

  GameController() {
    startNewGame(GameMode.twoVsTwoHumanAi);
  }

  int get requiredSequencesToWin {
    switch (mode) {
      case GameMode.twoVsTwoHumanAi:
      case GameMode.twoVsTwoTwoHumans:
      case GameMode.oneVsOne:
        return 2;
      case GameMode.oneVsOneVsOne:
        return 1;
    }
  }

  int get cardsPerHand {
    switch (mode) {
      case GameMode.twoVsTwoHumanAi:
      case GameMode.twoVsTwoTwoHumans:
        return 6;
      case GameMode.oneVsOne:
        return 7;
      case GameMode.oneVsOneVsOne:
        return 6;
    }
  }

  Player get currentPlayer => players[currentTurnIndex];

  void setHoveredCard(PlayingCard? card) {
    if (hoveredCard != card) {
      hoveredCard = card;
      notifyListeners();
    }
  }

  void selectCard(PlayingCard card) {
    if (selectedCard == card) {
      selectedCard = null;
    } else {
      selectedCard = card;
    }
    notifyListeners();
  }

  void startNewGame(GameMode newMode) {
    _turnTimer?.cancel();
    mode = newMode;
    deck.reset();
    board.chips.fillRange(0, 100, TeamId.none);
    board.lockedIndices.clear();
    board.completedSequences[TeamId.blue]?.clear();
    board.completedSequences[TeamId.green]?.clear();
    board.completedSequences[TeamId.red]?.clear();
    cardTracker.reset();

    discardPile.clear();
    moveLogs.clear();
    winningTeam = null;
    hoveredCard = null;
    selectedCard = null;
    lastMoveCoord = null;
    currentTurnIndex = 0;
    isAiThinking = false;
    remainingTurnSeconds = turnMaxSeconds;

    // Build players based on mode
    players.clear();
    if (mode == GameMode.twoVsTwoHumanAi) {
      players.addAll([
        Player(seatIndex: 0, name: "You (Human)", team: TeamId.blue, isHuman: true),
        Player(seatIndex: 1, name: "AI Alpha", team: TeamId.green, isHuman: false),
        Player(seatIndex: 2, name: "AI Partner", team: TeamId.blue, isHuman: false),
        Player(seatIndex: 3, name: "AI Beta", team: TeamId.green, isHuman: false),
      ]);
    } else if (mode == GameMode.twoVsTwoTwoHumans) {
      players.addAll([
        Player(seatIndex: 0, name: "Player 1", team: TeamId.blue, isHuman: true),
        Player(seatIndex: 1, name: "AI Alpha", team: TeamId.green, isHuman: false),
        Player(seatIndex: 2, name: "Player 2", team: TeamId.blue, isHuman: true),
        Player(seatIndex: 3, name: "AI Beta", team: TeamId.green, isHuman: false),
      ]);
    } else if (mode == GameMode.oneVsOne) {
      players.addAll([
        Player(seatIndex: 0, name: "You (Human)", team: TeamId.blue, isHuman: true),
        Player(seatIndex: 1, name: "AI Opponent", team: TeamId.green, isHuman: false),
      ]);
    } else if (mode == GameMode.oneVsOneVsOne) {
      players.addAll([
        Player(seatIndex: 0, name: "You (Blue)", team: TeamId.blue, isHuman: true),
        Player(seatIndex: 1, name: "AI Alpha (Green)", team: TeamId.green, isHuman: false),
        Player(seatIndex: 2, name: "AI Beta (Red)", team: TeamId.red, isHuman: false),
      ]);
    }

    // Deal cards
    for (int i = 0; i < cardsPerHand; i++) {
      for (final p in players) {
        final card = deck.draw();
        if (card != null) {
          p.hand.add(card);
        }
      }
    }

    _log("Game started: ${_modeName(mode)}. Good luck!");
    _startTurnTimer();
    notifyListeners();
  }

  String _modeName(GameMode m) {
    switch (m) {
      case GameMode.twoVsTwoHumanAi:
        return "2v2 Team Mode (You + AI Partner vs 2 AI Agents)";
      case GameMode.twoVsTwoTwoHumans:
        return "2v2 (2 Humans vs 2 AI Agents)";
      case GameMode.oneVsOne:
        return "1v1 Duel";
      case GameMode.oneVsOneVsOne:
        return "1v1v1 Cutthroat (3 Teams)";
    }
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    remainingTurnSeconds = turnMaxSeconds;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (winningTeam != null) {
        timer.cancel();
        return;
      }

      if (remainingTurnSeconds > 0) {
        remainingTurnSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _onTurnTimeout();
      }
    });
  }

  void _onTurnTimeout() {
    if (winningTeam != null) return;
    if (currentPlayer.isHuman && !isAiThinking) {
      _log("Time out! Auto-play fallback engaged.", playerName: currentPlayer.name);
      _runAiTurnForCurrentPlayer();
    }
  }

  void _log(String message, {String? playerName}) {
    final now = DateTime.now();
    final timeStr = "${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    moveLogs.insert(0, MoveLogEntry(
      playerName: playerName ?? "System",
      description: message,
      timestamp: timeStr,
    ));
    if (moveLogs.length > 20) {
      moveLogs.removeLast();
    }
  }

  bool swapDeadCard(PlayingCard card) {
    if (!currentPlayer.isHuman || winningTeam != null || isAiThinking) return false;
    if (!board.isCardDead(card)) return false;

    currentPlayer.hand.remove(card);
    discardPile.add(card);
    cardTracker.observeDiscard(card);

    final drawn = _drawOrRecycle();
    if (drawn != null) {
      currentPlayer.hand.add(drawn);
    }

    _log("Swapped dead card ${card.id} for new card.", playerName: currentPlayer.name);
    selectedCard = null;
    notifyListeners();
    return true;
  }

  PlayingCard? _drawOrRecycle() {
    if (deck.remaining == 0 && discardPile.isNotEmpty) {
      deck.recycleDiscards(discardPile);
    }
    return deck.draw();
  }

  bool playHumanMove(int r, int c) {
    if (winningTeam != null || isAiThinking) return false;
    if (!currentPlayer.isHuman) return false;

    final target = BoardCoordinate(r, c);
    final cardToPlay = selectedCard ?? hoveredCard;

    if (cardToPlay == null) return false;
    if (!currentPlayer.hand.contains(cardToPlay)) return false;

    // Check legality
    if (cardToPlay.isJack) {
      if (cardToPlay.jackType == JackType.twoEyed) {
        if (BoardLayout.isCorner(r, c) || board.getChip(r, c) != TeamId.none) {
          return false;
        }
        _executeMove(cardToPlay, target, isRemoval: false);
        return true;
      } else if (cardToPlay.jackType == JackType.oneEyed) {
        if (BoardLayout.isCorner(r, c)) return false;
        final chip = board.getChip(r, c);
        if (chip == TeamId.none || chip == currentPlayer.team) return false;
        if (board.isLocked(r, c)) return false;

        _executeMove(cardToPlay, target, isRemoval: true);
        return true;
      }
    } else {
      final validCoords = BoardLayout.cardToCoords[cardToPlay.id];
      if (validCoords == null || !validCoords.contains(target)) return false;
      if (board.getChip(r, c) != TeamId.none) return false;

      _executeMove(cardToPlay, target, isRemoval: false);
      return true;
    }

    return false;
  }

  void _executeMove(PlayingCard card, BoardCoordinate target, {required bool isRemoval}) {
    currentPlayer.hand.remove(card);
    discardPile.add(card);
    cardTracker.observeDiscard(card);
    lastMoveCoord = target;

    HapticsService.chipPlaced();

    if (isRemoval) {
      board.setChip(target.r, target.c, TeamId.none);
      _log("Played One-Eyed Jack (${card.id}) removing enemy chip at $target", playerName: currentPlayer.name);
    } else {
      board.setChip(target.r, target.c, currentPlayer.team);
      _log("Played ${card.id} at $target", playerName: currentPlayer.name);

      final newSeqs = board.checkNewSequences(target, currentPlayer.team);
      if (newSeqs.isNotEmpty) {
        board.registerSequences(newSeqs, currentPlayer.team);
        HapticsService.sequenceFormed();
        _log("★ FORMED A NEW SEQUENCE! Total: ${board.completedSequences[currentPlayer.team]?.length}/$requiredSequencesToWin",
            playerName: currentPlayer.name);
      }
    }

    final drawn = _drawOrRecycle();
    if (drawn != null) {
      currentPlayer.hand.add(drawn);
    }

    selectedCard = null;

    final teamSeqs = board.completedSequences[currentPlayer.team]?.length ?? 0;
    if (teamSeqs >= requiredSequencesToWin) {
      winningTeam = currentPlayer.team;
      _turnTimer?.cancel();
      _log("🏆 Team ${_teamName(winningTeam!)} WINS THE GAME!");
      notifyListeners();
      return;
    }

    _advanceTurn();
  }

  String _teamName(TeamId t) {
    switch (t) {
      case TeamId.blue:
        return "BLUE";
      case TeamId.green:
        return "GREEN";
      case TeamId.red:
        return "RED";
      case TeamId.none:
        return "NONE";
    }
  }

  void _advanceTurn() {
    currentTurnIndex = (currentTurnIndex + 1) % players.length;
    _startTurnTimer();
    notifyListeners();

    if (!currentPlayer.isHuman && winningTeam == null) {
      _runAiTurn();
    }
  }

  Future<void> _runAiTurn() async {
    isAiThinking = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));
    if (winningTeam != null) {
      isAiThinking = false;
      return;
    }

    _runAiTurnForCurrentPlayer();
    isAiThinking = false;
    notifyListeners();
  }

  void _runAiTurnForCurrentPlayer() {
    final deadCards = currentPlayer.hand.where((c) => board.isCardDead(c)).toList();
    if (deadCards.isNotEmpty) {
      final dead = deadCards.first;
      currentPlayer.hand.remove(dead);
      discardPile.add(dead);
      cardTracker.observeDiscard(dead);
      final drawn = _drawOrRecycle();
      if (drawn != null) {
        currentPlayer.hand.add(drawn);
      }
      _log("Exchanged dead card ${dead.id}", playerName: currentPlayer.name);
    }

    int otherCards = 0;
    for (final p in players) {
      if (p != currentPlayer) otherCards += p.hand.length;
    }

    final bestMove = aiEngine.chooseMove(
      aiPlayer: currentPlayer,
      board: board,
      cardTracker: cardTracker,
      deckRemaining: deck.remaining,
      totalOtherPlayersCards: otherCards,
    );

    if (bestMove != null) {
      _executeMove(bestMove.card, bestMove.coord, isRemoval: bestMove.isRemoval);
    } else {
      if (currentPlayer.hand.isNotEmpty) {
        final c = currentPlayer.hand.removeAt(0);
        discardPile.add(c);
        cardTracker.observeDiscard(c);
        final drawn = _drawOrRecycle();
        if (drawn != null) currentPlayer.hand.add(drawn);
        _log("Could not move, discarded ${c.id}", playerName: currentPlayer.name);
      }
      _advanceTurn();
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }
}
