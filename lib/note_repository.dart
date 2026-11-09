import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'note.dart';

typedef NoteSyncHandler = Future<Note> Function(Note note);

class NoteRepository {
  NoteRepository({Box<dynamic>? box, NoteSyncHandler? syncHandler})
    : _box = box ?? Hive.box('notebox'),
      _syncHandler = syncHandler;

  final Box<dynamic> _box;
  final NoteSyncHandler? _syncHandler;

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

  Future<void> saveNote(Note note) async {
    await _box.put(note.id, note.toMap());

    final handler = _syncHandler;
    if (handler != null) {
      unawaited(_syncInBackground(handler, note));
    }
  }

  Future<void> _syncInBackground(NoteSyncHandler handler, Note note) async {
    try {
      final synced = await handler(note);
      if (synced.notionPageId != note.notionPageId) {
        await _box.put(synced.id, synced.toMap());
      }
    } catch (_) {
      // Local-first: remote sync failures must never surface to the caller.
    }
  }

  Future<void> deleteNote(String id) => _box.delete(id);

  ValueListenable<Box<dynamic>> get listenable => _box.listenable();
}
