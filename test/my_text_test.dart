import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:focusboard/helpers/widgets/my_text_style.dart';

void main() {
  testWidgets('MyText renders without GoogleFonts (system font fallback)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyText('hello world', textType: MyTextType.bodySmall),
        ),
      ),
    );
    expect(find.text('hello world'), findsOneWidget);
  });
}
