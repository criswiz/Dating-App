import 'package:dating_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen title', (tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
  });
}
