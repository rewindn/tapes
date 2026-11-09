import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tapes/content.dart';
import 'package:tapes/note.dart';
import 'package:tapes/note_repository.dart';

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

Widget createTestWidget(NoteRepository repo) {
  return Provider<NoteRepository>(
    create: (_) => repo,
    child: const MaterialApp(home: Scaffold(body: MainContent())),
  );
}

void main() {
  testWidgets('renders the note form with input and save button', (
    WidgetTester tester,
  ) async {
    final repo = FakeNoteRepository();

    await tester.pumpWidget(createTestWidget(repo));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('types a note and saves it through the repository', (
    WidgetTester tester,
  ) async {
    final repo = FakeNoteRepository();

    await tester.pumpWidget(createTestWidget(repo));
    await tester.enterText(find.byType(TextField), 'Catatan latihan Tapes');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(repo.savedNotes, hasLength(1));
    expect(repo.savedNotes.single.blocks, hasLength(1));
    expect(repo.savedNotes.single.blocks.single.text, 'Catatan latihan Tapes');
    expect(repo.savedNotes.single.id, isNotEmpty);
  });

  testWidgets('does not save when the note is empty', (
    WidgetTester tester,
  ) async {
    final repo = FakeNoteRepository();

    await tester.pumpWidget(createTestWidget(repo));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(repo.savedNotes, isEmpty);
    expect(find.text('Isi semua field!'), findsOneWidget);
  });
}
