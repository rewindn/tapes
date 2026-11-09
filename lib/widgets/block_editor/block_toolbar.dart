import 'package:flutter/material.dart';
import 'package:tapes/note.dart';

class BlockToolbar extends StatelessWidget {
  final BlockType type;
  final VoidCallback onCycle;

  const BlockToolbar({super.key, required this.type, required this.onCycle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Tipe blok: ${type.name}',
          onPressed: onCycle,
          icon: Icon(_iconForType(type)),
        ),
        Text(type.name, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

IconData _iconForType(BlockType type) {
  return switch (type) {
    BlockType.text => Icons.text_fields,
    BlockType.todo => Icons.check_box_outline_blank,
    BlockType.toggle => Icons.keyboard_arrow_right,
  };
}
