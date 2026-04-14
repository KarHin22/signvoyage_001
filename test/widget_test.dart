import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:signvoyage_001/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SignVoyageApp()),
    );

    expect(find.text('Voice Chat'), findsOneWidget);
  });
}
