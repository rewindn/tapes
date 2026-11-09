import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';
import 'package:tapes/viewmodels/content_view_model.dart';

class FakeNoteRepository implements NoteRepository {
  final List<Note> savedNotes = [];

  @override
  List<Note> getAllNotes() => savedNotes;

  @override
  Note? getNote(String id) {
    for (final note in savedNotes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<void> saveNote(Note note) async {
    savedNotes.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    savedNotes.removeWhere((note) => note.id == id);
  }

  @override
  ValueListenable<Box<dynamic>> get listenable => throw UnimplementedError();
}

void main() {
  test('saveNote persists locally through the repository', () async {
    final repo = FakeNoteRepository();
    final vm = ContentViewModel(repo);
    vm.updateText(0, 'Halo');

    final saved = await vm.saveNote();

    expect(saved, isTrue);
    expect(repo.savedNotes, hasLength(1));
    expect(repo.savedNotes.single.blocks.single.text, 'Halo');
  });

  test('saveNote returns false when every block is empty', () async {
    final repo = FakeNoteRepository();
    final vm = ContentViewModel(repo);

    final saved = await vm.saveNote();

    expect(saved, isFalse);
    expect(repo.savedNotes, isEmpty);
  });
}
