import 'package:flutter_test/flutter_test.dart';
import 'package:secure_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureAIMobileApp());
    expect(find.byType(SecureAIMobileApp), findsOneWidget);
  });
}
