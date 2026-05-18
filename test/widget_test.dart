import 'package:flutter_test/flutter_test.dart';
import 'package:reflexiq/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReflexIQApp());
    expect(find.text('ReflexIQ'), findsWidgets);
  });
}
