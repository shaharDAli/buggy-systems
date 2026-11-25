import 'package:flutter_test/flutter_test.dart';
import 'package:bgy_delivery_partner/main.dart';

void main() {
  testWidgets('Home interaction', (tester) async {
    await tester.pumpWidget(const DeliveryPartnerApp());
    for (final label in ['Claim pickup', 'Confirm pickup', 'Mark delivered']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('Order #1040 delivered. No more pickups available.'),
      findsOneWidget,
    );
  });
}
