import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../domain/habit.dart';
import '../habits_providers.dart';

/// Calcule la série de jours consécutifs directement à partir des dates
/// de complétion déjà chargées en temps réel — évite toute dépendance à
/// un champ stocké côté serveur qui pourrait accuser un léger retard.
///
/// Règle : la série ne casse que si un jour ENTIER a été sauté. Si
/// aujourd'hui n'est pas encore coché mais qu'hier l'était, la série
/// reste affichée telle quelle (la journée n'est pas terminée) plutôt
/// que de retomber artificiellement à 0.
int _computeStreak(Set<String> completedDates) {
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  final todayKey = cursor.toIso8601String().split('T').first;
  if (!completedDates.contains(todayKey)) {
    final yesterday = cursor.subtract(const Duration(days: 1));
    final yesterdayKey = yesterday.toIso8601String().split('T').first;
    if (!completedDates.contains(yesterdayKey)) {
      return 0; // ni aujourd'hui ni hier : la série est réellement cassée
    }
    cursor = yesterday; // on compte la série encore active jusqu'à hier
  }

  var streak = 0;
  while (true) {
    final key = cursor.toIso8601String().split('T').first;
    if (completedDates.contains(key)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

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
            completionsAsync.when(
              data: (completions) {
                final streak = _computeStreak(completions);
                return Text('$streak jour${streak > 1 ? 's' : ''} de suite');
              },
              loading: () => Text('${habit.currentStreak} jour${habit.currentStreak > 1 ? 's' : ''} de suite'),
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
                // Filet de sécurité : rafraîchit le profil (XP/niveau)
                // au cas où l'événement Realtime tarderait à arriver.
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
