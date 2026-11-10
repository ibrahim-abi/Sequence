import 'package:flutter/foundation.dart';

enum Suit {
  spades,
  hearts,
  diamonds,
  clubs,
}

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

enum JackType {
  none,
  twoEyed, // JC, JD -> Wild: Place on any empty cell
  oneEyed, // JH, JS -> Anti-Wild: Remove opponent chip from unlocked sequence
}

@immutable
class PlayingCard {
  final Suit suit;
  final Rank rank;
  final String id; // e.g. "2S", "JC", "AH", "FREE"

  const PlayingCard({
    required this.suit,
    required this.rank,
    required this.id,
  });

  bool get isJack => rank == Rank.jack;

  JackType get jackType {
    if (!isJack) return JackType.none;
    if (suit == Suit.clubs || suit == Suit.diamonds) {
      return JackType.twoEyed;
    }
    return JackType.oneEyed;
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  String get rankLabel {
    switch (rank) {
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }

  static PlayingCard fromCode(String code) {
    if (code.length < 2) {
      throw ArgumentError('Invalid card code: $code');
    }
    final suitChar = code[code.length - 1].toUpperCase();
    final rankPart = code.substring(0, code.length - 1).toUpperCase();

    final Suit s;
    switch (suitChar) {
      case 'S':
        s = Suit.spades;
        break;
      case 'H':
        s = Suit.hearts;
        break;
      case 'D':
        s = Suit.diamonds;
        break;
      case 'C':
        s = Suit.clubs;
        break;
      default:
        throw ArgumentError('Unknown suit $suitChar in $code');
    }

    final Rank r;
    switch (rankPart) {
      case '2':
        r = Rank.two;
        break;
      case '3':
        r = Rank.three;
        break;
      case '4':
        r = Rank.four;
        break;
      case '5':
        r = Rank.five;
        break;
      case '6':
        r = Rank.six;
        break;
      case '7':
        r = Rank.seven;
        break;
      case '8':
        r = Rank.eight;
        break;
      case '9':
        r = Rank.nine;
        break;
      case '10':
        r = Rank.ten;
        break;
      case 'J':
        r = Rank.jack;
        break;
      case 'Q':
        r = Rank.queen;
        break;
      case 'K':
        r = Rank.king;
        break;
      case 'A':
        r = Rank.ace;
        break;
      default:
        throw ArgumentError('Unknown rank $rankPart in $code');
    }

    return PlayingCard(suit: s, rank: r, id: '$rankPart$suitChar');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => id;
}
