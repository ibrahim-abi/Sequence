import 'package:flutter/material.dart';
import '../../core/models/game_state.dart';
import '../controllers/game_controller.dart';

class TelemetryHud extends StatelessWidget {
  final GameController controller;

  const TelemetryHud({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final blueSeqs = controller.board.completedSequences[TeamId.blue]?.length ?? 0;
    final greenSeqs = controller.board.completedSequences[TeamId.green]?.length ?? 0;
    final redSeqs = controller.board.completedSequences[TeamId.red]?.length ?? 0;
    final target = controller.requiredSequencesToWin;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF030D0A),
        border: Border(
          left: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Logo with gold metallic touch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF73), Color(0xFFB38728)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.casino, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "SEQUENCE PRO",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                tooltip: "Restart Game",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => controller.startNewGame(controller.mode),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Glassmorphic Scoreboard Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A231C).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "TEAM SCOREBOARD",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                      ),
                      child: const Text(
                        "HARDCORE AI",
                        style: TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTeamScoreRow("Team Blue", "$blueSeqs / $target", const Color(0xFF3B82F6)),
                const SizedBox(height: 6),
                _buildTeamScoreRow("Team Green", "$greenSeqs / $target", const Color(0xFF10B981)),
                if (controller.mode == GameMode.oneVsOneVsOne) ...[
                  const SizedBox(height: 6),
                  _buildTeamScoreRow("Team Red", "$redSeqs / $target", const Color(0xFFEF4444)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Deck & Discard Counters in Glassmorphic tiles
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  "DECK",
                  "${controller.deck.remaining}",
                  Icons.layers,
                  const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  "DISCARDS",
                  "${controller.discardPile.length}",
                  Icons.delete_outline,
                  const Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Turn Telemetry
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3229),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                if (controller.isAiThinking)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFFD700),
                    ),
                  )
                else
                  const Icon(Icons.person, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Turn: ${controller.currentPlayer.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Feed Header
          const Text(
            "LIVE ACTION FEED",
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),

          // Action Feed Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF020705),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: controller.moveLogs.isEmpty
                  ? const Center(
                      child: Text(
                        "No moves logged yet",
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      itemCount: controller.moveLogs.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 6),
                      itemBuilder: (context, index) {
                        final log = controller.moveLogs[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  log.playerName,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  log.timestamp,
                                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),

          // Victory Banner
          if (controller.winningTeam != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF73), Color(0xFFD4AF37)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "🏆 VICTORY!",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Team ${controller.winningTeam.toString().split('.').last.toUpperCase()} Wins!",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFFD700),
                    ),
                    onPressed: () => controller.startNewGame(controller.mode),
                    child: const Text("PLAY AGAIN"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScoreRow(String name, String score, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          score,
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF071F1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
