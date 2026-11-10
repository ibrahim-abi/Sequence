import 'package:flutter/services.dart';

class HapticsService {
  static Future<void> cardSelect() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static Future<void> chipPlaced() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> sequenceFormed() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> cardSwap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
