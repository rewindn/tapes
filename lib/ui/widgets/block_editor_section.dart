import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/ui/widgets/block_editor/text_block_item.dart';
import 'package:tapes/ui/widgets/block_editor/todo_block_item.dart';
import 'package:tapes/ui/widgets/block_editor/toggle_block_item.dart';
import 'package:tapes/viewmodels/content_view_model.dart';

class BlockEditorSection extends StatefulWidget {
  final ContentViewModel viewModel;

  const BlockEditorSection({super.key, required this.viewModel});

  @override
  State<BlockEditorSection> createState() => _BlockEditorSectionState();
}

class _BlockEditorSectionState extends State<BlockEditorSection> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  TextEditingController _controllerFor(TapeBlock block) {
    return _controllers.putIfAbsent(
      block.id,
      () => TextEditingController(text: block.text),
    );
  }

  FocusNode _focusNodeFor(TapeBlock block) {
    return _focusNodes.putIfAbsent(
      block.id,
      () => FocusNode(onKeyEvent: (_, event) => _onKey(block.id, event)),
    );
  }

  KeyEventResult _onKey(String id, KeyEvent event) {
    // shortcut: only hardware key events reach here, some soft keyboards skip it
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    final vm = widget.viewModel;
    final index = vm.blocks.indexWhere((block) => block.id == id);
    if (index < 0 || vm.blocks[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    _removeBlock(index);
    return KeyEventResult.handled;
  }

  void _addAfter(ContentViewModel vm, int index) {
    vm.addBlockAfter(index);
    final next = vm.blocks[index < vm.blocks.length - 1 ? index + 1 : 0];
    _focusNodeFor(next).requestFocus();
  }

  void _removeBlock(int index) {
    final vm = widget.viewModel;
    if (vm.blocks.length <= 1) return;
    final removed = vm.blocks[index];
    vm.removeBlock(index);
    _controllers.remove(removed.id)?.dispose();
    _focusNodes.remove(removed.id)?.dispose();
    final previous = vm.blocks[index > 0 ? index - 1 : 0];
    _focusNodeFor(previous).requestFocus();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _blockWidget(ContentViewModel vm, int index) {
    final block = vm.blocks[index];
    return switch (block.type) {
      BlockType.text => TextBlockItem(
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        onTap: () {},
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
      BlockType.todo => TodoBlockItem(
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        isChecked: block.isChecked,
        onToggleCheck: () => vm.toggleTodo(index),
        onTap: () {},
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
      BlockType.toggle => ToggleBlockItem(
        block: block,
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        onTap: () {},
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < vm.blocks.length; index++)
              _blockWidget(vm, index),
          ],
        );
      },
    );
  }
}
