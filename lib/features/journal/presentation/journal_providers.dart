import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/journal_repository.dart';
import '../domain/journal_entry.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref.watch(supabaseClientProvider));
});

final journalEntriesStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  return ref.watch(journalRepositoryProvider).watchEntries();
});
