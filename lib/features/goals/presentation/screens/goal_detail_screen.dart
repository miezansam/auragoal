import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/goal.dart';
import '../goals_providers.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final _newStepController = TextEditingController();

  @override
  void dispose() {
    _newStepController.dispose();
    super.dispose();
  }

  Future<void> _addStep(List<GoalStep> currentSteps) async {
    final title = _newStepController.text.trim();
    if (title.isEmpty) return;
    _newStepController.clear();
    await ref.read(goalsRepositoryProvider).addStep(widget.goalId, title, currentSteps.length);
  }

  Future<void> _toggleStep(GoalStep step) async {
    await ref.read(goalsRepositoryProvider).toggleStep(step.id, !step.isCompleted);
    await ref.read(goalsRepositoryProvider).recalculateProgressFromSteps(widget.goalId);
  }

  Future<void> _archiveGoal() async {
    await ref.read(goalsRepositoryProvider).updateStatus(widget.goalId, GoalStatus.archived);
    if (mounted) context.pop();
  }

  Future<void> _markCompleted() async {
    await ref.read(goalsRepositoryProvider).updateStatus(widget.goalId, GoalStatus.completed);
    await ref.read(goalsRepositoryProvider).updateProgress(widget.goalId, 100);
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final stepsAsync = ref.watch(goalStepsStreamProvider(widget.goalId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'complete') _markCompleted();
              if (value == 'archive') _archiveGoal();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'complete', child: Text('Marquer comme terminé')),
              PopupMenuItem(value: 'archive', child: Text('Archiver')),
            ],
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          final matches = goals.where((g) => g.id == widget.goalId);
          final goal = matches.isEmpty ? null : matches.first;
          if (goal == null) {
            return const Center(child: Text('Objectif introuvable.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(goal.title, style: Theme.of(context).textTheme.headlineSmall),
              if (goal.category != null) ...[
                const SizedBox(height: 4),
                Chip(label: Text(goal.category!)),
              ],
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goal.progress / 100).clamp(0, 1),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text('${goal.progress.round()}% complété'),
              const SizedBox(height: 24),
              Text('Étapes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              stepsAsync.when(
                data: (steps) {
                  return Column(
                    children: [
                      ...steps.map((step) => CheckboxListTile(
                            value: step.isCompleted,
                            onChanged: (_) => _toggleStep(step),
                            title: Text(
                              step.title,
                              style: step.isCompleted
                                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                                  : null,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          )),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newStepController,
                                decoration: const InputDecoration(
                                  hintText: 'Ajouter une étape...',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addStep(steps),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () => _addStep(steps),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Erreur : $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
    );
  }
}
