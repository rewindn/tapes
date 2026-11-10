import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/ui/screens/home_page.dart';
import 'package:tapes/ui/screens/inder_page.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/models/notion_settings.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/repositories/settings_repository.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/token_store.dart';
import 'package:tapes/ui/screens/note_editor_screen.dart';
import 'package:tapes/ui/widgets/list_card.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';

class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

class RecordingNoteRepository extends NoteRepository {
  RecordingNoteRepository({required Box<dynamic> testBox}) : super(box: testBox);

  final List<Note> saved = [];

  @override
  List<Note> getAllNotes() {
    final notes = [...super.getAllNotes(), ...saved];
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  @override
  Future<void> saveNote(Note note) async {
    saved.add(note);
  }
}

class InMemorySettingsRepository extends SettingsRepository {
  InMemorySettingsRepository(super.box);

  NotionSettings settings = const NotionSettings();

  @override
  NotionSettings read() => settings;

  @override
  Future<void> save(NotionSettings value) async => settings = value;

  @override
  Future<void> clear() async => settings = const NotionSettings();
}

class FakeSchemaService implements NotionSchemaService {
  FakeSchemaService(this.schema);

  final NotionDatabaseSchema schema;

  @override
  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) async {
    return schema;
  }

  @override
  Future<NotionDatabaseSchema?> peek(String databaseId) async => schema;

  @override
  Future<void> cacheSchema(NotionDatabaseSchema schema) async {}

  @override
  Future<void> invalidate(String databaseId) async {}

  @override
  Future<void> clearAll() async {}
}

