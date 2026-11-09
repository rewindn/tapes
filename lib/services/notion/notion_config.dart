class NotionConfig {
  static const String token = String.fromEnvironment(
    'NOTION_TOKEN',
    defaultValue: '',
  );
  static const String databaseId = String.fromEnvironment(
    'NOTION_DATABASE_ID',
    defaultValue: '',
  );

  static bool get isConfigured => token.isNotEmpty && databaseId.isNotEmpty;
}
