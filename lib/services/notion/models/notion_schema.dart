enum TapesPropertyType {
  title,
  richText,
  number,
  checkbox,
  select,
  multiSelect,
  date,
  status,
  url,
  email,
  phone,
  unsupported,
}

class NotionPropertyOption {
  final String id;
  final String name;
  final String color;

  const NotionPropertyOption({
    required this.id,
    required this.name,
    this.color = 'default',
  });
}

class NotionPropertySchema {
  final String id;
  final String name;
  final String rawType;
  final TapesPropertyType tapesType;
  final bool isReadOnly;
  final bool isRequired;
  final List<NotionPropertyOption> options;

  const NotionPropertySchema({
    required this.id,
    required this.name,
    required this.rawType,
    required this.tapesType,
    required this.isReadOnly,
    required this.isRequired,
    this.options = const [],
  });

  bool get isWritable =>
      !isReadOnly && tapesType != TapesPropertyType.unsupported;
}

class NotionDatabaseSchema {
  final String databaseId;
  final DateTime fetchedAt;
  final Map<String, NotionPropertySchema> properties;

  const NotionDatabaseSchema({
    required this.databaseId,
    required this.fetchedAt,
    required this.properties,
  });

  List<NotionPropertySchema> get writableProperties => properties.values
      .where((property) => property.isWritable)
      .toList();

  NotionPropertySchema? get titleProperty {
    for (final property in properties.values) {
      if (property.tapesType == TapesPropertyType.title) return property;
    }
    return null;
  }
}
