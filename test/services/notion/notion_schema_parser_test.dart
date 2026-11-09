import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';

void main() {
  test('parses all supported property types', () {
    final schema = NotionSchemaParser.parse(
      'db-1',
      {
        'object': 'database',
        'properties': {
          'Name': {
            'id': 'title',
            'type': 'title',
            'title': <String, dynamic>{},
          },
          'Notes': {
            'id': 'rich',
            'type': 'rich_text',
            'rich_text': <String, dynamic>{},
          },
          'Score': {
            'id': 'num',
            'type': 'number',
            'number': {'format': 'number'},
          },
          'Done': {
            'id': 'check',
            'type': 'checkbox',
            'checkbox': <String, dynamic>{},
          },
          'Status': {
            'id': 'sel',
            'type': 'select',
            'select': {
              'options': [
                {'id': 'opt-1', 'name': 'Todo', 'color': 'red'},
                {'id': 'opt-2', 'name': 'Done', 'color': 'green'},
              ],
            },
          },
          'Tags': {
            'id': 'multi',
            'type': 'multi_select',
            'multi_select': {
              'options': [
                {'id': 'opt-3', 'name': 'flutter', 'color': 'blue'},
              ],
            },
          },
          'Due': {
            'id': 'date',
            'type': 'date',
            'date': <String, dynamic>{},
          },
          'State': {
            'id': 'status',
            'type': 'status',
            'status': {
              'options': [
                {'id': 'opt-4', 'name': 'In progress', 'color': 'yellow'},
              ],
            },
          },
          'Link': {'id': 'url', 'type': 'url', 'url': <String, dynamic>{}},
          'Email': {'id': 'mail', 'type': 'email', 'email': <String, dynamic>{}},
          'Phone': {
            'id': 'phone',
            'type': 'phone_number',
            'phone_number': <String, dynamic>{},
          },
        },
      },
      fetchedAt: DateTime(2026, 11, 10),
    );

    expect(schema.databaseId, 'db-1');
    expect(schema.fetchedAt, DateTime(2026, 11, 10));
    expect(schema.properties, hasLength(11));
    expect(schema.titleProperty?.name, 'Name');
    expect(schema.titleProperty?.isRequired, isTrue);
    expect(schema.properties['Notes']?.tapesType, TapesPropertyType.richText);
    expect(schema.properties['Score']?.tapesType, TapesPropertyType.number);
    expect(schema.properties['Done']?.tapesType, TapesPropertyType.checkbox);
    expect(schema.properties['Status']?.tapesType, TapesPropertyType.select);
    expect(schema.properties['Tags']?.tapesType, TapesPropertyType.multiSelect);
    expect(schema.properties['Due']?.tapesType, TapesPropertyType.date);
    expect(schema.properties['State']?.tapesType, TapesPropertyType.status);
    expect(schema.properties['Link']?.tapesType, TapesPropertyType.url);
    expect(schema.properties['Email']?.tapesType, TapesPropertyType.email);
    expect(schema.properties['Phone']?.tapesType, TapesPropertyType.phone);

    final status = schema.properties['Status']!;
    expect(status.options.map((option) => option.name), ['Todo', 'Done']);
    expect(status.options.first.id, 'opt-1');
    expect(status.options.first.color, 'red');
    expect(status.isWritable, isTrue);
    expect(schema.writableProperties, hasLength(11));
  });

  test('marks unsupported and read-only properties as not writable', () {
    final schema = NotionSchemaParser.parse('db-2', {
      'properties': {
        'Title': {'id': 't', 'type': 'title', 'title': <String, dynamic>{}},
        'People': {'id': 'p', 'type': 'people', 'people': <String, dynamic>{}},
        'Files': {'id': 'f', 'type': 'files', 'files': <String, dynamic>{}},
        'Related': {
          'id': 'r',
          'type': 'relation',
          'relation': <String, dynamic>{},
        },
        'Total': {'id': 'roll', 'type': 'rollup', 'rollup': <String, dynamic>{}},
        'Formula': {
          'id': 'form',
          'type': 'formula',
          'formula': <String, dynamic>{},
        },
        'Created': {
          'id': 'ct',
          'type': 'created_time',
          'created_time': <String, dynamic>{},
        },
      },
    });

    expect(
      schema.properties['People']?.tapesType,
      TapesPropertyType.unsupported,
    );
    expect(schema.properties['People']?.isWritable, isFalse);
    expect(schema.properties['Files']?.isWritable, isFalse);
    expect(schema.properties['Related']?.isWritable, isFalse);
    expect(schema.properties['Total']?.isReadOnly, isTrue);
    expect(schema.properties['Formula']?.isReadOnly, isTrue);
    expect(schema.properties['Created']?.isReadOnly, isTrue);
    expect(schema.writableProperties.map((property) => property.name), [
      'Title',
    ]);
  });

  test('handles missing or corrupted properties payload', () {
    expect(NotionSchemaParser.parse('db', {}).properties, isEmpty);
    expect(
      NotionSchemaParser.parse('db', {'properties': 'nope'}).properties,
      isEmpty,
    );
    expect(
      NotionSchemaParser.parse('db', {'properties': null}).properties,
      isEmpty,
    );
  });

  test('skips malformed property entries', () {
    final schema = NotionSchemaParser.parse('db', {
      'properties': {
        'NoType': {'id': 'x'},
        'NullValue': null,
        'StringValue': 'oops',
        'BadOptions': {
          'id': 'sel',
          'type': 'select',
          'select': {'options': 'nope'},
        },
      },
    });

    expect(schema.properties.containsKey('NoType'), isFalse);
    expect(schema.properties.containsKey('NullValue'), isFalse);
    expect(schema.properties.containsKey('StringValue'), isFalse);
    expect(schema.properties['BadOptions']?.options, isEmpty);
  });

  test('filters invalid option entries and falls back for missing fields', () {
    final schema = NotionSchemaParser.parse('db', {
      'properties': {
        'Tags': {
          'type': 'multi_select',
          'multi_select': {
            'options': [
              'oops',
              {'name': 'valid'},
              {'id': 'no-name'},
            ],
          },
        },
      },
    });

    final property = schema.properties['Tags']!;
    expect(property.id, 'Tags');
    expect(property.options, hasLength(1));
    expect(property.options.single.name, 'valid');
    expect(property.options.single.id, '');
    expect(property.options.single.color, 'default');
  });

  test('returns a null title property when the schema has no title', () {
    final schema = NotionSchemaParser.parse('db', {
      'properties': {
        'Done': {
          'id': 'check',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
      },
    });

    expect(schema.titleProperty, isNull);
  });
}
