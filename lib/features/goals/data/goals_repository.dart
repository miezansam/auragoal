import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/goal.dart';

class GoalsRepository {
  GoalsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  /// Flux temps réel de tous les objectifs de l'utilisateur.
  Stream<List<Goal>> watchGoals() {
    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at')
        .map((rows) => rows.map(Goal.fromMap).toList());
  }

  Future<Goal> createGoal({
    required String title,
    String? description,
    String? category,
    GoalPriority priority = GoalPriority.medium,
    DateTime? dueDate,
  }) async {
    final goal = Goal(
      id: '',
      userId: _userId,
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    final row = await _client.from('goals').insert(goal.toInsertMap()).select().single();
    return Goal.fromMap(row);
  }

  Future<void> updateStatus(String goalId, GoalStatus status) {
    return _client.from('goals').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }

  Future<void> updateProgress(String goalId, double progress) {
    return _client.from('goals').update({
      'progress': progress,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', goalId);
  }

  Future<void> deleteGoal(String goalId) {
    return _client.from('goals').delete().eq('id', goalId);
  }

  // ---- Étapes (goal_steps) ----

  Stream<List<GoalStep>> watchSteps(String goalId) {
    return _client
        .from('goal_steps')
        .stream(primaryKey: ['id'])
        .eq('goal_id', goalId)
        .order('order_index')
        .map((rows) => rows.map(GoalStep.fromMap).toList());
  }

  Future<void> addStep(String goalId, String title, int orderIndex) {
    return _client.from('goal_steps').insert({
      'goal_id': goalId,
      'user_id': _userId,
      'title': title,
      'order_index': orderIndex,
    });
  }

  Future<void> toggleStep(String stepId, bool isCompleted) {
    return _client.from('goal_steps').update({'is_completed': isCompleted}).eq('id', stepId);
  }

  Future<void> deleteStep(String stepId) {
    return _client.from('goal_steps').delete().eq('id', stepId);
  }

  /// Recalcule la progression d'un objectif à partir de ses étapes
  /// (0 étape = pas de changement automatique de la progression).
  Future<void> recalculateProgressFromSteps(String goalId) async {
    final steps = await _client.from('goal_steps').select('is_completed').eq('goal_id', goalId);
    if (steps.isEmpty) return;
    final completedCount = steps.where((s) => s['is_completed'] == true).length;
    final progress = (completedCount / steps.length) * 100;
    await updateProgress(goalId, progress);
    if (progress >= 100) {
      await updateStatus(goalId, GoalStatus.completed);
    }
  }
}
