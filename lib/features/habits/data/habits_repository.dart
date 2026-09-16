import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/habit.dart';

class HabitsRepository {
  HabitsRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  Stream<List<Habit>> watchHabits() {
    return _client
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at')
        .map((rows) => rows.map(Habit.fromMap).toList());
  }

  Future<Habit> createHabit({
    required String title,
    String? goalId,
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> daysOfWeek = const [],
  }) async {
    final habit = Habit(
      id: '',
      userId: _userId,
      title: title,
      goalId: goalId,
      frequency: frequency,
      daysOfWeek: daysOfWeek,
      createdAt: DateTime.now(),
    );
    final row = await _client.from('habits').insert(habit.toInsertMap()).select().single();
    return Habit.fromMap(row);
  }

  Future<void> setActive(String habitId, bool isActive) {
    return _client.from('habits').update({'is_active': isActive}).eq('id', habitId);
  }

  Future<void> deleteHabit(String habitId) {
    return _client.from('habits').delete().eq('id', habitId);
  }

  /// Renvoie les dates (YYYY-MM-DD) où l'habitude a été complétée.
  /// C'est la SEULE source que l'app utilise pour calculer et afficher
  /// la série — toujours en direct, jamais depuis une valeur mise en cache.
  Stream<Set<String>> watchCompletions(String habitId) {
    return _client
        .from('habit_completions')
        .stream(primaryKey: ['id'])
        .eq('habit_id', habitId)
        .map((rows) => rows.map((r) => r['completed_at'] as String).toSet());
  }

  Future<bool> isCompletedToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final rows = await _client
        .from('habit_completions')
        .select('id')
        .eq('habit_id', habitId)
        .eq('completed_at', today);
    return rows.isNotEmpty;
  }

  /// Check-in du jour + crédit XP sécurisé. Ne fait rien si déjà fait aujourd'hui.
  Future<void> checkInToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final alreadyDone = await isCompletedToday(habitId);
    if (alreadyDone) return;

    await _client.from('habit_completions').insert({
      'habit_id': habitId,
      'user_id': _userId,
      'completed_at': today,
    });

    await _client.rpc('credit_xp_for_habit_completion', params: {
      'p_habit_id': habitId,
      'p_completed_at': today,
    });

    await _updateStoredStreakStats(habitId);
  }

  Future<void> undoCheckInToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    await _client
        .from('habit_completions')
        .delete()
        .eq('habit_id', habitId)
        .eq('completed_at', today);

    await _updateStoredStreakStats(habitId);
  }

  /// Met à jour longest_streak (record historique) et current_streak
  /// dans la table habits. ATTENTION : ces colonnes sont purement
  /// informatives (utiles plus tard pour des exports, des bilans AURA,
  /// ou des requêtes analytiques côté base). L'app ne les lit JAMAIS
  /// pour l'affichage — computeCurrentStreak() est systématiquement
  /// recalculée en direct depuis watchCompletions(), qui est la seule
  /// source de vérité pour ce que voit l'utilisateur. Utilise la même
  /// fonction de calcul que l'affichage : aucune logique dupliquée.
  Future<void> _updateStoredStreakStats(String habitId) async {
    final rows = await _client
        .from('habit_completions')
        .select('completed_at')
        .eq('habit_id', habitId);

    final habitRow = await _client
        .from('habits')
        .select('longest_streak')
        .eq('id', habitId)
        .single();
    final previousLongest = habitRow['longest_streak'] as int? ?? 0;

    final completedDates = rows.map((r) => r['completed_at'] as String).toSet();
    final streak = computeCurrentStreak(completedDates);

    await _client.from('habits').update({
      'current_streak': streak,
      'longest_streak': streak > previousLongest ? streak : previousLongest,
    }).eq('id', habitId);
  }
}
