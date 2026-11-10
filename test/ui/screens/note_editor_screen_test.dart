import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/ui/screens/note_editor_screen.dart';

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
  Future<FakeNoteRepository> pumpEditor(
    WidgetTester tester, {
    Note? note,
    String databaseName = 'Weekday Learning System',
  }) async {
    final repository = FakeNoteRepository();
    await tester.pumpWidget(
      Provider<NoteRepository>(
        create: (_) => repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NoteEditorScreen(
                        note: note,
                        databaseName: databaseName,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> systemBack(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
  }

  Future<void> tapPlay(WidgetTester tester) async {
    await tester.ensureVisible(find.byIcon(Icons.play_arrow));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the cassette editor fields', (tester) async {
    await pumpEditor(tester);

    expect(find.text('Record Your Day'), findsOneWidget);
    expect(find.text('Weekday Learning System'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Tape in here ...........'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('saves title and content as a paragraph block', (tester) async {
    final repository = await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Catatan Baru');
    await tester.enterText(find.byType(TextField).at(1), 'Isi tape');
    await tapPlay(tester);

    expect(repository.savedNotes, hasLength(1));
    final saved = repository.savedNotes.single;
    expect(saved.title, 'Catatan Baru');
    expect(saved.blocks, hasLength(1));
    expect(saved.blocks.single.text, 'Isi tape');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('requires a title before saving', (tester) async {
    final repository = await pumpEditor(tester);

    await tapPlay(tester);

    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(repository.savedNotes, isEmpty);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('hydrates an existing note', (tester) async {
    final note = Note(
      id: 'note-1',
      title: 'Judul Lama',
      blocks: [TapeBlock(type: BlockType.text, text: 'Blok Lama')],
      createdAt: DateTime(2026, 11, 10),
    );

    await pumpEditor(tester, note: note);

    expect(find.text('Judul Lama'), findsOneWidget);
    expect(find.text('Blok Lama'), findsOneWidget);
  });

  testWidgets('PopScope blocks navigation while content is dirty', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(1), 'dirty');
    await tester.pump();
    await systemBack(tester);

    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Record Your Day'), findsOneWidget);
  });

  testWidgets('PopScope blocks navigation while the title is dirty', (
    tester,
  ) async {
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Judul');
    await tester.pump();
    await systemBack(tester);

    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('closes without a dialog when nothing changed', (tester) async {
    await pumpEditor(tester);

    await systemBack(tester);

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Buang perubahan?'), findsNothing);
  });
}
