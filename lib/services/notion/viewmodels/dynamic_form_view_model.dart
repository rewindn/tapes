import 'package:flutter/foundation.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/services/notion/sanitizer.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:uuid/uuid.dart';

enum DynamicFormLoadState { idle, loading, ready, stale, error }

class DynamicFormViewModel extends ChangeNotifier {
  DynamicFormViewModel({
    required NoteRepository repository,
    required NotionSchemaService schemaService,
    DateTime Function()? clock,
  }) : _repository = repository,
       _schemaService = schemaService,
       _clock = clock ?? DateTime.now;

  final NoteRepository _repository;
  final NotionSchemaService _schemaService;
  final DateTime Function() _clock;

  DynamicFormLoadState _loadState = DynamicFormLoadState.idle;
  NotionDatabaseSchema? _schema;
  String? _errorMessage;
  String _title = '';
  Map<String, Object?> _formValues = {};
  Map<String, String> _errors = {};
  Note? _note;
  String? _activeDatabaseId;
  String _initialTitle = '';
  Map<String, Object?> _initialValues = {};
  bool _disposed = false;

  DynamicFormLoadState get loadState => _loadState;
  NotionDatabaseSchema? get schema => _schema;
  String? get errorMessage => _errorMessage;
  String get title => _title;
  Map<String, Object?> get formValues => Map.unmodifiable(_formValues);
  Map<String, String> get errors => Map.unmodifiable(_errors);

  List<NotionPropertySchema> get visibleProperties {
    final schema = _schema;
    if (schema == null) return const [];
    return schema.properties.values
        .where((property) => property.isWritable)
        .toList();
  }

  String? get firstErrorProperty {
    if (_errors.isEmpty) return null;
    return _errors.keys.first;
  }

  bool get isDirty {
    return _title != _initialTitle || !mapEquals(_formValues, _initialValues);
  }

  void markClean() {
    _initialTitle = _title;
    _initialValues = Map<String, Object?>.of(_formValues);
  }

  Future<void> load(String databaseId, {Note? note}) async {
    _activeDatabaseId = databaseId;
    _note = note;
    _loadState = DynamicFormLoadState.loading;
    _errorMessage = null;
    _notify();

    try {
      final schema = await _schemaService.getSchema(databaseId);
      if (_activeDatabaseId != databaseId) return;
      _applySchema(schema, note);
    } on NotionApiException catch (error) {
      if (_activeDatabaseId != databaseId) return;
      _errorMessage = error.message;
      final cached = await _schemaService.peek(databaseId);
      if (cached != null) {
        _applySchema(cached, note);
      } else {
        _loadState = DynamicFormLoadState.error;
      }
    }
    _notify();
  }

  Future<void> refresh() async {
    final databaseId = _activeDatabaseId;
    if (databaseId == null) return;

    _loadState = DynamicFormLoadState.loading;
    _notify();

    try {
      final schema = await _schemaService.getSchema(
        databaseId,
        forceRefresh: true,
      );
      if (_activeDatabaseId != databaseId) return;
      _schema = schema;
      _reconcile(schema);
      _loadState = _isStale(schema)
          ? DynamicFormLoadState.stale
          : DynamicFormLoadState.ready;
      _errorMessage = null;
    } on NotionApiException catch (error) {
      if (_activeDatabaseId != databaseId) return;
      _errorMessage = error.message;
      _loadState = _schema == null
          ? DynamicFormLoadState.error
          : DynamicFormLoadState.stale;
    }
    _notify();
  }

  void updateField(
    String propertyName,
    Object? value, {
    bool shouldNotify = false,
  }) {
    final titleProperty = _schema?.titleProperty;
    if (titleProperty != null && titleProperty.name == propertyName) {
      _title = value is String ? value : '';
    } else if (value == null) {
      _formValues.remove(propertyName);
    } else {
      _formValues[propertyName] = value;
    }

    final errorRemoved = _errors.remove(propertyName) != null;
    if (errorRemoved || shouldNotify) _notify();
  }

