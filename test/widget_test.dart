import 'package:flutter_test/flutter_test.dart';
import 'package:e_forecast/main.dart';

void main() {
  testWidgets('EForecastApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EForecastApp());
    expect(find.text('E-FORECAST'), findsWidgets);
  });
}
