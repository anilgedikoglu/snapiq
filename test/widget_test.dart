import 'package:flutter_test/flutter_test.dart';
import 'package:snapiq/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SnapIQApp());
    expect(find.text('SnapIQ'), findsWidgets);
  });
}
