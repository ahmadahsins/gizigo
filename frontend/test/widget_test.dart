import 'package:flutter_test/flutter_test.dart';
import 'package:gizigo/main.dart';

void main() {
  testWidgets('GiziGo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GiziGoApp());
    expect(find.text('GiziGo'), findsOneWidget);
  });
}
