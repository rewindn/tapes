import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/remote_schema_data_source.dart';

class FakeSchemaSource implements RemoteSchemaDataSource {
  final Map<String, dynamic> response = {
    'properties': {
      'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
      'Score': {'id': 'n', 'type': 'number', 'number': <String, dynamic>{}},
    },
  };

  NotionApiException? error;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetchDatabaseSchema(String databaseId) async {
    final pending = gate;
    if (pending != null) await pending;
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late FakeSchemaSource source;
  late NotionSchemaService service;
  late DateTime now;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_schema_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('notion_schema');
    source = FakeSchemaSource();
    now = DateTime(2026, 11, 10, 10);
    service = NotionSchemaService(source, box, clock: () => now);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('fetches and caches the schema per database id', () async {
    final schema = await service.getSchema('db-1');

    expect(source.calls, 1);
    expect(schema.databaseId, 'db-1');
    expect(schema.fetchedAt, DateTime(2026, 11, 10, 10));
    expect(box.containsKey('db:db-1'), isTrue);

    final cached = await service.getSchema('db-1');
    expect(source.calls, 1);
    expect(cached.titleProperty?.name, 'Name');
  });

  test('keeps separate cache entries for different databases', () async {
    await service.getSchema('db-1');
    await service.getSchema('db-2');

    expect(box.containsKey('db:db-1'), isTrue);
    expect(box.containsKey('db:db-2'), isTrue);
    expect(source.calls, 2);

    await service.getSchema('db-1');
    expect(source.calls, 2);
  });

  test('forceRefresh bypasses the cache', () async {
    await service.getSchema('db-1');
    await service.getSchema('db-1', forceRefresh: true);

    expect(source.calls, 2);
  });

  test('returns stale cache immediately and revalidates in background', () async {
    await service.getSchema('db-1');
    now = now.add(const Duration(hours: 25));

    final stale = await service.getSchema('db-1');
    expect(stale.fetchedAt, DateTime(2026, 11, 10, 10));

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(source.calls, 2);

    final fresh = await service.getSchema('db-1');
    expect(fresh.fetchedAt, now);
  });

  test('deduplicates concurrent fetches for the same database', () async {
    final gate = Completer<void>();
    source.gate = gate.future;

    final first = service.getSchema('db-1');
    final second = service.getSchema('db-1');
    gate.complete();

    final results = await Future.wait([first, second]);

    expect(source.calls, 1);
    expect(results.first.databaseId, results.last.databaseId);
  });

  test('invalidates the cache on 401', () async {
    await service.getSchema('db-1');
    source.error = const NotionApiException('Unauthorized', 401);

    await expectLater(
      service.getSchema('db-1', forceRefresh: true),
      throwsA(isA<NotionApiException>()),
    );

    expect(box.containsKey('db:db-1'), isFalse);
  });

  test('invalidates the cache on 404', () async {
    await service.getSchema('db-1');
    source.error = const NotionApiException('Not found', 404);

    await expectLater(
      service.getSchema('db-1', forceRefresh: true),
      throwsA(isA<NotionApiException>()),
    );

    expect(box.containsKey('db:db-1'), isFalse);
  });

  test('keeps the cache on 429', () async {
    await service.getSchema('db-1');
    source.error = const NotionApiException('Rate limited', 429);

    await expectLater(
      service.getSchema('db-1', forceRefresh: true),
      throwsA(isA<NotionApiException>()),
    );

    expect(box.containsKey('db:db-1'), isTrue);
  });

  test('falls back to stale cache when the refresh fails offline', () async {
    await service.getSchema('db-1');
    now = now.add(const Duration(hours: 25));
    source.error = const NotionApiException('offline');

    final schema = await service.getSchema('db-1');
    expect(schema.fetchedAt, DateTime(2026, 11, 10, 10));

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(box.containsKey('db:db-1'), isTrue);
  });

  test('throws when there is no cache and the fetch fails', () async {
    source.error = const NotionApiException('offline');

    await expectLater(
      service.getSchema('db-1'),
      throwsA(isA<NotionApiException>()),
    );
  });

  test('ignores corrupt cache entries and refetches', () async {
    await box.put('db:db-1', 'garbage');

    final schema = await service.getSchema('db-1');

    expect(source.calls, 1);
    expect(schema.titleProperty?.name, 'Name');
  });

  test('ignores cache entries from an older cache version', () async {
    await box.put('db:db-1', {
      'version': -1,
      'fetchedAt': DateTime(2026, 11, 10, 10).toIso8601String(),
      'properties': <String, dynamic>{},
    });

    await service.getSchema('db-1');

    expect(source.calls, 1);
  });

  test('peek, invalidate, and clearAll operate on the cache box', () async {
    await service.getSchema('db-1');
    expect((await service.peek('db-1'))?.databaseId, 'db-1');

    await service.invalidate('db-1');
    expect(await service.peek('db-1'), isNull);

    await service.getSchema('db-1');
    await service.getSchema('db-2');
    await service.clearAll();
    expect(box.isEmpty, isTrue);
  });
}
