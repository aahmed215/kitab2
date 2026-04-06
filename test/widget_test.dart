// Basic app launch test — verifies the app builds without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitab/app.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const KitabApp());
    expect(find.text('Kitab'), findsOneWidget);
  });
}
