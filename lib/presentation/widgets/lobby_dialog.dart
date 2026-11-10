import 'package:flutter/material.dart';
import '../../core/models/game_state.dart';

class LobbyDialog extends StatelessWidget {
  final GameMode currentMode;
  final ValueChanged<GameMode> onSelectMode;
  final VoidCallback onStartRadarMatchmaking;

  const LobbyDialog({
    super.key,
    required this.currentMode,
    required this.onSelectMode,
    required this.onStartRadarMatchmaking,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF041512),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.casino, color: Color(0xFFFFD700), size: 24),
          SizedBox(width: 10),
          Text(
            "GAME LOBBY",
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent Online Matchmaking Radar Button
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onStartRadarMatchmaking();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "PLAY 2v2 ONLINE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "POPULAR",
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Fast matchmaking radar with 12s bot fallback.",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "OR SELECT LOCAL / TABLE MODE:",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),

            _buildModeTile(
              mode: GameMode.twoVsTwoHumanAi,
              title: "Mode A: 2v2 (You + AI Partner vs 2 AI)",
              desc: "4 Players, alternating turns, zero-cheat mathematical AI partner.",
              badge: "DEFAULT",
            ),
            const SizedBox(height: 8),
            _buildModeTile(
              mode: GameMode.twoVsTwoTwoHumans,
              title: "Mode B: 2v2 (2 Humans vs 2 AI)",
              desc: "Two human players team up against 2 mathematical AI agents.",
            ),
            const SizedBox(height: 8),
            _buildModeTile(
              mode: GameMode.oneVsOne,
              title: "Mode C: 1v1 Duel",
              desc: "1 Human vs 1 AI Agent (7 cards each, 2 sequences to win).",
            ),
            const SizedBox(height: 8),
            _buildModeTile(
              mode: GameMode.oneVsOneVsOne,
              title: "Mode D: 1v1v1 Cutthroat (3 Teams)",
              desc: "3 Players: Blue vs Green vs Red (6 cards each, 1 sequence to win).",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "CLOSE",
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTile({
    required GameMode mode,
    required String title,
    required String desc,
    String? badge,
  }) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: () => onSelectMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3B32) : const Color(0xFF071F1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
