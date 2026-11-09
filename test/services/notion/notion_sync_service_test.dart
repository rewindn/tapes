import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/note.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_client.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/notion_schema_service.dart';
import 'package:tapes/services/notion/notion_sync_service.dart';
import 'package:tapes/services/notion/remote_note_data_source.dart';

class FakeRemoteSource implements RemoteNoteDataSource {
  FakeRemoteSource({this.remoteId = 'page-123'});

  final String remoteId;
  final List<NotionApiException> errors = [];
  final List<Map<String, dynamic>> payloads = [];
  int attempts = 0;

  @override
  Future<String> createPageFromPayload(Map<String, dynamic> payload) async {
    attempts++;
    payloads.add(payload);
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return remoteId;
  }

  @override
  Future<String> createNotePage({
    required String databaseId,
    required String title,
    required List<TapeBlock> blocks,
  }) async {
    throw UnimplementedError();
  }
}

class FakeSchemaService implements NotionSchemaService {
  FakeSchemaService(this.schemas);

  final List<NotionDatabaseSchema> schemas;
  int getCalls = 0;
  int invalidations = 0;
  final List<bool> forceRefreshFlags = [];

  @override
  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) async {
    getCalls++;
    forceRefreshFlags.add(forceRefresh);
    final index = getCalls - 1 < schemas.length ? getCalls - 1 : schemas.length - 1;
    return schemas[index];
  }

  @override
  Future<NotionDatabaseSchema?> peek(String databaseId) async => null;

  @override
  Future<void> invalidate(String databaseId) async {
    invalidations++;
  }

  @override
  Future<void> clearAll() async {}
}

NotionDatabaseSchema buildSchema({bool withStatus = false}) {
  return NotionSchemaParser.parse('db', {
    'properties': {
      'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
      'Score': {'id': 'n', 'type': 'number', 'number': <String, dynamic>{}},
      if (withStatus)
        'Status': {
          'id': 's',
          'type': 'select',
          'select': {
            'options': [
              {'id': 'o', 'name': 'Todo', 'color': 'red'},
            ],
          },
        },
    },
  });
}

Note buildNote({
  String title = 'Halo',
  String? notionPageId,
  Map<String, dynamic> properties = const {},
}) {
  return Note(
    id: 'note-1',
    title: title,
    blocks: [TapeBlock(type: BlockType.text, text: 'Konten')],
    createdAt: DateTime(2026, 11, 10),
    notionPageId: notionPageId,
    properties: properties,
  );
}

Map<String, dynamic> propertiesOf(Map<String, dynamic> payload) {
  return payload['properties'] as Map<String, dynamic>;
}

void main() {
  test('syncs a new note with a schema-built payload', () async {
    final source = FakeRemoteSource(remoteId: 'page-1');
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);
    final note = buildNote(properties: {'Score': 42});

    final synced = await service.syncNote(note, databaseId: 'db-1');

    expect(synced.notionPageId, 'page-1');
    expect(source.attempts, 1);
    expect(schemaService.getCalls, 1);
    expect(source.payloads.single['parent'], {'database_id': 'db-1'});
    expect(propertiesOf(source.payloads.single)['Score'], {'number': 42});
    expect(
      propertiesOf(source.payloads.single)['Name'],
      {
        'title': [
          {
            'text': {'content': 'Halo'},
          },
        ],
      },
    );
  });

  test('skips the remote call for an already synced note', () async {
    final source = FakeRemoteSource();
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);
    final note = buildNote(notionPageId: 'page-existing');

    final result = await service.syncNote(note, databaseId: 'db-1');

    expect(identical(result, note), isTrue);
    expect(source.attempts, 0);
    expect(schemaService.getCalls, 0);
  });

  test('syncs a note with an empty notionPageId', () async {
    final source = FakeRemoteSource(remoteId: 'page-9');
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);

    final synced = await service.syncNote(
      buildNote(notionPageId: ''),
      databaseId: 'db-1',
    );

    expect(source.attempts, 1);
    expect(synced.notionPageId, 'page-9');
  });

  test('falls back to Untitled when the note title is empty', () async {
    final source = FakeRemoteSource();
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);

    await service.syncNote(buildNote(title: ''), databaseId: 'db-1');

    expect(propertiesOf(source.payloads.single)['Name'], {
      'title': [
        {
          'text': {'content': 'Untitled'},
        },
      ],
    });
  });

  test('self-heals on HTTP 400 by invalidating and retrying once', () async {
    final source = FakeRemoteSource(remoteId: 'page-2');
    source.errors.add(const NotionApiException('bad schema', 400));
    final schemaService = FakeSchemaService([
      buildSchema(),
      buildSchema(withStatus: true),
    ]);
    final service = NotionSyncService(source, schemaService);
    final note = buildNote(properties: {'Status': 'Todo'});

    final synced = await service.syncNote(note, databaseId: 'db-1');

    expect(synced.notionPageId, 'page-2');
    expect(source.attempts, 2);
    expect(schemaService.invalidations, 1);
    expect(schemaService.forceRefreshFlags, [false, true]);
    expect(propertiesOf(source.payloads.first).containsKey('Status'), isFalse);
    expect(propertiesOf(source.payloads.last)['Status'], {
      'select': {'name': 'Todo'},
    });
  });

  test('rethrows when the 400 retry also fails', () async {
    final source = FakeRemoteSource();
    source.errors.add(const NotionApiException('bad schema', 400));
    source.errors.add(const NotionApiException('bad schema again', 400));
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);

    await expectLater(
      service.syncNote(buildNote(), databaseId: 'db-1'),
      throwsA(isA<NotionApiException>()),
    );
    expect(source.attempts, 2);
    expect(schemaService.invalidations, 1);
  });

  test('does not retry or invalidate on non-400 errors', () async {
    final source = FakeRemoteSource();
    source.errors.add(const NotionApiException('Unauthorized', 401));
    final schemaService = FakeSchemaService([buildSchema()]);
    final service = NotionSyncService(source, schemaService);

    await expectLater(
      service.syncNote(buildNote(), databaseId: 'db-1'),
      throwsA(isA<NotionApiException>()),
    );
    expect(source.attempts, 1);
    expect(schemaService.invalidations, 0);
    expect(schemaService.forceRefreshFlags, [false]);
  });
}
