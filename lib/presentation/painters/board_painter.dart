import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/card.dart';
import '../../core/models/board_layout.dart';
import '../../core/models/game_state.dart';
import '../../core/engine/sequence_rules.dart';

class BoardPainter extends CustomPainter {
  final BoardState boardState;
  final PlayingCard? hoveredCard;
  final BoardCoordinate? selectedCoord;
  final BoardCoordinate? lastMoveCoord;
  final TeamId currentTurnTeam;

  BoardPainter({
    required this.boardState,
    this.hoveredCard,
    this.selectedCoord,
    this.lastMoveCoord,
    required this.currentTurnTeam,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 10.0;
    final cellHeight = size.height / 10.0;

    // 1. Luxury Casino Emerald Felt Background with Vignette & Micro-Texture
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Color(0xFF0D3328), // Deep vibrant emerald center
          Color(0xFF061A14), // Dark casino felt
          Color(0xFF020907), // Black vignette edge
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Brass / Gold Beveled Framing
    final outerFramePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFDF73), // Bright gold shine
          Color(0xFFB38728), // Deep antique brass
          Color(0xFFFBF5B7), // Specular light hit
          Color(0xFFAA771C), // Rich shadow gold
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
        const Radius.circular(10),
      ),
      outerFramePaint,
    );

    // Collect valid hover targets
    final hoverTargets = <BoardCoordinate>{};
    bool isTwoEyedJackHover = false;
    bool isOneEyedJackHover = false;

    if (hoveredCard != null) {
      if (hoveredCard!.isJack) {
        if (hoveredCard!.jackType == JackType.twoEyed) {
          isTwoEyedJackHover = true;
        } else if (hoveredCard!.jackType == JackType.oneEyed) {
          isOneEyedJackHover = true;
        }
      } else {
        final coords = BoardLayout.cardToCoords[hoveredCard!.id];
        if (coords != null) {
          hoverTargets.addAll(coords);
        }
      }
    }

    // 3. Render 100 Board Cells (Cards & Corners)
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final rect = Rect.fromLTWH(
          c * cellWidth + 2.5,
          r * cellHeight + 2.5,
          cellWidth - 5.0,
          cellHeight - 5.0,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7.0));
        final code = BoardLayout.matrix[r][c];
        final isCorner = BoardLayout.isCorner(r, c);

        final isTargeted = hoverTargets.contains(BoardCoordinate(r, c));
        final isJackValidEmpty = isTwoEyedJackHover && !isCorner && boardState.getChip(r, c) == TeamId.none;
        final isJackRemovable = isOneEyedJackHover &&
            !isCorner &&
            boardState.getChip(r, c) != TeamId.none &&
            boardState.getChip(r, c) != currentTurnTeam &&
            !boardState.isLocked(r, c);

        // Draw Card Multi-Layer Shadow for 3D elevation
        final cardShadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
        canvas.drawRRect(rrect.shift(const Offset(0.5, 1.5)), cardShadowPaint);

        // Card Face Gradient
        final cardFacePaint = Paint();
        if (isCorner) {
          cardFacePaint.shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ).createShader(rect);
        } else {
          cardFacePaint.shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isTargeted
                ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF4EDE4)],
          ).createShader(rect);
        }
        canvas.drawRRect(rrect, cardFacePaint);

        // Card Border with subtle metallic or glow effect
        final cardBorderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (isTargeted || isJackValidEmpty || isJackRemovable) ? 2.5 : 1.0;

        if (isCorner) {
          cardBorderPaint.color = const Color(0xFFFFD700);
        } else if (isTargeted) {
          cardBorderPaint.color = const Color(0xFFFFD700);
        } else if (isJackValidEmpty) {
          cardBorderPaint.color = const Color(0xFF00E5FF);
        } else if (isJackRemovable) {
          cardBorderPaint.color = const Color(0xFFFF1744);
        } else {
          cardBorderPaint.color = const Color(0xFFD1D5DB).withValues(alpha: 0.85);
        }
        canvas.drawRRect(rrect, cardBorderPaint);

        // Inner Card Content (Pip & Suit Vector Graphics)
        if (isCorner) {
          _drawCornerSymbol(canvas, rect);
        } else {
          _drawCardContent(canvas, rect, code);
        }

        // Draw Placed Chip
        final chip = boardState.getChip(r, c);
        if (chip != TeamId.none) {
          final isLocked = boardState.isLocked(r, c);
          _draw3DPokerChip(
            canvas: canvas,
            center: rect.center,
            radius: min(cellWidth, cellHeight) * 0.38,
            team: chip,
            isLocked: isLocked,
          );
        } else if (isTargeted || isJackValidEmpty) {
          _drawGhostChip(
            canvas: canvas,
            center: rect.center,
            radius: min(cellWidth, cellHeight) * 0.38,
            team: currentTurnTeam,
          );
        }

        // Draw Crosshair Marker for Removable Chips
        if (isJackRemovable) {
          _drawRemovalMarker(canvas, rect.center, min(cellWidth, cellHeight) * 0.40);
        }

        // Last Move Pulse Ring
        if (lastMoveCoord != null && lastMoveCoord!.r == r && lastMoveCoord!.c == c) {
          final lastMoveGlow = Paint()
            ..color = const Color(0xFFFFD700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
          canvas.drawCircle(rect.center, min(cellWidth, cellHeight) * 0.44, lastMoveGlow);
        }
      }
    }

    // 4. Laser Beams for Completed Sequences
    _drawSequenceLaserLines(canvas, cellWidth, cellHeight);
  }

  void _drawCornerSymbol(Canvas canvas, Rect rect) {
    // Elegant Casino Gold Star
    final starPainter = TextPainter(
      text: const TextSpan(
        text: '★\nFREE',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    starPainter.paint(
      canvas,
      Offset(rect.center.dx - starPainter.width / 2, rect.center.dy - starPainter.height / 2),
    );
  }

  void _drawCardContent(Canvas canvas, Rect rect, String code) {
    if (code.length < 2) return;
    final suitChar = code[code.length - 1];
    final rankPart = code.substring(0, code.length - 1);

    final isRed = suitChar == 'H' || suitChar == 'D';
    final suitSymbol = suitChar == 'S'
        ? '♠'
        : suitChar == 'H'
            ? '♥'
            : suitChar == 'D'
                ? '♦'
                : '♣';

    final textColor = isRed ? const Color(0xFFDC2626) : const Color(0xFF0F172A);

    final fontSize = (rect.width * 0.36).clamp(16.0, 32.0);
    final suitSize = (rect.width * 0.40).clamp(18.0, 34.0);

    final span = TextSpan(
      children: [
        TextSpan(
          text: '$rankPart\n',
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 0.90,
          ),
        ),
        TextSpan(
          text: suitSymbol,
          style: TextStyle(
            color: textColor,
            fontSize: suitSize,
            height: 1.0,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    textPainter.paint(
      canvas,
      Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
    );
  }

  void _draw3DPokerChip({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required TeamId team,
    required bool isLocked,
  }) {
    Color baseColor;
    Color lightColor;
    Color darkColor;

    switch (team) {
      case TeamId.blue:
        baseColor = const Color(0xFF2563EB);
        lightColor = const Color(0xFF93C5FD);
        darkColor = const Color(0xFF1E3A8A);
        break;
      case TeamId.green:
        baseColor = const Color(0xFF059669);
        lightColor = const Color(0xFF6EE7B7);
        darkColor = const Color(0xFF064E3B);
        break;
      case TeamId.red:
        baseColor = const Color(0xFFDC2626);
        lightColor = const Color(0xFFFCA5A5);
        darkColor = const Color(0xFF7F1D1D);
        break;
      case TeamId.none:
        return;
    }

    // Heavy Drop Shadow for tactile 3D feel
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center.translate(1.8, 2.5), radius, shadowPaint);

    // Beveled Chip Base Gradient
    final chipBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        colors: [lightColor, baseColor, darkColor],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, chipBodyPaint);

    // Outer Casino Inlay Dashed Ring
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, radius - 2.0, rimPaint);

    // Inner Recessed Poker Well
    final innerWellPaint = Paint()
      ..color = darkColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius * 0.56, innerWellPaint);

    // Specular Highlight Glint
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 3.2),
      -pi * 0.75,
      pi * 0.5,
      false,
      glintPaint,
    );

    // Locked Sequence Crown
    if (isLocked) {
      final lockGlowPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8;
      canvas.drawCircle(center, radius + 1.8, lockGlowPaint);

      final starPainter = TextPainter(
        text: const TextSpan(
          text: '★',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      starPainter.paint(
        canvas,
        Offset(center.dx - starPainter.width / 2, center.dy - starPainter.height / 2),
      );
    }
  }

  void _drawGhostChip({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required TeamId team,
  }) {
    Color previewColor = team == TeamId.blue
        ? const Color(0xFF60A5FA)
        : team == TeamId.green
            ? const Color(0xFF34D399)
            : const Color(0xFFF87171);

    final ghostPaint = Paint()
      ..color = previewColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ghostPaint);

    final ghostBorder = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, radius, ghostBorder);
  }

  void _drawRemovalMarker(Canvas canvas, Offset center, double radius) {
    final crossPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    canvas.drawLine(
      Offset(center.dx - radius * 0.65, center.dy - radius * 0.65),
      Offset(center.dx + radius * 0.65, center.dy + radius * 0.65),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.65, center.dy - radius * 0.65),
      Offset(center.dx - radius * 0.65, center.dy + radius * 0.65),
      crossPaint,
    );
  }

  void _drawSequenceLaserLines(Canvas canvas, double cellWidth, double cellHeight) {
    for (final entry in boardState.completedSequences.entries) {
      final team = entry.key;
      final seqs = entry.value;

      Color laserColor = team == TeamId.blue
          ? const Color(0xFF3B82F6)
          : team == TeamId.green
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444);

      for (final seq in seqs) {
        if (seq.coords.length < 5) continue;
        final startCoord = seq.coords.first;
        final endCoord = seq.coords.last;

        final startPoint = Offset(
          startCoord.c * cellWidth + cellWidth / 2,
          startCoord.r * cellHeight + cellHeight / 2,
        );
        final endPoint = Offset(
          endCoord.c * cellWidth + cellWidth / 2,
          endCoord.r * cellHeight + cellHeight / 2,
        );

        // Neon Blur
        final glowPaint = Paint()
          ..color = laserColor.withValues(alpha: 0.45)
          ..strokeWidth = 9.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
        canvas.drawLine(startPoint, endPoint, glowPaint);

        // Gold Laser Core
        final corePaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 3.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(startPoint, endPoint, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
