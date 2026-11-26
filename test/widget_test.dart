import 'package:flutter_test/flutter_test.dart';
import 'package:jantabackery/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CakeShopApp());
    expect(find.text('Cake Shop Dashboard'), findsOneWidget);
  });
}