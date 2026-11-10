import 'package:flutter/foundation.dart';
import 'package:tapes/models/note.dart';

class ContentViewModel extends ChangeNotifier {
  ContentViewModel({List<TapeBlock>? blocks})
    : _blocks = List.of(
        blocks == null || blocks.isEmpty
            ? [TapeBlock(type: BlockType.text, text: '')]
            : blocks,
      ) {
    _initialSignatures = _signatures;
  }

  final List<TapeBlock> _blocks;
  late List<String> _initialSignatures;

  List<TapeBlock> get blocks => List.unmodifiable(_blocks);

  bool get isDirty => !listEquals(_signatures, _initialSignatures);

  void markClean() {
    _initialSignatures = _signatures;
  }

  List<String> get _signatures => _blocks
      .map(
        (block) =>
            '${block.id}|${block.type.name}|${block.text}|${block.isChecked}',
      )
      .toList();

  void updateText(int index, String text) {
    if (index < 0 || index >= _blocks.length) return;
    _blocks[index] = _blocks[index].copyWith(text: text);
    notifyListeners();
  }

  void addBlockAfter(int index, {BlockType type = BlockType.text}) {
    final insertAt = index >= 0 && index < _blocks.length
        ? index + 1
        : _blocks.length;
    _blocks.insert(insertAt, TapeBlock(type: type, text: ''));
    notifyListeners();
  }

  void removeBlock(int index) {
    if (_blocks.length <= 1 || index < 0 || index >= _blocks.length) return;
    _blocks.removeAt(index);
    notifyListeners();
  }

  void toggleTodo(int index) {
    if (index < 0 || index >= _blocks.length) return;
    _blocks[index] = _blocks[index].copyWith(
      isChecked: !_blocks[index].isChecked,
    );
    notifyListeners();
  }

  void changeType(int index, BlockType newType) {
    if (index < 0 || index >= _blocks.length) return;
    _blocks[index] = _blocks[index].copyWith(type: newType);
    notifyListeners();
  }
}
