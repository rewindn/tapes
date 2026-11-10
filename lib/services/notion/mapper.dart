import 'package:tapes/services/notion/models/notion_schema.dart';

class NotionPropertyMapper {
  static Map<String, dynamic>? toNotionProperty(
    NotionPropertySchema schema,
    Object? value,
  ) {
    if (value == null) return null;

    return switch (schema.tapesType) {
      TapesPropertyType.title => _richText('title', value),
      TapesPropertyType.richText => _richText('rich_text', value),
      TapesPropertyType.number => value is num ? {'number': value} : null,
      TapesPropertyType.checkbox => value is bool
          ? {'checkbox': value}
          : null,
      TapesPropertyType.select => value is String
          ? {
              'select': {'name': value},
            }
          : null,
      TapesPropertyType.status => value is String
          ? {
              'status': {'name': value},
            }
          : null,
      TapesPropertyType.multiSelect => value is List
          ? _multiSelect(value)
          : null,
      TapesPropertyType.date => value is String
          ? {
              'date': {'start': value},
            }
          : null,
      TapesPropertyType.url => value is String ? {'url': value} : null,
      TapesPropertyType.email => value is String ? {'email': value} : null,
      TapesPropertyType.phone => value is String
          ? {'phone_number': value}
          : null,
      TapesPropertyType.unsupported => null,
    };
  }

  static Map<String, dynamic>? _richText(String type, Object value) {
    if (value is! String || value.isEmpty) return null;
    return {
      type: [
        {
          'text': {'content': value},
        },
      ],
    };
  }

  static Map<String, dynamic>? _multiSelect(List<dynamic> value) {
    final names = [
      for (final item in value)
        if (item is String && item.isNotEmpty) {'name': item},
    ];
    if (names.isEmpty) return null;
    return {'multi_select': names};
  }
}
