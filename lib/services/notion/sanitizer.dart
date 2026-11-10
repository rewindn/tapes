import 'package:tapes/services/notion/models/notion_schema.dart';

class HivePropertySanitizer {
  static Map<String, dynamic> sanitize(
    NotionDatabaseSchema schema,
    Map<String, Object?> values,
  ) {
    final result = <String, dynamic>{};
    for (final property in schema.writableProperties) {
      final sanitized = sanitizeValue(property, values[property.name]);
      if (sanitized != null) result[property.name] = sanitized;
    }
    return result;
  }

  static Object? sanitizeValue(
    NotionPropertySchema schema,
    Object? value,
  ) {
    if (value == null) return null;

    return switch (schema.tapesType) {
      TapesPropertyType.title ||
      TapesPropertyType.richText ||
      TapesPropertyType.url ||
      TapesPropertyType.email ||
      TapesPropertyType.phone => _string(value),
      TapesPropertyType.number => _number(value),
      TapesPropertyType.checkbox => value is bool ? value : null,
      TapesPropertyType.select || TapesPropertyType.status => _select(
        schema,
        value,
      ),
      TapesPropertyType.multiSelect => _multiSelect(schema, value),
      TapesPropertyType.date => _date(value),
      TapesPropertyType.unsupported => null,
    };
  }

  static String? formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static String? _string(Object value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static num? _number(Object value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }

  static String? _select(NotionPropertySchema schema, Object value) {
    if (value is! String) return null;
    for (final option in schema.options) {
      if (option.name == value) return value;
    }
    return null;
  }

  static List<String>? _multiSelect(NotionPropertySchema schema, Object value) {
    if (value is! List) return null;
    final allowed = schema.options.map((option) => option.name).toSet();
    final result = <String>[];
    for (final item in value) {
      if (item is String && allowed.contains(item) && !result.contains(item)) {
        result.add(item);
      }
    }
    return result.isEmpty ? null : result;
  }

  static String? _date(Object value) {
    if (value is DateTime) return formatDate(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed == null ? null : formatDate(parsed);
    }
    return null;
  }
}
