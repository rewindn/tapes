import 'package:hive/hive.dart';
import 'package:tapes/models/notion_settings.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  static const String key = 'notion';

  final Box<dynamic> _box;

  NotionSettings read() {
    final raw = _box.get(key);
    if (raw is Map) return NotionSettings.fromMap(raw);
    return const NotionSettings();
  }

  Future<void> save(NotionSettings settings) => _box.put(key, settings.toMap());

  Future<void> clear() => _box.delete(key);
}
