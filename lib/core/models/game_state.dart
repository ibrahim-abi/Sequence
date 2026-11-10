import 'dart:math';
import '../models/card.dart';

enum TeamId {
  none,
  blue,
  green,
  red,
}

enum GameMode {
  twoVsTwoHumanAi, // You + AI Partner vs 2 AI Agents
  twoVsTwoTwoHumans, // 2 Real Players vs 2 AI Agents
  oneVsOne, // 1 Human vs 1 AI
  oneVsOneVsOne, // 3 Players Cutthroat
}

class Player {
  final int seatIndex;
  final String name;
  final TeamId team;
  final bool isHuman;
  final List<PlayingCard> hand;

  Player({
    required this.seatIndex,
    required this.name,
    required this.team,
    required this.isHuman,
    List<PlayingCard>? hand,
  }) : hand = hand ?? [];

  Player copyWith({
    int? seatIndex,
    String? name,
    TeamId? team,
    bool? isHuman,
    List<PlayingCard>? hand,
  }) {
    return Player(
      seatIndex: seatIndex ?? this.seatIndex,
      name: name ?? this.name,
      team: team ?? this.team,
      isHuman: isHuman ?? this.isHuman,
      hand: hand ?? List<PlayingCard>.from(this.hand),
    );
  }
}

class Deck {
  final List<PlayingCard> _cards = [];
  final Random _rng = Random();

  Deck() {
    reset();
  }

  void reset() {
    _cards.clear();
    // 2 standard 52-card decks without Jokers = 104 cards
    for (int deckNum = 0; deckNum < 2; deckNum++) {
      for (final suit in Suit.values) {
        for (final rank in Rank.values) {
          final sChar = suit == Suit.spades
              ? 'S'
              : suit == Suit.hearts
                  ? 'H'
                  : suit == Suit.diamonds
                      ? 'D'
                      : 'C';
          final rLabel = PlayingCard(suit: suit, rank: rank, id: '').rankLabel;
          _cards.add(PlayingCard(suit: suit, rank: rank, id: '$rLabel$sChar'));
        }
      }
    }
    shuffle();
  }

  void shuffle() {
    for (int i = _cards.length - 1; i > 0; i--) {
      int j = _rng.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  int get remaining => _cards.length;

  PlayingCard? draw() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  void recycleDiscards(List<PlayingCard> discards) {
    _cards.addAll(discards);
    shuffle();
    discards.clear();
  }
}
