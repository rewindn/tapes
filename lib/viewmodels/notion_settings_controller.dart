import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/models/notion_settings.dart';
import 'package:tapes/repositories/settings_repository.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/notion_sync_service.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/token_store.dart';

typedef FetchDatabaseSchema =
    Future<Map<String, dynamic>> Function(
      NotionClient client,
      String databaseId,
    );

class NotionSettingsController extends ChangeNotifier {
  NotionSettingsController({
    required SettingsRepository settingsRepository,
    required TokenStore tokenStore,
    required Box<dynamic> schemaBox,
    FetchDatabaseSchema? fetchDatabaseSchema,
    NotionSchemaService? schemaServiceOverride,
    DateTime Function()? clock,
  }) : _settingsRepository = settingsRepository,
       _tokenStore = tokenStore,
       _schemaBox = schemaBox,
       _fetchDatabaseSchema = fetchDatabaseSchema ?? _defaultFetch,
       _schemaServiceOverride = schemaServiceOverride,
       _clock = clock ?? DateTime.now;

  static Future<Map<String, dynamic>> _defaultFetch(
    NotionClient client,
    String databaseId,
  ) {
    return client.fetchDatabaseSchema(databaseId);
  }

  final SettingsRepository _settingsRepository;
  final TokenStore _tokenStore;
  final Box<dynamic> _schemaBox;
  final FetchDatabaseSchema _fetchDatabaseSchema;
  final NotionSchemaService? _schemaServiceOverride;
  final DateTime Function() _clock;

  NotionSettings _settings = const NotionSettings();
  String? _token;
  NotionSchemaService? _schemaService;
  NotionSyncService? _syncService;

  NotionSettings get settings => _settings;
  String get databaseId => _settings.databaseId;
  String? get databaseName => _settings.databaseName;
  bool get isConnected => _settings.isConnected;
  bool get hasStoredToken => _token != null && _token!.isNotEmpty;
  bool get isConfigured =>
      hasStoredToken && _settings.databaseId.isNotEmpty;
  NotionSchemaService? get schemaService => _schemaService;

  Future<void> initialize() async {
    _settings = _settingsRepository.read();
    _token = await _tokenStore.read();

    if (!isConfigured) {
      _settings = _settings.copyWith(isConnected: false);
    }
    _rebuild();
    notifyListeners();
  }

  Future<void> validateAndSave({
    String? token,
    required String rawDatabaseId,
  }) async {
    final databaseId = sanitizeDatabaseId(rawDatabaseId);
    if (databaseId.isEmpty) {
      throw const NotionApiException('Database ID belum diisi');
    }

    final provided = token?.trim();
    final effectiveToken = provided != null && provided.isNotEmpty
        ? provided
        : _token;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw const NotionApiException('Token Notion belum diisi');
    }

    final client = NotionClient.withToken(effectiveToken);
    final json = await _fetchDatabaseSchema(client, databaseId);
    final schema = NotionSchemaParser.parse(
      databaseId,
      json,
      fetchedAt: _clock(),
    );

    final service =
        _schemaServiceOverride ?? NotionSchemaService(client, _schemaBox);
    await service.cacheSchema(schema);

    final settings = NotionSettings(
      databaseId: databaseId,
      databaseName: _extractDatabaseName(json),
      isConnected: true,
      lastCheckedAt: _clock(),
    );
    await _tokenStore.write(effectiveToken);
    await _settingsRepository.save(settings);

    _token = effectiveToken;
    _settings = settings;
    _rebuild();
    notifyListeners();
  }

  Future<void> disconnect() async {
    final previousDatabaseId = _settings.databaseId;
    final service = _schemaService;

    await _tokenStore.clear();
    await _settingsRepository.clear();
    if (service != null && previousDatabaseId.isNotEmpty) {
      await service.invalidate(previousDatabaseId);
    }

    _token = null;
    _settings = const NotionSettings();
    _schemaService = null;
    _syncService = null;
    notifyListeners();
  }

  Future<Note> syncNote(Note note) async {
    final sync = _syncService;
    final dbId = _settings.databaseId;
    if (sync == null || dbId.isEmpty) return note;
    await _schemaService?.invalidate(dbId);
    return sync.syncNote(note, databaseId: dbId);
  }

  static String sanitizeDatabaseId(String raw) {
    // shortcut: first 32-hex run after stripping dashes; upgrade to URL parsing
    // if pasted text can contain multiple hex-looking ids.
    final compact = raw.replaceAll('-', '');
    final match = RegExp(r'[0-9a-fA-F]{32}').firstMatch(compact);
    return (match?.group(0) ?? raw.trim()).toLowerCase();
  }

  void _rebuild() {
    if (!isConfigured) {
      _schemaService = null;
      _syncService = null;
      return;
    }
    final client = NotionClient.withToken(_token!);
    final service =
        _schemaServiceOverride ?? NotionSchemaService(client, _schemaBox);
    _schemaService = service;
    _syncService = NotionSyncService(client, service);
  }

  String? _extractDatabaseName(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! List) return null;

    final parts = <String>[];
    for (final item in title) {
      if (item is! Map) continue;
      final plain = item['plain_text'];
      if (plain is String && plain.isNotEmpty) {
        parts.add(plain);
        continue;
      }
      final text = item['text'];
      if (text is Map && text['content'] is String) {
        parts.add(text['content'] as String);
      }
    }

    final name = parts.join().trim();
    return name.isEmpty ? null : name;
  }
}
