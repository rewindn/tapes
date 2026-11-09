import 'package:tapes/services/notion/models/notion_schema.dart';

class NotionSchemaParser {
  static const Set<String> _readOnlyTypes = {
    'formula',
    'rollup',
    'created_time',
    'created_by',
    'last_edited_time',
    'last_edited_by',
    'unique_id',
    'verification',
    'button',
  };

  static NotionDatabaseSchema parse(
    String databaseId,
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final rawProperties = json['properties'];
    final properties = <String, NotionPropertySchema>{};

    if (rawProperties is Map) {
      for (final entry in rawProperties.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final property = _parseProperty(entry.key.toString(), value);
        if (property != null) properties[property.name] = property;
      }
    }

    return NotionDatabaseSchema(
      databaseId: databaseId,
      fetchedAt: fetchedAt ?? DateTime.now(),
      properties: properties,
    );
  }

  static NotionPropertySchema? _parseProperty(
    String name,
    Map<dynamic, dynamic> value,
  ) {
    final rawType = value['type'];
    if (rawType is! String) return null;

    final tapesType = _tapesTypeFor(rawType);

    return NotionPropertySchema(
      id: value['id'] is String ? value['id'] as String : name,
      name: name,
      rawType: rawType,
      tapesType: tapesType,
      isReadOnly: _readOnlyTypes.contains(rawType),
      isRequired: tapesType == TapesPropertyType.title,
      options: _parseOptions(value, rawType),
    );
  }

  static TapesPropertyType _tapesTypeFor(String rawType) {
    return switch (rawType) {
      'title' => TapesPropertyType.title,
      'rich_text' => TapesPropertyType.richText,
      'number' => TapesPropertyType.number,
      'checkbox' => TapesPropertyType.checkbox,
      'select' => TapesPropertyType.select,
      'multi_select' => TapesPropertyType.multiSelect,
      'date' => TapesPropertyType.date,
      'status' => TapesPropertyType.status,
      'url' => TapesPropertyType.url,
      'email' => TapesPropertyType.email,
      'phone_number' => TapesPropertyType.phone,
      _ => TapesPropertyType.unsupported,
    };
  }

  static List<NotionPropertyOption> _parseOptions(
    Map<dynamic, dynamic> value,
    String rawType,
  ) {
    if (rawType != 'select' &&
        rawType != 'multi_select' &&
        rawType != 'status') {
      return const [];
    }
    final config = value[rawType];
    if (config is! Map) return const [];
    final rawOptions = config['options'];
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
