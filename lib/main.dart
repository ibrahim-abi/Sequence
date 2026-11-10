import 'package:flutter/material.dart';
import 'core/models/card.dart';
import 'core/models/game_state.dart';
import 'core/audio_haptics/haptics_service.dart';
import 'presentation/controllers/game_controller.dart';
import 'presentation/painters/board_painter.dart';
import 'presentation/widgets/curved_hand_fan.dart';
import 'presentation/widgets/telemetry_hud.dart';
import 'presentation/widgets/lobby_dialog.dart';
import 'presentation/widgets/top_players_bar.dart';
import 'features/lobby/widgets/matchmaking_radar_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SequenceApp());
}

class SequenceApp extends StatelessWidget {
  const SequenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sequence Pro — 2v2 Mathematical AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF04120E),
      ),
      home: const SequenceGameScreen(),
    );
  }
}

class SequenceGameScreen extends StatefulWidget {
  const SequenceGameScreen({super.key});

  @override
  State<SequenceGameScreen> createState() => _SequenceGameScreenState();
}

class _SequenceGameScreenState extends State<SequenceGameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _showLobbyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => LobbyDialog(
        currentMode: _controller.mode,
        onSelectMode: (mode) {
          Navigator.of(ctx).pop();
          _controller.startNewGame(mode);
        },
        onStartRadarMatchmaking: _showRadarDialog,
      ),
    );
  }

  void _showRadarDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MatchmakingRadarDialog(
        mode: GameMode.twoVsTwoHumanAi,
        onMatchReady: (mode) {
          _controller.startNewGame(mode);
        },
      ),
    );
  }

  Widget _buildDeckVisual() {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030D0A),
        border: Border(
          right: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "DRAW DECK",
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          // 3D Stack of Cards
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(3.5, 3.5),
                child: _buildDeckCardBack(),
              ),
              Transform.translate(
                offset: const Offset(1.8, 1.8),
                child: _buildDeckCardBack(),
              ),
              _buildDeckCardBack(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${_controller.deck.remaining} CARDS",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          // Discard Pile
          const Text(
            "DISCARD",
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          if (_controller.discardPile.isNotEmpty)
            _buildDiscardCardFace(_controller.discardPile.last)
          else
            Container(
              width: 55,
              height: 75,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text("EMPTY", style: TextStyle(color: Colors.white24, fontSize: 8.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeckCardBack() {
    return Container(
      width: 58,
      height: 82,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF831843), Color(0xFF4C0519)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.style, color: Color(0xFFFFD700), size: 22),
      ),
    );
  }

  Widget _buildDiscardCardFace(PlayingCard card) {
    final isRed = card.isRed;
    return Container(
      width: 58,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.rankLabel,
              style: TextStyle(
                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              card.suitSymbol,
              style: TextStyle(
                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF04120E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.casino, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 8),
            const Text(
              "SEQUENCE — PRO 2v2",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 12),

            // Quick Play Radar Button
            ElevatedButton.icon(
              icon: const Icon(Icons.radar, size: 15, color: Colors.black),
              label: const Text(
                "QUICK MATCH",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: _showRadarDialog,
            ),
            const SizedBox(width: 8),

            OutlinedButton.icon(
              icon: const Icon(Icons.settings, size: 15, color: Color(0xFFFFD700)),
              label: const Text(
                "LOBBY",
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4AF37)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: _showLobbyDialog,
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left Side: 3D Visual Draw Deck & Discard Tray
          _buildDeckVisual(),

          // Center: Top Players Bar + Interactive 10x10 Board Stage + Curved Fan Hand
          Expanded(
            child: Column(
              children: [
                // Top 4-Player Seating Bar with 20s Circular Countdown Timer
                TopPlayersBar(controller: _controller),

                // 10x10 Board Stage with InteractiveViewer (Pinch-to-zoom on Mobile)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 2.5,
                              child: GestureDetector(
                                onTapUp: (details) {
                                  final cellSize = constraints.maxWidth / 10.0;
                                  final col = (details.localPosition.dx / cellSize).floor().clamp(0, 9);
                                  final row = (details.localPosition.dy / cellSize).floor().clamp(0, 9);
                                  HapticsService.cardSelect();
                                  _controller.playHumanMove(row, col);
                                },
                                child: CustomPaint(
                                  size: Size(constraints.maxWidth, constraints.maxHeight),
                                  painter: BoardPainter(
                                    boardState: _controller.board,
                                    hoveredCard: _controller.selectedCard ?? _controller.hoveredCard,
                                    selectedCoord: _controller.lastMoveCoord,
                                    lastMoveCoord: _controller.lastMoveCoord,
                                    currentTurnTeam: _controller.currentPlayer.team,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Curved Fan Hand Dock with -24px Lift & Dead Card Swap
                CurvedHandFan(controller: _controller),
              ],
            ),
          ),

          // Telemetry HUD Sidebar
          TelemetryHud(controller: _controller),
        ],
      ),
    );
  }
}