  bool validate() {
    final schema = _schema;
    if (schema == null) return false;

    final errors = <String, String>{};
    final titleProperty = schema.titleProperty;
    if (titleProperty != null && _title.trim().isEmpty) {
      errors[titleProperty.name] = 'Judul wajib diisi';
    }

    for (final property in schema.properties.values) {
      if (!property.isWritable ||
          property.tapesType == TapesPropertyType.title) {
        continue;
      }
      final value = _formValues[property.name];
      if (value == null) continue;
      final error = _validateValue(property, value);
      if (error != null) errors[property.name] = error;
    }

    _errors = errors;
    _notify();
    return errors.isEmpty;
  }

  Future<Note?> saveNote({required List<TapeBlock> blocks}) async {
    final schema = _schema;
    if (schema == null || !validate()) return null;

    final properties = HivePropertySanitizer.sanitize(schema, _formValues);
    final existing = _note;
    final saved = existing == null
        ? Note(
            id: const Uuid().v4(),
            title: _title,
            properties: properties,
            blocks: blocks,
            createdAt: _clock(),
          )
        : existing.copyWith(
            title: _title,
            properties: properties,
            blocks: blocks,
          );

    await _repository.saveNote(saved);

    _note = saved;
    _initialTitle = _title;
    _initialValues = Map<String, Object?>.of(_formValues);
    _notify();
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _applySchema(NotionDatabaseSchema schema, Note? note) {
    _schema = schema;
    _initialiseValues(schema, note);
    _loadState = _isStale(schema)
        ? DynamicFormLoadState.stale
        : DynamicFormLoadState.ready;
    _errorMessage = null;
  }

  void _initialiseValues(NotionDatabaseSchema schema, Note? note) {
    final values = <String, Object?>{};
    var title = '';

    if (note != null) {
      title = note.title;
      for (final property in schema.properties.values) {
        if (!property.isWritable ||
            property.tapesType == TapesPropertyType.title) {
          continue;
        }
        final value = HivePropertySanitizer.sanitizeValue(
          property,
          note.properties[property.name],
        );
        if (value != null) values[property.name] = value;
      }

      final titleProperty = schema.titleProperty;
      if (title.isEmpty && titleProperty != null) {
        final fallback = HivePropertySanitizer.sanitizeValue(
          titleProperty,
          note.properties[titleProperty.name],
        );
        if (fallback is String) title = fallback;
      }
    }

    _title = title;
    _formValues = values;
    _errors = {};
    _initialTitle = title;
    _initialValues = Map<String, Object?>.of(values);
  }

  void _reconcile(NotionDatabaseSchema schema) {
    final writable = {
      for (final property in schema.properties.values)
        if (property.isWritable && property.tapesType != TapesPropertyType.title)
          property.name: property,
    };

    final reconciled = <String, Object?>{};
    for (final entry in _formValues.entries) {
      final property = writable[entry.key];
      if (property == null) continue;
      if (HivePropertySanitizer.sanitizeValue(property, entry.value) == null) {
        continue;
      }
      reconciled[entry.key] = entry.value;
    }
    _formValues = reconciled;

    _errors = {
      for (final entry in _errors.entries)
        if (writable.containsKey(entry.key)) entry.key: entry.value,
    };
  }

  String? _validateValue(NotionPropertySchema property, Object value) {
    switch (property.tapesType) {
      case TapesPropertyType.number:
        return _parseNumber(value) == null ? 'Masukkan angka yang valid' : null;
      case TapesPropertyType.select:
      case TapesPropertyType.status:
        return _isKnownOption(property, value)
            ? null
            : 'Pilih opsi yang tersedia';
      case TapesPropertyType.multiSelect:
        return _isValidMultiSelect(property, value)
            ? null
            : 'Pilih opsi yang tersedia';
      case TapesPropertyType.date:
        return value is String && DateTime.tryParse(value) != null
            ? null
            : 'Format tanggal tidak valid';
      default:
        return null;
    }
  }

  num? _parseNumber(Object value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }

  bool _isKnownOption(NotionPropertySchema property, Object value) {
    if (value is! String) return false;
    return property.options.any((option) => option.name == value);
  }

  bool _isValidMultiSelect(NotionPropertySchema property, Object value) {
    if (value is! List) return false;
    final allowed = property.options.map((option) => option.name).toSet();
    return value.every((item) => item is String && allowed.contains(item));
  }

  bool _isStale(NotionDatabaseSchema schema) {
    return _clock().difference(schema.fetchedAt) > NotionSchemaService.ttl;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
