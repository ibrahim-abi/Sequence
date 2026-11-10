import '../models/card.dart';

class CardTracker {
  // Total copies per card initially = 2
  static const int initialCopies = 2;

  // Track discards observed publicly
  final Map<String, int> _discardCounts = {};

  // Track chips currently on board for each card
  // (Note: Two-Eyed Jacks placed on a cell don't consume that cell's printed card)

  CardTracker();

  void reset() {
    _discardCounts.clear();
  }

  void observeDiscard(PlayingCard card) {
    _discardCounts[card.id] = (_discardCounts[card.id] ?? 0) + 1;
  }

  /// Calculates remaining unseen copies of card `c` from the perspective of an AI player holding `aiHand`.
  int getUnseenCopies(String cardId, List<PlayingCard> aiHand) {
    int discarded = _discardCounts[cardId] ?? 0;
    int inHand = 0;
    for (final c in aiHand) {
      if (c.id == cardId) {
        inHand++;
      }
    }
    int remaining = initialCopies - discarded - inHand;
    return remaining > 0 ? remaining : 0;
  }

  /// Total unseen cards remaining in draw deck + opponent/teammate hands
  int getTotalUnseenCards(int deckRemaining, int totalOtherPlayersCards) {
    return deckRemaining + totalOtherPlayersCards;
  }

  /// Probability that a specific card rank/suit is still live/drawable
  double pLive(String cardId, List<PlayingCard> aiHand, int totalUnseenPool) {
    if (totalUnseenPool <= 0) return 0.0;
    int unseen = getUnseenCopies(cardId, aiHand);
    return unseen / totalUnseenPool;
  }

  /// Probability of any Two-Eyed Jack (JC, JD) remaining unseen
  double pWild(List<PlayingCard> aiHand, int totalUnseenPool) {
    if (totalUnseenPool <= 0) return 0.0;
    int unseenJC = getUnseenCopies("JC", aiHand);
    int unseenJD = getUnseenCopies("JD", aiHand);
    return (unseenJC + unseenJD) / totalUnseenPool;
  }

  /// Probability of any One-Eyed Jack (JH, JS) remaining unseen
  double pRemove(List<PlayingCard> aiHand, int totalUnseenPool) {
    if (totalUnseenPool <= 0) return 0.0;
    int unseenJH = getUnseenCopies("JH", aiHand);
    int unseenJS = getUnseenCopies("JS", aiHand);
    return (unseenJH + unseenJS) / totalUnseenPool;
  }
}
