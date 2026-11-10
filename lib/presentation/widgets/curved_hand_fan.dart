import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/card.dart';
import '../../core/audio_haptics/haptics_service.dart';
import '../controllers/game_controller.dart';

class CurvedHandFan extends StatelessWidget {
  final GameController controller;

  const CurvedHandFan({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final player = controller.currentPlayer;
    final hand = player.hand;
    final count = hand.length;

    if (count == 0) {
      return const SizedBox(height: 140);
    }

    return Container(
      height: 145,
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF04120E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
      child: Center(
        child: SizedBox(
          height: 135,
          width: min(count * 62.0 + 70.0, 500.0),
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: List.generate(count, (index) {
              final card = hand[index];
              final isDead = controller.board.isCardDead(card);
              final isSelected = controller.selectedCard == card;
              final isHovered = controller.hoveredCard == card;

              // Fan rotation angle and vertical arc offset
              final centerOffset = index - (count - 1) / 2.0;
              final angle = centerOffset * 0.065; // ~3.7 degrees per card
              final arcY = pow(centerOffset.abs(), 1.6) * 5.0; // parabolic curve
              final liftY = (isSelected || isHovered) ? -24.0 : 0.0;

              // Card horizontal spacing
              final spacing = (count > 6) ? 46.0 : 54.0;
              final posX = centerOffset * spacing;

              return Transform.translate(
                offset: Offset(posX, arcY + liftY),
                child: Transform.rotate(
                  angle: angle,
                  child: MouseRegion(
                    onEnter: (_) {
                      controller.setHoveredCard(card);
                    },
                    onExit: (_) {
                      if (controller.hoveredCard == card) {
                        controller.setHoveredCard(null);
                      }
                    },
                    child: GestureDetector(
                      onTap: () {
                        HapticsService.cardSelect();
                        if (isDead) {
                          HapticsService.cardSwap();
                          controller.swapDeadCard(card);
                        } else {
                          controller.selectCard(card);
                        }
                      },
                      child: _buildCard(card, isDead, isSelected, isHovered),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(PlayingCard card, bool isDead, bool isSelected, bool isHovered) {
    final textColor = card.isRed ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 78,
      height: 116,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFBEB) : const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFFFD700).withValues(alpha: 0.85)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: isSelected ? 16 : 7,
            spreadRadius: isSelected ? 3.0 : 0.5,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700)
              : isDead
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFCBD5E1),
          width: isSelected || isDead ? 2.6 : 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Subtle card pattern rim
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.5),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
            ),
          ),

          // Card Content: Rank, Suit, Jack Type
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    height: 1.0,
                  ),
                ),
                if (card.isJack) ...[
                  const SizedBox(height: 2),
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

          // Fiery Dead Card Badge
          if (isDead)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: const Text(
                  "DEAD 🔥 SWAP",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
