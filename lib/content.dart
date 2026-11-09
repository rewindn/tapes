import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';
import 'package:tapes/viewmodels/content_view_model.dart';
import 'package:tapes/widgets/block_editor/block_toolbar.dart';
import 'package:tapes/widgets/block_editor/text_block_item.dart';
import 'package:tapes/widgets/block_editor/todo_block_item.dart';
import 'package:tapes/widgets/block_editor/toggle_block_item.dart';

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ContentViewModel(ctx.read<NoteRepository>()),
      child: const _ContentForm(),
    );
  }
}

class _ContentForm extends StatefulWidget {
  const _ContentForm();

  @override
  State<_ContentForm> createState() => _ContentFormState();
}

class _ContentFormState extends State<_ContentForm> {
  final date = DateFormat.yMMMd().format(DateTime.now());
  final day = DateFormat.EEEE().format(DateTime.now());

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _activeId;

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
    final vm = context.read<ContentViewModel>();
    final index = vm.blocks.indexWhere((block) => block.id == id);
    if (index < 0 || vm.blocks[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    _removeBlock(vm, index);
    return KeyEventResult.handled;
  }

  int _activeIndex(ContentViewModel vm) {
    final id = _activeId;
    if (id != null) {
      final index = vm.blocks.indexWhere((block) => block.id == id);
      if (index >= 0) return index;
    }
    return 0;
  }

  void _setActive(String id) {
    if (_activeId == id) return;
    setState(() => _activeId = id);
  }

  void _addAfter(ContentViewModel vm, int index) {
    vm.addBlockAfter(index);
    final next = vm.blocks[index < vm.blocks.length - 1 ? index + 1 : 0];
    _focusNodeFor(next).requestFocus();
  }

  void _removeBlock(ContentViewModel vm, int index) {
    if (vm.blocks.length <= 1) return;
    final removed = vm.blocks[index];
    vm.removeBlock(index);
    _controllers.remove(removed.id)?.dispose();
    _focusNodes.remove(removed.id)?.dispose();
    final previous = vm.blocks[index > 0 ? index - 1 : 0];
    _focusNodeFor(previous).requestFocus();
  }

  void _cycleType(ContentViewModel vm, int index) {
    final nextType = BlockType
        .values[(vm.blocks[index].type.index + 1) % BlockType.values.length];
    vm.changeType(index, nextType);
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

  Future<void> _save() async {
    final vm = context.read<ContentViewModel>();
    final text = vm.blocks
        .map((block) => block.text)
        .where((value) => value.isNotEmpty)
        .join('\n');
    final saved = await vm.saveNote();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'User $text ditambahkan! ✅' : 'Isi semua field!'),
      ),
    );
  }

  Widget _blockWidget(ContentViewModel vm, int index) {
    final block = vm.blocks[index];
    return switch (block.type) {
      BlockType.text => TextBlockItem(
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        onTap: () => _setActive(block.id),
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
      BlockType.todo => TodoBlockItem(
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        isChecked: block.isChecked,
        onToggleCheck: () => vm.toggleTodo(index),
        onTap: () => _setActive(block.id),
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
      BlockType.toggle => ToggleBlockItem(
        block: block,
        controller: _controllerFor(block),
        focusNode: _focusNodeFor(block),
        onTap: () => _setActive(block.id),
        onChanged: (text) => vm.updateText(index, text),
        onSubmitted: () => _addAfter(vm, index),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ContentViewModel>();
    final activeIndex = _activeIndex(vm);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Record Your Day',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 586),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 174, 93, 100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'in $date',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 0.8,
                          fontSize: 32,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Apa 1 masalah yang kamu selesaikan hari ini? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: vm.blocks.length,
                          itemBuilder: (context, index) =>
                              _blockWidget(vm, index),
                        ),
                      ),
                      const SizedBox(height: 8),
                      BlockToolbar(
                        type: vm.blocks[activeIndex].type,
                        onCycle: () => _cycleType(vm, activeIndex),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ElevatedButton(
                            onPressed: _save,
                            style: const ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Color.fromARGB(255, 255, 229, 136),
                              ),
                              elevation: WidgetStatePropertyAll(2),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
