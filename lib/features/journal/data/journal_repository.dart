import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Stream<List<JournalEntry>> watchEntries() {
    return _client
        .from('journal_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('entry_date', ascending: false)
        .map((rows) => rows.map(JournalEntry.fromMap).toList());
  }

  Future<void> addEntry({required String content, String? mood}) {
    final today = DateTime.now().toIso8601String().split('T').first;
    return _client.from('journal_entries').insert({
      'user_id': _userId,
      'content': content,
      'mood': mood,
      'entry_date': today,
    });
  }

  Future<void> deleteEntry(String entryId) {
    return _client.from('journal_entries').delete().eq('id', entryId);
  }
}
