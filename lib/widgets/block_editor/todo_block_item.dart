import 'package:flutter/material.dart';

class TodoBlockItem extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isChecked;
  final VoidCallback onToggleCheck;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  const TodoBlockItem({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isChecked,
    required this.onToggleCheck,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: isChecked, onChanged: (_) => onToggleCheck()),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmitted(),
            decoration: const InputDecoration(
              hintText: 'To-do...',
              hintStyle: TextStyle(color: Colors.black38),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
