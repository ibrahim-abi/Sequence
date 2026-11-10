import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/models/game_state.dart';

class MatchmakingRadarDialog extends StatefulWidget {
  final GameMode mode;
  final ValueChanged<GameMode> onMatchReady;

  const MatchmakingRadarDialog({
    super.key,
    required this.mode,
    required this.onMatchReady,
  });

  @override
  State<MatchmakingRadarDialog> createState() => _MatchmakingRadarDialogState();
}

class _MatchmakingRadarDialogState extends State<MatchmakingRadarDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  int _secondsLeft = 12;
  int _playersFound = 1;
  Timer? _countdownTimer;
  Timer? _playersTimer;
  final String _roomCode = "SEQ-${(Random().nextInt(899) + 100)}";

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startMatchmaking();
  }

  void _startMatchmaking() {
    // Simulate finding players or filling with AI bots
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          timer.cancel();
          _finalizeMatch();
        }
      });
    });

    // Random human/bot connection ticks
    _playersTimer = Timer.periodic(const Duration(milliseconds: 2800), (timer) {
      if (!mounted) return;
      if (_playersFound < 4) {
        setState(() {
          _playersFound++;
        });
        if (_playersFound == 4) {
          timer.cancel();
          _finalizeMatch();
        }
      }
    });
  }

  void _finalizeMatch() {
    _countdownTimer?.cancel();
    _playersTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMatchReady(widget.mode);
      }
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _countdownTimer?.cancel();
    _playersTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF041512),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 8),
                const Text(
                  "ONLINE MATCHMAKING",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _roomCode,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Animated Radar Scan Circle
            SizedBox(
              width: 140,
              height: 140,
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarSweepPainter(progress: _radarController.value),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$_playersFound/4",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            "PLAYERS",
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Status description
            Text(
              _playersFound == 4
                  ? "✓ Table Ready! Launching Match..."
                  : "Searching for Global Players ($_secondsLeft s)...",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Smart Liquidity Engine: Empty seats will be filled by Master AI Bots if timeout occurs.",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Cancel button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                foregroundColor: Colors.white70,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL SEARCH"),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double progress;

  _RadarSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.4, ringPaint);
    canvas.drawCircle(center, radius * 0.7, ringPaint);
    canvas.drawCircle(center, radius, ringPaint);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Radar Sweep Beam
    final sweepAngle = progress * 2 * pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi * 0.5,
        colors: [
          const Color(0xFF34D399).withValues(alpha: 0.45),
          const Color(0xFF34D399).withValues(alpha: 0.0),
        ],
        transform: GradientRotation(sweepAngle - pi * 0.5),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
