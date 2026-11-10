import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/viewmodels/dynamic_form_view_model.dart';

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
  FakeSchemaService({
    this.schema,
    this.refreshedSchema,
    this.cachedSchema,
    this.error,
  });

  NotionDatabaseSchema? schema;
  NotionDatabaseSchema? refreshedSchema;
  NotionDatabaseSchema? cachedSchema;
  NotionApiException? error;
  int getCalls = 0;
  final List<bool> forceRefreshFlags = [];

  @override
  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) async {
    getCalls++;
    forceRefreshFlags.add(forceRefresh);

    if (forceRefresh) {
      final refreshed = refreshedSchema ?? schema;
      if (refreshed != null) return refreshed;
    }

    final failure = error;
    if (failure != null) throw failure;

    final current = schema;
    if (current == null) throw const NotionApiException('no schema');
    return current;
  }

  @override
  Future<NotionDatabaseSchema?> peek(String databaseId) async => cachedSchema;

  @override
  Future<void> cacheSchema(NotionDatabaseSchema schema) async {}

  @override
  Future<void> invalidate(String databaseId) async {}

  @override
  Future<void> clearAll() async {}
}

final clock = DateTime(2026, 11, 10, 12);

NotionDatabaseSchema buildSchema({DateTime? fetchedAt}) {
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
              {'id': 'o2', 'name': 'Done', 'color': 'green'},
            ],
          },
        },
        'Calc': {
          'id': 'f',
          'type': 'formula',
          'formula': <String, dynamic>{},
        },
      },
    },
    fetchedAt: fetchedAt ?? DateTime(2026, 11, 10),
  );
}

NotionDatabaseSchema buildRefreshedSchema() {
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
        'Done': {
          'id': 'c',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
        'Fresh': {
          'id': 'x',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
      },
    },
    fetchedAt: clock,
  );
}

(DynamicFormViewModel, FakeNoteRepository) createViewModel(
  FakeSchemaService service,
) {
  final repository = FakeNoteRepository();
  final viewModel = DynamicFormViewModel(
    repository: repository,
    schemaService: service,
    clock: () => clock,
  );
  return (viewModel, repository);
}

