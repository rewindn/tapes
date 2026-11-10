import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_block_mapper.dart';
import 'package:tapes/services/notion/payload.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';

NotionDatabaseSchema buildSchema() {
  return NotionSchemaParser.parse('db', {
    'properties': {
      'Name': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
      'Notes': {
        'id': 'r',
        'type': 'rich_text',
        'rich_text': <String, dynamic>{},
      },
      'Score': {'id': 'n', 'type': 'number', 'number': <String, dynamic>{}},
      'Done': {'id': 'c', 'type': 'checkbox', 'checkbox': <String, dynamic>{}},
      'Status': {
        'id': 's',
        'type': 'select',
        'select': {
          'options': [
            {'id': 'o1', 'name': 'Todo', 'color': 'red'},
          ],
        },
      },
      'Tags': {
        'id': 'm',
        'type': 'multi_select',
        'multi_select': {
          'options': [
            {'id': 'o2', 'name': 'flutter', 'color': 'blue'},
          ],
        },
      },
      'Due': {'id': 'd', 'type': 'date', 'date': <String, dynamic>{}},
      'Link': {'id': 'u', 'type': 'url', 'url': <String, dynamic>{}},
      'Calc': {'id': 'f', 'type': 'formula', 'formula': <String, dynamic>{}},
    },
  });
}

Note buildNote({
  String title = 'Judul',
  Map<String, dynamic> properties = const {},
}) {
  return Note(
    id: 'note-1',
    title: title,
    properties: properties,
    blocks: [TapeBlock(type: BlockType.text, text: 'Halo')],
    createdAt: DateTime(2026, 11, 10),
  );
}

void main() {
  test('builds a full create-page payload', () {
    final schema = buildSchema();
    final note = buildNote(
      properties: {
        'Notes': 'Isi',
        'Score': 42,
        'Done': true,
        'Status': 'Todo',
        'Tags': ['flutter'],
        'Due': '2026-11-10',
        'Link': 'https://example.com',
        'Calc': 'ignored',
        'Unknown': 'ignored',
      },
    );

    final payload = NotionPayloadBuilder.buildCreatePagePayload(
      schema: schema,
      note: note,
      databaseId: 'db-1',
    );

    expect(payload['parent'], {'database_id': 'db-1'});
    expect(
      payload['children'],
      NotionBlockMapper.blocksToNotionPayload(note.blocks),
    );

    final properties = payload['properties'] as Map<String, dynamic>;
    expect(properties['Name'], {
      'title': [
        {
          'text': {'content': 'Judul'},
        },
      ],
    });
    expect(properties['Notes'], {
      'rich_text': [
        {
          'text': {'content': 'Isi'},
        },
      ],
    });
    expect(properties['Score'], {'number': 42});
    expect(properties['Done'], {'checkbox': true});
    expect(properties['Status'], {
      'select': {'name': 'Todo'},
    });
    expect(properties['Tags'], {
      'multi_select': [
        {'name': 'flutter'},
      ],
    });
    expect(properties['Due'], {
      'date': {'start': '2026-11-10'},
    });
    expect(properties['Link'], {'url': 'https://example.com'});
    expect(properties.containsKey('Calc'), isFalse);
    expect(properties.containsKey('Unknown'), isFalse);
  });

  test('title always comes from note.title with an Untitled fallback', () {
    final payload = NotionPayloadBuilder.buildCreatePagePayload(
      schema: buildSchema(),
      note: buildNote(title: '', properties: {'Name': 'ignored'}),
      databaseId: 'db',
    );

    final properties = payload['properties'] as Map<String, dynamic>;
    expect(properties['Name'], {
      'title': [
        {
          'text': {'content': 'Untitled'},
        },
      ],
    });
  });

  test('omits empty and invalid property values', () {
    final payload = NotionPayloadBuilder.buildCreatePagePayload(
      schema: buildSchema(),
      note: buildNote(properties: {'Notes': '', 'Score': 'not-a-number'}),
      databaseId: 'db',
    );

    final properties = payload['properties'] as Map<String, dynamic>;
    expect(properties.keys, ['Name']);
  });

  test('builds properties even when the schema has no title column', () {
    final schema = NotionSchemaParser.parse('db', {
      'properties': {
        'Done': {
          'id': 'c',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
      },
    });

    final payload = NotionPayloadBuilder.buildCreatePagePayload(
      schema: schema,
      note: buildNote(properties: {'Done': true}),
      databaseId: 'db',
    );

    final properties = payload['properties'] as Map<String, dynamic>;
    expect(properties.keys, ['Done']);
  });
}
