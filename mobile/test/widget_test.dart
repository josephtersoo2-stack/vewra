import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('Vewra App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VewraApp());
    expect(find.byType(VewraApp), findsOneWidget);
  });
}
