import 'dart:async';

import 'package:hive/hive.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';
import 'package:tapes/services/notion/remote_schema_data_source.dart';

class NotionSchemaService {
  NotionSchemaService(
    this._source,
    this._cacheBox, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Duration ttl = Duration(hours: 24);
  static const int cacheVersion = 1;

  final RemoteSchemaDataSource _source;
  final Box<dynamic> _cacheBox;
  final DateTime Function() _clock;
  final Map<String, Future<NotionDatabaseSchema>> _inFlight = {};

  Future<NotionDatabaseSchema> getSchema(
    String databaseId, {
    bool forceRefresh = false,
  }) {
    final cached = _readCache(databaseId);

    if (!forceRefresh && cached != null) {
      if (!_isStale(cached)) return Future.value(cached);
      unawaited(_refresh(databaseId).catchError((Object _) => cached));
      return Future.value(cached);
    }

    return _refresh(databaseId);
  }

  Future<NotionDatabaseSchema?> peek(String databaseId) async {
    return _readCache(databaseId);
  }

  Future<void> invalidate(String databaseId) {
    return _cacheBox.delete(_key(databaseId));
  }

  Future<void> cacheSchema(NotionDatabaseSchema schema) {
    return _cacheBox.put(_key(schema.databaseId), _encode(schema));
  }

  Future<void> clearAll() => _cacheBox.clear();

  Future<NotionDatabaseSchema> _refresh(String databaseId) {
    final existing = _inFlight[databaseId];
    if (existing != null) return existing;

    final future = _fetchAndStore(databaseId).whenComplete(() {
      _inFlight.remove(databaseId);
    });
    _inFlight[databaseId] = future;
    return future;
  }

  Future<NotionDatabaseSchema> _fetchAndStore(String databaseId) async {
    try {
      final json = await _source.fetchDatabaseSchema(databaseId);
      final schema = NotionSchemaParser.parse(
        databaseId,
        json,
        fetchedAt: _clock(),
      );
      await _cacheBox.put(_key(databaseId), _encode(schema));
      return schema;
    } on NotionApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 404) {
        await _cacheBox.delete(_key(databaseId));
      }
      rethrow;
    }
  }

  bool _isStale(NotionDatabaseSchema schema) {
    return _clock().difference(schema.fetchedAt) > ttl;
  }

  String _key(String databaseId) => 'db:$databaseId';

  Map<String, dynamic> _encode(NotionDatabaseSchema schema) {
    return {
      'version': cacheVersion,
      'databaseId': schema.databaseId,
      'fetchedAt': schema.fetchedAt.toIso8601String(),
      'properties': {
        for (final property in schema.properties.values)
          property.name: {
            'id': property.id,
            'name': property.name,
            'type': property.rawType,
            'tapesType': property.tapesType.name,
            'isReadOnly': property.isReadOnly,
            'isRequired': property.isRequired,
            'options': [
              for (final option in property.options)
                {'id': option.id, 'name': option.name, 'color': option.color},
            ],
          },
      },
    };
  }

  NotionDatabaseSchema? _readCache(String databaseId) {
    final raw = _cacheBox.get(_key(databaseId));
    if (raw is! Map) return null;
    if (raw['version'] != cacheVersion) return null;
    final fetchedAt = DateTime.tryParse(raw['fetchedAt']?.toString() ?? '');
    if (fetchedAt == null) return null;

    final properties = <String, NotionPropertySchema>{};
    final rawProperties = raw['properties'];
    if (rawProperties is Map) {
      for (final entry in rawProperties.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final rawType = value['type'];
        if (rawType is! String) continue;
        final name = entry.key.toString();
        properties[name] = NotionPropertySchema(
          id: value['id'] is String ? value['id'] as String : name,
          name: value['name'] is String ? value['name'] as String : name,
          rawType: rawType,
          tapesType: _tapesTypeFromName(value['tapesType']),
          isReadOnly: value['isReadOnly'] == true,
          isRequired: value['isRequired'] == true,
          options: _decodeOptions(value['options']),
        );
      }
    }

    return NotionDatabaseSchema(
      databaseId: databaseId,
      fetchedAt: fetchedAt,
      properties: properties,
    );
  }

  TapesPropertyType _tapesTypeFromName(Object? name) {
    for (final type in TapesPropertyType.values) {
      if (type.name == name) return type;
    }
    return TapesPropertyType.unsupported;
  }

  List<NotionPropertyOption> _decodeOptions(Object? rawOptions) {
    if (rawOptions is! List) return const [];
    return rawOptions
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (option) => NotionPropertyOption(
            id: option['id'] is String ? option['id'] as String : '',
            name: option['name'] is String ? option['name'] as String : '',
            color: option['color'] is String
                ? option['color'] as String
                : 'default',
          ),
        )
        .where((option) => option.name.isNotEmpty)
        .toList();
  }
}
