import 'package:tapes/note.dart';

abstract interface class RemoteNoteDataSource {
  Future<String> createNotePage({
    required String databaseId,
    required String title,
    required List<TapeBlock> blocks,
  });

  Future<String> createPageFromPayload(Map<String, dynamic> payload);
}
