import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapes/listcard.dart';
import 'package:tapes/note_repository.dart';

class ListTape extends StatelessWidget {
  const ListTape({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NoteRepository>();
    return ValueListenableBuilder(
      valueListenable: repo.listenable,
      builder: (_, _, _) {
        final notes = repo.getAllNotes();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 101),
              const Text(
                'Recorded Tape',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'there is no note',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notes.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return ListCard(
                            note: note.content,
                            date: note.createdAt,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
