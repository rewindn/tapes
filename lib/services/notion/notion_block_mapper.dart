import 'package:tapes/note.dart';

class NotionBlockMapper {
  static Map<String, dynamic> blockToNotionJson(TapeBlock block) {
    final richText = [
      {
        'type': 'text',
        'text': {'content': block.text},
      },
    ];

    return switch (block.type) {
      BlockType.text => {
        'object': 'block',
        'type': 'paragraph',
        'paragraph': {'rich_text': richText},
      },
      BlockType.todo => {
        'object': 'block',
        'type': 'to_do',
        'to_do': {'rich_text': richText, 'checked': block.isChecked},
      },
      BlockType.toggle => {
        'object': 'block',
        'type': 'toggle',
        'toggle': {
          'rich_text': richText,
          if (block.children.isNotEmpty)
            'children': blocksToNotionPayload(block.children),
        },
      },
    };
  }

  static List<Map<String, dynamic>> blocksToNotionPayload(
    List<TapeBlock> blocks,
  ) {
    return blocks.map(blockToNotionJson).toList();
  }
}
