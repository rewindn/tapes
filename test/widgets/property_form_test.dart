import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/viewmodels/dynamic_form_view_model.dart';
import 'package:tapes/ui/widgets/dynamic_form/dynamic_property_form.dart';

class FakeNoteRepository implements NoteRepository {
  final List<Note> savedNotes = [];

  @override
  List<Note> getAllNotes() => savedNotes;

  @override
  Note? getNote(String id) {
    for (final note in savedNotes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<void> saveNote(Note note) async {
    savedNotes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    savedNotes.removeWhere((note) => note.id == id);
  }

  @override
  ValueListenable<Box<dynamic>> get listenable => throw UnimplementedError();
}

class FakeSchemaService implements NotionSchemaService {
  FakeSchemaService({required this.schema, this.refreshedSchema});

  final NotionDatabaseSchema schema;
  NotionDatabaseSchema? refreshedSchema;

  @override
  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) return refreshedSchema ?? schema;
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
        'Score': {'id': 'n', 'type': 'number', 'number': <String, dynamic>{}},
        'Done': {
          'id': 'c',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
        'Status': {
          'id': 's',
          'type': 'select',
          'select': {
            'options': [
              {'id': 'o1', 'name': 'Todo', 'color': 'red'},
            ],
          },
        },
        'Tags': {
          'id': 'm',
          'type': 'multi_select',
          'multi_select': {
            'options': [
              {'id': 'o2', 'name': 'flutter', 'color': 'blue'},
            ],
          },
        },
        'Due': {'id': 'd', 'type': 'date', 'date': <String, dynamic>{}},
        'Link': {'id': 'u', 'type': 'url', 'url': <String, dynamic>{}},
        'Calc': {
          'id': 'f',
          'type': 'formula',
          'formula': <String, dynamic>{},
        },
      },
    },
    fetchedAt: DateTime(2026, 11, 10, 12),
  );
}

Future<DynamicFormViewModel> buildViewModel({Note? note}) async {
  final viewModel = DynamicFormViewModel(
    repository: FakeNoteRepository(),
    schemaService: FakeSchemaService(schema: buildSchema()),
    clock: () => DateTime(2026, 11, 10, 12),
  );
  await viewModel.load('db', note: note);
  return viewModel;
}

Widget wrap(DynamicFormViewModel viewModel) {
  return MaterialApp(
    home: Scaffold(
      body: DynamicPropertyForm(viewModel: viewModel),
    ),
  );
}

void main() {
  testWidgets('renders a field per writable schema type', (tester) async {
    final viewModel = await buildViewModel();

    await tester.pumpWidget(wrap(viewModel));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Calc'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is PopScope), findsOneWidget);
  });

  testWidgets('typing in the title updates the view model', (tester) async {
    final viewModel = await buildViewModel();
    await tester.pumpWidget(wrap(viewModel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Judul baru');
    await tester.pump();

    expect(viewModel.title, 'Judul baru');
    expect(viewModel.isDirty, isTrue);
  });

  testWidgets('toggling a checkbox updates the value', (tester) async {
    final viewModel = await buildViewModel();
    await tester.pumpWidget(wrap(viewModel));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(viewModel.formValues['Done'], isTrue);
  });

  testWidgets('renders validation errors under the failing fields', (
    tester,
  ) async {
    final viewModel = await buildViewModel();
    await tester.pumpWidget(wrap(viewModel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(2), 'abc');
    viewModel.validate();
    await tester.pump();

    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Masukkan angka yang valid'), findsOneWidget);
  });

  testWidgets('keeps controller text and cursor when the schema refreshes', (
    tester,
  ) async {
    final note = Note(
      id: 'note-1',
      title: 'Awal',
      createdAt: DateTime(2026, 11, 10),
    );
    final viewModel = await buildViewModel(note: note);
    await tester.pumpWidget(wrap(viewModel));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Halo!');
    await tester.pump();

    await viewModel.refresh();
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(titleField.controller?.text, 'Halo!');
    expect(
      titleField.controller?.selection,
      const TextSelection.collapsed(offset: 5),
    );
  });
}
