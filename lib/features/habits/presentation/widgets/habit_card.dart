import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/habit.dart';
import '../habits_providers.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final completionsAsync = ref.watch(habitCompletionsStreamProvider(habit.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(habit.title),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text('${habit.currentStreak} jour${habit.currentStreak > 1 ? 's' : ''} de suite'),
          ],
        ),
        trailing: completionsAsync.when(
          data: (completions) {
            final doneToday = completions.contains(today);
            return IconButton(
              iconSize: 32,
              icon: Icon(
                doneToday ? Icons.check_circle : Icons.circle_outlined,
                color: doneToday ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                final repo = ref.read(habitsRepositoryProvider);
                if (doneToday) {
                  repo.undoCheckInToday(habit.id);
                } else {
                  repo.checkInToday(habit.id);
                }
              },
            );
          },
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error_outline),
        ),
      ),
    );
  }
}
