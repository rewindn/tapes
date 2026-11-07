import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/index.dart';
import 'package:tapes/note_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('notebox');
    await initializeDateFormatting('id', null);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('InderPage renders Home page with header and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<NoteRepository>(
        create: (_) => NoteRepository(box: Hive.box('notebox')),
        child: const MaterialApp(home: InderPage()),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final dayName = DateFormat.EEEE().format(now);
    final monthName = DateFormat.MMMM('id').format(DateTime(now.year, now.month, 1));
    final yearString = now.year.toString();

    // Verify header elements
    expect(find.text(dayName), findsOneWidget);
    expect(find.text(now.day.toString()), findsWidgets);
    expect(find.text(monthName), findsOneWidget);
    expect(find.text(yearString), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // Verify navigation bar icons
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Tap Add note icon (tab 1)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Record Your Day'), findsOneWidget);

    // Tap Bookmark icon (tab 2)
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.text('Recorded Tape'), findsOneWidget);

    // Tap Home icon (tab 0)
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.text(monthName), findsOneWidget);

    // Unmount widget so listeners detach cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
