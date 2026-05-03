import 'package:flutter_test/flutter_test.dart';
import 'package:manny_ui_showcase/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MannyShowcaseApp());
    expect(find.text('Nebula Dashboard'), findsOneWidget);
  });
}
