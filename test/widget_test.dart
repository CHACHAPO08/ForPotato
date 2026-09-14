import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary_app/database/database.dart';
import 'package:diary_app/main.dart';
import 'package:diary_app/providers/database_provider.dart';

void main() {
  testWidgets('App loads and shows bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DiaryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Blog'), findsOneWidget);
    expect(find.text('Insights'), findsWidgets);

    // Dispose the container (and its database connection) before the test
    // ends, then pump once so drift's internal cleanup timer fires here
    // instead of tripping flutter_test's "pending timer" check during the
    // framework's own teardown.
    container.dispose();
    await tester.pump(Duration.zero);
  });
}
