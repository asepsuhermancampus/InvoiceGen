import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const InvoiceGeneratorApp());
  });
}
