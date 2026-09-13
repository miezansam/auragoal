import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/habits_repository.dart';
import '../domain/habit.dart';

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepository(ref.watch(supabaseClientProvider));
});

final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitsRepositoryProvider).watchHabits();
});

final habitCompletionsStreamProvider = StreamProvider.family<Set<String>, String>((ref, habitId) {
  return ref.watch(habitsRepositoryProvider).watchCompletions(habitId);
});
