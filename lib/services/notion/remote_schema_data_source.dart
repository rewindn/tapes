abstract interface class RemoteSchemaDataSource {
  Future<Map<String, dynamic>> fetchDatabaseSchema(String databaseId);
}