NotionDatabaseSchema buildSchema() {
  return NotionSchemaParser.parse(
    'db',
    {
      'properties': {
        'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
        'Notes': {
          'id': 'r',
          'type': 'rich_text',
          'rich_text': <String, dynamic>{},
        },
        'Date': {
          'id': 'd',
          'type': 'date',
          'date': <String, dynamic>{},
        },
        'Total Time': {
          'id': 'num',
          'type': 'number',
          'number': <String, dynamic>{},
        },
        'Dominant Focus': {
          'id': 'sel',
          'type': 'select',
          'select': {
            'options': [
              {'id': 'o1', 'name': 'fast.ai', 'color': 'red'},
              {'id': 'o2', 'name': '3D', 'color': 'blue'},
              {'id': 'o3', 'name': 'Code', 'color': 'green'},
            ],
          },
        },
        'Done': {
          'id': 'done',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
        'Auto Duration': {
          'id': 'auto',
          'type': 'formula',
          'formula': <String, dynamic>{},
        },
      },
    },
    fetchedAt: DateTime(2026, 11, 10, 12),
  );
}

Note buildNavNote() {
  return Note(
    id: 'note-1',
    title: 'Judul Lama',
    properties: {'Notes': 'Meta Lama'},
    blocks: [TapeBlock(type: BlockType.text, text: 'Blok Lama')],
    createdAt: DateTime(2026, 10, 10),
    notionPageId: 'page-1',
  );
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late Box<dynamic> settingsBox;
  late Box<dynamic> schemaBox;
  late RecordingNoteRepository repository;
  late NotionSettingsController controller;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_nav_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('notebox');
    settingsBox = await Hive.openBox<dynamic>('settings');
    schemaBox = await Hive.openBox<dynamic>('notion_schema');
    await initializeDateFormatting('id', null);
  });

  setUp(() async {
    await box.clear();
    await settingsBox.clear();
    await schemaBox.clear();
    await box.put('note-1', buildNavNote().toMap());
    repository = RecordingNoteRepository(testBox: box);
    final settingsRepository = InMemorySettingsRepository(settingsBox);
    await settingsRepository.save(
      const NotionSettings(
        databaseId: 'db',
        databaseName: 'Tapes DB',
        isConnected: true,
      ),
    );
    controller = NotionSettingsController(
      settingsRepository: settingsRepository,
      tokenStore: InMemoryTokenStore('token'),
      schemaBox: schemaBox,
      fetchDatabaseSchema: (_, _) async => <String, dynamic>{},
      schemaServiceOverride: FakeSchemaService(buildSchema()),
      clock: () => DateTime(2026, 11, 10, 12),
    );
    await controller.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotionSettingsController>.value(
            value: controller,
          ),
          Provider<NoteRepository>.value(value: repository),
        ],
        child: MaterialApp(
          home: InderPage(onSyncNote: (note) async => note),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Add tab opens the editor inside the shell', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('tab switching keeps the editor draft', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Draft');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.text('Recorded On'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a card opens the editor read-only', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.byType(ListCard), findsOneWidget);

    await tester.tap(find.byType(ListCard));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.text('October 10, 2026'), findsOneWidget);
    expect(find.text('Meta Lama'), findsOneWidget);
    expect(find.text('Tapes DB'), findsWidgets);
    expect(find.text('Total Time'), findsOneWidget);
    expect(find.text('Dominant Focus'), findsOneWidget);
    expect(find.text('fast.ai'), findsOneWidget);
    expect(find.text('✕ Belum'), findsOneWidget);
    expect(find.text('✓ Selesai'), findsOneWidget);
    expect(find.text('Auto Duration'), findsNothing);
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.readOnly, isTrue);
      expect(field.enabled, isFalse);
    }
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull);
    }
    final doneSegment = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.text('✓ Selesai'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(doneSegment.onTap, isNull);

    await tester.ensureVisible(find.text('Tutup'));
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Recorded On'), findsOneWidget);
    expect(find.byType(NoteEditorScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('saving a new note builds the title from day and focus', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Catatan Baru');
    await tester.ensureVisible(find.text('fast.ai'));
    await tester.tap(find.text('fast.ai'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('✓ Selesai'));
    await tester.tap(find.text('✓ Selesai'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.play_arrow));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorScreen), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Catatan hari ini berhasil direkam!'), findsOneWidget);
    expect(repository.saved, hasLength(1));
    final saved = repository.saved.single;
    final day = DateFormat('EEEE', 'id').format(DateTime.now());
    expect(saved.title, '$day - fast.ai');
    expect(saved.properties['Notes'], 'Catatan Baru');
    expect(saved.properties['Done'], isTrue);
    expect(
      saved.properties['Date'],
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('Hari Ini Terekam'), findsOneWidget);
    expect(find.text('Anda sudah merekam hari ini.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Rekam Ulang / Tambah Sesi Lain'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
    expect(find.text('Catatan Baru'), findsOneWidget);

    await tester.ensureVisible(find.text('Tutup'));
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Recorded On'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('Hari Ini Terekam'), findsOneWidget);
    await tester.tap(find.text('Rekam Ulang / Tambah Sesi Lain'));
    await tester.pumpAndSettle();
    expect(find.text('Hari Ini Terekam'), findsNothing);
    expect(find.byType(TextField), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('recorded cards show date, database, focus, and status', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await box.put(
        'note-2',
        Note(
          id: 'note-2',
          createdAt: DateTime(2026, 11, 10, 12),
          properties: const {'Total Time': 90, 'Dominant Focus': 'fast.ai'},
        ).toMap(),
      );
    });
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    expect(find.text('Total Time: 90'), findsNothing);
    expect(find.text('fast.ai'), findsOneWidget);
    expect(find.text('✓ Recorded'), findsNWidgets(2));
    expect(find.text('Tapes DB'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('date cassette opens a date picker', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();

    final today = DateFormat('MMMM d, yyyy').format(DateTime.now());
    await tester.ensureVisible(find.text(today));
    await tester.tap(find.text(today));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('disconnect updates every tab without a restart', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.byType(ListCard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(find.text('Total Time'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Putuskan Koneksi / Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Putuskan'));
    await tester.pumpAndSettle();

    expect(controller.isConnected, isFalse);

    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    expect(
      find.text('Belum Terhubung ke Notion, atur koneksi di Settings'),
      findsOneWidget,
    );
    expect(find.text('Total Time'), findsNothing);

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(find.byType(ListCard), findsNothing);
    expect(
      find.text('Belum Terhubung ke Notion, atur koneksi di Settings'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('navbar persists on all four tabs', (tester) async {
    await pumpApp(tester);

    for (final icon in [
      Icons.add_circle,
      Icons.bookmark,
      Icons.settings,
      Icons.home,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
