import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'note.dart';

class NoteRepository {
  final Box _box;

  NoteRepository({Box? box}) : _box = box ?? Hive.box('notebox');

  List<Note> getAllNotes() {
    final notes = _box
        .toMap()
        .entries
        .where((entry) => entry.value is Map)
        .map((entry) => Note.fromMap(entry.value as Map, entry.key.toString()))
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Note? getNote(String id) {
    final raw = _box.get(id);
    if (raw is Map) return Note.fromMap(raw, id);
    return null;
  }

  Future<void> saveNote(Note note) => _box.put(note.id, note.toMap());

  Future<void> deleteNote(String id) => _box.delete(id);

  ValueListenable<Box> get listenable => _box.listenable();
}
