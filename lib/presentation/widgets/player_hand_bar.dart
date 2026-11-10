import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/card.dart';
import '../../core/models/game_state.dart';
import '../controllers/game_controller.dart';

class PlayerHandBar extends StatelessWidget {
  final GameController controller;

  const PlayerHandBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final player = controller.currentPlayer;
    final isHuman = player.isHuman;
    final hand = player.hand;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF061815),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Player info badge with pulse animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: player.team == TeamId.blue
                  ? const Color(0xFF1E3A8A)
                  : player.team == TeamId.green
                      ? const Color(0xFF065F46)
                      : const Color(0xFF991B1B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isHuman ? "YOUR TURN" : "AI THINKING...",
                  style: TextStyle(
                    color: isHuman ? const Color(0xFFFFD700) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate(target: isHuman ? 1 : 0)
              .shimmer(duration: 1200.ms, color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
          const SizedBox(width: 16),

          // Cards list
          Expanded(
            child: SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hand.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final card = hand[index];
                  final isDead = controller.board.isCardDead(card);
                  final isSelected = controller.selectedCard == card;
                  final isHovered = controller.hoveredCard == card;

                  return MouseRegion(
                    onEnter: (_) => controller.setHoveredCard(card),
                    onExit: (_) {
                      if (controller.hoveredCard == card) {
                        controller.setHoveredCard(null);
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (isDead) {
                          controller.swapDeadCard(card);
                        } else {
                          controller.selectCard(card);
                        }
                      },
                      child: _buildCardItem(card, isDead, isSelected, isHovered)
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(PlayingCard card, bool isDead, bool isSelected, bool isHovered) {
    final textColor = card.isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 86,
      margin: EdgeInsets.only(top: isSelected || isHovered ? 0 : 8, bottom: isSelected || isHovered ? 8 : 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: isSelected ? 14 : 6,
            spreadRadius: isSelected ? 2.5 : 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700)
              : isDead
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
          width: isSelected || isDead ? 2.8 : 1.4,
        ),
      ),
      child: Stack(
        children: [
          // Card Rank & Suit
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    height: 1.0,
                  ),
                ),
                if (card.isJack) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: card.jackType == JackType.twoEyed
                            ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                            : [const Color(0xFFDC2626), const Color(0xFF991B1B)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.jackType == JackType.twoEyed ? "2-EYED" : "1-EYED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Dead card badge
          if (isDead)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  "DEAD\nSWAP",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
