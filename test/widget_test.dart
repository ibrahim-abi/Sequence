import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sequence_game/main.dart';

void main() {
  testWidgets('Sequence App builds and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const SequenceApp());
    expect(find.textContaining('SEQUENCE'), findsWidgets);

    // Fast-forward pending speech bubble timers
    await tester.pump(const Duration(seconds: 4));

    // Dispose widget tree to cancel controller timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

