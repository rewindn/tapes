import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapes/ui/widgets/list_card.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:tapes/ui/widgets/retro_screen_header.dart';

class ListTape extends StatelessWidget {
  final ValueChanged<Note>? onNoteTap;
  final bool isConnected;
  final String? databaseName;

  const ListTape({
    super.key,
    this.onNoteTap,
    this.isConnected = true,
    this.databaseName,
  });

  String? _focusFor(Note note) {
    final value = note.properties['Dominant Focus'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  @override
  Widget build(BuildContext context) {    if (!isConnected) {
      return const SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RetroScreenHeader(title: 'Recorded On'),
            Expanded(
              child: Center(
                child: Text(
                  'Belum Terhubung ke Notion, atur koneksi di Settings',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final repo = context.read<NoteRepository>();
    return ValueListenableBuilder(
      valueListenable: repo.listenable,
      builder: (_, _, _) {
        final notes = repo.getAllNotes();
        final onTap = onNoteTap;
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RetroScreenHeader(title: 'Recorded On'),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.zero,
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: notes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == notes.length) {
                            // ruang kosong agar kartu terakhir bebas navbar
                            return const SizedBox(height: 140.0);
                          }
                          final note = notes[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: ListCard(
                              date: note.createdAt,
                              databaseName: databaseName,
                              focus: _focusFor(note),
                              onTap: onTap == null ? null : () => onTap(note),
                            ),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
