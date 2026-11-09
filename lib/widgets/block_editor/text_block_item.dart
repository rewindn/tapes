import 'package:flutter/material.dart';

class TextBlockItem extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const TextBlockItem({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        decoration: const InputDecoration(
          hintText: 'Tape In Here...',
          hintStyle: TextStyle(color: Colors.black38),
          isDense: true,
        ),
      ),
    );
  }
}
