import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/goal.dart';
import '../goals_providers.dart';

Future<void> showCreateGoalSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CreateGoalSheet(),
  );
}

class _CreateGoalSheet extends ConsumerStatefulWidget {
  const _CreateGoalSheet();

  @override
  ConsumerState<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<_CreateGoalSheet> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  GoalPriority _priority = GoalPriority.medium;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(goalsRepositoryProvider).createGoal(
            title: _titleController.text.trim(),
            category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
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
          Text('Nouvel objectif', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Catégorie (optionnel)',
              border: OutlineInputBorder(),
              hintText: 'Ex: Santé, Carrière...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Priorité :'),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<GoalPriority>(
                  segments: const [
                    ButtonSegment(value: GoalPriority.low, label: Text('Basse')),
                    ButtonSegment(value: GoalPriority.medium, label: Text('Moyenne')),
                    ButtonSegment(value: GoalPriority.high, label: Text('Haute')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selection) => setState(() => _priority = selection.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDueDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _dueDate == null
                  ? 'Définir une échéance (optionnel)'
                  : 'Échéance : ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_titleController.text.trim().isEmpty || _isSaving) ? null : _submit,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Créer l\'objectif'),
          ),
        ],
      ),
    );
  }
}
