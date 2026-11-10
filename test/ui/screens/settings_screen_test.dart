import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tapes/models/notion_settings.dart';
import 'package:tapes/repositories/settings_repository.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/token_store.dart';
import 'package:tapes/ui/screens/settings_screen.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';

const databaseId = '0123456789abcdef0123456789abcdef';
const databaseUrl =
    'https://www.notion.so/workspace/Tapes-$databaseId?v=1234';

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

class InMemorySettingsRepository extends SettingsRepository {
  InMemorySettingsRepository(super.box);

  NotionSettings settings = const NotionSettings();

  @override
  NotionSettings read() => settings;

  @override
  Future<void> save(NotionSettings value) async {
    settings = value;
  }

  @override
  Future<void> clear() async {
    settings = const NotionSettings();
  }
}

class FakeBackend {
  NotionApiException? error;
  int calls = 0;
  final Map<String, dynamic> response = {
    'title': [
      {'plain_text': 'Tapes DB'},
    ],
    'properties': {
      'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
    },
  };

  Future<Map<String, dynamic>> fetch(
    NotionClient client,
    String databaseId,
  ) async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }
}

class FakeSchemaService implements NotionSchemaService {
  NotionDatabaseSchema? cached;
  String? invalidated;

  @override
  Future<void> cacheSchema(NotionDatabaseSchema schema) async {
    cached = schema;
  }

  @override
  Future<NotionDatabaseSchema?> peek(String databaseId) async => cached;

  @override
  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) async {
    final schema = cached;
    if (schema == null) {
      throw const NotionApiException('no schema');
    }
    return schema;
  }

  @override
  Future<void> invalidate(String databaseId) async {
    invalidated = databaseId;
    cached = null;
  }

  @override
  Future<void> clearAll() async {
    cached = null;
  }
}

NotionDatabaseSchema buildSchema() {
  return NotionSchemaParser.parse(
    databaseId,
    {
      'properties': {
        'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
      },
    },
    fetchedAt: DateTime(2026, 11, 10, 12),
  );
}

void main() {
  late Directory tempDir;
  late Box<dynamic> settingsBox;
  late InMemoryTokenStore tokenStore;
  late InMemorySettingsRepository settingsRepository;
  late FakeBackend backend;
  late FakeSchemaService schemaService;
  late NotionSettingsController controller;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_settings_test_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox<dynamic>('settings');
  });

  setUp(() async {
    await settingsBox.clear();
    tokenStore = InMemoryTokenStore('stored-token');
    settingsRepository = InMemorySettingsRepository(settingsBox)
      ..settings = const NotionSettings(
        databaseId: databaseId,
        databaseName: 'Tapes DB',
        isConnected: true,
      );
    backend = FakeBackend();
    schemaService = FakeSchemaService()..cached = buildSchema();
    controller = NotionSettingsController(
      settingsRepository: settingsRepository,
      tokenStore: tokenStore,
      schemaBox: settingsBox,
      fetchDatabaseSchema: backend.fetch,
      schemaServiceOverride: schemaService,
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

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<NotionSettingsController>.value(
        value: controller,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('sanitizeDatabaseId extracts the id from a Notion URL', () {
    expect(
      NotionSettingsController.sanitizeDatabaseId(databaseUrl),
      databaseId,
    );
    expect(
      NotionSettingsController.sanitizeDatabaseId(
        '01234567-89ab-cdef-0123-456789abcdef',
      ),
      databaseId,
    );
    expect(NotionSettingsController.sanitizeDatabaseId('  raw-id  '), 'raw-id');
  });

  test('SettingsRepository round-trips settings without a token', () async {
    final repository = SettingsRepository(settingsBox);
    const settings = NotionSettings(
      databaseId: 'db-1',
      databaseName: 'Tapes',
      isConnected: true,
    );

    await repository.save(settings);
    final restored = repository.read();

    expect(restored.databaseId, 'db-1');
    expect(restored.databaseName, 'Tapes');
    expect(restored.isConnected, isTrue);
    expect(restored.toMap().containsKey('token'), isFalse);

    await repository.clear();
    expect(repository.read().databaseId, isEmpty);
  });

  testWidgets('valid credentials connect and cache the schema', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.textContaining('Belum Terhubung'), findsNothing);
    await tester.enterText(find.byType(TextField).at(0), 'new-token');
    await tester.enterText(find.byType(TextField).at(1), databaseUrl);
    await tester.tap(find.text('Test Connection & Sync Schema'));
    await tester.pumpAndSettle();

    expect(backend.calls, 1);
    expect(tokenStore.token, 'new-token');
    expect(settingsRepository.settings.databaseId, databaseId);
    expect(settingsRepository.settings.databaseName, 'Tapes DB');
    expect(controller.isConnected, isTrue);
    expect(schemaService.cached?.databaseId, databaseId);
    expect(find.text('Terhubung: Tapes DB'), findsOneWidget);
  });

  testWidgets('a 401 shows a specific error without clearing old state', (
    tester,
  ) async {
    final previousSchema = schemaService.cached;
    backend.error = const NotionApiException('unauthorized', 401);
    await pumpSettings(tester);

    await tester.enterText(find.byType(TextField).at(0), 'bad-token');
    await tester.tap(find.text('Test Connection & Sync Schema'));
    await tester.pumpAndSettle();

    expect(find.text('Token salah atau kedaluwarsa'), findsOneWidget);
    expect(controller.isConnected, isTrue);
    expect(settingsRepository.settings.databaseName, 'Tapes DB');
    expect(identical(schemaService.cached, previousSchema), isTrue);
    expect(tokenStore.token, 'stored-token');
  });

  testWidgets('a 404 shows a specific error', (tester) async {
    backend.error = const NotionApiException('not found', 404);
    await pumpSettings(tester);

    await tester.tap(find.text('Test Connection & Sync Schema'));
    await tester.pumpAndSettle();

    expect(find.text('Database ID tidak ditemukan'), findsOneWidget);
    expect(controller.isConnected, isTrue);
  });

  testWidgets('disconnect clears credentials and schema cache', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Putuskan Koneksi / Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Putuskan koneksi?'), findsOneWidget);

    await tester.tap(find.text('Putuskan'));
    await tester.pumpAndSettle();

    expect(controller.isConfigured, isFalse);
    expect(tokenStore.token, isNull);
    expect(settingsRepository.settings.databaseId, isEmpty);
    expect(schemaService.invalidated, databaseId);
    expect(find.text('Belum Terhubung'), findsOneWidget);
  });
}
