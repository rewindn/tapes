import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'note.g.dart'; // Generate this with: flutter pub run build_runner build

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String note;

  @HiveField(2)
  late DateTime createdAt;

  Note({
    String? id,
    required this.note,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }


  // Convert to Map (untuk save ke Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'createdAt': createdAt.toString(),
    };
  }

  // Convert dari Map (untuk load dari Hive)
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  @override
  String toString() => 'Note(id: $id, note: $note, date: $createdAt)';
}
