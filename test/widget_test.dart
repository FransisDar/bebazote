import 'package:bebazote/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hardcoded login opens the ride booking screen', (tester) async {
    await tester.pumpWidget(const BebazoteApp());

    expect(find.text('Bebazote'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Request ride'), findsOneWidget);
  });
}
