import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/note.dart';
import 'package:tapes/services/notion/notion_block_mapper.dart';
import 'package:tapes/services/notion/notion_client.dart';

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Object? headerValue(RequestOptions request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}

NotionClient createClient(MockHttpAdapter adapter, {String token = 'secret-token'}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return NotionClient.withToken(token, dio: dio);
}

void main() {
  test('withToken configures base url, headers, and timeouts', () {
    final dio = Dio();

    NotionClient.withToken('token-123', dio: dio);

    expect(dio.options.baseUrl, 'https://api.notion.com/v1/');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    expect(dio.options.headers['Authorization'], 'Bearer token-123');
    expect(dio.options.headers['Notion-Version'], '2022-06-28');
  });

  test('createPage posts mapped payload to /pages with auth headers', () async {
    final adapter = MockHttpAdapter(
      statusCode: 200,
      body: {'object': 'page', 'id': 'page-1'},
    );
    final client = createClient(adapter);
    final blocks = [
      TapeBlock(type: BlockType.text, text: 'Halo'),
      TapeBlock(type: BlockType.todo, text: 'Tugas', isChecked: true),
    ];

    final result = await client.createPage(
      databaseId: 'db-1',
      title: 'Catatan',
      blocks: blocks,
    );

    final request = adapter.request!;
    expect(request.method, 'POST');
    expect(request.path, '/pages');
    expect(request.uri.toString(), 'https://api.notion.com/v1/pages');
    expect(headerValue(request, 'Authorization'), 'Bearer secret-token');
    expect(headerValue(request, 'Notion-Version'), '2022-06-28');
    expect(headerValue(request, 'Content-Type'), 'application/json');

    final data = request.data! as Map<String, dynamic>;
    expect(data['parent'], {'database_id': 'db-1'});
    expect(data['properties'], {
      'title': {
        'title': [
          {
            'text': {'content': 'Catatan'},
          },
        ],
      },
    });
    expect(data['children'], NotionBlockMapper.blocksToNotionPayload(blocks));
    expect(result, {'object': 'page', 'id': 'page-1'});
  });

  test('createNotePage returns the remote page id', () async {
    final adapter = MockHttpAdapter(
      statusCode: 200,
      body: {'id': 'page-42'},
    );
    final client = createClient(adapter);

    final id = await client.createNotePage(
      databaseId: 'db',
      title: 't',
      blocks: <TapeBlock>[],
    );

    expect(id, 'page-42');
  });

  test('createNotePage throws when the response has no page id', () async {
    final adapter = MockHttpAdapter(statusCode: 200, body: {'object': 'page'});
    final client = createClient(adapter);

    await expectLater(
      client.createNotePage(databaseId: 'db', title: 't', blocks: <TapeBlock>[]),
      throwsA(isA<NotionApiException>()),
    );
  });

  test('fetchDatabaseSchema GETs the database endpoint', () async {
    final adapter = MockHttpAdapter(
      statusCode: 200,
      body: {'object': 'database', 'id': 'db-9'},
    );
    final client = createClient(adapter);

    final result = await client.fetchDatabaseSchema('db-9');

    final request = adapter.request!;
    expect(request.method, 'GET');
    expect(request.path, '/databases/db-9');
    expect(
      request.uri.toString(),
      'https://api.notion.com/v1/databases/db-9',
    );
    expect(headerValue(request, 'Authorization'), 'Bearer secret-token');
    expect(result['id'], 'db-9');
  });

  test('fetchDatabaseSchema maps 404 to NotionApiException', () async {
    final adapter = MockHttpAdapter(
      statusCode: 404,
      body: {'message': 'Not found'},
    );
    final client = createClient(adapter);

    await expectLater(
      client.fetchDatabaseSchema('db'),
      throwsA(
        isA<NotionApiException>()
            .having((error) => error.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('createPageFromPayload posts the given payload', () async {
    final adapter = MockHttpAdapter(
      statusCode: 200,
      body: {'id': 'page-7'},
    );
    final client = createClient(adapter);
    final payload = <String, dynamic>{
      'parent': {'database_id': 'db-1'},
      'properties': <String, dynamic>{},
    };

    final id = await client.createPageFromPayload(payload);

    final request = adapter.request!;
    expect(request.method, 'POST');
    expect(request.path, '/pages');
    expect(request.data, payload);
    expect(id, 'page-7');
  });

  test('createPage maps a 401 response to NotionApiException', () async {
    final adapter = MockHttpAdapter(
      statusCode: 401,
      body: {'message': 'Unauthorized', 'code': 'unauthorized'},
    );
    final client = createClient(adapter, token: 'bad-token');

    await expectLater(
      client.createPage(databaseId: 'db', title: 't', blocks: <TapeBlock>[]),
      throwsA(
        isA<NotionApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'Unauthorized'),
      ),
    );
  });

  test('createPage maps a 429 response to NotionApiException', () async {
    final adapter = MockHttpAdapter(
      statusCode: 429,
      body: {'message': 'Rate limit exceeded', 'code': 'rate_limited'},
    );
    final client = createClient(adapter);

    await expectLater(
      client.createPage(databaseId: 'db', title: 't', blocks: <TapeBlock>[]),
      throwsA(
        isA<NotionApiException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.message, 'message', 'Rate limit exceeded'),
      ),
    );
  });
}
