import 'package:flutter/foundation.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';
import 'package:uuid/uuid.dart';

class ContentViewModel extends ChangeNotifier {
  ContentViewModel(this._repository);

  final NoteRepository _repository;
  final List<TapeBlock> _blocks = [TapeBlock(type: BlockType.text, text: '')];

  List<TapeBlock> get blocks => List.unmodifiable(_blocks);

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

  Future<bool> saveNote() async {
    final text = _blocks
        .map((block) => block.text)
        .where((value) => value.isNotEmpty)
        .join('\n');
    if (text.isEmpty) return false;

    final note = Note(
      id: const Uuid().v4(),
      blocks: List.of(_blocks),
      createdAt: DateTime.now(),
    );
    await _repository.saveNote(note);
    return true;
  }
}
