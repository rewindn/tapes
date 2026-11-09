import 'package:flutter/material.dart';
import 'package:tapes/note.dart';

class ToggleBlockItem extends StatefulWidget {
  final TapeBlock block;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const ToggleBlockItem({
    super.key,
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<ToggleBlockItem> createState() => _ToggleBlockItemState();
}

class _ToggleBlockItemState extends State<ToggleBlockItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onTap: widget.onTap,
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmitted(),
                decoration: const InputDecoration(
                  hintText: 'Toggle...',
                  hintStyle: TextStyle(color: Colors.black38),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        if (_expanded)
          for (final child in widget.block.children) _buildChild(child, 0),
      ],
    );
  }

  Widget _buildChild(TapeBlock child, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: 56 + 16.0 * depth, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            child.text,
            style: const TextStyle(color: Colors.white70),
          ),
          for (final grandChild in child.children)
            _buildChild(grandChild, depth + 1),
        ],
      ),
    );
  }
}
