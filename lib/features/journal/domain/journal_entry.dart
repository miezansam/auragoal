class JournalEntry {
  JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.mood,
    required this.entryDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String content;
  final String? mood;
  final DateTime entryDate;
  final DateTime createdAt;

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      mood: map['mood'] as String?,
      entryDate: DateTime.parse(map['entry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

const moodOptions = [
  ('grateful', '🙏 Reconnaissant'),
  ('happy', '😊 Content'),
  ('neutral', '😐 Neutre'),
  ('tired', '😴 Fatigué'),
  ('stressed', '😰 Stressé'),
  ('sad', '😔 Triste'),
];
