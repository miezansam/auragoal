import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/journal_entry.dart';
import '../journal_providers.dart';
import '../widgets/new_entry_sheet.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  String _moodLabel(String? moodId) {
    if (moodId == null) return '';
    final match = moodOptions.where((m) => m.$1 == moodId);
    return match.isEmpty ? '' : match.first.$2;
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'Aucune entrée — commence à écrire.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDate(entry.entryDate),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (entry.mood != null) ...[
                            const SizedBox(width: 8),
                            Text(_moodLabel(entry.mood)),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              try {
                                await ref.read(journalRepositoryProvider).deleteEntry(entry.id);
                                // Filet de sécurité : force un rafraîchissement au cas où
                                // l'événement Realtime de suppression n'arriverait pas.
                                ref.invalidate(journalEntriesStreamProvider);
                              } catch (e) {
                                debugPrint('Erreur suppression journal_entries: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Suppression impossible.')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(entry.content),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNewJournalEntrySheet(context, ref),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
