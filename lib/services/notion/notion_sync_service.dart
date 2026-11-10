import 'package:tapes/models/note.dart';
import 'package:tapes/services/notion/models/notion_schema.dart';
import 'package:tapes/services/notion/client.dart';
import 'package:tapes/services/notion/payload.dart';
import 'package:tapes/services/notion/schema.dart';
import 'package:tapes/services/notion/remote_note_data_source.dart';

class NotionSyncService {
  NotionSyncService(this._source, this._schemaService);

  final RemoteNoteDataSource _source;
  final NotionSchemaService _schemaService;

  Future<Note> syncNote(Note note, {required String databaseId}) async {
    final existing = note.notionPageId;
    if (existing != null && existing.isNotEmpty) {
      return note;
    }

    final schema = await _schemaService.getSchema(databaseId);

    try {
      final remoteId = await _createPage(note, databaseId, schema);
      return note.copyWith(notionPageId: remoteId);
    } on NotionApiException catch (error) {
      if (error.statusCode != 400) rethrow;

      await _schemaService.invalidate(databaseId);
      final refreshed = await _schemaService.getSchema(
        databaseId,
        forceRefresh: true,
      );
      final remoteId = await _createPage(note, databaseId, refreshed);
      return note.copyWith(notionPageId: remoteId);
    }
  }

  Future<String> _createPage(
    Note note,
    String databaseId,
    NotionDatabaseSchema schema,
  ) {
    return _source.createPageFromPayload(
      NotionPayloadBuilder.buildCreatePagePayload(
        schema: schema,
        note: note,
        databaseId: databaseId,
      ),
    );
  }
}
