import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits_providers.dart';

Future<void> showCreateHabitSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CreateHabitSheet(),
  );
}

class _CreateHabitSheet extends ConsumerStatefulWidget {
  const _CreateHabitSheet();

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(habitsRepositoryProvider).createHabit(title: _titleController.text.trim());
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
          Text('Nouvelle habitude', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
              hintText: 'Ex: Lire 10 minutes, boire 2L d\'eau...',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fréquence quotidienne par défaut — options avancées bientôt disponibles.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_titleController.text.trim().isEmpty || _isSaving) ? null : _submit,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer l\'habitude'),
          ),
        ],
      ),
    );
  }
}
