import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color midnightObsidian = Color(0xFF04120E);
  static const Color deepFeltGreen = Color(0xFF092921);
  static const Color royalEmerald = Color(0xFF0D3B30);
  static const Color feltVignette = Color(0xFF020907);

  // Metallic Gold Accents
  static const Color goldBright = Color(0xFFFFDF73);
  static const Color goldMetallic = Color(0xFFFFD700);
  static const Color goldAntique = Color(0xFFB38728);
  static const Color goldDark = Color(0xFFAA771C);

  // Team Colors
  static const Color teamBlue = Color(0xFF2563EB);
  static const Color teamBlueGlow = Color(0xFF60A5FA);
  static const Color teamGreen = Color(0xFF059669);
  static const Color teamGreenGlow = Color(0xFF34D399);
  static const Color teamRed = Color(0xFFDC2626);
  static const Color teamRedGlow = Color(0xFFF87171);

  // Cards & Surfaces
  static const Color cardFace = Color(0xFFFAF6F0);
  static const Color cardFaceHighLight = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFCBD5E1);
  static const Color cardSpotlightGlow = Color(0xFFFFD700);

  // Jack Accents
  static const Color jackTwoEyed = Color(0xFF0284C7);
  static const Color jackOneEyed = Color(0xFFDC2626);

  // Status & Badges
  static const Color deadCardBurn = Color(0xFFEF4444);
  static const Color turnActiveGlow = Color(0xFFFFD700);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldBright, goldMetallic, goldAntique],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient feltGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [royalEmerald, deepFeltGreen, feltVignette],
    stops: [0.0, 0.65, 1.0],
  );
}
