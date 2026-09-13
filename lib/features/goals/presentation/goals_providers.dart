import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../data/goals_repository.dart';
import '../domain/goal.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(supabaseClientProvider));
});

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchGoals();
});

final goalStepsStreamProvider = StreamProvider.family<List<GoalStep>, String>((ref, goalId) {
  return ref.watch(goalsRepositoryProvider).watchSteps(goalId);
});
