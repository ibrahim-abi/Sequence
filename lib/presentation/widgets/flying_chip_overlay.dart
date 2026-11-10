import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/game_state.dart';

class FlyingChipOverlay extends StatelessWidget {
  final Offset startOffset;
  final Offset endOffset;
  final double progress; // 0.0 to 1.0
  final TeamId team;

  const FlyingChipOverlay({
    super.key,
    required this.startOffset,
    required this.endOffset,
    required this.progress,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0 || progress >= 1.0) {
      return const SizedBox.shrink();
    }

    // Quadratic Bezier Curve interpolation with high arc
    final t = progress;
    final controlPoint = Offset(
      (startOffset.dx + endOffset.dx) / 2.0,
      min(startOffset.dy, endOffset.dy) - 90.0,
    );

    final currentX = (1 - t) * (1 - t) * startOffset.dx +
        2 * (1 - t) * t * controlPoint.dx +
        t * t * endOffset.dx;
    final currentY = (1 - t) * (1 - t) * startOffset.dy +
        2 * (1 - t) * t * controlPoint.dy +
        t * t * endOffset.dy;

    // Subtle scale and spin
    final scale = 1.0 + sin(t * pi) * 0.35;
    final spin = t * 2 * pi;

    Color chipColor = team == TeamId.blue
        ? const Color(0xFF2563EB)
        : team == TeamId.green
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);

    return Positioned(
      left: currentX - 16,
      top: currentY - 16,
      child: Transform.rotate(
        angle: spin,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chipColor,
              border: Border.all(color: Colors.white, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
            ),
          ),
        ),
      ),
    );
  }
}
