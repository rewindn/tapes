import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/repositories/settings_repository.dart';
import 'package:tapes/services/notion/token_store.dart';
import 'package:tapes/ui/screens/inder_page.dart';
import 'package:tapes/ui/theme/app_theme.dart';
import 'package:tapes/viewmodels/notion_settings_controller.dart';

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
  await Hive.openBox<dynamic>('settings');

  final settingsController = NotionSettingsController(
    settingsRepository: SettingsRepository(Hive.box<dynamic>('settings')),
    tokenStore: SecureTokenStore(),
    schemaBox: Hive.box<dynamic>('notion_schema'),
  );
  await settingsController.initialize();

  final repository = NoteRepository(box: Hive.box<dynamic>('notebox'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NotionSettingsController>.value(
          value: settingsController,
        ),
        Provider<NoteRepository>.value(value: repository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext build) {
    return MaterialApp(theme: AppTheme.light, home: const InderPage());
  }
}
