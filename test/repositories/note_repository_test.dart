import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tapes_repo_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('notebox');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Note buildNote({String id = 'note-1'}) {
    return Note(
      id: id,
      blocks: [TapeBlock(type: BlockType.text, text: 'Halo')],
      createdAt: DateTime(2026, 11, 7),
    );
  }

  test('persists locally and stores the synced remote id', () async {
    final repository = NoteRepository(
      box: box,
      syncHandler: (note) async => note.copyWith(notionPageId: 'page-1'),
    );
    final note = buildNote();

    await repository.saveNote(note);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final stored = repository.getNote(note.id);
    expect(stored, isNotNull);
    expect(stored!.notionPageId, 'page-1');
    expect(stored.blocks.single.text, 'Halo');
  });

  test('saves locally when the sync handler fails', () async {
    final repository = NoteRepository(
      box: box,
      syncHandler: (note) async => throw Exception('offline'),
    );
    final note = buildNote();

    await repository.saveNote(note);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final stored = repository.getNote(note.id);
    expect(stored, isNotNull);
    expect(stored!.notionPageId, isNull);
  });

  test('saves locally when no sync handler is configured', () async {
    final repository = NoteRepository(box: box);
    final note = buildNote();

    await repository.saveNote(note);

    expect(repository.getNote(note.id), isNotNull);
    expect(repository.getAllNotes(), hasLength(1));
  });

  test('keeps local note when the sync result has no remote id', () async {
    final repository = NoteRepository(
      box: box,
      syncHandler: (note) async => note,
    );
    final note = buildNote();

    await repository.saveNote(note);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final stored = repository.getNote(note.id);
    expect(stored, isNotNull);
    expect(stored!.notionPageId, isNull);
  });
}
