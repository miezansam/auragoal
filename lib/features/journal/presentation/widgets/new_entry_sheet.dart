import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/journal_entry.dart';
import '../journal_providers.dart';

Future<void> showNewJournalEntrySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _NewEntrySheet(),
  );
}

class _NewEntrySheet extends ConsumerStatefulWidget {
  const _NewEntrySheet();

  @override
  ConsumerState<_NewEntrySheet> createState() => _NewEntrySheetState();
}

class _NewEntrySheetState extends ConsumerState<_NewEntrySheet> {
  final _contentController = TextEditingController();
  String? _selectedMood;
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(journalRepositoryProvider).addEntry(
            content: _contentController.text.trim(),
            mood: _selectedMood,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Comment te sens-tu ?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moodOptions.map((option) {
              final (id, label) = option;
              return ChoiceChip(
                label: Text(label),
                selected: _selectedMood == id,
                onSelected: (_) => setState(() => _selectedMood = _selectedMood == id ? null : id),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _contentController,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Écris librement — gratitude, réflexion, ce qui te passe par la tête...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ton journal est privé par défaut.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_contentController.text.trim().isEmpty || _isSaving) ? null : _submit,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
