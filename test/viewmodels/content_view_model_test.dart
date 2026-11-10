import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/viewmodels/content_view_model.dart';

void main() {
  test('starts with one empty text block', () {
    final vm = ContentViewModel();

    expect(vm.blocks, hasLength(1));
    expect(vm.blocks.single.type, BlockType.text);
    expect(vm.isDirty, isFalse);
  });

  test('starts from provided blocks', () {
    final block = TapeBlock(type: BlockType.text, text: 'Awal');
    final vm = ContentViewModel(blocks: [block]);

    expect(vm.blocks.single.text, 'Awal');
    expect(vm.isDirty, isFalse);
  });

  test('tracks dirty state until marked clean', () {
    final vm = ContentViewModel();

    vm.updateText(0, 'Halo');
    expect(vm.isDirty, isTrue);

    vm.markClean();
    expect(vm.isDirty, isFalse);

    vm.toggleTodo(0);
    expect(vm.isDirty, isTrue);
  });

  test('manipulates the block list', () {
    final vm = ContentViewModel();

    vm.updateText(0, 'Satu');
    vm.addBlockAfter(0);
    expect(vm.blocks, hasLength(2));

    vm.changeType(1, BlockType.todo);
    expect(vm.blocks[1].type, BlockType.todo);

    vm.toggleTodo(1);
    expect(vm.blocks[1].isChecked, isTrue);

    vm.removeBlock(1);
    expect(vm.blocks, hasLength(1));
  });
}
