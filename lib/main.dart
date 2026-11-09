import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tapes/index.dart';
import 'package:tapes/note_repository.dart';
import 'package:tapes/services/notion/notion_client.dart';
import 'package:tapes/services/notion/notion_config.dart';
import 'package:tapes/services/notion/notion_schema_service.dart';
import 'package:tapes/services/notion/notion_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeDateFormatting('id', null);
  await Hive.initFlutter();
  await Hive.openBox<dynamic>('notebox');
  await Hive.openBox<dynamic>('notion_schema');

  NotionSyncService? syncService;
  if (NotionConfig.isConfigured) {
    final client = NotionClient.withToken(NotionConfig.token);
    syncService = NotionSyncService(
      client,
      NotionSchemaService(client, Hive.box<dynamic>('notion_schema')),
    );
  }

  final sync = syncService;
  final repository = NoteRepository(
    box: Hive.box<dynamic>('notebox'),
    syncHandler: sync == null
        ? null
        : (note) => sync.syncNote(
            note,
            databaseId: NotionConfig.databaseId,
          ),
  );

  runApp(
    Provider<NoteRepository>(
      create: (_) => repository,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext build) {
    return const MaterialApp(home: InderPage());
  }
}
