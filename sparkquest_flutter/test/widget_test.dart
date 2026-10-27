import 'package:flutter_test/flutter_test.dart';
import 'package:sparkquest/main.dart';

void main() {
  testWidgets('SparkQuest smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SparkQuestApp());
    expect(find.text('SPARKQUEST'), findsOneWidget);
  });
}
