import 'package:flutter/material.dart';
import '../../core/models/game_state.dart';
import '../controllers/game_controller.dart';

class TopPlayersBar extends StatelessWidget {
  final GameController controller;

  const TopPlayersBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF04120E),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.players.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = controller.players[index];
          final isTurn = controller.currentPlayer == p;
          final isSpeaking = controller.activeSpeakerSeat == p.seatIndex &&
              controller.activeSpeechText != null;
          final color = p.team == TeamId.blue
              ? const Color(0xFF2563EB)
              : p.team == TeamId.green
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626);

          final timerProgress = isTurn
              ? (controller.remainingTurnSeconds / 20.0).clamp(0.0, 1.0)
              : 0.0;
          final isUrgent = isTurn && controller.remainingTurnSeconds <= 5;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTurn ? color.withValues(alpha: 0.28) : const Color(0xFF09241E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTurn
                    ? (isUrgent ? const Color(0xFFEF4444) : const Color(0xFFFFD700))
                    : (isSpeaking ? const Color(0xFFFFDF73) : Colors.white12),
                width: isTurn || isSpeaking ? 1.8 : 1.0,
              ),
              boxShadow: isTurn
                  ? [
                      BoxShadow(
                        color: (isUrgent
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFFFD700))
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular 20-second turn countdown around player avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isTurn)
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: timerProgress,
                          strokeWidth: 2.5,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isUrgent
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: color,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Name & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: isTurn ? Colors.white : Colors.white70,
                        fontSize: 11.5,
                        fontWeight: isTurn ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isTurn
                              ? "${controller.remainingTurnSeconds}s"
                              : "${p.hand.length} cards",
                          style: TextStyle(
                            color: isTurn
                                ? (isUrgent
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFFFD700))
                                : Colors.white38,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (p.isHuman) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              "YOU",
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              "AI PRO",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Dynamic Speech & Strategy Bubble
                if (isSpeaking) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology,
                            size: 13, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            controller.activeSpeechText!,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
