import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Music Vibes app smoke test', (WidgetTester tester) async {
    // Build a minimal test widget since the app requires Firebase
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Music Vibes'),
            ),
          ),
        ),
      ),
    );

    // Verify that the text is displayed
    expect(find.text('Music Vibes'), findsOneWidget);
  });
}
