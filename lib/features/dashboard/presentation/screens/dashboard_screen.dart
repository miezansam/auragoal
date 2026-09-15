import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/presentation/goals_providers.dart';
import '../../../goals/presentation/widgets/goal_card.dart';
import '../../../habits/presentation/habits_providers.dart';
import '../../../habits/presentation/widgets/habit_card.dart';

/// Seuil XP nécessaire pour atteindre un niveau donné.
/// Doit rester cohérent avec la fonction SQL credit_xp_for_habit_completion.
int _xpForLevel(int level) => 50 * (level - 1) * (level - 1);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final habitsAsync = ref.watch(habitsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AURAGOAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentProfileProvider);
          ref.invalidate(goalsStreamProvider);
          ref.invalidate(habitsStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              data: (profile) => _GreetingCard(
                greeting: _greeting(),
                name: profile?.displayName,
                level: profile?.level ?? 1,
                xp: profile?.xp ?? 0,
              ),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Objectifs prioritaires', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            goalsAsync.when(
              data: (goals) {
                final active = goals.where((g) => g.status == GoalStatus.active).toList()
                  ..sort((a, b) => _priorityRank(b.priority).compareTo(_priorityRank(a.priority)));
                final topGoals = active.take(3).toList();
                if (topGoals.isEmpty) {
                  return _EmptyHint(
                    text: 'Aucun objectif actif pour l\'instant.',
                    actionLabel: 'Créer un objectif',
                    onTap: () => context.go('/goals'),
                  );
                }
                return Column(
                  children: topGoals
                      .map((goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: GoalCard(goal: goal, onTap: () => context.push('/goals/${goal.id}')),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erreur : $error'),
            ),
            const SizedBox(height: 24),
            Text('Habitudes du jour', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            habitsAsync.when(
              data: (habits) {
                final active = habits.where((h) => h.isActive).toList();
                if (active.isEmpty) {
                  return _EmptyHint(
                    text: 'Aucune habitude pour l\'instant.',
                    actionLabel: 'Créer une habitude',
                    onTap: () => context.go('/habits'),
                  );
                }
                return Column(
                  children: active.map((habit) => HabitCard(habit: habit)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Erreur : $error'),
            ),
          ],
        ),
      ),
    );
  }

  int _priorityRank(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.high:
        return 2;
      case GoalPriority.medium:
        return 1;
      case GoalPriority.low:
        return 0;
    }
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.greeting,
    required this.name,
    required this.level,
    required this.xp,
  });

  final String greeting;
  final String? name;
  final int level;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final currentLevelXp = _xpForLevel(level);
    final nextLevelXp = _xpForLevel(level + 1);
    final progress = nextLevelXp > currentLevelXp
        ? ((xp - currentLevelXp) / (nextLevelXp - currentLevelXp)).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name != null && name!.isNotEmpty ? '$greeting, $name !' : greeting,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text('$level', style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Niveau $level', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, minHeight: 8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$xp XP · ${nextLevelXp - xp > 0 ? nextLevelXp - xp : 0} XP avant le niveau ${level + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.actionLabel, required this.onTap});

  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
