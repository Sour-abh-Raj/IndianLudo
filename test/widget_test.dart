import 'package:flutter_test/flutter_test.dart';
import 'package:indian_ludo/main.dart';
import 'package:indian_ludo/ui/setup_screen.dart';

void main() {
  testWidgets('Home renders entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    expect(find.text('Indian Ludo'), findsOneWidget);
    expect(find.text('Play Local'), findsOneWidget);
    expect(find.text('Play Online'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });

  testWidgets('How to Play dialog opens and closes', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('Play Local navigates to setup', (WidgetTester tester) async {
    await tester.pumpWidget(const IndianLudoApp());

    await tester.tap(find.text('Play Local'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
  });
}
