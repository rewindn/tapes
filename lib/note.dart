import 'package:uuid/uuid.dart';

enum BlockType {
  text,
  todo,
  toggle;

  static BlockType fromString(Object? value) {
    if (value is String) {
      return BlockType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => BlockType.text,
      );
    }
    return BlockType.text;
  }
}

class TapeBlock {
  final String id;
  final BlockType type;
  final String text;
  final bool isChecked;
  final List<TapeBlock> children;

  TapeBlock({
    String? id,
    this.type = BlockType.text,
    this.text = '',
    this.isChecked = false,
    this.children = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'isChecked': isChecked,
      'children': children.map((child) => child.toMap()).toList(),
    };
  }

  factory TapeBlock.fromMap(Map<dynamic, dynamic> map) {
    final rawChildren = map['children'];
    return TapeBlock(
      id: map['id'] as String?,
      type: BlockType.fromString(map['type']),
      text: map['text'] as String? ?? '',
      isChecked: map['isChecked'] == true,
      children: (rawChildren is List ? rawChildren : const [])
          .map((e) => e is TapeBlock
              ? e
              : e is Map
                  ? TapeBlock.fromMap(e)
                  : null)
          .whereType<TapeBlock>()
          .toList(),
    );
  }

  TapeBlock copyWith({
    String? id,
    BlockType? type,
    String? text,
    bool? isChecked,
    List<TapeBlock>? children,
  }) {
    return TapeBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      children: children ?? this.children,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final List<TapeBlock> blocks;
  final DateTime createdAt;

  const Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.blocks = const [],
    required this.createdAt,
  });

  String _deriveContent() {
    return blocks
        .where((block) => block.text.isNotEmpty)
        .map((block) => block.text)
        .join('\n');
  }

  Map<String, dynamic> toMap() {
    final text = content.isEmpty ? _deriveContent() : content;
    return {
      'id': id,
      'note': text,
      'title': title,
      'content': text,
      'blocks': blocks.map((block) => block.toMap()).toList(),
      'createdAt': createdAt.toString(),
    };
  }

  factory Note.fromMap(Map<dynamic, dynamic> map, String id) {
    final text = map['content'] as String? ?? map['note'] as String? ?? '';
    final rawBlocks = map['blocks'];
    List<TapeBlock> blocks = (rawBlocks is List ? rawBlocks : const [])
        .map((e) => e is TapeBlock
            ? e
            : e is Map
                ? TapeBlock.fromMap(e)
                : null)
        .whereType<TapeBlock>()
        .toList();
    if (blocks.isEmpty) {
      blocks = [TapeBlock(type: BlockType.text, text: text)];
    }
    return Note(
      id: (map['id'] as String?) ?? id,
      title: map['title'] as String? ?? '',
      content: text,
      blocks: blocks,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() => 'Note(id: $id, content: $content, date: $createdAt)';
}
