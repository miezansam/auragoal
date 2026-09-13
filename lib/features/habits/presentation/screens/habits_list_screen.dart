import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../habits_providers.dart';
import '../widgets/create_habit_sheet.dart';
import '../widgets/habit_card.dart';

class HabitsListScreen extends ConsumerWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      body: habitsAsync.when(
        data: (habits) {
          final activeHabits = habits.where((h) => h.isActive).toList();
          if (activeHabits.isEmpty) {
            return Center(
              child: Text(
                'Aucune habitude — crée la première !',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: activeHabits.length,
            itemBuilder: (context, i) => HabitCard(habit: activeHabits[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateHabitSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
