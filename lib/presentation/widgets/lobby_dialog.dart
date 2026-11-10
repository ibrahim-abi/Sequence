import 'package:flutter/material.dart';
import '../../core/models/game_state.dart';

class LobbyDialog extends StatelessWidget {
  final GameMode currentMode;
  final ValueChanged<GameMode> onSelectMode;

  const LobbyDialog({
    super.key,
    required this.currentMode,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF071F1B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.style, color: Color(0xFFFFD700), size: 24),
          SizedBox(width: 10),
          Text(
            "SELECT GAME MODE",
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
            _buildModeTile(
              mode: GameMode.twoVsTwoHumanAi,
              title: "Mode A: 2v2 (You + AI Partner vs 2 AI)",
              desc: "4 Players, alternating turns, zero-cheat mathematical AI partner (2 sequences to win).",
              badge: "RECOMMENDED",
            ),
            const SizedBox(height: 10),
            _buildModeTile(
              mode: GameMode.twoVsTwoTwoHumans,
              title: "Mode B: 2v2 (2 Humans vs 2 AI)",
              desc: "Two human players team up against 2 mathematical AI agents.",
            ),
            const SizedBox(height: 10),
            _buildModeTile(
              mode: GameMode.oneVsOne,
              title: "Mode C: 1v1 Duel",
              desc: "1 Human vs 1 AI Agent (7 cards each, 2 sequences to win).",
            ),
            const SizedBox(height: 10),
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
            "CANCEL",
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3B32) : const Color(0xFF0B2B26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white54,
            ),
            const SizedBox(width: 12),
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
                          fontSize: 13,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
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
