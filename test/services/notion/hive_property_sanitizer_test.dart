import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/services/notion/hive_property_sanitizer.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/notion_schema_parser.dart';

NotionDatabaseSchema buildSchema() {
  return NotionSchemaParser.parse(
    'db',
    {
      'properties': {
        'Name': {
          'id': 't',
          'type': 'title',
          'title': <String, dynamic>{},
        },
        'Notes': {
          'id': 'r',
          'type': 'rich_text',
          'rich_text': <String, dynamic>{},
        },
        'Score': {
          'id': 'n',
          'type': 'number',
          'number': <String, dynamic>{},
        },
        'Done': {
          'id': 'c',
          'type': 'checkbox',
          'checkbox': <String, dynamic>{},
        },
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
              {'id': 'o3', 'name': 'journal', 'color': 'green'},
            ],
          },
        },
        'Due': {
          'id': 'd',
          'type': 'date',
          'date': <String, dynamic>{},
        },
        'Link': {'id': 'u', 'type': 'url', 'url': <String, dynamic>{}},
        'Calc': {
          'id': 'f',
          'type': 'formula',
          'formula': <String, dynamic>{},
        },
      },
    },
    fetchedAt: DateTime(2026),
  );
}

void main() {
  test('keeps supported values and drops unknown/read-only/unsupported', () {
    final schema = buildSchema();

    final result = HivePropertySanitizer.sanitize(schema, {
      'Name': 'Hari ini',
      'Notes': '',
      'Score': '12,5',
      'Done': true,
      'Status': 'Todo',
      'Tags': ['flutter', 'unknown', 'flutter'],
      'Due': DateTime(2026, 11, 10, 15, 30),
      'Link': 'https://example.com',
      'Calc': 'ignored',
      'Unknown': 'dropped',
    });

    expect(result, {
      'Name': 'Hari ini',
      'Score': 12.5,
      'Done': true,
      'Status': 'Todo',
      'Tags': ['flutter'],
      'Due': '2026-11-10',
      'Link': 'https://example.com',
    });
  });

  test('normalizes numeric strings before parsing', () {
    final score = buildSchema().properties['Score']!;

    expect(HivePropertySanitizer.sanitizeValue(score, '42'), 42);
    expect(HivePropertySanitizer.sanitizeValue(score, '12,5'), 12.5);
    expect(HivePropertySanitizer.sanitizeValue(score, 3.5), 3.5);
    expect(HivePropertySanitizer.sanitizeValue(score, '1 000'), isNull);
    expect(HivePropertySanitizer.sanitizeValue(score, true), isNull);
  });

  test('checkbox only accepts bool', () {
    final done = buildSchema().properties['Done']!;

    expect(HivePropertySanitizer.sanitizeValue(done, true), isTrue);
    expect(HivePropertySanitizer.sanitizeValue(done, false), isFalse);
    expect(HivePropertySanitizer.sanitizeValue(done, 'true'), isNull);
  });

  test('select and status drop values outside schema options', () {
    final status = buildSchema().properties['Status']!;

    expect(HivePropertySanitizer.sanitizeValue(status, 'Todo'), 'Todo');
    expect(HivePropertySanitizer.sanitizeValue(status, 'Done'), isNull);
    expect(HivePropertySanitizer.sanitizeValue(status, 5), isNull);
  });

  test('multi_select filters unknown values and removes duplicates', () {
    final tags = buildSchema().properties['Tags']!;

    expect(
      HivePropertySanitizer.sanitizeValue(tags, [
        'flutter',
        'nope',
        'flutter',
        'journal',
      ]),
      ['flutter', 'journal'],
    );
    expect(HivePropertySanitizer.sanitizeValue(tags, 'flutter'), isNull);
    expect(HivePropertySanitizer.sanitizeValue(tags, ['nope']), isNull);
  });

  test('date is stored as YYYY-MM-DD', () {
    final due = buildSchema().properties['Due']!;

    expect(
      HivePropertySanitizer.sanitizeValue(due, DateTime(2026, 1, 2, 23, 59)),
      '2026-01-02',
    );
    expect(HivePropertySanitizer.sanitizeValue(due, '2026-11-10'), '2026-11-10');
    expect(HivePropertySanitizer.sanitizeValue(due, 'not-a-date'), isNull);
  });

  test('drops null and empty-string values', () {
    final schema = buildSchema();

    expect(
      HivePropertySanitizer.sanitize(schema, {
        'Name': '   ',
        'Notes': null,
        'Score': null,
      }),
      isEmpty,
    );
  });

  test('is idempotent', () {
    final schema = buildSchema();
    final values = <String, Object?>{
      'Name': 'Hari ini',
      'Score': '7',
      'Tags': ['flutter', 'flutter'],
      'Due': '2026-11-10',
    };

    final once = HivePropertySanitizer.sanitize(schema, values);
    final twice = HivePropertySanitizer.sanitize(schema, once);

    expect(twice, once);
  });
}
