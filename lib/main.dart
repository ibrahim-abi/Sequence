import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'core/models/game_state.dart';
import 'presentation/controllers/game_controller.dart';
import 'presentation/painters/board_painter.dart';
import 'presentation/widgets/player_hand_bar.dart';
import 'presentation/widgets/telemetry_hud.dart';
import 'presentation/widgets/lobby_dialog.dart';

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
        scaffoldBackgroundColor: const Color(0xFF041210),
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
      ),
    );
  }

  Widget _buildTopFourPlayersBar() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF061A16),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = _controller.players[index];
          final isTurn = _controller.currentPlayer == p;
          final color = p.team == TeamId.blue
              ? const Color(0xFF2563EB)
              : p.team == TeamId.green
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isTurn ? color.withValues(alpha: 0.3) : const Color(0xFF0B2B26),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isTurn ? const Color(0xFFFFD700) : Colors.white12,
                width: isTurn ? 1.8 : 1.0,
              ),
              boxShadow: isTurn
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        color: isTurn ? Colors.white : Colors.white70,
                        fontSize: 11,
                        fontWeight: isTurn ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      isTurn ? (p.isHuman ? "ACTIVE (YOU)" : "THINKING...") : "${p.hand.length} cards",
                      style: TextStyle(
                        color: isTurn ? const Color(0xFFFFD700) : Colors.white38,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeckVisual() {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF041512),
        border: Border(
          right: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
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
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // 3D Stack of Cards Representation
          Stack(
            alignment: Alignment.center,
            children: [
              // Bottom card shadow
              Transform.translate(
                offset: const Offset(4, 4),
                child: _buildDeckCardBack(),
              ),
              // Middle card
              Transform.translate(
                offset: const Offset(2, 2),
                child: _buildDeckCardBack(),
              ),
              // Top active card
              _buildDeckCardBack(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${_controller.deck.remaining} CARDS",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Discard Pile Top
          const Text(
            "DISCARD",
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (_controller.discardPile.isNotEmpty)
            _buildDiscardCardFace(_controller.discardPile.last)
          else
            Container(
              width: 55,
              height: 75,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text("EMPTY", style: TextStyle(color: Colors.white24, fontSize: 9)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeckCardBack() {
    return Container(
      width: 60,
      height: 85,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF831843), Color(0xFF4C0519)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.style, color: Color(0xFFFFD700), size: 24),
      ),
    );
  }

  Widget _buildDiscardCardFace(card) {
    final isRed = card.isRed;
    return Container(
      width: 60,
      height: 85,
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
                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              card.suitSymbol,
              style: TextStyle(
                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                fontSize: 18,
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
        backgroundColor: const Color(0xFF061815),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.style, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            const Text(
              "SEQUENCE — PRO 2v2 EDITION",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.settings, size: 16, color: Color(0xFFFFD700)),
              label: const Text(
                "GAME MODE",
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4AF37)),
              ),
              onPressed: _showLobbyDialog,
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left Side: 3D Visual Draw Deck & Discard Pile
          _buildDeckVisual(),

          // Center: Top 4-Player Indicators + 10x10 Board Stage + Hand Bar
          Expanded(
            child: Column(
              children: [
                // Top All-Players Seating & Turn Indicator
                _buildTopFourPlayersBar(),

                // 10x10 Board Stage
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTapUp: (details) {
                                final cellSize = constraints.maxWidth / 10.0;
                                final col = (details.localPosition.dx / cellSize).floor().clamp(0, 9);
                                final row = (details.localPosition.dy / cellSize).floor().clamp(0, 9);
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
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Player Hand Bar at bottom
                PlayerHandBar(controller: _controller),
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
