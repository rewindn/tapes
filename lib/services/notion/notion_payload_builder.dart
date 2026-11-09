import 'package:tapes/note.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_block_mapper.dart';
import 'package:tapes/services/notion/notion_property_mapper.dart';

class NotionPayloadBuilder {
  static Map<String, dynamic> buildCreatePagePayload({
    required NotionDatabaseSchema schema,
    required Note note,
    required String databaseId,
  }) {
    final properties = <String, dynamic>{};
    final title = note.title.trim().isEmpty ? 'Untitled' : note.title.trim();

    for (final property in schema.properties.values) {
      if (!property.isWritable) continue;
      final value = property.tapesType == TapesPropertyType.title
          ? title
          : note.properties[property.name];
      final mapped = NotionPropertyMapper.toNotionProperty(property, value);
      if (mapped != null) properties[property.name] = mapped;
    }

    return {
      'parent': {'database_id': databaseId},
      'properties': properties,
      'children': NotionBlockMapper.blocksToNotionPayload(note.blocks),
    };
  }
}
