enum HabitFrequency { daily, specificDays, weekly }

/// Calcule la série de jours consécutifs (jour de grâce jusqu'à la fin de
/// la journée en cours) à partir des dates de complétion réelles.
///
/// SOURCE UNIQUE de cette logique dans tout le projet — utilisée à la
/// fois pour l'affichage (toujours recalculée en direct depuis le flux
/// temps réel, donc jamais périmée) et par HabitsRepository (pour mettre
/// à jour longest_streak en base). Ne jamais dupliquer cet algorithme
/// ailleurs : si la règle change, elle ne doit changer qu'ici.
int computeCurrentStreak(Set<String> completedDates) {
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  final todayKey = cursor.toIso8601String().split('T').first;
  if (!completedDates.contains(todayKey)) {
    final yesterday = cursor.subtract(const Duration(days: 1));
    final yesterdayKey = yesterday.toIso8601String().split('T').first;
    if (!completedDates.contains(yesterdayKey)) {
      return 0; // ni aujourd'hui ni hier : la série est réellement cassée
    }
    cursor = yesterday;
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

class Habit {
  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.goalId,
    this.frequency = HabitFrequency.daily,
    this.daysOfWeek = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? goalId;
  final HabitFrequency frequency;
  final List<int> daysOfWeek; // 0=dimanche ... 6=samedi
  final int currentStreak;
  final int longestStreak;
  final bool isActive;
  final DateTime createdAt;

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      goalId: map['goal_id'] as String?,
      frequency: _matchFrequency(map['frequency'] as String? ?? 'daily'),
      daysOfWeek: (map['days_of_week'] as List<dynamic>?)?.cast<int>() ?? [],
      currentStreak: map['current_streak'] as int? ?? 0,
      longestStreak: map['longest_streak'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static HabitFrequency _matchFrequency(String value) {
    switch (value) {
      case 'specific_days':
        return HabitFrequency.specificDays;
      case 'weekly':
        return HabitFrequency.weekly;
      default:
        return HabitFrequency.daily;
    }
  }

  static String _dbValueFor(HabitFrequency frequency) => switch (frequency) {
        HabitFrequency.daily => 'daily',
        HabitFrequency.specificDays => 'specific_days',
        HabitFrequency.weekly => 'weekly',
      };

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'goal_id': goalId,
      'frequency': _dbValueFor(frequency),
      'days_of_week': daysOfWeek,
    };
  }
}
