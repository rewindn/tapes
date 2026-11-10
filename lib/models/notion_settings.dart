class NotionSettings {
  final String databaseId;
  final String? databaseName;
  final bool isConnected;
  final DateTime? lastCheckedAt;

  const NotionSettings({
    this.databaseId = '',
    this.databaseName,
    this.isConnected = false,
    this.lastCheckedAt,
  });

  NotionSettings copyWith({
    String? databaseId,
    String? databaseName,
    bool? isConnected,
    DateTime? lastCheckedAt,
  }) {
    return NotionSettings(
      databaseId: databaseId ?? this.databaseId,
      databaseName: databaseName ?? this.databaseName,
      isConnected: isConnected ?? this.isConnected,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'databaseId': databaseId,
      'databaseName': databaseName,
      'isConnected': isConnected,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    };
  }

  factory NotionSettings.fromMap(Map<dynamic, dynamic> map) {
    return NotionSettings(
      databaseId: map['databaseId'] is String
          ? map['databaseId'] as String
          : '',
      databaseName: map['databaseName'] is String
          ? map['databaseName'] as String
          : null,
      isConnected: map['isConnected'] == true,
      lastCheckedAt: DateTime.tryParse(
        map['lastCheckedAt']?.toString() ?? '',
      ),
    );
  }
}
