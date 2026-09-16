import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../../../core/services/notifications_service.dart';
import '../../domain/habit.dart';
import '../habits_providers.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final completionsAsync = ref.watch(habitCompletionsStreamProvider(habit.id));

    // La série n'est JAMAIS lue depuis une valeur stockée (habit.currentStreak) :
    // elle est recalculée à chaque affichage via computeCurrentStreak(), à
    // partir du flux temps réel des complétions réelles. Ainsi, même si tu
    // n'ouvres pas l'app pendant plusieurs jours, la valeur affichée est
    // toujours exacte au moment où tu la regardes — jamais périmée.
    completionsAsync.whenData((completions) {
      final doneToday = completions.contains(today);
      if (doneToday) {
        NotificationsService.cancelReminder(habit.id);
      } else {
        NotificationsService.scheduleGentleStreakReminder(
          habitId: habit.id,
          habitTitle: habit.title,
          currentStreak: computeCurrentStreak(completions),
        );
      }
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(habit.title),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            completionsAsync.when(
              data: (completions) {
                final streak = computeCurrentStreak(completions);
                return Text('$streak jour${streak > 1 ? 's' : ''} de suite');
              },
              loading: () => const Text('...'),
              error: (_, __) => const Text('—'),
            ),
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
              onPressed: () async {
                final repo = ref.read(habitsRepositoryProvider);
                if (doneToday) {
                  await repo.undoCheckInToday(habit.id);
                } else {
                  await repo.checkInToday(habit.id);
                }
                ref.invalidate(currentProfileProvider);
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
