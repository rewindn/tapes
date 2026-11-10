import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/repositories/settings_repository.dart';
import 'package:tapes/services/notion/token_store.dart';
import 'package:tapes/ui/screens/inder_page.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';
import 'package:tapes/repositories/note_repository.dart';

class InMemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  late Directory tempDir;
  late NotionSettingsController controller;
  late NoteRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_test_');
    Hive.init(tempDir.path);
    final noteBox = await Hive.openBox<dynamic>('notebox');
    final settingsBox = await Hive.openBox<dynamic>('settings');
    final schemaBox = await Hive.openBox<dynamic>('notion_schema');
    await initializeDateFormatting('id', null);

    controller = NotionSettingsController(
      settingsRepository: SettingsRepository(settingsBox),
      tokenStore: InMemoryTokenStore(),
      schemaBox: schemaBox,
    );
    await controller.initialize();
    repository = NoteRepository(box: noteBox);
  });

  testWidgets('InderPage renders Home page with header and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotionSettingsController>.value(
            value: controller,
          ),
          Provider<NoteRepository>.value(value: repository),
        ],
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
    expect(find.byIcon(Icons.add_circle), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Tap Add switches to the editor tab inside the shell
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('Record Your Day'), findsOneWidget);

    // Tap Bookmark icon (tab 2)
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.text('Recorded On'), findsOneWidget);

    // Tap Home icon (tab 0)
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.text(monthName), findsOneWidget);

    // Unmount widget so listeners detach cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
