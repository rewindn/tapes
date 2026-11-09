import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/note.dart';

void expectBlockEquals(TapeBlock actual, TapeBlock expected) {
  expect(actual.id, expected.id);
  expect(actual.type, expected.type);
  expect(actual.text, expected.text);
  expect(actual.isChecked, expected.isChecked);
  expect(actual.children.length, expected.children.length);
  for (var i = 0; i < expected.children.length; i++) {
    expectBlockEquals(actual.children[i], expected.children[i]);
  }
}

void main() {
  group('Note serialization', () {
    test('round-trips all fields through toMap/fromMap', () {
      final note = Note(
        id: 'note-1',
        title: 'Hari ini',
        content: 'Selesaikan bug',
        blocks: [
          TapeBlock(
            id: 'block-1',
            type: BlockType.todo,
            text: 'Selesaikan bug',
            isChecked: true,
            children: [
              TapeBlock(id: 'block-2', type: BlockType.text, text: 'Detail'),
            ],
          ),
          TapeBlock(id: 'block-3', type: BlockType.toggle, text: 'Bagian'),
        ],
        createdAt: DateTime(2026, 11, 7, 10, 30, 15, 123, 456),
        notionPageId: 'page-1',
        properties: {
          'Status': 'Done',
          'Tags': <String>['flutter', 'journal'],
          'Score': 3,
        },
      );

      final restored = Note.fromMap(note.toMap(), note.id);

      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.createdAt.isAtSameMomentAs(note.createdAt), isTrue);
      expect(restored.notionPageId, 'page-1');
      expect(restored.properties, note.properties);
      expect(restored.blocks.length, note.blocks.length);
      for (var i = 0; i < note.blocks.length; i++) {
        expectBlockEquals(restored.blocks[i], note.blocks[i]);
      }
    });

    test('toMap derives content from block text when content is empty', () {
      final note = Note(
        id: 'note-2',
        blocks: [TapeBlock(text: 'a'), TapeBlock(text: 'b')],
        createdAt: DateTime(2026, 11, 7),
      );

      expect(note.toMap()['content'], 'a\nb');
    });
  });

  group('Note.fromMap defensive parsing', () {
    test('empty map uses safe defaults', () {
      final note = Note.fromMap(<dynamic, dynamic>{}, 'fallback-id');

      expect(note.id, 'fallback-id');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.notionPageId, isNull);
      expect(note.properties, isEmpty);
      expect(note.blocks, hasLength(1));
      expect(note.blocks.single.type, BlockType.text);
      expect(note.blocks.single.text, '');
    });

    test('null createdAt falls back to now', () {
      final before = DateTime.now();
      final note = Note.fromMap(<dynamic, dynamic>{'createdAt': null}, 'id');
      final after = DateTime.now();

      expect(note.createdAt.isBefore(before), isFalse);
      expect(note.createdAt.isAfter(after), isFalse);
    });

    test('malformed createdAt string falls back to now', () {
      final before = DateTime.now();
      final note = Note.fromMap(
        <dynamic, dynamic>{'createdAt': 'not-a-date'},
        'id',
      );
      final after = DateTime.now();

      expect(note.createdAt.isBefore(before), isFalse);
      expect(note.createdAt.isAfter(after), isFalse);
    });

    test('notionPageId with an invalid type falls back to null', () {
      final note = Note.fromMap(
        <dynamic, dynamic>{'notionPageId': 123},
        'id',
      );

      expect(note.notionPageId, isNull);
    });

    test('properties with an invalid type fall back to an empty map', () {
      expect(
        Note.fromMap(<dynamic, dynamic>{'properties': 'nope'}, 'id').properties,
        isEmpty,
      );
      expect(
        Note.fromMap(<dynamic, dynamic>{'properties': null}, 'id').properties,
        isEmpty,
      );
      expect(
        Note.fromMap(<dynamic, dynamic>{
          'properties': {1: 'x'},
        }, 'id').properties,
        {'1': 'x'},
      );
    });

    test('null blocks wraps legacy content into one text block', () {
      final note = Note.fromMap(
        <dynamic, dynamic>{'content': 'legacy', 'blocks': null},
        'id',
      );

      expect(note.blocks, hasLength(1));
      expect(note.blocks.single.type, BlockType.text);
      expect(note.blocks.single.text, 'legacy');
    });

    test('non-list blocks value is ignored safely', () {
      final note = Note.fromMap(
        <dynamic, dynamic>{'content': 'legacy', 'blocks': 'not-a-list'},
        'id',
      );

      expect(note.blocks, hasLength(1));
      expect(note.blocks.single.text, 'legacy');
    });

    test('blocks containing invalid element types are filtered out', () {
      final note = Note.fromMap(
        <dynamic, dynamic>{
          'blocks': [
            42,
            'oops',
            null,
            <dynamic, dynamic>{'text': 'valid', 'type': 'unknown'},
          ],
        },
        'id',
      );

      expect(note.blocks, hasLength(1));
      expect(note.blocks.single.text, 'valid');
      expect(note.blocks.single.type, BlockType.text);
    });
  });

  group('Note date conversion', () {
    test('ISO-8601 createdAt keeps microsecond precision', () {
      final createdAt = DateTime(2026, 11, 7, 10, 30, 15, 123, 456);
      final note = Note.fromMap(
        <dynamic, dynamic>{'createdAt': createdAt.toString()},
        'id',
      );

      expect(note.createdAt.isAtSameMomentAs(createdAt), isTrue);
    });

    test('UTC ISO-8601 createdAt keeps the same instant', () {
      final createdAt = DateTime.utc(2026, 11, 7, 10, 30, 15, 123, 456);
      final note = Note.fromMap(
        <dynamic, dynamic>{'createdAt': createdAt.toString()},
        'id',
      );

      expect(note.createdAt.isAtSameMomentAs(createdAt), isTrue);
    });
  });
}