void main() {
  test('loads a schema into the ready state', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, _) = createViewModel(service);

    await viewModel.load('db');

    expect(viewModel.loadState, DynamicFormLoadState.ready);
    expect(viewModel.schema, isNotNull);
    expect(viewModel.visibleProperties.map((property) => property.name), [
      'Name',
      'Notes',
      'Score',
      'Done',
      'Status',
    ]);
    expect(viewModel.title, '');
    expect(viewModel.isDirty, isFalse);
  });

  test('marks the state stale when the schema exceeds the TTL', () async {
    final service = FakeSchemaService(
      schema: buildSchema(fetchedAt: clock.subtract(const Duration(hours: 25))),
    );
    final (viewModel, _) = createViewModel(service);

    await viewModel.load('db');

    expect(viewModel.loadState, DynamicFormLoadState.stale);
  });

  test('enters the error state when offline without cache', () async {
    final service = FakeSchemaService(
      error: const NotionApiException('offline'),
    );
    final (viewModel, _) = createViewModel(service);

    await viewModel.load('db');

    expect(viewModel.loadState, DynamicFormLoadState.error);
    expect(viewModel.errorMessage, 'offline');
    expect(viewModel.schema, isNull);
  });

  test('falls back to a cached schema when loading fails', () async {
    final cached = buildSchema(fetchedAt: DateTime(2026, 11, 8));
    final service = FakeSchemaService(
      error: const NotionApiException('offline'),
      cachedSchema: cached,
    );
    final (viewModel, _) = createViewModel(service);

    await viewModel.load('db');

    expect(viewModel.loadState, DynamicFormLoadState.stale);
    expect(viewModel.schema, isNotNull);
  });

  test('hydrates editable values from an existing note', () async {
    final note = Note(
      id: 'note-1',
      title: 'Judul',
      properties: {
        'Notes': 'Isi',
        'Score': 42,
        'Done': true,
        'Status': 'Todo',
        'Calc': 'ignored',
        'Unknown': 'ignored',
      },
      createdAt: DateTime(2026, 11, 10),
    );
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, _) = createViewModel(service);

    await viewModel.load('db', note: note);

    expect(viewModel.title, 'Judul');
    expect(viewModel.formValues, {
      'Notes': 'Isi',
      'Score': 42,
      'Done': true,
      'Status': 'Todo',
    });
    expect(viewModel.isDirty, isFalse);
  });

  test('reconciles values on refresh without losing active input', () async {
    final service = FakeSchemaService(
      schema: buildSchema(),
      refreshedSchema: buildRefreshedSchema(),
    );
    final (viewModel, _) = createViewModel(service);
    await viewModel.load('db');

    viewModel.updateField('Name', 'Judul', shouldNotify: true);
    viewModel.updateField('Notes', 'Sedang diketik', shouldNotify: true);
    viewModel.updateField('Score', 5, shouldNotify: true);
    viewModel.updateField('Done', true, shouldNotify: true);

    await viewModel.refresh();

    expect(viewModel.loadState, DynamicFormLoadState.ready);
    expect(viewModel.title, 'Judul');
    expect(viewModel.formValues['Notes'], 'Sedang diketik');
    expect(viewModel.formValues['Done'], isTrue);
    expect(viewModel.formValues.containsKey('Score'), isFalse);
    expect(viewModel.formValues.containsKey('Status'), isFalse);
    expect(
      viewModel.visibleProperties.any((property) => property.name == 'Fresh'),
      isTrue,
    );
  });

  test('validates the title, number, and select values', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, _) = createViewModel(service);
    await viewModel.load('db');

    expect(viewModel.validate(), isFalse);
    expect(viewModel.errors['Name'], 'Judul wajib diisi');

    viewModel.updateField('Name', 'Judul', shouldNotify: true);
    viewModel.updateField('Score', 'abc', shouldNotify: true);
    expect(viewModel.validate(), isFalse);
    expect(viewModel.errors['Score'], 'Masukkan angka yang valid');

    viewModel.updateField('Score', '12,5', shouldNotify: true);
    viewModel.updateField('Status', 'Nope', shouldNotify: true);
    expect(viewModel.validate(), isFalse);
    expect(viewModel.errors['Status'], 'Pilih opsi yang tersedia');

    viewModel.updateField('Status', 'Todo', shouldNotify: true);
    expect(viewModel.validate(), isTrue);
    expect(viewModel.errors, isEmpty);
  });

  test('sanitizes and saves through the repository', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, repository) = createViewModel(service);
    await viewModel.load('db');

    viewModel.updateField('Name', 'Judul', shouldNotify: true);
    viewModel.updateField('Notes', 'Isi', shouldNotify: true);
    viewModel.updateField('Score', '12,5', shouldNotify: true);
    viewModel.updateField('Done', true, shouldNotify: true);
    viewModel.updateField('Status', 'Todo', shouldNotify: true);

    final saved = await viewModel.saveNote(blocks: const []);

    expect(saved, isNotNull);
    expect(repository.savedNotes, hasLength(1));
    final note = repository.savedNotes.single;
    expect(note.title, 'Judul');
    expect(note.properties, {
      'Notes': 'Isi',
      'Score': 12.5,
      'Done': true,
      'Status': 'Todo',
    });
    expect(note.properties.containsKey('Name'), isFalse);
    expect(viewModel.isDirty, isFalse);
  });

  test('does not save when validation fails', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, repository) = createViewModel(service);
    await viewModel.load('db');

    final saved = await viewModel.saveNote(blocks: const []);

    expect(saved, isNull);
    expect(repository.savedNotes, isEmpty);
  });

  test('updateField only notifies for discrete values or removed errors', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, _) = createViewModel(service);
    await viewModel.load('db');

    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.updateField('Notes', 'a');
    expect(notifications, 0);

    viewModel.updateField('Done', true, shouldNotify: true);
    expect(notifications, 1);

    viewModel.updateField('Name', 'Judul');
    expect(notifications, 1);

    await viewModel.saveNote(blocks: const []);
    expect(notifications, greaterThan(1));
  });

  test('tracks dirty state until the note is saved', () async {
    final service = FakeSchemaService(schema: buildSchema());
    final (viewModel, _) = createViewModel(service);
    await viewModel.load('db');

    expect(viewModel.isDirty, isFalse);
    viewModel.updateField('Notes', 'baru');
    expect(viewModel.isDirty, isTrue);

    viewModel.updateField('Name', 'Judul');
    await viewModel.saveNote(blocks: const []);

    expect(viewModel.isDirty, isFalse);
  });
}
