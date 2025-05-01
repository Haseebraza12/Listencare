// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/app.dart'; // Import your app entry point

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ListenCareApp()); // Use the correct app class

    // Verify that the app starts without errors.
    expect(find.text('ListenCare'), findsNothing); // Adjust based on your app's UI
  });
}
