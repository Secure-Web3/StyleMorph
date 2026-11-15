import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/main.dart';

void main() {
  testWidgets('StyleMorphApp boots and renders welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StyleMorphApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify StyleMorph is in the widget tree
    expect(find.byType(StyleMorphApp), findsOneWidget);
  });
}
