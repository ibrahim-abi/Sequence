import 'package:flutter_test/flutter_test.dart';
import 'package:sequence_game/main.dart';

void main() {
  testWidgets('Sequence App builds and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const SequenceApp());
    expect(find.textContaining('SEQUENCE'), findsWidgets);
    await tester.pumpAndSettle();
  });
}
