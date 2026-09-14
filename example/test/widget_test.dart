import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Chatwoot SDK Example'), findsOneWidget);
    expect(find.text('Native (History)'), findsOneWidget);
    expect(find.text('WebView'), findsOneWidget);
  });
}
