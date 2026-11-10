import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/services/notion/notion_block_mapper.dart';

Map<String, dynamic> richText(String content) {
  return {
    'type': 'text',
    'text': {'content': content},
  };
}

void main() {
  group('NotionBlockMapper.blockToNotionJson', () {
    test('maps a text block to a paragraph block', () {
      final block = TapeBlock(type: BlockType.text, text: 'Halo Tapes');

      expect(NotionBlockMapper.blockToNotionJson(block), {
        'object': 'block',
        'type': 'paragraph',
        'paragraph': {
          'rich_text': [richText('Halo Tapes')],
        },
      });
    });

    test('maps a checked todo block to a to_do block', () {
      final block = TapeBlock(
        type: BlockType.todo,
        text: 'Selesai',
        isChecked: true,
      );

      expect(NotionBlockMapper.blockToNotionJson(block), {
        'object': 'block',
        'type': 'to_do',
        'to_do': {
          'rich_text': [richText('Selesai')],
          'checked': true,
        },
      });
    });

    test('maps an unchecked todo block to a to_do block', () {
      final block = TapeBlock(
        type: BlockType.todo,
        text: 'Belum selesai',
        isChecked: false,
      );

      expect(NotionBlockMapper.blockToNotionJson(block), {
        'object': 'block',
        'type': 'to_do',
        'to_do': {
          'rich_text': [richText('Belum selesai')],
          'checked': false,
        },
      });
    });

    test('maps a toggle block with recursive children', () {
      final block = TapeBlock(
        type: BlockType.toggle,
        text: 'Bagian',
        children: [
          TapeBlock(type: BlockType.text, text: 'Anak teks'),
          TapeBlock(
            type: BlockType.todo,
            text: 'Anak todo',
            isChecked: true,
            children: [
              TapeBlock(type: BlockType.text, text: 'Cucu'),
            ],
          ),
        ],
      );

      expect(NotionBlockMapper.blockToNotionJson(block), {
        'object': 'block',
        'type': 'toggle',
        'toggle': {
          'rich_text': [richText('Bagian')],
          'children': [
            {
              'object': 'block',
              'type': 'paragraph',
              'paragraph': {
                'rich_text': [richText('Anak teks')],
              },
            },
            {
              'object': 'block',
              'type': 'to_do',
              'to_do': {
                'rich_text': [richText('Anak todo')],
                'checked': true,
              },
            },
          ],
        },
      });
    });

    test('omits children for a toggle without children', () {
      final block = TapeBlock(type: BlockType.toggle, text: 'Kosong');

      expect(NotionBlockMapper.blockToNotionJson(block), {
        'object': 'block',
        'type': 'toggle',
        'toggle': {
          'rich_text': [richText('Kosong')],
        },
      });
    });
  });

  group('NotionBlockMapper.blocksToNotionPayload', () {
    test('maps a mixed list in order', () {
      final blocks = [
        TapeBlock(type: BlockType.text, text: 'Satu'),
        TapeBlock(type: BlockType.todo, text: 'Dua', isChecked: false),
        TapeBlock(type: BlockType.toggle, text: 'Tiga'),
      ];

      final payload = NotionBlockMapper.blocksToNotionPayload(blocks);

      expect(payload, hasLength(3));
      expect(payload[0]['type'], 'paragraph');
      expect(payload[1]['type'], 'to_do');
      expect(payload[2]['type'], 'toggle');
      expect(payload[0], NotionBlockMapper.blockToNotionJson(blocks[0]));
      expect(payload[1], NotionBlockMapper.blockToNotionJson(blocks[1]));
      expect(payload[2], NotionBlockMapper.blockToNotionJson(blocks[2]));
    });

    test('returns an empty payload for an empty list', () {
      expect(NotionBlockMapper.blocksToNotionPayload(<TapeBlock>[]), isEmpty);
    });
  });
}
