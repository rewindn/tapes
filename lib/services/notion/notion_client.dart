import 'package:dio/dio.dart';
import 'package:tapes/note.dart';
import 'package:tapes/services/notion/notion_block_mapper.dart';
import 'package:tapes/services/notion/remote_note_data_source.dart';
import 'package:tapes/services/notion/remote_schema_data_source.dart';

class NotionApiException implements Exception {
  const NotionApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NotionApiException($statusCode): $message';
}

class NotionClient implements RemoteNoteDataSource, RemoteSchemaDataSource {
  NotionClient(this._dio);

  factory NotionClient.withToken(String token, {Dio? dio}) {
    final client = dio ?? Dio();
    client.options
      ..baseUrl = 'https://api.notion.com/v1/'
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      });
    return NotionClient(client);
  }

  final Dio _dio;

  @override
  Future<String> createNotePage({
    required String databaseId,
    required String title,
    required List<TapeBlock> blocks,
  }) async {
    final response = await createPage(
      databaseId: databaseId,
      title: title,
      blocks: blocks,
    );
    return _extractPageId(response);
  }

  @override
  Future<String> createPageFromPayload(Map<String, dynamic> payload) async {
    final response = await _createPageRequest(payload);
    return _extractPageId(response);
  }

  Future<Map<String, dynamic>> createPage({
    required String databaseId,
    required String title,
    required List<TapeBlock> blocks,
  }) {
    final Map<String, dynamic> payload = {
      'parent': {'database_id': databaseId},
      'properties': {
        'title': {
          'title': [
            {
              'text': {'content': title},
            },
          ],
        },
      },
      'children': NotionBlockMapper.blocksToNotionPayload(blocks),
    };
    return _createPageRequest(payload);
  }

  Future<Map<String, dynamic>> _createPageRequest(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/pages',
        data: payload,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw NotionApiException(_errorMessage(error), error.response?.statusCode);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchDatabaseSchema(String databaseId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/databases/$databaseId',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      throw const NotionApiException('Notion response is not a valid object');
    } on DioException catch (error) {
      throw NotionApiException(_errorMessage(error), error.response?.statusCode);
    }
  }

  String _extractPageId(Map<String, dynamic> response) {
    final id = response['id'];
    if (id is! String || id.isEmpty) {
      throw const NotionApiException('Notion response is missing a page id');
    }
    return id;
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return error.message ?? 'Notion request failed';
  }
}
