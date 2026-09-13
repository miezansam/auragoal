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

  /// Check-in du jour + recalcul de la série. Ne fait rien si déjà fait aujourd'hui.
  Future<void> checkInToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final alreadyDone = await isCompletedToday(habitId);
    if (alreadyDone) return;

    await _client.from('habit_completions').insert({
      'habit_id': habitId,
      'user_id': _userId,
      'completed_at': today,
    });

    await _recalculateStreak(habitId);

    // Crédit XP via fonction serveur sécurisée (anti-fraude, anti-double-crédit).
    await _client.rpc('credit_xp_for_habit_completion', params: {
      'p_habit_id': habitId,
      'p_completed_at': today,
    });
  }

  Future<void> undoCheckInToday(String habitId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    await _client
        .from('habit_completions')
        .delete()
        .eq('habit_id', habitId)
        .eq('completed_at', today);
    await _recalculateStreak(habitId);
  }

  Future<void> _recalculateStreak(String habitId) async {
    final rows = await _client
        .from('habit_completions')
        .select('completed_at')
        .eq('habit_id', habitId)
        .order('completed_at', ascending: false);

    if (rows.isEmpty) {
      await _client.from('habits').update({'current_streak': 0}).eq('id', habitId);
      return;
    }

    final dates = rows.map((r) => DateTime.parse(r['completed_at'] as String)).toList();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (final date in dates) {
      final normalized = DateTime(date.year, date.month, date.day);
      if (normalized == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (normalized.isBefore(cursor)) {
        break;
      }
    }

    await _client.from('habits').update({'current_streak': streak}).eq('id', habitId);
  }
}
