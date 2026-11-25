import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bgy_customer/main.dart';

void main() {
  testWidgets('Home interaction', (tester) async {
    await tester.pumpWidget(const BuggyApp());
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('Green Tiffin'), findsNothing);
    await tester.tap(find.text('Oven Lane'));
    await tester.pumpAndSettle();
    expect(find.text('Margherita · ₹240'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('No restaurants match your search.'), findsOneWidget);
  });
}
