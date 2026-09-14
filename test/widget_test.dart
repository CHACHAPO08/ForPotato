import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary_app/main.dart';

void main() {
  testWidgets('App loads and shows bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DiaryApp()));

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Blog'), findsOneWidget);
    expect(find.text('Insights'), findsWidgets);
  });
}
